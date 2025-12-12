import 'dart:math';

import 'package:intl/intl.dart';

import '../models/habit.dart';

final _storageDateFormat = DateFormat('yyyy-MM-dd');
final _displayDateFormat = DateFormat('MMM d, yyyy');

String formatDate(DateTime date) => _storageDateFormat.format(date);

String formatDisplayDate(String dateString) {
  return _displayDateFormat.format(DateTime.parse(dateString));
}

String getTodayString() => formatDate(DateTime.now());

int _dayDiff(DateTime a, DateTime b) {
  final aDate = DateTime(a.year, a.month, a.day);
  final bDate = DateTime(b.year, b.month, b.day);
  return aDate.difference(bDate).inDays;
}

HabitStreak calculateStreak(String habitId, List<HabitEntry> entries) {
  final habitEntries = entries
      .where((e) => e.habitId == habitId && e.completed)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  if (habitEntries.isEmpty) {
    return HabitStreak(
      habitId: habitId,
      currentStreak: 0,
      longestStreak: 0,
      lastCompletedDate: '',
    );
  }

  var currentStreak = 0;
  var longestStreak = 0;
  var previousDate = DateTime.now();
  var firstLoop = true;

  for (final entry in habitEntries) {
    final entryDate = DateTime.parse(entry.date);
    if (firstLoop) {
      final diff = _dayDiff(DateTime.now(), entryDate);
      if (diff <= 1) {
        currentStreak++;
        previousDate = entryDate;
      } else {
        break;
      }
      firstLoop = false;
      continue;
    }

    final diff = _dayDiff(previousDate, entryDate);
    if (diff == 1) {
      currentStreak++;
      previousDate = entryDate;
    } else {
      break;
    }
  }

  var temp = 1;
  previousDate = DateTime.parse(habitEntries.first.date);
  for (var i = 1; i < habitEntries.length; i++) {
    final entryDate = DateTime.parse(habitEntries[i].date);
    final diff = _dayDiff(previousDate, entryDate);
    if (diff == 1) {
      temp++;
    } else {
      longestStreak = max(longestStreak, temp);
      temp = 1;
    }
    previousDate = entryDate;
  }
  longestStreak = max(longestStreak, temp);
  longestStreak = max(longestStreak, currentStreak);

  return HabitStreak(
    habitId: habitId,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastCompletedDate: habitEntries.first.date,
  );
}

HabitStats calculateHabitStats(Habit habit, List<HabitEntry> entries) {
  final habitEntries = entries.where((e) => e.habitId == habit.id).toList();
  final completed = habitEntries.where((e) => e.completed).toList();
  final totalCompletions = completed.length;
  final completionRate =
      habitEntries.isEmpty ? 0 : (totalCompletions / habitEntries.length) * 100;

  final uniqueDates = habitEntries.map((e) => e.date).toSet().toList()..sort();
  var averagePerWeek = 0.0;
  if (uniqueDates.isNotEmpty) {
    final firstDate = DateTime.parse(uniqueDates.first);
    final lastDate = DateTime.parse(uniqueDates.last);
    final totalWeeks = max(1, ((lastDate.difference(firstDate).inDays) / 7).ceil());
    averagePerWeek = totalCompletions / totalWeeks;
  }

  final streakData = calculateStreak(habit.id, entries);

  return HabitStats(
    habitId: habit.id,
    totalCompletions: totalCompletions,
    completionRate: double.parse(completionRate.toStringAsFixed(2)),
    averagePerWeek: double.parse(averagePerWeek.toStringAsFixed(2)),
    streakData: streakData,
  );
}

class WeeklyData {
  WeeklyData({required this.week, required this.completions, required this.total});

  final String week;
  final int completions;
  final int total;
}

List<WeeklyData> getWeeklyData(String habitId, List<HabitEntry> entries,
    {int weeksBack = 4}) {
  final data = <WeeklyData>[];
  final today = DateTime.now();

  for (var i = weeksBack - 1; i >= 0; i--) {
    final weekStart = DateTime(today.year, today.month, today.day - (today.weekday - 1) - (i * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final weekEntries = entries.where((entry) {
      if (entry.habitId != habitId) return false;
      final entryDate = DateTime.parse(entry.date);
      return entryDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
          entryDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();

    final completions = weekEntries.where((e) => e.completed).length;
    data.add(WeeklyData(
      week: DateFormat('MMM d').format(weekStart),
      completions: completions,
      total: 7,
    ));
  }

  return data;
}

HabitEntry? getHabitCompletionForDate(
    String habitId, String date, List<HabitEntry> entries) {
  try {
    return entries.firstWhere(
      (entry) => entry.habitId == habitId && entry.date == date,
    );
  } catch (_) {
    return null;
  }
}

bool isHabitCompletedToday(String habitId, List<HabitEntry> entries) {
  final today = getTodayString();
  final entry = getHabitCompletionForDate(habitId, today, entries);
  return entry?.completed ?? false;
}

double getCompletionRateForPeriod(
    String habitId, List<HabitEntry> entries, int days) {
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: days));

  final periodEntries = entries.where((entry) {
    if (entry.habitId != habitId) return false;
    final entryDate = DateTime.parse(entry.date);
    return entryDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        entryDate.isBefore(endDate.add(const Duration(days: 1)));
  }).toList();

  if (periodEntries.isEmpty) return 0;
  final completed = periodEntries.where((e) => e.completed).length;
  return (completed / periodEntries.length) * 100;
}

List<String> generateHabitColors() {
  return const [
    '#FF6B6B',
    '#4ECDC4',
    '#45B7D1',
    '#96CEB4',
    '#FECA57',
    '#FF9FF3',
    '#54A0FF',
    '#5F27CD',
    '#00D2D3',
    '#FF9F43',
  ];
}

String getRandomColor() {
  final colors = generateHabitColors();
  return colors[Random().nextInt(colors.length)];
}

Map<String, List<String>> getHabitIconSuggestions() {
  return {
    'Health': ['💧', '🥗', '😴', '🚶', '🧘'],
    'Learning': ['📚', '🧠', '📝', '🎧', '🧩'],
    'Productivity': ['✅', '📈', '⌛', '📆', '🧹'],
    'Social': ['💬', '🤝', '📱', '👥', '🎉'],
    'Creative': ['🎨', '✏️', '🎸', '📸', '🧵'],
    'Fitness': ['🏃', '🏋️', '🚴', '🧗', '🏊'],
    'Mindfulness': ['🧘', '🌿', '📓', '🕯️', '🎧'],
    'Finance': ['💰', '💳', '📊', '🧾', '🏦'],
  };
}
