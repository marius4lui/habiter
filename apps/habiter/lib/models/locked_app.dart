import 'dart:convert';
import 'dart:typed_data';

export '../features/app_lock/domain/app_block_config.dart';

/// Represents an app that can be locked until habits are completed
class LockedApp {
  const LockedApp({
    required this.packageName,
    required this.appName,
    this.iconBytes,
    this.isLocked = false,
  });

  /// Android package name (e.g., com.instagram.android)
  final String packageName;

  /// User-visible app name
  final String appName;

  /// App icon as bytes (from Android PackageManager)
  final Uint8List? iconBytes;

  /// Whether this app is currently locked
  final bool isLocked;

  LockedApp copyWith({
    String? packageName,
    String? appName,
    Uint8List? iconBytes,
    bool? isLocked,
  }) {
    return LockedApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconBytes: iconBytes ?? this.iconBytes,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'iconBytes': iconBytes != null ? base64Encode(iconBytes!) : null,
      'isLocked': isLocked,
    };
  }

  factory LockedApp.fromMap(Map<String, dynamic> map) {
    return LockedApp(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      iconBytes: map['iconBytes'] != null
          ? base64Decode(map['iconBytes'] as String)
          : null,
      isLocked: map['isLocked'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LockedApp.fromJson(String source) =>
      LockedApp.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LockedApp && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;
}
