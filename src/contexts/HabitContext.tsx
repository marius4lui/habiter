import React, { createContext, useContext, useReducer, useEffect, ReactNode } from 'react';
import { Habit, HabitEntry, AIInsight, UserPreferences } from '../types/habit';
import { StorageService } from '../services/storage';
import { calculateHabitStats } from '../utils/habitUtils';

interface HabitState {
  habits: Habit[];
  habitEntries: HabitEntry[];
  aiInsights: AIInsight[];
  userPreferences: UserPreferences;
  loading: boolean;
  error: string | null;
}

type HabitAction =
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'SET_HABITS'; payload: Habit[] }
  | { type: 'ADD_HABIT'; payload: Habit }
  | { type: 'UPDATE_HABIT'; payload: { id: string; updates: Partial<Habit> } }
  | { type: 'DELETE_HABIT'; payload: string }
  | { type: 'SET_HABIT_ENTRIES'; payload: HabitEntry[] }
  | { type: 'ADD_HABIT_ENTRY'; payload: HabitEntry }
  | { type: 'SET_AI_INSIGHTS'; payload: AIInsight[] }
  | { type: 'ADD_AI_INSIGHT'; payload: AIInsight }
  | { type: 'MARK_INSIGHT_READ'; payload: string }
  | { type: 'SET_USER_PREFERENCES'; payload: UserPreferences }
  | { type: 'INIT_DATA'; payload: { habits: Habit[]; entries: HabitEntry[]; insights: AIInsight[]; preferences: UserPreferences } };

const initialState: HabitState = {
  habits: [],
  habitEntries: [],
  aiInsights: [],
  userPreferences: {
    theme: 'auto',
    notifications: true,
    reminderTime: '20:00',
    aiInsights: true,
    language: 'en',
  },
  loading: true,
  error: null,
};

const habitReducer = (state: HabitState, action: HabitAction): HabitState => {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, loading: action.payload };

    case 'SET_ERROR':
      return { ...state, error: action.payload };

    case 'SET_HABITS':
      return { ...state, habits: action.payload };

    case 'ADD_HABIT':
      return { ...state, habits: [...state.habits, action.payload] };

    case 'UPDATE_HABIT':
      return {
        ...state,
        habits: state.habits.map(habit =>
          habit.id === action.payload.id
            ? { ...habit, ...action.payload.updates }
            : habit
        ),
      };

    case 'DELETE_HABIT':
      return {
        ...state,
        habits: state.habits.filter(habit => habit.id !== action.payload),
        habitEntries: state.habitEntries.filter(entry => entry.habitId !== action.payload),
      };

    case 'SET_HABIT_ENTRIES':
      return { ...state, habitEntries: action.payload };

    case 'ADD_HABIT_ENTRY':
      return {
        ...state,
        habitEntries: [
          ...state.habitEntries.filter(
            entry => !(entry.habitId === action.payload.habitId && entry.date === action.payload.date)
          ),
          action.payload,
        ],
      };

    case 'SET_AI_INSIGHTS':
      return { ...state, aiInsights: action.payload };

    case 'ADD_AI_INSIGHT':
      return { ...state, aiInsights: [action.payload, ...state.aiInsights] };

    case 'MARK_INSIGHT_READ':
      return {
        ...state,
        aiInsights: state.aiInsights.map(insight =>
          insight.id === action.payload
            ? { ...insight, isRead: true }
            : insight
        ),
      };

    case 'SET_USER_PREFERENCES':
      return { ...state, userPreferences: action.payload };

    case 'INIT_DATA':
      return {
        ...state,
        habits: action.payload.habits,
        habitEntries: action.payload.entries,
        aiInsights: action.payload.insights,
        userPreferences: action.payload.preferences,
        loading: false,
      };

    default:
      return state;
  }
};

interface HabitContextType extends HabitState {
  // Habit actions
  addHabit: (habit: Omit<Habit, 'id' | 'createdAt'>) => Promise<void>;
  updateHabit: (id: string, updates: Partial<Habit>) => Promise<void>;
  deleteHabit: (id: string) => Promise<void>;

  // Habit entry actions
  toggleHabitCompletion: (habitId: string, date: string) => Promise<void>;

  // AI insight actions
  addAIInsight: (insight: Omit<AIInsight, 'id' | 'createdAt'>) => Promise<void>;
  markInsightAsRead: (insightId: string) => Promise<void>;

  // Preferences actions
  updateUserPreferences: (preferences: Partial<UserPreferences>) => Promise<void>;

  // Utility functions
  getHabitStats: (habitId: string) => ReturnType<typeof calculateHabitStats>;
  refreshData: () => Promise<void>;
}

const HabitContext = createContext<HabitContextType | undefined>(undefined);

export const useHabits = (): HabitContextType => {
  const context = useContext(HabitContext);
  if (!context) {
    throw new Error('useHabits must be used within a HabitProvider');
  }
  return context;
};

interface HabitProviderProps {
  children: ReactNode;
}

export const HabitProvider: React.FC<HabitProviderProps> = ({ children }) => {
  const [state, dispatch] = useReducer(habitReducer, initialState);

  // Initialize data on mount
  useEffect(() => {
    loadInitialData();
  }, []);

  const loadInitialData = async () => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });

      const [habits, entries, insights, preferences] = await Promise.all([
        StorageService.getHabits(),
        StorageService.getHabitEntries(),
        StorageService.getAIInsights(),
        StorageService.getUserPreferences(),
      ]);

      dispatch({
        type: 'INIT_DATA',
        payload: { habits, entries, insights, preferences },
      });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to load data' });
      console.error('Error loading initial data:', error);
    }
  };

  const addHabit = async (habitData: Omit<Habit, 'id' | 'createdAt'>) => {
    try {
      const newHabit: Habit = {
        ...habitData,
        id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
        createdAt: new Date(),
      };

      await StorageService.addHabit(newHabit);
      dispatch({ type: 'ADD_HABIT', payload: newHabit });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to add habit' });
      throw error;
    }
  };

  const updateHabit = async (id: string, updates: Partial<Habit>) => {
    try {
      await StorageService.updateHabit(id, updates);
      dispatch({ type: 'UPDATE_HABIT', payload: { id, updates } });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to update habit' });
      throw error;
    }
  };

  const deleteHabit = async (id: string) => {
    try {
      await StorageService.deleteHabit(id);
      dispatch({ type: 'DELETE_HABIT', payload: id });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to delete habit' });
      throw error;
    }
  };

  const toggleHabitCompletion = async (habitId: string, date: string) => {
    try {
      const existingEntry = state.habitEntries.find(
        entry => entry.habitId === habitId && entry.date === date
      );

      const newEntry: HabitEntry = {
        id: existingEntry?.id || Date.now().toString() + Math.random().toString(36).substr(2, 9),
        habitId,
        date,
        completed: !existingEntry?.completed,
        count: existingEntry?.completed ? 0 : 1,
        timestamp: new Date(),
      };

      await StorageService.addHabitEntry(newEntry);
      dispatch({ type: 'ADD_HABIT_ENTRY', payload: newEntry });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to update habit completion' });
      throw error;
    }
  };

  const addAIInsight = async (insightData: Omit<AIInsight, 'id' | 'createdAt'>) => {
    try {
      const newInsight: AIInsight = {
        ...insightData,
        id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
        createdAt: new Date(),
      };

      await StorageService.addAIInsight(newInsight);
      dispatch({ type: 'ADD_AI_INSIGHT', payload: newInsight });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to add AI insight' });
      throw error;
    }
  };

  const markInsightAsRead = async (insightId: string) => {
    try {
      dispatch({ type: 'MARK_INSIGHT_READ', payload: insightId });
      // Update in storage
      const insights = await StorageService.getAIInsights();
      const updatedInsights = insights.map(insight =>
        insight.id === insightId ? { ...insight, isRead: true } : insight
      );
      await StorageService.saveAIInsights(updatedInsights);
    } catch {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to mark insight as read' });
    }
  };

  const updateUserPreferences = async (preferences: Partial<UserPreferences>) => {
    try {
      const updatedPreferences = { ...state.userPreferences, ...preferences };
      await StorageService.saveUserPreferences(updatedPreferences);
      dispatch({ type: 'SET_USER_PREFERENCES', payload: updatedPreferences });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to update preferences' });
      throw error;
    }
  };

  const getHabitStats = (habitId: string) => {
    const habit = state.habits.find(h => h.id === habitId);
    if (!habit) {
      throw new Error('Habit not found');
    }
    return calculateHabitStats(habit, state.habitEntries);
  };

  const refreshData = async () => {
    await loadInitialData();
  };

  const contextValue: HabitContextType = {
    ...state,
    addHabit,
    updateHabit,
    deleteHabit,
    toggleHabitCompletion,
    addAIInsight,
    markInsightAsRead,
    updateUserPreferences,
    getHabitStats,
    refreshData,
  };

  return (
    <HabitContext.Provider value={contextValue}>
      {children}
    </HabitContext.Provider>
  );
};