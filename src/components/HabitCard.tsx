import { Theme } from '@/constants/theme';
import React from 'react';
import { Animated, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
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

  const scaleAnim = React.useRef(new Animated.Value(1)).current;

  const handlePressIn = () => {
    Animated.spring(scaleAnim, {
      toValue: 0.97,
      useNativeDriver: true,
    }).start();
  };

  const handlePressOut = () => {
    Animated.spring(scaleAnim, {
      toValue: 1,
      friction: 3,
      tension: 40,
      useNativeDriver: true,
    }).start();
  };

  const handleToggleCompletion = async () => {
    try {
      await toggleHabitCompletion(habit.id, today);
    } catch (error) {
      console.error('Error toggling habit completion:', error);
    }
  };

  return (
    <Animated.View style={{ transform: [{ scale: scaleAnim }], flex: 1 }}>
      <TouchableOpacity
        style={[
          styles.container,
          {
            padding: spacing.lg,
            marginVertical: spacing.xs,
            marginHorizontal: isMobile ? 0 : spacing.xs,
          }
        ]}
        onPress={onPress}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        activeOpacity={0.7}
      >
        <View style={styles.content}>
          {/* Header */}
          <View style={[styles.header, { marginBottom: spacing.md }]}>
            <View style={styles.titleRow}>
              {/* Icon - Minimalist Circle */}
              <View style={[styles.iconContainer, { backgroundColor: `${habit.color}10` }]}>
                <Text style={[styles.icon, { fontSize: fontSizes.lg }]}>{habit.icon}</Text>
              </View>

              <View style={styles.titleContainer}>
                <Text style={[styles.title, { fontSize: fontSizes.md }]} numberOfLines={1}>
                  {habit.name}
                </Text>
                {habit.description && (
                  <Text style={[styles.description, { fontSize: fontSizes.xs }]} numberOfLines={1}>
                    {habit.description}
                  </Text>
                )}
              </View>
            </View>

            {/* Clean Checkbox */}
            <TouchableOpacity
              style={[
                styles.checkbox,
                {
                  borderColor: isCompleted ? habit.color : Theme.colors.borderLight,
                  backgroundColor: isCompleted ? habit.color : 'transparent',
                  width: 28,
                  height: 28,
                  borderRadius: 14,
                }
              ]}
              onPress={handleToggleCompletion}
            >
              {isCompleted && (
                <Text style={[styles.checkmark, { fontSize: 16 }]}>✓</Text>
              )}
            </TouchableOpacity>
          </View>

          {/* Footer - Minimal */}
          <View style={styles.footer}>
            {streak.currentStreak > 0 && (
              <View style={styles.streakContainer}>
                <View style={[styles.streakBadge, { backgroundColor: `${habit.color}10` }]}>
                  <Text style={styles.streakEmoji}>🔥</Text>
                  <Text style={[styles.streakValue, { fontSize: fontSizes.sm, color: habit.color }]}>
                    {streak.currentStreak} day{streak.currentStreak !== 1 ? 's' : ''}
                  </Text>
                </View>
              </View>
            )}

            <View style={[styles.category, { paddingHorizontal: spacing.sm, paddingVertical: 4 }]}>
              <Text style={[styles.categoryText, { fontSize: 9 }]}>{habit.category}</Text>
            </View>
          </View>
        </View>
      </TouchableOpacity>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: Theme.colors.surface,
    borderRadius: Theme.borderRadius.lg,
    ...Theme.shadows.sm,
    flex: 1,
    borderWidth: 1,
    borderColor: Theme.colors.borderLight,
  },
  content: {
    // No extra padding
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
    marginRight: 12,
  },
  iconContainer: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  icon: {
    // fontSize handled dynamically
  },
  titleContainer: {
    flex: 1,
    justifyContent: 'center',
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    color: Theme.colors.text,
    marginBottom: 2,
  },
  description: {
    fontSize: 13,
    color: Theme.colors.textTertiary,
  },
  checkbox: {
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
  },
  checkmark: {
    color: '#fff',
    fontWeight: '600',
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  category: {
    backgroundColor: Theme.colors.backgroundDark,
    borderRadius: Theme.borderRadius.sm,
  },
  categoryText: {
    fontSize: 9,
    fontWeight: '600',
    color: Theme.colors.textTertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  streakContainer: {
    flex: 1,
  },
  streakBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: Theme.borderRadius.full,
    gap: 6,
  },
  streakEmoji: {
    fontSize: 14,
  },
  streakValue: {
    fontWeight: '600',
  },
});