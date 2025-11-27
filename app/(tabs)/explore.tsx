import { useHabits } from '@/src/contexts/HabitContext';
import { useResponsive } from '@/src/hooks/useResponsive';
import { AIInsight } from '@/src/types/habit';
import { calculateHabitStats, getWeeklyData } from '@/src/utils/habitUtils';
import { useState } from 'react';
import {
  ScrollView,
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
        color: () => selectedHabit?.color || '#007AFF',
      }]
    };
  };

  const chartConfig = {
    backgroundColor: '#fff',
    backgroundGradientFrom: '#fff',
    backgroundGradientTo: '#fff',
    decimalPlaces: 0,
    color: (opacity = 1) => `rgba(0, 122, 255, ${opacity})`,
    labelColor: (opacity = 1) => `rgba(102, 102, 102, ${opacity})`,
    style: {
      borderRadius: 16,
    },
    propsForDots: {
      r: '6',
      strokeWidth: '2',
      stroke: '#fff'
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
          <Text style={[styles.insightIcon, { fontSize: fontSizes.lg }]}>{getInsightIcon(insight.type)}</Text>
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
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={[styles.title, { fontSize: fontSizes.xl }]}>Analytics & Insights</Text>
      </View>

      <ScrollView
        style={styles.content}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ alignItems: 'center' }}
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
    backgroundColor: '#f8f9fa',
  },
  header: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e1e5e9',
  },
  title: {
    fontWeight: 'bold',
    color: '#333',
  },
  content: {
    flex: 1,
  },
  statsContainer: {
    // margin handled dynamically
  },
  sectionTitle: {
    fontWeight: '600',
    color: '#333',
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  statCard: {
    flex: 1,
    backgroundColor: '#fff',
    borderRadius: 12,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statValue: {
    fontWeight: 'bold',
    color: '#007AFF',
  },
  statLabel: {
    color: '#666',
    textAlign: 'center',
    marginTop: 4,
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
    backgroundColor: '#fff',
    borderRadius: 20,
    marginRight: 8,
    borderWidth: 2,
  },
  habitChipIcon: {
    // fontSize handled dynamically
  },
  habitChipText: {
    color: '#333',
    fontWeight: '500',
  },
  habitChipTextSelected: {
    color: '#fff',
  },
  chartContainer: {
    alignItems: 'center',
  },
  chart: {
    borderRadius: 16,
  },
  habitsStatsSection: {
    // margin handled dynamically
  },
  habitStatCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    borderLeftWidth: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
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
    color: '#333',
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
    color: '#007AFF',
  },
  habitStatLabel: {
    color: '#666',
    marginTop: 2,
  },
  insightsSection: {
    // margin handled dynamically
  },
  insightsList: {
    // gap handled dynamically
  },
  insightCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  insightCardRead: {
    opacity: 0.7,
  },
  insightHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  insightIcon: {
    marginRight: 8,
  },
  insightTitleContainer: {
    flex: 1,
  },
  insightTitle: {
    fontWeight: '600',
    color: '#333',
  },
  insightType: {
    fontSize: 10,
    color: '#007AFF',
    fontWeight: '500',
    marginTop: 2,
  },
  unreadDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#007AFF',
  },
  insightMessage: {
    color: '#666',
    lineHeight: 20,
    marginBottom: 8,
  },
  insightConfidence: {
    fontSize: 12,
    color: '#999',
  },
  emptyInsights: {
    alignItems: 'center',
  },
  emptyInsightsIcon: {
    marginBottom: 12,
  },
  emptyInsightsText: {
    color: '#666',
    textAlign: 'center',
  },
});
