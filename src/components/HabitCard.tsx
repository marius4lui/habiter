import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { useHabits } from '../contexts/HabitContext';
import { useResponsive } from '../hooks/useResponsive';
import { Habit } from '../types/habit';
import { calculateStreak, getTodayString, isHabitCompletedToday } from '../utils/habitUtils';

interface HabitCardProps {
  habit: Habit;
  onPress?: () => void;
}

export const HabitCard: React.FC<HabitCardProps> = ({ habit, onPress }) => {
  const { habitEntries, toggleHabitCompletion } = useHabits();
  const { spacing, fontSizes, isMobile } = useResponsive();
  const today = getTodayString();
  const isCompleted = isHabitCompletedToday(habit.id, habitEntries);
  const streak = calculateStreak(habit.id, habitEntries);

  const handleToggleCompletion = async () => {
    try {
      await toggleHabitCompletion(habit.id, today);
    } catch (error) {
      console.error('Error toggling habit completion:', error);
    }
  };

  return (
    <TouchableOpacity
      style={[
        styles.container,
        {
          borderLeftColor: habit.color,
          padding: spacing.md,
          marginVertical: spacing.xs,
          marginHorizontal: isMobile ? spacing.md : spacing.xs,
        }
      ]}
      onPress={onPress}
      activeOpacity={0.7}
    >
      <View style={[styles.header, { marginBottom: spacing.sm }]}>
        <View style={styles.titleRow}>
          <Text style={[styles.icon, { fontSize: fontSizes.xl, marginRight: spacing.sm }]}>{habit.icon}</Text>
          <View style={styles.titleContainer}>
            <Text style={[styles.title, { fontSize: fontSizes.md }]}>{habit.name}</Text>
            {habit.description && (
              <Text style={[styles.description, { fontSize: fontSizes.sm }]} numberOfLines={1}>
                {habit.description}
              </Text>
            )}
          </View>
        </View>

        <TouchableOpacity
          style={[
            styles.checkbox,
            {
              backgroundColor: isCompleted ? habit.color : '#f0f0f0',
              width: isMobile ? 32 : 40,
              height: isMobile ? 32 : 40,
              borderRadius: isMobile ? 16 : 20,
            }
          ]}
          onPress={handleToggleCompletion}
        >
          {isCompleted && (
            <Text style={[styles.checkmark, { fontSize: fontSizes.md }]}>✓</Text>
          )}
        </TouchableOpacity>
      </View>

      <View style={styles.footer}>
        <View style={[styles.category, { paddingHorizontal: spacing.sm, paddingVertical: spacing.xs / 2 }]}>
          <Text style={[styles.categoryText, { fontSize: fontSizes.xs }]}>{habit.category}</Text>
        </View>

        <View style={styles.streakContainer}>
          <Text style={[styles.streakLabel, { fontSize: fontSizes.xs, marginRight: spacing.xs }]}>Streak:</Text>
          <Text style={[styles.streakValue, { color: habit.color, fontSize: fontSizes.sm }]}>
            {streak.currentStreak} days
          </Text>
        </View>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#fff',
    borderRadius: 12,
    borderLeftWidth: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
    flex: 1, // Important for grid layout
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  icon: {
    // fontSize handled dynamically
  },
  titleContainer: {
    flex: 1,
  },
  title: {
    fontWeight: '600',
    color: '#333',
    marginBottom: 2,
  },
  description: {
    color: '#666',
  },
  checkbox: {
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: '#ddd',
  },
  checkmark: {
    color: '#fff',
    fontWeight: 'bold',
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  category: {
    backgroundColor: '#f8f9fa',
    borderRadius: 12,
  },
  categoryText: {
    color: '#666',
    fontWeight: '500',
  },
  streakContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  streakLabel: {
    color: '#666',
  },
  streakValue: {
    fontWeight: '600',
  },
});