import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/app_lock/application/app_block_recommendation_service.dart';
import 'package:habiter/features/app_lock/domain/app_block_candidate.dart';
import 'package:habiter/features/app_lock/infrastructure/local_distraction_catalog.dart';

void main() {
  const service = AppBlockRecommendationService();
  final now = DateTime(2026, 8, 19, 12);
  final catalog = LocalDistractionCatalog.fromJson('''
    {"packages": {
      "social.example": {"category": "social", "prior": "high"},
      "maps.example": {"category": "navigation", "prior": "low"}
    }}
  ''');

  test('combines normalized usage, catalog prior, and recency locally', () {
    final result = service.rank(
      usage: <AppUsageRecord>[
        AppUsageRecord(
          packageName: 'social.example',
          appName: 'Social',
          foregroundDuration: const Duration(hours: 2),
          lastUsed: now,
        ),
        AppUsageRecord(
          packageName: 'maps.example',
          appName: 'Maps',
          foregroundDuration: const Duration(hours: 2),
          lastUsed: now.subtract(const Duration(days: 6)),
        ),
      ],
      catalog: catalog,
      now: now,
    );

    expect(result.first.packageName, 'social.example');
    expect(result.first.category, 'social');
    expect(result.first.score, greaterThan(result.last.score));
  });

  test('uses deterministic package ordering for equal scores', () {
    final result = service.rank(
      usage: <AppUsageRecord>[
        const AppUsageRecord(
          packageName: 'b.example',
          appName: 'B',
          foregroundDuration: Duration(hours: 1),
          lastUsed: null,
        ),
        const AppUsageRecord(
          packageName: 'a.example',
          appName: 'A',
          foregroundDuration: Duration(hours: 1),
          lastUsed: null,
        ),
      ],
      catalog: const LocalDistractionCatalog(
        <String, DistractionCatalogEntry>{},
      ),
      now: now,
    );
    expect(result.map((item) => item.packageName), <String>[
      'a.example',
      'b.example',
    ]);
  });

  test('missing usage data returns manual-selection fallback state', () {
    expect(
      service.rank(usage: const <AppUsageRecord>[], catalog: catalog, now: now),
      isEmpty,
    );
  });

  test('recommendations carry no implicit selection state and are capped', () {
    final usage = List<AppUsageRecord>.generate(
      8,
      (index) => AppUsageRecord(
        packageName: 'app.$index',
        appName: 'App $index',
        foregroundDuration: Duration(minutes: index + 1),
        lastUsed: now,
      ),
    );
    expect(
      service.rank(usage: usage, catalog: catalog, now: now),
      hasLength(5),
    );
  });
}
