import { Theme } from '@/constants/theme';
import { useHabits } from '@/src/contexts/HabitContext';
import { useResponsive } from '@/src/hooks/useResponsive';
import { AIInsight } from '@/src/types/habit';
import { calculateHabitStats, getWeeklyData } from '@/src/utils/habitUtils';
import { useState } from 'react';
import {
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View
} from 'react-native';
import { LineChart } from 'react-native-chart-kit';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function AnalyticsScreen() {
  const { habits, habitEntries, aiInsights, markInsightAsRead } = useHabits();
  const [selectedHabitId, setSelectedHabitId] = useState<string | null>(null);
  const { isMobile, isTablet, isDesktop, width, spacing, fontSizes, maxContentWidth, numColumns } = useResponsive();

  const activeHabits = habits.filter(habit => habit.isActive);
  const selectedHabit = selectedHabitId ? habits.find(h => h.id === selectedHabitId) : null;

  // Overall stats
  const totalHabits = activeHabits.length;
  const totalCompletions = habitEntries.filter(entry => entry.completed).length;
  const avgCompletionRate = activeHabits.length > 0 ?
    activeHabits.reduce((sum, habit) => {
      const stats = calculateHabitStats(habit, habitEntries);
      return sum + stats.completionRate;
    }, 0) / activeHabits.length : 0;

  // Weekly chart data for selected habit
  const getChartData = () => {
    if (!selectedHabitId) return null;

    const weeklyData = getWeeklyData(selectedHabitId, habitEntries, 4);
    return {
      labels: weeklyData.map(week => week.week),
      datasets: [{
        data: weeklyData.map(week => week.completions),
        strokeWidth: 3,
        color: () => selectedHabit?.color || Theme.colors.primary,
      }]
    };
  };

  const chartConfig = {
    backgroundColor: Theme.colors.surface,
    backgroundGradientFrom: Theme.colors.surface,
    backgroundGradientTo: Theme.colors.surface,
    decimalPlaces: 0,
    color: (opacity = 1) => `rgba(99, 102, 241, ${opacity})`, // Indigo
    labelColor: (opacity = 1) => `rgba(100, 116, 139, ${opacity})`, // Slate 500
    style: {
      borderRadius: 16,
    },
    propsForDots: {
      r: '6',
      strokeWidth: '2',
      stroke: Theme.colors.surface
    }
  };

  const renderInsightCard = (insight: AIInsight) => {
    const getInsightIcon = (type: string) => {
      switch (type) {
        case 'recommendation': return '💡';
        case 'motivation': return '🚀';
        case 'analysis': return '📊';
        case 'prediction': return '🔮';
        default: return '✨';
      }
    };

    return (
      <TouchableOpacity
        key={insight.id}
        style={[styles.insightCard, insight.isRead && styles.insightCardRead]}
        onPress={() => markInsightAsRead(insight.id)}
      >
        <View style={styles.insightHeader}>
          <View style={[styles.insightIconContainer, { backgroundColor: `${Theme.colors.primary}15` }]}>
            <Text style={[styles.insightIcon, { fontSize: fontSizes.lg }]}>{getInsightIcon(insight.type)}</Text>
          </View>
          <View style={styles.insightTitleContainer}>
            <Text style={[styles.insightTitle, { fontSize: fontSizes.md }]}>{insight.title}</Text>
            <Text style={styles.insightType}>{insight.type.toUpperCase()}</Text>
          </View>
          {!insight.isRead && <View style={styles.unreadDot} />}
        </View>
        <Text style={[styles.insightMessage, { fontSize: fontSizes.sm }]}>{insight.message}</Text>
        <Text style={styles.insightConfidence}>
          Confidence: {Math.round(insight.confidence * 100)}%
        </Text>
      </TouchableOpacity>
    );
  };

  const chartWidth = Math.min(width - (spacing.md * 2), 800); // Max width for chart

  return (
    <SafeAreaView style={styles.container} edges={['top', 'left', 'right']}>
      <StatusBar barStyle="dark-content" backgroundColor={Theme.colors.background} />
      <View style={styles.header}>
        <Text style={styles.title}>Analytics</Text>
      </View>

      <ScrollView
        style={styles.content}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ alignItems: 'center', paddingBottom: spacing.xl }}
      >
        <View style={{ width: '100%', maxWidth: maxContentWidth }}>
          {/* Overall Stats */}
          <View style={[styles.statsContainer, { margin: spacing.md }]}>
            <Text style={[styles.sectionTitle, { fontSize: fontSizes.lg, marginBottom: spacing.sm }]}>Overview</Text>
            <View style={[styles.statsRow, { gap: spacing.sm }]}>
              <View style={[styles.statCard, { padding: spacing.md }]}>
                <Text style={[styles.statValue, { fontSize: fontSizes.xl }]}>{totalHabits}</Text>
                <Text style={[styles.statLabel, { fontSize: fontSizes.xs }]}>Active Habits</Text>
              </View>
              <View style={[styles.statCard, { padding: spacing.md }]}>
                <Text style={[styles.statValue, { fontSize: fontSizes.xl }]}>{totalCompletions}</Text>
                <Text style={[styles.statLabel, { fontSize: fontSizes.xs }]}>Total Completions</Text>
              </View>
              <View style={[styles.statCard, { padding: spacing.md }]}>
                <Text style={[styles.statValue, { fontSize: fontSizes.xl }]}>{Math.round(avgCompletionRate)}%</Text>
                <Text style={[styles.statLabel, { fontSize: fontSizes.xs }]}>Avg. Success Rate</Text>
              </View>
            </View>
          </View>

          {/* Habit Selection for Chart */}
          {activeHabits.length > 0 && (
            <View style={[styles.chartSection, { margin: spacing.md }]}>
              <Text style={[styles.sectionTitle, { fontSize: fontSizes.lg, marginBottom: spacing.sm }]}>Weekly Progress</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={[styles.habitSelector, { marginBottom: spacing.md }]}>
                {activeHabits.map((habit) => (
                  <TouchableOpacity
                    key={habit.id}
                    style={[
                      styles.habitChip,
                      { borderColor: habit.color, paddingHorizontal: spacing.sm, paddingVertical: spacing.xs },
                      selectedHabitId === habit.id && { backgroundColor: habit.color }
                    ]}
                    onPress={() => setSelectedHabitId(habit.id)}
                  >
                    <Text style={[styles.habitChipIcon, { fontSize: fontSizes.sm, marginRight: spacing.xs }]}>{habit.icon}</Text>
                    <Text
                      style={[
                        styles.habitChipText,
                        { fontSize: fontSizes.sm },
                        selectedHabitId === habit.id && styles.habitChipTextSelected
                      ]}
                    >
                      {habit.name}
                    </Text>
                  </TouchableOpacity>
                ))}
              </ScrollView>

              {/* Chart */}
              {selectedHabitId && getChartData() && (
                <View style={styles.chartContainer}>
                  <LineChart
                    data={getChartData()!}
                    width={chartWidth}
                    height={220}
                    chartConfig={chartConfig}
                    bezier
                    style={styles.chart}
                    withDots={true}
                    withInnerLines={false}
                    withOuterLines={false}
                    withVerticalLines={false}
                    withHorizontalLines={true}
                  />
                </View>
              )}
            </View>
          )}

          {/* Habit Stats */}
          {activeHabits.length > 0 && (
            <View style={[styles.habitsStatsSection, { margin: spacing.md }]}>
              <Text style={[styles.sectionTitle, { fontSize: fontSizes.lg, marginBottom: spacing.sm }]}>Habit Statistics</Text>
              <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: spacing.md }}>
                {activeHabits.map((habit) => {
                  const stats = calculateHabitStats(habit, habitEntries);
                  return (
                    <View
                      key={habit.id}
                      style={[
                        styles.habitStatCard,
                        {
                          borderLeftColor: habit.color,
                          padding: spacing.md,
                          width: isMobile ? '100%' : `calc(${100 / numColumns}% - ${spacing.md}px)`,
                          flexBasis: isMobile ? '100%' : `calc(${100 / numColumns}% - ${spacing.md}px)`
                        }
                      ]}
                    >
                      <View style={[styles.habitStatHeader, { marginBottom: spacing.sm }]}>
                        <Text style={[styles.habitStatIcon, { fontSize: fontSizes.lg, marginRight: spacing.sm }]}>{habit.icon}</Text>
                        <Text style={[styles.habitStatName, { fontSize: fontSizes.md }]}>{habit.name}</Text>
                      </View>
                      <View style={styles.habitStatDetails}>
                        <View style={styles.habitStatItem}>
                          <Text style={[styles.habitStatValue, { fontSize: fontSizes.md }]}>{stats.streakData.currentStreak}</Text>
                          <Text style={[styles.habitStatLabel, { fontSize: fontSizes.xs }]}>Streak</Text>
                        </View>
                        <View style={styles.habitStatItem}>
                          <Text style={[styles.habitStatValue, { fontSize: fontSizes.md }]}>{Math.round(stats.completionRate)}%</Text>
                          <Text style={[styles.habitStatLabel, { fontSize: fontSizes.xs }]}>Success</Text>
                        </View>
                        <View style={styles.habitStatItem}>
                          <Text style={[styles.habitStatValue, { fontSize: fontSizes.md }]}>{stats.totalCompletions}</Text>
                          <Text style={[styles.habitStatLabel, { fontSize: fontSizes.xs }]}>Total</Text>
                        </View>
                      </View>
                    </View>
                  );
                })}
              </View>
            </View>
          )}

          {/* AI Insights */}
          <View style={[styles.insightsSection, { margin: spacing.md, marginBottom: spacing.xl }]}>
            <Text style={[styles.sectionTitle, { fontSize: fontSizes.lg, marginBottom: spacing.sm }]}>AI Insights</Text>
            {aiInsights.length > 0 ? (
              <View style={[styles.insightsList, { gap: spacing.sm }]}>
                {aiInsights.slice(0, 5).map(renderInsightCard)}
              </View>
            ) : (
              <View style={[styles.emptyInsights, { padding: spacing.xl }]}>
                <Text style={[styles.emptyInsightsIcon, { fontSize: fontSizes.xxl }]}>🤖</Text>
                <Text style={[styles.emptyInsightsText, { fontSize: fontSizes.md }]}>
                  AI insights will appear here as you build more habit data
                </Text>
              </View>
            )}
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Theme.colors.background,
  },
  header: {
    paddingHorizontal: Theme.spacing.lg,
    paddingTop: Theme.spacing.sm,
    paddingBottom: Theme.spacing.md,
    backgroundColor: Theme.colors.background,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: Theme.colors.text,
    letterSpacing: -0.5,
  },
  content: {
    flex: 1,
  },
  statsContainer: {
    // margin handled dynamically
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: Theme.colors.text,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  statCard: {
    flex: 1,
    backgroundColor: Theme.colors.surface,
    borderRadius: Theme.borderRadius.md,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Theme.colors.borderLight,
  },
  statValue: {
    fontWeight: '700',
    color: Theme.colors.primary,
  },
  statLabel: {
    fontSize: 12,
    color: Theme.colors.textSecondary,
    textAlign: 'center',
    marginTop: 2,
    fontWeight: '500',
  },
  chartSection: {
    // margin handled dynamically
  },
  habitSelector: {
    // marginBottom handled dynamically
  },
  habitChip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Theme.colors.surface,
    borderRadius: Theme.borderRadius.full,
    marginRight: 8,
    borderWidth: 1.5,
  },
  habitChipIcon: {
    // fontSize handled dynamically
  },
  habitChipText: {
    color: Theme.colors.text,
    fontWeight: '600',
  },
  habitChipTextSelected: {
    color: '#fff',
    fontWeight: '600',
  },
  chartContainer: {
    alignItems: 'center',
    backgroundColor: Theme.colors.surface,
    borderRadius: Theme.borderRadius.md,
    padding: Theme.spacing.md,
    borderWidth: 1,
    borderColor: Theme.colors.borderLight,
  },
  chart: {
    borderRadius: 16,
  },
  habitsStatsSection: {
    // margin handled dynamically
  },
  habitStatCard: {
    backgroundColor: Theme.colors.surface,
    borderRadius: Theme.borderRadius.md,
    borderLeftWidth: 3,
    borderWidth: 1,
    borderColor: Theme.colors.borderLight,
  },
  habitStatHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  habitStatIcon: {
    // fontSize handled dynamically
  },
  habitStatName: {
    fontWeight: '600',
    color: Theme.colors.text,
  },
  habitStatDetails: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  habitStatItem: {
    alignItems: 'center',
  },
  habitStatValue: {
    fontWeight: 'bold',
    color: Theme.colors.primary,
  },
  habitStatLabel: {
    color: Theme.colors.textSecondary,
    marginTop: 2,
  },
  insightsSection: {
    // margin handled dynamically
  },
  insightsList: {
    // gap handled dynamically
  },
  insightCard: {
    backgroundColor: Theme.colors.surface,
    borderRadius: Theme.borderRadius.md,
    padding: Theme.spacing.md,
    borderWidth: 1,
    borderColor: Theme.colors.borderLight,
  },
  insightCardRead: {
    opacity: 0.6,
    backgroundColor: Theme.colors.backgroundDark,
  },
  insightHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  insightIconContainer: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  insightIcon: {
    // fontSize handled dynamically
  },
  insightTitleContainer: {
    flex: 1,
  },
  insightTitle: {
    fontWeight: '600',
    color: Theme.colors.text,
  },
  insightType: {
    fontSize: 10,
    color: Theme.colors.primary,
    fontWeight: '600',
    marginTop: 2,
    letterSpacing: 0.5,
  },
  unreadDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Theme.colors.primary,
  },
  insightMessage: {
    color: Theme.colors.textSecondary,
    lineHeight: 20,
    marginBottom: 8,
  },
  insightConfidence: {
    fontSize: 12,
    color: Theme.colors.textTertiary,
  },
  emptyInsights: {
    alignItems: 'center',
  },
  emptyInsightsIcon: {
    marginBottom: 12,
  },
  emptyInsightsText: {
    color: Theme.colors.textSecondary,
    textAlign: 'center',
  },
});
