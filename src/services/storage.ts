import AsyncStorage from '@react-native-async-storage/async-storage';
import { Habit, HabitEntry, AIInsight, UserPreferences } from '../types/habit';

const STORAGE_KEYS = {
  HABITS: '@habiter_habits',
  HABIT_ENTRIES: '@habiter_habit_entries',
  AI_INSIGHTS: '@habiter_ai_insights',
  USER_PREFERENCES: '@habiter_user_preferences',
};

export class StorageService {
  // Habits
  static async getHabits(): Promise<Habit[]> {
    try {
      const habitsJson = await AsyncStorage.getItem(STORAGE_KEYS.HABITS);
      return habitsJson ? JSON.parse(habitsJson) : [];
    } catch (error) {
      console.error('Error fetching habits:', error);
      return [];
    }
  }

  static async saveHabits(habits: Habit[]): Promise<void> {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.HABITS, JSON.stringify(habits));
    } catch (error) {
      console.error('Error saving habits:', error);
      throw error;
    }
  }

  static async addHabit(habit: Habit): Promise<void> {
    try {
      const habits = await this.getHabits();
      habits.push(habit);
      await this.saveHabits(habits);
    } catch (error) {
      console.error('Error adding habit:', error);
      throw error;
    }
  }

  static async updateHabit(habitId: string, updates: Partial<Habit>): Promise<void> {
    try {
      const habits = await this.getHabits();
      const index = habits.findIndex(h => h.id === habitId);
      if (index !== -1) {
        habits[index] = { ...habits[index], ...updates };
        await this.saveHabits(habits);
      }
    } catch (error) {
      console.error('Error updating habit:', error);
      throw error;
    }
  }

  static async deleteHabit(habitId: string): Promise<void> {
    try {
      const habits = await this.getHabits();
      const filteredHabits = habits.filter(h => h.id !== habitId);
      await this.saveHabits(filteredHabits);
    } catch (error) {
      console.error('Error deleting habit:', error);
      throw error;
    }
  }

  // Habit Entries
  static async getHabitEntries(): Promise<HabitEntry[]> {
    try {
      const entriesJson = await AsyncStorage.getItem(STORAGE_KEYS.HABIT_ENTRIES);
      return entriesJson ? JSON.parse(entriesJson) : [];
    } catch (error) {
      console.error('Error fetching habit entries:', error);
      return [];
    }
  }

  static async saveHabitEntries(entries: HabitEntry[]): Promise<void> {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.HABIT_ENTRIES, JSON.stringify(entries));
    } catch (error) {
      console.error('Error saving habit entries:', error);
      throw error;
    }
  }

  static async addHabitEntry(entry: HabitEntry): Promise<void> {
    try {
      const entries = await this.getHabitEntries();
      // Remove existing entry for same habit and date if exists
      const filteredEntries = entries.filter(
        e => !(e.habitId === entry.habitId && e.date === entry.date)
      );
      filteredEntries.push(entry);
      await this.saveHabitEntries(filteredEntries);
    } catch (error) {
      console.error('Error adding habit entry:', error);
      throw error;
    }
  }

  static async getHabitEntriesForDate(date: string): Promise<HabitEntry[]> {
    try {
      const entries = await this.getHabitEntries();
      return entries.filter(entry => entry.date === date);
    } catch (error) {
      console.error('Error fetching habit entries for date:', error);
      return [];
    }
  }

  static async getHabitEntriesForHabit(habitId: string): Promise<HabitEntry[]> {
    try {
      const entries = await this.getHabitEntries();
      return entries.filter(entry => entry.habitId === habitId);
    } catch (error) {
      console.error('Error fetching habit entries for habit:', error);
      return [];
    }
  }

  // AI Insights
  static async getAIInsights(): Promise<AIInsight[]> {
    try {
      const insightsJson = await AsyncStorage.getItem(STORAGE_KEYS.AI_INSIGHTS);
      return insightsJson ? JSON.parse(insightsJson) : [];
    } catch (error) {
      console.error('Error fetching AI insights:', error);
      return [];
    }
  }

  static async saveAIInsights(insights: AIInsight[]): Promise<void> {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.AI_INSIGHTS, JSON.stringify(insights));
    } catch (error) {
      console.error('Error saving AI insights:', error);
      throw error;
    }
  }

  static async addAIInsight(insight: AIInsight): Promise<void> {
    try {
      const insights = await this.getAIInsights();
      insights.unshift(insight); // Add to beginning
      // Keep only last 50 insights
      if (insights.length > 50) {
        insights.splice(50);
      }
      await this.saveAIInsights(insights);
    } catch (error) {
      console.error('Error adding AI insight:', error);
      throw error;
    }
  }

  // User Preferences
  static async getUserPreferences(): Promise<UserPreferences> {
    try {
      const prefsJson = await AsyncStorage.getItem(STORAGE_KEYS.USER_PREFERENCES);
      return prefsJson ? JSON.parse(prefsJson) : {
        theme: 'auto',
        notifications: true,
        reminderTime: '20:00',
        aiInsights: true,
        language: 'en',
      };
    } catch (error) {
      console.error('Error fetching user preferences:', error);
      return {
        theme: 'auto',
        notifications: true,
        reminderTime: '20:00',
        aiInsights: true,
        language: 'en',
      };
    }
  }

  static async saveUserPreferences(preferences: UserPreferences): Promise<void> {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.USER_PREFERENCES, JSON.stringify(preferences));
    } catch (error) {
      console.error('Error saving user preferences:', error);
      throw error;
    }
  }

  // Utility methods
  static async clearAllData(): Promise<void> {
    try {
      await AsyncStorage.multiRemove(Object.values(STORAGE_KEYS));
    } catch (error) {
      console.error('Error clearing all data:', error);
      throw error;
    }
  }
}