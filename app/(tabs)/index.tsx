import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  RefreshControl,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useHabits } from '@/src/contexts/HabitContext';
import { HabitCard } from '@/src/components/HabitCard';
import { AddHabitModal } from '@/src/components/AddHabitModal';
import { AISetupModal } from '@/src/components/AISetupModal';
import { Habit } from '@/src/types/habit';
import { formatDisplayDate, getTodayString } from '@/src/utils/habitUtils';
import { AIManager, useAIManager } from '@/src/services/aiManager';

export default function HomeScreen() {
  const { habits, loading, error, refreshData } = useHabits();
  const [refreshing, setRefreshing] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showAISetup, setShowAISetup] = useState(false);
  const [generatingInsights, setGeneratingInsights] = useState(false);
  const { generateInsights, isConfigured } = useAIManager();

  useEffect(() => {
    // Initialize AI service on app start
    AIManager.initializeService();
  }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshData();
    } finally {
      setRefreshing(false);
    }
  };

  const handleGenerateInsights = async () => {
    if (!isConfigured) {
      Alert.alert(
        'AI Not Configured',
        'Please set up your GLM API key to use AI features.',
        [
          { text: 'Cancel', style: 'cancel' },
          { text: 'Setup', onPress: () => setShowAISetup(true) }
        ]
      );
      return;
    }

    setGeneratingInsights(true);
    try {
      await generateInsights();
      Alert.alert('Success', 'AI insights generated! Check the Analytics tab to view them.');
    } catch {
      Alert.alert('Error', 'Failed to generate AI insights. Please try again.');
    } finally {
      setGeneratingInsights(false);
    }
  };

  const renderHabitCard = ({ item }: { item: Habit }) => (
    <HabitCard
      habit={item}
      onPress={() => {
        // TODO: Navigate to habit details
      }}
    />
  );

  const renderEmptyState = () => (
    <View style={styles.emptyState}>
      <Text style={styles.emptyIcon}>🌱</Text>
      <Text style={styles.emptyTitle}>Start Building Habits</Text>
      <Text style={styles.emptyText}>
        Create your first habit and begin your journey to a better you!
      </Text>
      <TouchableOpacity
        style={styles.addFirstHabitButton}
        onPress={() => setShowAddModal(true)}
      >
        <Text style={styles.addFirstHabitText}>Add Your First Habit</Text>
      </TouchableOpacity>
    </View>
  );

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#007AFF" />
          <Text style={styles.loadingText}>Loading your habits...</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (error) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>Something went wrong</Text>
          <TouchableOpacity style={styles.retryButton} onPress={onRefresh}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const activeHabits = habits.filter(habit => habit.isActive);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.titleContainer}>
          <Text style={styles.title}>Habiter</Text>
          <Text style={styles.subtitle}>
            {formatDisplayDate(getTodayString())}
          </Text>
        </View>
        <View style={styles.headerButtons}>
          <TouchableOpacity
            style={[styles.aiButton, !isConfigured && styles.aiButtonNotConfigured]}
            onPress={isConfigured ? handleGenerateInsights : () => setShowAISetup(true)}
            disabled={generatingInsights}
          >
            {generatingInsights ? (
              <ActivityIndicator size="small" color="#fff" />
            ) : (
              <Text style={styles.aiButtonText}>🤖</Text>
            )}
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.addButton}
            onPress={() => setShowAddModal(true)}
          >
            <Text style={styles.addButtonText}>+</Text>
          </TouchableOpacity>
        </View>
      </View>

      <FlatList
        data={activeHabits}
        renderItem={renderHabitCard}
        keyExtractor={(item) => item.id}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={[
          styles.listContent,
          activeHabits.length === 0 && styles.emptyListContent,
        ]}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        ListEmptyComponent={renderEmptyState}
      />

      <AddHabitModal
        visible={showAddModal}
        onClose={() => setShowAddModal(false)}
      />

      <AISetupModal
        visible={showAISetup}
        onClose={() => setShowAISetup(false)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e1e5e9',
  },
  titleContainer: {
    flex: 1,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
  },
  subtitle: {
    fontSize: 14,
    color: '#666',
    marginTop: 2,
  },
  headerButtons: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  aiButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#007AFF',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 4,
  },
  aiButtonNotConfigured: {
    backgroundColor: '#FF9500',
  },
  aiButtonText: {
    fontSize: 20,
  },
  addButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#007AFF',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 4,
  },
  addButtonText: {
    fontSize: 24,
    color: '#fff',
    fontWeight: '300',
  },
  listContent: {
    paddingTop: 8,
    paddingBottom: 16,
  },
  emptyListContent: {
    flex: 1,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  emptyIcon: {
    fontSize: 64,
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 24,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
    textAlign: 'center',
  },
  emptyText: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: 24,
  },
  addFirstHabitButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 24,
  },
  addFirstHabitText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingText: {
    fontSize: 16,
    color: '#666',
    marginTop: 12,
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  errorText: {
    fontSize: 18,
    color: '#666',
    marginBottom: 16,
    textAlign: 'center',
  },
  retryButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  retryText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
