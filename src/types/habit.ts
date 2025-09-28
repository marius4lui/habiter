export interface Habit {
  id: string;
  name: string;
  description?: string;
  color: string;
  icon: string;
  frequency: 'daily' | 'weekly' | 'custom';
  targetCount: number;
  category: string;
  createdAt: Date;
  isActive: boolean;
}

export interface HabitEntry {
  id: string;
  habitId: string;
  date: string; // YYYY-MM-DD format
  completed: boolean;
  count: number;
  timestamp: Date;
}

export interface HabitStreak {
  habitId: string;
  currentStreak: number;
  longestStreak: number;
  lastCompletedDate: string;
}

export interface HabitStats {
  habitId: string;
  totalCompletions: number;
  completionRate: number;
  averagePerWeek: number;
  streakData: HabitStreak;
}

export interface AIInsight {
  id: string;
  habitId?: string;
  type: 'recommendation' | 'motivation' | 'analysis' | 'prediction';
  title: string;
  message: string;
  confidence: number;
  createdAt: Date;
  isRead: boolean;
}

export interface UserPreferences {
  theme: 'light' | 'dark' | 'auto';
  notifications: boolean;
  reminderTime: string;
  aiInsights: boolean;
  language: string;
}