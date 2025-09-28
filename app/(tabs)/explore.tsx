import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LineChart } from 'react-native-chart-kit';
import { useHabits } from '@/src/contexts/HabitContext';
import { calculateHabitStats, getWeeklyData } from '@/src/utils/habitUtils';
import { AIInsight } from '@/src/types/habit';

const screenWidth = Dimensions.get('window').width;

export default function AnalyticsScreen() {
  const { habits, habitEntries, aiInsights, markInsightAsRead } = useHabits();
  const [selectedHabitId, setSelectedHabitId] = useState<string | null>(null);

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
          <Text style={styles.insightIcon}>{getInsightIcon(insight.type)}</Text>
          <View style={styles.insightTitleContainer}>
            <Text style={styles.insightTitle}>{insight.title}</Text>
            <Text style={styles.insightType}>{insight.type.toUpperCase()}</Text>
          </View>
          {!insight.isRead && <View style={styles.unreadDot} />}
        </View>
        <Text style={styles.insightMessage}>{insight.message}</Text>
        <Text style={styles.insightConfidence}>
          Confidence: {Math.round(insight.confidence * 100)}%
        </Text>
      </TouchableOpacity>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Analytics & Insights</Text>
      </View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Overall Stats */}
        <View style={styles.statsContainer}>
          <Text style={styles.sectionTitle}>Overview</Text>
          <View style={styles.statsRow}>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{totalHabits}</Text>
              <Text style={styles.statLabel}>Active Habits</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{totalCompletions}</Text>
              <Text style={styles.statLabel}>Total Completions</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{Math.round(avgCompletionRate)}%</Text>
              <Text style={styles.statLabel}>Avg. Success Rate</Text>
            </View>
          </View>
        </View>

        {/* Habit Selection for Chart */}
        {activeHabits.length > 0 && (
          <View style={styles.chartSection}>
            <Text style={styles.sectionTitle}>Weekly Progress</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.habitSelector}>
              {activeHabits.map((habit) => (
                <TouchableOpacity
                  key={habit.id}
                  style={[
                    styles.habitChip,
                    { borderColor: habit.color },
                    selectedHabitId === habit.id && { backgroundColor: habit.color }
                  ]}
                  onPress={() => setSelectedHabitId(habit.id)}
                >
                  <Text style={styles.habitChipIcon}>{habit.icon}</Text>
                  <Text
                    style={[
                      styles.habitChipText,
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
                  width={screenWidth - 32}
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
          <View style={styles.habitsStatsSection}>
            <Text style={styles.sectionTitle}>Habit Statistics</Text>
            {activeHabits.map((habit) => {
              const stats = calculateHabitStats(habit, habitEntries);
              return (
                <View key={habit.id} style={[styles.habitStatCard, { borderLeftColor: habit.color }]}>
                  <View style={styles.habitStatHeader}>
                    <Text style={styles.habitStatIcon}>{habit.icon}</Text>
                    <Text style={styles.habitStatName}>{habit.name}</Text>
                  </View>
                  <View style={styles.habitStatDetails}>
                    <View style={styles.habitStatItem}>
                      <Text style={styles.habitStatValue}>{stats.streakData.currentStreak}</Text>
                      <Text style={styles.habitStatLabel}>Current Streak</Text>
                    </View>
                    <View style={styles.habitStatItem}>
                      <Text style={styles.habitStatValue}>{Math.round(stats.completionRate)}%</Text>
                      <Text style={styles.habitStatLabel}>Success Rate</Text>
                    </View>
                    <View style={styles.habitStatItem}>
                      <Text style={styles.habitStatValue}>{stats.totalCompletions}</Text>
                      <Text style={styles.habitStatLabel}>Total Done</Text>
                    </View>
                  </View>
                </View>
              );
            })}
          </View>
        )}

        {/* AI Insights */}
        <View style={styles.insightsSection}>
          <Text style={styles.sectionTitle}>AI Insights</Text>
          {aiInsights.length > 0 ? (
            <View style={styles.insightsList}>
              {aiInsights.slice(0, 5).map(renderInsightCard)}
            </View>
          ) : (
            <View style={styles.emptyInsights}>
              <Text style={styles.emptyInsightsIcon}>🤖</Text>
              <Text style={styles.emptyInsightsText}>
                AI insights will appear here as you build more habit data
              </Text>
            </View>
          )}
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
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
  },
  content: {
    flex: 1,
  },
  statsContainer: {
    margin: 16,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#333',
    marginBottom: 12,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  statCard: {
    flex: 1,
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginHorizontal: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#007AFF',
  },
  statLabel: {
    fontSize: 12,
    color: '#666',
    textAlign: 'center',
    marginTop: 4,
  },
  chartSection: {
    margin: 16,
  },
  habitSelector: {
    marginBottom: 16,
  },
  habitChip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    marginRight: 8,
    borderWidth: 2,
  },
  habitChipIcon: {
    fontSize: 16,
    marginRight: 6,
  },
  habitChipText: {
    fontSize: 14,
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
    margin: 16,
  },
  habitStatCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
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
    marginBottom: 12,
  },
  habitStatIcon: {
    fontSize: 20,
    marginRight: 8,
  },
  habitStatName: {
    fontSize: 16,
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
    fontSize: 18,
    fontWeight: 'bold',
    color: '#007AFF',
  },
  habitStatLabel: {
    fontSize: 12,
    color: '#666',
    marginTop: 2,
  },
  insightsSection: {
    margin: 16,
    marginBottom: 32,
  },
  insightsList: {
    gap: 12,
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
    fontSize: 20,
    marginRight: 8,
  },
  insightTitleContainer: {
    flex: 1,
  },
  insightTitle: {
    fontSize: 16,
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
    fontSize: 14,
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
    padding: 32,
  },
  emptyInsightsIcon: {
    fontSize: 48,
    marginBottom: 12,
  },
  emptyInsightsText: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
});
