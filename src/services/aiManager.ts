import AsyncStorage from '@react-native-async-storage/async-storage';
import { useHabits } from '../contexts/HabitContext';
import { AIInsight, Habit, HabitEntry } from '../types/habit';
import { calculateStreak } from '../utils/habitUtils';
import { AIProvider, UnifiedAIService, createAIService, getAvailableModels, getDefaultModel } from './aiService';

const AI_CONFIG_STORAGE = '@habiter_ai_config';

interface StoredAIConfig {
  provider: AIProvider;
  apiKey: string;
  model: string;
}

export class AIManager {
  private static aiService: UnifiedAIService | null = null;
  private static config: StoredAIConfig | null = null;

  static async saveConfig(config: StoredAIConfig): Promise<void> {
    try {
      await AsyncStorage.setItem(AI_CONFIG_STORAGE, JSON.stringify(config));
      this.config = config;
      this.aiService = createAIService(config);
    } catch (error) {
      console.error('Error saving AI config:', error);
      throw error;
    }
  }

  static async getConfig(): Promise<StoredAIConfig | null> {
    try {
      const stored = await AsyncStorage.getItem(AI_CONFIG_STORAGE);
      if (stored) {
        this.config = JSON.parse(stored);
        return this.config;
      }
      return null;
    } catch (error) {
      console.error('Error getting AI config:', error);
      return null;
    }
  }

  static async clearConfig(): Promise<void> {
    try {
      await AsyncStorage.removeItem(AI_CONFIG_STORAGE);
      this.config = null;
      this.aiService = null;
    } catch (error) {
      console.error('Error clearing AI config:', error);
      throw error;
    }
  }

  static async initializeService(): Promise<boolean> {
    try {
      const config = await this.getConfig();
      if (config) {
        this.aiService = createAIService(config);
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error initializing AI service:', error);
      return false;
    }
  }

  static isConfigured(): boolean {
    return this.aiService !== null;
  }

  static getCurrentProvider(): AIProvider | null {
    return this.config?.provider || null;
  }

  static getCurrentModel(): string | null {
    return this.config?.model || null;
  }

  // Backward compatibility methods
  static async saveApiKey(apiKey: string): Promise<void> {
    await this.saveConfig({
      provider: 'glm',
      apiKey,
      model: getDefaultModel('glm'),
    });
  }

  static async getApiKey(): Promise<string | null> {
    const config = await this.getConfig();
    return config?.apiKey || null;
  }

  static async clearApiKey(): Promise<void> {
    await this.clearConfig();
  }

  static async generateDailyInsights(
    habits: Habit[],
    habitEntries: HabitEntry[],
    addInsight: (insight: Omit<AIInsight, 'id' | 'createdAt'>) => Promise<void>
  ): Promise<void> {
    if (!this.aiService || habits.length === 0) return;

    try {
      // 1. Generate habit recommendation if user has < 5 habits
      if (habits.length < 5) {
        try {
          const recommendation = await this.aiService.generateHabitRecommendation(habits);
          await addInsight({
            type: recommendation.type,
            title: recommendation.title,
            message: recommendation.message,
            confidence: recommendation.confidence,
            isRead: false,
          });
        } catch (error) {
          console.warn('Failed to generate habit recommendation:', error);
        }
      }

      // 2. Generate motivational messages for high-streak habits
      const highStreakHabits = habits.filter(habit => {
        const streak = calculateStreak(habit.id, habitEntries);
        return streak.currentStreak >= 7;
      });

      // Only generate for top 2 streaks to avoid spam
      const topStreaks = highStreakHabits
        .map(habit => ({
          habit,
          streak: calculateStreak(habit.id, habitEntries).currentStreak,
        }))
        .sort((a, b) => b.streak - a.streak)
        .slice(0, 2);

      for (const { habit, streak } of topStreaks) {
        try {
          const motivation = await this.aiService.generateMotivationalMessage(habit, streak);
          await addInsight({
            habitId: motivation.habitId,
            type: motivation.type,
            title: motivation.title,
            message: motivation.message,
            confidence: motivation.confidence,
            isRead: false,
          });
        } catch (error) {
          console.warn(`Failed to generate motivation for habit ${habit.name}:`, error);
        }
      }

      // 3. Generate personalized tips if enough data
      if (habitEntries.length > 20) {
        try {
          const tips = await this.aiService.generatePersonalizedTips(habits, habitEntries);
          await addInsight({
            type: tips.type,
            title: tips.title,
            message: tips.message,
            confidence: tips.confidence,
            isRead: false,
          });
        } catch (error) {
          console.warn('Failed to generate personalized tips:', error);
        }
      }

      // 4. Analyze struggling habits (< 50% completion rate)
      const strugglingHabits = habits.filter(habit => {
        const habitData = habitEntries.filter(e => e.habitId === habit.id);
        if (habitData.length < 7) return false;
        const completionRate = habitData.filter(e => e.completed).length / habitData.length;
        return completionRate < 0.5;
      }).slice(0, 1); // Only analyze 1 to avoid overwhelming

      for (const habit of strugglingHabits) {
        try {
          const habitData = habitEntries.filter(e => e.habitId === habit.id);
          const analysis = await this.aiService.analyzeHabitPattern(habit, habitData);
          await addInsight({
            habitId: analysis.habitId,
            type: analysis.type,
            title: analysis.title,
            message: analysis.message,
            confidence: analysis.confidence,
            isRead: false,
          });
        } catch (error) {
          console.warn(`Failed to analyze habit ${habit.name}:`, error);
        }
      }
    } catch (error) {
      console.error('Error generating daily insights:', error);
      throw error;
    }
  }

  static async analyzeHabit(
    habit: Habit,
    habitEntries: HabitEntry[],
    addInsight: (insight: Omit<AIInsight, 'id' | 'createdAt'>) => Promise<void>
  ): Promise<void> {
    if (!this.aiService) return;

    try {
      const habitData = habitEntries.filter(entry => entry.habitId === habit.id);

      if (habitData.length >= 7) {
        // Generate analysis
        const analysis = await this.aiService.analyzeHabitPattern(habit, habitData);
        await addInsight({
          habitId: analysis.habitId,
          type: analysis.type,
          title: analysis.title,
          message: analysis.message,
          confidence: analysis.confidence,
          isRead: false,
        });

        // Generate prediction if enough data
        if (habitData.length >= 14) {
          const prediction = await this.aiService.predictHabitSuccess(habit, habitData);
          await addInsight({
            habitId: prediction.habitId,
            type: prediction.type,
            title: prediction.title,
            message: prediction.message,
            confidence: prediction.confidence,
            isRead: false,
          });
        }
      }
    } catch (error) {
      console.error('Error analyzing habit:', error);
      throw error;
    }
  }

  static async testConnection(): Promise<boolean> {
    if (!this.aiService) return false;

    try {
      const testHabit: Habit = {
        id: 'test',
        name: 'Morning Exercise',
        description: 'Test habit',
        category: 'Health',
        frequency: 'daily',
        targetCount: 1,
        color: '#8B5CF6',
        icon: '🧪',
        createdAt: new Date(),
        isActive: true,
      };

      await this.aiService.generateHabitRecommendation([testHabit]);
      return true;
    } catch (error) {
      console.error('AI connection test failed:', error);
      return false;
    }
  }
}

// Hook for easy AI management in components
export const useAIManager = () => {
  const { habits, habitEntries, addAIInsight } = useHabits();

  const generateInsights = async () => {
    await AIManager.generateDailyInsights(habits, habitEntries, addAIInsight);
  };

  const analyzeHabit = async (habit: Habit) => {
    await AIManager.analyzeHabit(habit, habitEntries, addAIInsight);
  };

  const setupAI = async (config: StoredAIConfig) => {
    await AIManager.saveConfig(config);
  };

  const setupApiKey = async (apiKey: string) => {
    await AIManager.saveApiKey(apiKey);
  };

  const testConnection = async () => {
    return await AIManager.testConnection();
  };

  const getCurrentConfig = async () => {
    return await AIManager.getConfig();
  };

  return {
    generateInsights,
    analyzeHabit,
    setupAI,
    setupApiKey, // Backward compatibility
    testConnection,
    getCurrentConfig,
    isConfigured: AIManager.isConfigured(),
    currentProvider: AIManager.getCurrentProvider(),
    currentModel: AIManager.getCurrentModel(),
  };
};

// Export utility functions
export { getAvailableModels, getDefaultModel };
export type { AIProvider, StoredAIConfig };
