import AsyncStorage from '@react-native-async-storage/async-storage';
import { GLMService, createGLMService } from './glm';
import { useHabits } from '../contexts/HabitContext';
import { Habit, HabitEntry, AIInsight } from '../types/habit';
import { calculateStreak } from '../utils/habitUtils';

const GLM_API_KEY_STORAGE = '@habiter_glm_api_key';

export class AIManager {
  private static glmService: GLMService | null = null;

  static async saveApiKey(apiKey: string): Promise<void> {
    try {
      await AsyncStorage.setItem(GLM_API_KEY_STORAGE, apiKey);
      this.glmService = createGLMService(apiKey);
    } catch (error) {
      console.error('Error saving API key:', error);
      throw error;
    }
  }

  static async getApiKey(): Promise<string | null> {
    try {
      return await AsyncStorage.getItem(GLM_API_KEY_STORAGE);
    } catch (error) {
      console.error('Error getting API key:', error);
      return null;
    }
  }

  static async clearApiKey(): Promise<void> {
    try {
      await AsyncStorage.removeItem(GLM_API_KEY_STORAGE);
      this.glmService = null;
    } catch (error) {
      console.error('Error clearing API key:', error);
      throw error;
    }
  }

  static async initializeService(): Promise<boolean> {
    try {
      const apiKey = await this.getApiKey();
      if (apiKey) {
        this.glmService = createGLMService(apiKey);
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error initializing AI service:', error);
      return false;
    }
  }

  static isConfigured(): boolean {
    return this.glmService !== null;
  }

  static async generateDailyInsights(
    habits: Habit[],
    habitEntries: HabitEntry[],
    addInsight: (insight: Omit<AIInsight, 'id' | 'createdAt'>) => Promise<void>
  ): Promise<void> {
    if (!this.glmService || habits.length === 0) return;

    try {
      // Generate habit recommendation if user has < 5 habits
      if (habits.length < 5) {
        const recommendation = await this.glmService.generateHabitRecommendation(habits);
        await addInsight({
          type: recommendation.type,
          title: recommendation.title,
          message: recommendation.message,
          confidence: recommendation.confidence,
          isRead: false,
        });
      }

      // Generate motivational messages for high-streak habits
      for (const habit of habits) {
        const streak = calculateStreak(habit.id, habitEntries);
        if (streak.currentStreak >= 7) {
          try {
            const motivation = await this.glmService.generateMotivationalMessage(habit, streak.currentStreak);
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
      }

      // Generate personalized tips
      if (habitEntries.length > 10) {
        try {
          const tips = await this.glmService.generatePersonalizedTips(habits, habitEntries);
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
    } catch (error) {
      console.error('Error generating daily insights:', error);
    }
  }

  static async analyzeHabit(
    habit: Habit,
    habitEntries: HabitEntry[],
    addInsight: (insight: Omit<AIInsight, 'id' | 'createdAt'>) => Promise<void>
  ): Promise<void> {
    if (!this.glmService) return;

    try {
      const habitData = habitEntries.filter(entry => entry.habitId === habit.id);

      if (habitData.length >= 7) {
        // Generate analysis
        const analysis = await this.glmService.analyzeHabitPattern(habit, habitData);
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
          const prediction = await this.glmService.predictHabitSuccess(habit, habitData);
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
    }
  }

  static async testConnection(): Promise<boolean> {
    if (!this.glmService) return false;

    try {
      // Create a simple test habit for connection testing
      const testHabit: Habit = {
        id: 'test',
        name: 'Test Habit',
        description: 'Test',
        category: 'Health',
        frequency: 'daily',
        targetCount: 1,
        color: '#007AFF',
        icon: '🧪',
        createdAt: new Date(),
        isActive: true,
      };

      await this.glmService.generateHabitRecommendation([testHabit]);
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

  const setupApiKey = async (apiKey: string) => {
    await AIManager.saveApiKey(apiKey);
  };

  const testConnection = async () => {
    return await AIManager.testConnection();
  };

  return {
    generateInsights,
    analyzeHabit,
    setupApiKey,
    testConnection,
    isConfigured: AIManager.isConfigured(),
  };
};