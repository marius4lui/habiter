final class AppUsageRecord {
  const AppUsageRecord({
    required this.packageName,
    required this.appName,
    required this.foregroundDuration,
    required this.lastUsed,
  });

  final String packageName;
  final String appName;
  final Duration foregroundDuration;
  final DateTime? lastUsed;
}

final class AppBlockCandidate {
  const AppBlockCandidate({
    required this.packageName,
    required this.appName,
    required this.foregroundDuration,
    required this.category,
    required this.score,
  });

  final String packageName;
  final String appName;
  final Duration foregroundDuration;
  final String? category;
  final double score;
}
