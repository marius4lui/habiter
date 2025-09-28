import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Habit } from '../types/habit';
import { useHabits } from '../contexts/HabitContext';
import { getTodayString, isHabitCompletedToday, calculateStreak } from '../utils/habitUtils';

interface HabitCardProps {
  habit: Habit;
  onPress?: () => void;
}

export const HabitCard: React.FC<HabitCardProps> = ({ habit, onPress }) => {
  const { habitEntries, toggleHabitCompletion } = useHabits();
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
      style={[styles.container, { borderLeftColor: habit.color }]}
      onPress={onPress}
      activeOpacity={0.7}
    >
      <View style={styles.header}>
        <View style={styles.titleRow}>
          <Text style={styles.icon}>{habit.icon}</Text>
          <View style={styles.titleContainer}>
            <Text style={styles.title}>{habit.name}</Text>
            {habit.description && (
              <Text style={styles.description} numberOfLines={1}>
                {habit.description}
              </Text>
            )}
          </View>
        </View>

        <TouchableOpacity
          style={[
            styles.checkbox,
            { backgroundColor: isCompleted ? habit.color : '#f0f0f0' }
          ]}
          onPress={handleToggleCompletion}
        >
          {isCompleted && (
            <Text style={styles.checkmark}>✓</Text>
          )}
        </TouchableOpacity>
      </View>

      <View style={styles.footer}>
        <View style={styles.category}>
          <Text style={styles.categoryText}>{habit.category}</Text>
        </View>

        <View style={styles.streakContainer}>
          <Text style={styles.streakLabel}>Streak:</Text>
          <Text style={[styles.streakValue, { color: habit.color }]}>
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
    padding: 16,
    marginVertical: 6,
    marginHorizontal: 16,
    borderLeftWidth: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  icon: {
    fontSize: 24,
    marginRight: 12,
  },
  titleContainer: {
    flex: 1,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 2,
  },
  description: {
    fontSize: 14,
    color: '#666',
  },
  checkbox: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: '#ddd',
  },
  checkmark: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  category: {
    backgroundColor: '#f8f9fa',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  categoryText: {
    fontSize: 12,
    color: '#666',
    fontWeight: '500',
  },
  streakContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  streakLabel: {
    fontSize: 12,
    color: '#666',
    marginRight: 4,
  },
  streakValue: {
    fontSize: 14,
    fontWeight: '600',
  },
});