import 'dart:convert';

import 'package:flutter/services.dart';

enum DistractionPrior { low, medium, high }

final class DistractionCatalogEntry {
  const DistractionCatalogEntry({required this.category, required this.prior});

  final String category;
  final DistractionPrior prior;
}

final class LocalDistractionCatalog {
  const LocalDistractionCatalog(this.entries);

  final Map<String, DistractionCatalogEntry> entries;

  static Future<LocalDistractionCatalog> load({AssetBundle? bundle}) async =>
      LocalDistractionCatalog.fromJson(
        await (bundle ?? rootBundle).loadString(
          'assets/app_block/distraction_catalog.v1.json',
        ),
      );

  factory LocalDistractionCatalog.fromJson(String source) {
    final decoded = Map<String, dynamic>.from(jsonDecode(source) as Map);
    final packages = decoded['packages'] is Map
        ? Map<String, dynamic>.from(decoded['packages'] as Map)
        : decoded;
    return LocalDistractionCatalog(
      Map<String, DistractionCatalogEntry>.unmodifiable(
        packages.map((packageName, value) {
          final map = Map<String, dynamic>.from(value as Map);
          return MapEntry<String, DistractionCatalogEntry>(
            packageName,
            DistractionCatalogEntry(
              category: map['category'] as String? ?? 'other',
              prior: DistractionPrior.values.firstWhere(
                (prior) => prior.name == map['prior'],
                orElse: () => DistractionPrior.low,
              ),
            ),
          );
        }),
      ),
    );
  }
}
