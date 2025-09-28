import { format, parseISO, differenceInDays, subDays, startOfWeek, endOfWeek } from 'date-fns';
import { Habit, HabitEntry, HabitStreak, HabitStats } from '../types/habit';

export const formatDate = (date: Date): string => {
  return format(date, 'yyyy-MM-dd');
};

export const formatDisplayDate = (dateString: string): string => {
  return format(parseISO(dateString), 'MMM d, yyyy');
};

export const getTodayString = (): string => {
  return formatDate(new Date());
};

export const calculateStreak = (habitId: string, entries: HabitEntry[]): HabitStreak => {
  const habitEntries = entries
    .filter(entry => entry.habitId === habitId && entry.completed)
    .sort((a, b) => b.date.localeCompare(a.date)); // Sort by date descending

  if (habitEntries.length === 0) {
    return {
      habitId,
      currentStreak: 0,
      longestStreak: 0,
      lastCompletedDate: '',
    };
  }

  let currentStreak = 0;
  let longestStreak = 0;
  let tempStreak = 0;
  let previousDate: Date | null = null;

  // Calculate current streak (from today backwards)
  const today = new Date();
  let checkDate = today;

  for (const entry of habitEntries) {
    const entryDate = parseISO(entry.date);
    const dayDiff = differenceInDays(checkDate, entryDate);

    if (dayDiff === 0 || (dayDiff === 1 && currentStreak === 0)) {
      currentStreak++;
      checkDate = subDays(checkDate, 1);
    } else if (dayDiff === 1 && previousDate && differenceInDays(previousDate, entryDate) === 1) {
      currentStreak++;
    } else {
      break;
    }

    previousDate = entryDate;
  }

  // Calculate longest streak
  let consecutiveDays = 1;
  previousDate = parseISO(habitEntries[0].date);

  for (let i = 1; i < habitEntries.length; i++) {
    const currentDate = parseISO(habitEntries[i].date);
    const dayDiff = differenceInDays(previousDate, currentDate);

    if (dayDiff === 1) {
      consecutiveDays++;
      tempStreak = Math.max(tempStreak, consecutiveDays);
    } else {
      consecutiveDays = 1;
    }

    previousDate = currentDate;
  }

  longestStreak = Math.max(tempStreak, consecutiveDays, currentStreak);

  return {
    habitId,
    currentStreak,
    longestStreak,
    lastCompletedDate: habitEntries[0]?.date || '',
  };
};

export const calculateHabitStats = (habit: Habit, entries: HabitEntry[]): HabitStats => {
  const habitEntries = entries.filter(entry => entry.habitId === habit.id);
  const completedEntries = habitEntries.filter(entry => entry.completed);

  const totalCompletions = completedEntries.length;
  const completionRate = habitEntries.length > 0
    ? (totalCompletions / habitEntries.length) * 100
    : 0;

  // Calculate average per week
  const uniqueDates = [...new Set(habitEntries.map(entry => entry.date))];
  const sortedDates = uniqueDates.sort();

  let averagePerWeek = 0;
  if (sortedDates.length > 0) {
    const firstDate = parseISO(sortedDates[0]);
    const lastDate = parseISO(sortedDates[sortedDates.length - 1]);
    const totalWeeks = Math.max(1, Math.ceil(differenceInDays(lastDate, firstDate) / 7));
    averagePerWeek = totalCompletions / totalWeeks;
  }

  const streakData = calculateStreak(habit.id, entries);

  return {
    habitId: habit.id,
    totalCompletions,
    completionRate: Math.round(completionRate * 100) / 100,
    averagePerWeek: Math.round(averagePerWeek * 100) / 100,
    streakData,
  };
};

export const getWeeklyData = (habitId: string, entries: HabitEntry[], weeksBack: number = 4) => {
  const weeklyData = [];
  const today = new Date();

  for (let i = weeksBack - 1; i >= 0; i--) {
    const weekStart = startOfWeek(subDays(today, i * 7));
    const weekEnd = endOfWeek(weekStart);

    const weekEntries = entries.filter(entry => {
      if (entry.habitId !== habitId) return false;
      const entryDate = parseISO(entry.date);
      return entryDate >= weekStart && entryDate <= weekEnd;
    });

    const completions = weekEntries.filter(entry => entry.completed).length;

    weeklyData.push({
      week: format(weekStart, 'MMM d'),
      completions,
      total: 7, // Assuming daily habits
    });
  }

  return weeklyData;
};

export const getHabitCompletionForDate = (habitId: string, date: string, entries: HabitEntry[]): HabitEntry | null => {
  return entries.find(entry =>
    entry.habitId === habitId &&
    entry.date === date
  ) || null;
};

export const isHabitCompletedToday = (habitId: string, entries: HabitEntry[]): boolean => {
  const today = getTodayString();
  const todayEntry = getHabitCompletionForDate(habitId, today, entries);
  return todayEntry?.completed || false;
};

export const getCompletionRateForPeriod = (
  habitId: string,
  entries: HabitEntry[],
  days: number
): number => {
  const endDate = new Date();
  const startDate = subDays(endDate, days);

  const periodEntries = entries.filter(entry => {
    if (entry.habitId !== habitId) return false;
    const entryDate = parseISO(entry.date);
    return entryDate >= startDate && entryDate <= endDate;
  });

  if (periodEntries.length === 0) return 0;

  const completedCount = periodEntries.filter(entry => entry.completed).length;
  return (completedCount / periodEntries.length) * 100;
};

export const generateHabitColors = (): string[] => {
  return [
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#96CEB4', // Green
    '#FECA57', // Yellow
    '#FF9FF3', // Pink
    '#54A0FF', // Light Blue
    '#5F27CD', // Purple
    '#00D2D3', // Cyan
    '#FF9F43', // Orange
  ];
};

export const getRandomColor = (): string => {
  const colors = generateHabitColors();
  return colors[Math.floor(Math.random() * colors.length)];
};

export const getHabitIconSuggestions = (category: string): string[] => {
  const iconMap: { [key: string]: string[] } = {
    'Health': ['💪', '🏃', '🧘', '💊', '🥗', '💧'],
    'Learning': ['📚', '💻', '🎓', '✍️', '🧠', '🔬'],
    'Productivity': ['✅', '⏰', '📝', '🎯', '📊', '💼'],
    'Social': ['👥', '📞', '💬', '❤️', '🤝', '👨‍👩‍👧‍👦'],
    'Creative': ['🎨', '🎵', '📸', '✨', '🖌️', '🎭'],
    'Fitness': ['🏋️', '🚴', '🏊', '🤸', '⚽', '🧗'],
    'Mindfulness': ['🧘', '🙏', '📿', '🌸', '🕯️', '☮️'],
    'Finance': ['💰', '📈', '💳', '🏦', '💎', '📊'],
  };

  return iconMap[category] || ['✨', '🎯', '⭐', '🌟', '💫', '🔥'];
};