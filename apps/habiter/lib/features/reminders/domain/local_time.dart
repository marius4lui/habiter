import 'package:collection/collection.dart';

final class LocalTime implements Comparable<LocalTime> {
  const LocalTime(this.hour, this.minute)
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  factory LocalTime.fromMinuteOfDay(int value) {
    if (value < 0 || value >= minutesPerDay) {
      throw ArgumentError.value(value, 'value', 'Must be between 0 and 1439.');
    }
    return LocalTime(value ~/ 60, value % 60);
  }

  factory LocalTime.parse(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) throw FormatException('Invalid local time: $value');
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      throw FormatException('Invalid local time: $value');
    }
    return LocalTime(hour, minute);
  }

  static const minutesPerDay = 24 * 60;

  final int hour;
  final int minute;

  int get minuteOfDay => hour * 60 + minute;

  LocalTime addMinutes(int value) =>
      LocalTime.fromMinuteOfDay((minuteOfDay + value) % minutesPerDay);

  @override
  int compareTo(LocalTime other) => minuteOfDay.compareTo(other.minuteOfDay);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is LocalTime && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

final class LocalTimeRange {
  const LocalTimeRange({required this.start, required this.end});

  factory LocalTimeRange.fromMap(Map<String, Object?> map) => LocalTimeRange(
    start: LocalTime.parse(map['start']! as String),
    end: LocalTime.parse(map['end']! as String),
  );

  final LocalTime start;
  final LocalTime end;

  bool get crossesMidnight => end.compareTo(start) < 0;

  int get durationMinutes {
    final raw = end.minuteOfDay - start.minuteOfDay;
    return raw >= 0 ? raw : LocalTime.minutesPerDay + raw;
  }

  bool contains(LocalTime value) {
    if (!crossesMidnight) {
      return value.compareTo(start) >= 0 && value.compareTo(end) <= 0;
    }
    return value.compareTo(start) >= 0 || value.compareTo(end) <= 0;
  }

  bool overlaps(LocalTimeRange other) {
    final boundaries = <LocalTime>[start, end, other.start, other.end];
    return boundaries.any(
      (value) =>
          (contains(value) && other.contains(value)) ||
          (other.contains(value) && contains(value)),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'start': start.toString(),
    'end': end.toString(),
  };

  @override
  bool operator ==(Object other) =>
      other is LocalTimeRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

List<LocalTimeRange> normalizeTimeRanges(Iterable<LocalTimeRange> values) {
  final ranges = values.toList()
    ..sort((left, right) => left.start.compareTo(right.start));
  if (ranges.any((range) => range.durationMinutes == 0)) {
    throw ArgumentError.value(values, 'values', 'Ranges must not be empty.');
  }
  for (var index = 1; index < ranges.length; index++) {
    if (ranges[index - 1].overlaps(ranges[index])) {
      throw ArgumentError.value(values, 'values', 'Ranges must not overlap.');
    }
  }
  return List<LocalTimeRange>.unmodifiable(ranges);
}

bool timeRangesEqual(List<LocalTimeRange> left, List<LocalTimeRange> right) =>
    const ListEquality<LocalTimeRange>().equals(left, right);
