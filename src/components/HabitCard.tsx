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
            padding: spacing.md,
            marginVertical: spacing.sm,
            marginHorizontal: isMobile ? spacing.md : spacing.xs,
          }
        ]}
        onPress={onPress}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        activeOpacity={1}
      >
        {/* Gradient Border Effect */}
        <View style={[styles.gradientBorder, { borderColor: habit.color }]} />

        <View style={styles.content}>
          {/* Header */}
          <View style={[styles.header, { marginBottom: spacing.sm }]}>
            <View style={styles.titleRow}>
              {/* Icon with gradient background */}
              <View style={[styles.iconContainer, { backgroundColor: `${habit.color}15` }]}>
                <Text style={[styles.icon, { fontSize: fontSizes.xl }]}>{habit.icon}</Text>
              </View>

              <View style={styles.titleContainer}>
                <Text style={[styles.title, { fontSize: fontSizes.md }]} numberOfLines={1}>
                  {habit.name}
                </Text>
                {habit.description && (
                  <Text style={[styles.description, { fontSize: fontSizes.sm }]} numberOfLines={1}>
                    {habit.description}
                  </Text>
                )}
              </View>
            </View>

            {/* Checkbox with animation */}
            <TouchableOpacity
              style={[
                styles.checkbox,
                {
                  borderColor: isCompleted ? habit.color : Theme.colors.border,
                  backgroundColor: isCompleted ? habit.color : Theme.colors.surface,
                  width: isMobile ? 36 : 40,
                  height: isMobile ? 36 : 40,
                  borderRadius: isMobile ? 18 : 20,
                  ...Theme.shadows.md,
                }
              ]}
              onPress={handleToggleCompletion}
            >
              {isCompleted && (
                <Text style={[styles.checkmark, { fontSize: fontSizes.md }]}>✓</Text>
              )}
            </TouchableOpacity>
          </View>

          {/* Footer */}
          <View style={styles.footer}>
            <View style={[styles.category, { paddingHorizontal: spacing.sm, paddingVertical: 6 }]}>
              <Text style={[styles.categoryText, { fontSize: 10 }]}>{habit.category.toUpperCase()}</Text>
            </View>

            {streak.currentStreak > 0 && (
              <View style={styles.streakContainer}>
                <Text style={styles.streakEmoji}>🔥</Text>
                <Text style={[styles.streakValue, { fontSize: fontSizes.sm }]}>
                  {streak.currentStreak}
                  <Text style={styles.streakLabel}> day{streak.currentStreak !== 1 ? 's' : ''}</Text>
                </Text>
              </View>
            )}
          </View>
        </View>
      </TouchableOpacity>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: Theme.colors.surface,
    borderRadius: Theme.borderRadius.xl,
    ...Theme.shadows.md,
    flex: 1,
    overflow: 'hidden',
  },
  gradientBorder: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: 4,
    borderTopLeftRadius: Theme.borderRadius.xl,
    borderTopRightRadius: Theme.borderRadius.xl,
  },
  content: {
    paddingTop: 4,
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
    width: 48,
    height: 48,
    borderRadius: Theme.borderRadius.md,
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
    ...Theme.typography.h3,
    fontSize: 17,
    marginBottom: 2,
  },
  description: {
    ...Theme.typography.bodySmall,
    color: Theme.colors.textTertiary,
  },
  checkbox: {
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2.5,
  },
  checkmark: {
    color: '#fff',
    fontWeight: 'bold',
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  category: {
    backgroundColor: Theme.colors.backgroundDark,
    borderRadius: Theme.borderRadius.full,
    borderWidth: 1,
    borderColor: Theme.colors.borderLight,
  },
  categoryText: {
    ...Theme.typography.label,
    color: Theme.colors.textSecondary,
  },
  streakContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  streakEmoji: {
    fontSize: 14,
  },
  streakValue: {
    fontWeight: '700',
    color: Theme.colors.text,
  },
  streakLabel: {
    fontWeight: '400',
    color: Theme.colors.textSecondary,
  },
});