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

            {/* Header with gradient background */}
            <View style={styles.headerContainer}>
                <View style={styles.header}>
                    <View style={styles.titleContainer}>
                        <View style={styles.greetingRow}>
                            <Text style={styles.greetingEmoji}>{getGreetingEmoji()}</Text>
                            <Text style={styles.greeting}>{getGreeting()}</Text>
                        </View>
                        <Text style={styles.date}>{formatDisplayDate(today)}</Text>

                        {/* Progress indicator */}
                        {activeHabits.length > 0 && (
                            <View style={styles.progressContainer}>
                                <View style={styles.progressBar}>
                                    <LinearGradient
                                        colors={Theme.gradients.primary}
                                        start={{ x: 0, y: 0 }}
                                        end={{ x: 1, y: 0 }}
                                        style={[
                                            styles.progressFill,
                                            { width: `${Math.round((completedToday / activeHabits.length) * 100)}%` }
                                        ]}
                                    />
                                </View>
                                <Text style={styles.progressText}>
                                    {completedToday}/{activeHabits.length} completed today
                                </Text>
                            </View>
                        )}
                    </View>

                    <View style={styles.headerButtons}>
                        <TouchableOpacity
                            style={[styles.iconButton, !isConfigured && styles.iconButtonWarning]}
                            onPress={isConfigured ? handleGenerateInsights : () => setShowAISetup(true)}
                            disabled={generatingInsights}
                        >
                            {generatingInsights ? (
                                <ActivityIndicator size="small" color={Theme.colors.primary} />
                            ) : (
                                <Text style={styles.iconButtonText}>✨</Text>
                            )}
                        </TouchableOpacity>

                        <TouchableOpacity
                            style={styles.addButton}
                            onPress={() => setShowAddModal(true)}
                        >
                            <LinearGradient
                                colors={Theme.gradients.primary}
                                style={styles.addButtonGradient}
                            >
                                <Text style={styles.addButtonText}>+</Text>
                            </LinearGradient>
                        </TouchableOpacity>
                    </View>
                </View>
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
        backgroundColor: Theme.colors.surface,
        borderBottomLeftRadius: Theme.borderRadius.xxl,
        borderBottomRightRadius: Theme.borderRadius.xxl,
        ...Theme.shadows.sm,
    },
    header: {
        flexDirection: 'row',
        alignItems: 'flex-start',
        justifyContent: 'space-between',
        paddingHorizontal: Theme.spacing.md,
        paddingTop: Theme.spacing.md,
        paddingBottom: Theme.spacing.lg,
    },
    titleContainer: {
        flex: 1,
        marginRight: Theme.spacing.md,
    },
    greetingRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        marginBottom: 4,
    },
    greetingEmoji: {
        fontSize: 24,
    },
    greeting: {
        ...Theme.typography.h1,
        fontSize: 26,
    },
    date: {
        ...Theme.typography.caption,
        marginTop: 2,
        marginBottom: 12,
    },
    progressContainer: {
        marginTop: 8,
    },
    progressBar: {
        height: 6,
        backgroundColor: Theme.colors.borderLight,
        borderRadius: Theme.borderRadius.full,
        overflow: 'hidden',
        marginBottom: 6,
    },
    progressFill: {
        height: '100%',
        borderRadius: Theme.borderRadius.full,
    },
    progressText: {
        ...Theme.typography.caption,
        fontSize: 11,
    },
    headerButtons: {
        gap: 10,
        alignItems: 'flex-end',
    },
    iconButton: {
        width: 44,
        height: 44,
        borderRadius: Theme.borderRadius.md,
        backgroundColor: Theme.colors.backgroundDark,
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 1,
        borderColor: Theme.colors.borderLight,
    },
    iconButtonWarning: {
        borderColor: Theme.colors.warning,
        backgroundColor: Theme.colors.warningLight,
    },
    iconButtonText: {
        fontSize: 20,
    },
    addButton: {
        width: 52,
        height: 52,
        borderRadius: Theme.borderRadius.xl,
        overflow: 'hidden',
        ...Theme.shadows.lg,
    },
    addButtonGradient: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
    },
    addButtonText: {
        fontSize: 30,
        color: '#fff',
        fontWeight: '300',
        marginTop: -2,
    },
    listContent: {
        paddingTop: Theme.spacing.lg,
        paddingBottom: Theme.spacing.xl,
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
    emptyIconContainer: {
        width: 100,
        height: 100,
        borderRadius: Theme.borderRadius.full,
        backgroundColor: Theme.colors.primaryLight + '20',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 24,
    },
    emptyIcon: {
        fontSize: 48,
    },
    emptyTitle: {
        ...Theme.typography.h1,
        fontSize: 28,
        marginBottom: 12,
        textAlign: 'center',
    },
    emptyText: {
        ...Theme.typography.body,
        color: Theme.colors.textSecondary,
        textAlign: 'center',
        marginBottom: 32,
        lineHeight: 24,
    },
    addFirstHabitButton: {
        borderRadius: Theme.borderRadius.xl,
        overflow: 'hidden',
        ...Theme.shadows.lg,
    },
    addFirstHabitGradient: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        paddingHorizontal: 28,
        paddingVertical: 16,
    },
    addFirstHabitText: {
        color: '#fff',
        fontSize: 17,
        fontWeight: '600',
    },
    addFirstHabitEmoji: {
        fontSize: 18,
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
