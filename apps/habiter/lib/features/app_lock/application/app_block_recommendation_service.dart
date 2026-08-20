import '../domain/app_block_candidate.dart';
import '../infrastructure/local_distraction_catalog.dart';

final class AppBlockRecommendationService {
  const AppBlockRecommendationService();

  List<AppBlockCandidate> rank({
    required Iterable<AppUsageRecord> usage,
    required LocalDistractionCatalog catalog,
    required DateTime now,
    int limit = 5,
  }) {
    final records = usage
        .where((record) => record.foregroundDuration > Duration.zero)
        .toList(growable: false);
    if (records.isEmpty) return const <AppBlockCandidate>[];
    final maxMilliseconds = records
        .map((record) => record.foregroundDuration.inMilliseconds)
        .reduce((a, b) => a > b ? a : b);

    final candidates =
        records
            .map((record) {
              final catalogEntry = catalog.entries[record.packageName];
              final usageScore =
                  record.foregroundDuration.inMilliseconds / maxMilliseconds;
              final priorScore = switch (catalogEntry?.prior) {
                DistractionPrior.high => 1.0,
                DistractionPrior.medium => 0.6,
                DistractionPrior.low => 0.25,
                null => 0.0,
              };
              final daysSinceUse = record.lastUsed == null
                  ? 7
                  : now.difference(record.lastUsed!).inDays.clamp(0, 7);
              final recencyScore = 1 - (daysSinceUse / 7);
              return AppBlockCandidate(
                packageName: record.packageName,
                appName: record.appName,
                foregroundDuration: record.foregroundDuration,
                category: catalogEntry?.category,
                score:
                    (usageScore * 0.7) +
                    (priorScore * 0.2) +
                    (recencyScore * 0.1),
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            final score = b.score.compareTo(a.score);
            return score != 0 ? score : a.packageName.compareTo(b.packageName);
          });
    return List<AppBlockCandidate>.unmodifiable(candidates.take(limit));
  }
}
