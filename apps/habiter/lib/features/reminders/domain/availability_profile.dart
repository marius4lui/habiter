import 'dart:collection';

enum ProfileDayType { weekday, weekend }

final class ProfileBucketKey implements Comparable<ProfileBucketKey> {
  const ProfileBucketKey({required this.dayType, required this.minuteOfDay})
    : assert(minuteOfDay >= 0 && minuteOfDay < 1440),
      assert(minuteOfDay % 30 == 0);

  factory ProfileBucketKey.fromMap(Map<String, Object?> map) =>
      ProfileBucketKey(
        dayType: ProfileDayType.values.byName(map['dayType']! as String),
        minuteOfDay: (map['minuteOfDay']! as num).toInt(),
      );

  final ProfileDayType dayType;
  final int minuteOfDay;

  String get storageKey => '${dayType.name}:$minuteOfDay';

  Map<String, Object?> toMap() => <String, Object?>{
    'dayType': dayType.name,
    'minuteOfDay': minuteOfDay,
  };

  @override
  int compareTo(ProfileBucketKey other) {
    final type = dayType.index.compareTo(other.dayType.index);
    return type != 0 ? type : minuteOfDay.compareTo(other.minuteOfDay);
  }

  @override
  bool operator ==(Object other) =>
      other is ProfileBucketKey &&
      dayType == other.dayType &&
      minuteOfDay == other.minuteOfDay;

  @override
  int get hashCode => Object.hash(dayType, minuteOfDay);
}

final class ProfileBucket {
  const ProfileBucket({
    required this.explicitAvailability,
    required this.completionLikelihood,
    required this.combinedScore,
    required this.confidence,
    required this.effectiveWeight,
  });

  factory ProfileBucket.fromMap(Map<String, Object?> map) => ProfileBucket(
    explicitAvailability: (map['explicitAvailability']! as num).toDouble(),
    completionLikelihood: (map['completionLikelihood']! as num).toDouble(),
    combinedScore: (map['combinedScore']! as num).toDouble(),
    confidence: (map['confidence']! as num).toDouble(),
    effectiveWeight: (map['effectiveWeight']! as num).toDouble(),
  );

  final double explicitAvailability;
  final double completionLikelihood;
  final double combinedScore;
  final double confidence;
  final double effectiveWeight;

  Map<String, Object?> toMap() => <String, Object?>{
    'explicitAvailability': explicitAvailability,
    'completionLikelihood': completionLikelihood,
    'combinedScore': combinedScore,
    'confidence': confidence,
    'effectiveWeight': effectiveWeight,
  };
}

final class AvailabilityProfile {
  AvailabilityProfile({
    required this.profileId,
    this.habitId,
    this.category,
    required Map<ProfileBucketKey, ProfileBucket> buckets,
    required this.confidence,
    required this.effectiveSamples,
    required this.computedAt,
    required this.algorithmVersion,
  }) : buckets = UnmodifiableMapView<ProfileBucketKey, ProfileBucket>(
         Map<ProfileBucketKey, ProfileBucket>.from(buckets),
       );

  factory AvailabilityProfile.fromMap(Map<String, Object?> map) {
    final buckets = <ProfileBucketKey, ProfileBucket>{};
    for (final value
        in (map['buckets'] as List<Object?>?) ?? const <Object?>[]) {
      final item = Map<String, Object?>.from(value! as Map);
      buckets[ProfileBucketKey.fromMap(
        Map<String, Object?>.from(item['key']! as Map),
      )] = ProfileBucket.fromMap(
        Map<String, Object?>.from(item['value']! as Map),
      );
    }
    return AvailabilityProfile(
      profileId: map['profileId']! as String,
      habitId: map['habitId'] as String?,
      category: map['category'] as String?,
      buckets: buckets,
      confidence: (map['confidence']! as num).toDouble(),
      effectiveSamples: (map['effectiveSamples']! as num).toInt(),
      computedAt: DateTime.parse(map['computedAt']! as String),
      algorithmVersion: (map['algorithmVersion']! as num).toInt(),
    );
  }

  final String profileId;
  final String? habitId;
  final String? category;
  final Map<ProfileBucketKey, ProfileBucket> buckets;
  final double confidence;
  final int effectiveSamples;
  final DateTime computedAt;
  final int algorithmVersion;

  ProfileBucket? bucketFor(int weekday, int minuteOfDay) =>
      buckets[ProfileBucketKey(
        dayType: weekday >= DateTime.saturday
            ? ProfileDayType.weekend
            : ProfileDayType.weekday,
        minuteOfDay: (minuteOfDay ~/ 30) * 30,
      )];

  Map<String, Object?> toMap() {
    final entries = buckets.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return <String, Object?>{
      'profileId': profileId,
      if (habitId != null) 'habitId': habitId,
      if (category != null) 'category': category,
      'buckets': entries
          .map(
            (entry) => <String, Object?>{
              'key': entry.key.toMap(),
              'value': entry.value.toMap(),
            },
          )
          .toList(growable: false),
      'confidence': confidence,
      'effectiveSamples': effectiveSamples,
      'computedAt': computedAt.toUtc().toIso8601String(),
      'algorithmVersion': algorithmVersion,
    };
  }
}

enum ProfileConfidenceLabel {
  learning,
  earlyTrend,
  good,
  stable;

  factory ProfileConfidenceLabel.fromScore(double score) => switch (score) {
    < 0.45 => ProfileConfidenceLabel.learning,
    < 0.65 => ProfileConfidenceLabel.earlyTrend,
    < 0.80 => ProfileConfidenceLabel.good,
    _ => ProfileConfidenceLabel.stable,
  };
}
