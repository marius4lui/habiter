import 'widget_configuration.dart';

final class WidgetInstance {
  const WidgetInstance({
    required this.widgetId,
    required this.widthDp,
    required this.heightDp,
    required this.breakpoint,
    required this.configuration,
  });

  factory WidgetInstance.fromMap(Map<String, Object?> map) {
    final widgetId = (map['widgetId'] as num?)?.toInt();
    final widthDp = (map['widthDp'] as num?)?.toInt();
    final heightDp = (map['heightDp'] as num?)?.toInt();
    final breakpointName = map['breakpoint'];
    final source = map['configuration'];
    if (widgetId == null ||
        widthDp == null ||
        heightDp == null ||
        breakpointName is! String ||
        source is! String) {
      throw const FormatException('Widget instance response is malformed.');
    }
    final breakpoint = WidgetBreakpoint.values
        .where((value) => value.name == breakpointName)
        .firstOrNull;
    if (breakpoint == null) {
      throw const FormatException('Widget instance breakpoint is invalid.');
    }
    return WidgetInstance(
      widgetId: widgetId,
      widthDp: widthDp,
      heightDp: heightDp,
      breakpoint: breakpoint,
      configuration: WidgetConfiguration.fromJsonOrDefaults(
        source,
        widgetId: widgetId,
      ),
    );
  }

  final int widgetId;
  final int widthDp;
  final int heightDp;
  final WidgetBreakpoint breakpoint;
  final WidgetConfiguration configuration;
}

abstract interface class WidgetConfigurationGateway {
  Future<List<WidgetInstance>> listWidgetInstances();

  Future<void> saveWidgetConfiguration(WidgetConfiguration configuration);

  Future<void> resetWidgetConfiguration(int widgetId);
}
