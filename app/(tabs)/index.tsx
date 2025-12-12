import { Theme } from '@/constants/theme';
import { AddHabitModal } from '@/src/components/AddHabitModal';
import { AISetupModal } from '@/src/components/AISetupModal';
import { HabitCard } from '@/src/components/HabitCard';
import { useHabits } from '@/src/contexts/HabitContext';
import { useResponsive } from '@/src/hooks/useResponsive';
import { AIManager, useAIManager } from '@/src/services/aiManager';
import { Habit } from '@/src/types/habit';
import { formatDisplayDate, getTodayString, isHabitCompletedToday } from '@/src/utils/habitUtils';
import { LinearGradient } from 'expo-linear-gradient';
import { useEffect, useState } from 'react';
import {
    ActivityIndicator,
    Alert,
    FlatList,
    RefreshControl,
    StatusBar,
    StyleSheet,
    Text,
    TouchableOpacity,
    View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function HomeScreen() {
    const { habits, habitEntries, loading, error, refreshData } = useHabits();
    const [refreshing, setRefreshing] = useState(false);
    const [showAddModal, setShowAddModal] = useState(false);
    const [showAISetup, setShowAISetup] = useState(false);
    const [generatingInsights, setGeneratingInsights] = useState(false);
    const { generateInsights, isConfigured } = useAIManager();
    const { numColumns, spacing, maxContentWidth, isMobile } = useResponsive();

    useEffect(() => {
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
                'Please set up your AI provider to use AI features.',
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

    const getGreeting = () => {
        const hour = new Date().getHours();
        if (hour < 12) return 'Good Morning';
        if (hour < 18) return 'Good Afternoon';
        return 'Good Evening';
    };

    const getGreetingEmoji = () => {
        const hour = new Date().getHours();
        if (hour < 12) return '☀️';
        if (hour < 18) return '👋';
        return '🌙';
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
            <View style={styles.emptyIconContainer}>
                <Text style={styles.emptyIcon}>🌱</Text>
            </View>
            <Text style={styles.emptyTitle}>Start Your Journey</Text>
            <Text style={styles.emptyText}>
                Build better habits, one day at a time. Create your first habit to get started!
            </Text>
            <TouchableOpacity
                style={styles.addFirstHabitButton}
                onPress={() => setShowAddModal(true)}
            >
                <LinearGradient
                    colors={Theme.gradients.primary}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 0 }}
                    style={styles.addFirstHabitGradient}
                >
                    <Text style={styles.addFirstHabitText}>Create Your First Habit</Text>
                    <Text style={styles.addFirstHabitEmoji}>✨</Text>
                </LinearGradient>
            </TouchableOpacity>
        </View>
    );

    if (loading) {
        return (
            <SafeAreaView style={styles.container}>
                <View style={styles.loadingContainer}>
                    <ActivityIndicator size="large" color={Theme.colors.primary} />
                    <Text style={styles.loadingText}>Loading your habits...</Text>
                </View>
            </SafeAreaView>
        );
    }

    if (error) {
        return (
            <SafeAreaView style={styles.container}>
                <View style={styles.errorContainer}>
                    <Text style={styles.errorIcon}>⚠️</Text>
                    <Text style={styles.errorText}>Something went wrong</Text>
                    <TouchableOpacity style={styles.retryButton} onPress={onRefresh}>
                        <Text style={styles.retryText}>Try Again</Text>
                    </TouchableOpacity>
                </View>
            </SafeAreaView>
        );
    }

    const activeHabits = habits.filter(habit => habit.isActive);
    const today = getTodayString();
    const completedToday = activeHabits.filter(habit =>
        isHabitCompletedToday(habit.id, habitEntries)
    ).length;

    return (
        <SafeAreaView style={styles.container} edges={['top', 'left', 'right']}>
            <StatusBar barStyle="dark-content" backgroundColor={Theme.colors.background} />

            {/* Clean Header */}
            <View style={styles.headerContainer}>
                <View style={styles.header}>
                    <View style={styles.titleContainer}>
                        <Text style={styles.greeting}>{getGreeting()}</Text>
                        <Text style={styles.date}>{formatDisplayDate(today)}</Text>
                    </View>

                    <View style={styles.headerButtons}>
                        <TouchableOpacity
                            style={styles.iconButton}
                            onPress={isConfigured ? handleGenerateInsights : () => setShowAISetup(true)}
                            disabled={generatingInsights}
                        >
                            {generatingInsights ? (
                                <ActivityIndicator size="small" color={Theme.colors.textSecondary} />
                            ) : (
                                <Text style={styles.iconButtonText}>✨</Text>
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

                {/* Progress indicator */}
                {activeHabits.length > 0 && (
                    <View style={styles.progressContainer}>
                        <View style={styles.progressInfo}>
                            <Text style={styles.progressLabel}>Today's Progress</Text>
                            <Text style={styles.progressText}>
                                {completedToday}/{activeHabits.length}
                            </Text>
                        </View>
                        <View style={styles.progressBar}>
                            <View
                                style={[
                                    styles.progressFill,
                                    {
                                        width: `${Math.round((completedToday / activeHabits.length) * 100)}%`,
                                        backgroundColor: Theme.colors.primary
                                    }
                                ]}
                            />
                        </View>
                    </View>
                )}
            </View>

            <FlatList
                data={activeHabits}
                renderItem={renderHabitCard}
                keyExtractor={(item) => item.id}
                showsVerticalScrollIndicator={false}
                numColumns={numColumns}
                key={numColumns}
                columnWrapperStyle={numColumns > 1 ? { gap: spacing.md } : undefined}
                contentContainerStyle={[
                    styles.listContent,
                    activeHabits.length === 0 && styles.emptyListContent,
                    {
                        maxWidth: maxContentWidth,
                        alignSelf: 'center',
                        width: '100%',
                        paddingHorizontal: isMobile ? spacing.md : spacing.xl,
                    }
                ]}
                refreshControl={
                    <RefreshControl
                        refreshing={refreshing}
                        onRefresh={onRefresh}
                        tintColor={Theme.colors.primary}
                        colors={[Theme.colors.primary]}
                    />
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
        backgroundColor: Theme.colors.background,
    },
    headerContainer: {
        backgroundColor: Theme.colors.background,
        paddingBottom: Theme.spacing.md,
    },
    header: {
        flexDirection: 'row',
        alignItems: 'flex-start',
        justifyContent: 'space-between',
        paddingHorizontal: Theme.spacing.lg,
        paddingTop: Theme.spacing.sm,
        paddingBottom: Theme.spacing.md,
    },
    titleContainer: {
        flex: 1,
        marginRight: Theme.spacing.md,
    },
    greeting: {
        fontSize: 28,
        fontWeight: '700',
        color: Theme.colors.text,
        letterSpacing: -0.5,
        marginBottom: 2,
    },
    date: {
        fontSize: 14,
        color: Theme.colors.textSecondary,
        fontWeight: '500',
    },
    progressContainer: {
        paddingHorizontal: Theme.spacing.lg,
        paddingTop: Theme.spacing.sm,
    },
    progressInfo: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 8,
    },
    progressLabel: {
        fontSize: 13,
        fontWeight: '600',
        color: Theme.colors.textSecondary,
    },
    progressText: {
        fontSize: 13,
        fontWeight: '700',
        color: Theme.colors.primary,
    },
    progressBar: {
        height: 4,
        backgroundColor: Theme.colors.borderLight,
        borderRadius: Theme.borderRadius.full,
        overflow: 'hidden',
    },
    progressFill: {
        height: '100%',
        borderRadius: Theme.borderRadius.full,
    },
    headerButtons: {
        flexDirection: 'row',
        gap: 8,
        alignItems: 'center',
    },
    iconButton: {
        width: 40,
        height: 40,
        borderRadius: 20,
        backgroundColor: Theme.colors.surface,
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 1,
        borderColor: Theme.colors.border,
    },
    iconButtonText: {
        fontSize: 18,
    },
    addButton: {
        width: 40,
        height: 40,
        borderRadius: 20,
        backgroundColor: Theme.colors.primary,
        alignItems: 'center',
        justifyContent: 'center',
        ...Theme.shadows.sm,
    },
    addButtonText: {
        fontSize: 24,
        color: '#fff',
        fontWeight: '400',
        marginTop: -1,
    },
    listContent: {
        paddingTop: Theme.spacing.md,
        paddingBottom: Theme.spacing.xl,
    },
    emptyListContent: {
        flex: 1,
    },
    emptyState: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: 40,
    },
    emptyIconContainer: {
        width: 80,
        height: 80,
        borderRadius: 40,
        backgroundColor: Theme.colors.backgroundDark,
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 20,
    },
    emptyIcon: {
        fontSize: 40,
    },
    emptyTitle: {
        fontSize: 24,
        fontWeight: '700',
        color: Theme.colors.text,
        marginBottom: 8,
        textAlign: 'center',
    },
    emptyText: {
        fontSize: 15,
        color: Theme.colors.textSecondary,
        textAlign: 'center',
        marginBottom: 28,
        lineHeight: 22,
    },
    addFirstHabitButton: {
        borderRadius: Theme.borderRadius.lg,
        overflow: 'hidden',
        backgroundColor: Theme.colors.primary,
        ...Theme.shadows.md,
    },
    addFirstHabitGradient: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        paddingHorizontal: 24,
        paddingVertical: 14,
    },
    addFirstHabitText: {
        color: '#fff',
        fontSize: 16,
        fontWeight: '600',
    },
    addFirstHabitEmoji: {
        fontSize: 16,
    },
    loadingContainer: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
    },
    loadingText: {
        ...Theme.typography.body,
        color: Theme.colors.textSecondary,
        marginTop: 16,
    },
    errorContainer: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: 32,
    },
    errorIcon: {
        fontSize: 48,
        marginBottom: 16,
    },
    errorText: {
        ...Theme.typography.h3,
        color: Theme.colors.textSecondary,
        marginBottom: 24,
        textAlign: 'center',
    },
    retryButton: {
        backgroundColor: Theme.colors.primary,
        paddingHorizontal: 28,
        paddingVertical: 14,
        borderRadius: Theme.borderRadius.md,
        ...Theme.shadows.md,
    },
    retryText: {
        color: '#fff',
        fontSize: 16,
        fontWeight: '600',
    },
});
