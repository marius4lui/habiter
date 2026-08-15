final class LocalDate implements Comparable<LocalDate> {
  factory LocalDate(int year, int month, int day) {
    final candidate = DateTime.utc(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      throw ArgumentError.value(
        '$year-$month-$day',
        'date',
        'Must be a real Gregorian calendar date.',
      );
    }
    return LocalDate._(year, month, day);
  }

  const LocalDate._(this.year, this.month, this.day);

  factory LocalDate.fromDateTime(DateTime value) {
    return LocalDate(value.year, value.month, value.day);
  }

  factory LocalDate.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('Expected a date in yyyy-MM-dd format.', value);
    }
    try {
      return LocalDate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    } on ArgumentError {
      throw FormatException('Invalid Gregorian calendar date.', value);
    }
  }

  final int year;
  final int month;
  final int day;

  int get weekday => DateTime.utc(year, month, day).weekday;

  LocalDate addDays(int days) {
    final result = DateTime.utc(year, month, day).add(Duration(days: days));
    return LocalDate(result.year, result.month, result.day);
  }

  @override
  int compareTo(LocalDate other) {
    final yearResult = year.compareTo(other.year);
    if (yearResult != 0) return yearResult;
    final monthResult = month.compareTo(other.month);
    if (monthResult != 0) return monthResult;
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalDate &&
        year == other.year &&
        month == other.month &&
        day == other.day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
