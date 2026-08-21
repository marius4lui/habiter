import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/widgets/domain/widget_configuration.dart';
import 'package:habiter/features/widgets/domain/widget_configuration_gateway.dart';
import 'package:habiter/features/widgets/presentation/widget_basic_editor.dart';
import 'package:habiter/features/widgets/presentation/widget_management_screen.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';

void main() {
  testWidgets('management lists independently named widget instances', (
    tester,
  ) async {
    final gateway = _FakeWidgetConfigurationGateway(
      instances: <WidgetInstance>[
        WidgetInstance(
          widgetId: 17,
          widthDp: 250,
          heightDp: 120,
          breakpoint: WidgetBreakpoint.mediumHero,
          configuration: WidgetConfiguration(
            widgetId: 17,
            displayName: 'Training',
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      _app(WidgetManagementScreen(gateway: gateway, habits: const <Habit>[])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Training'), findsOneWidget);
    expect(find.textContaining('250 × 120 dp'), findsOneWidget);
    expect(find.textContaining('Medium Hero'), findsOneWidget);

    await tester.tap(find.byKey(const Key('widget-instance-17')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('widget-basic-editor')), findsOneWidget);
  });

  testWidgets('launcher flow opens the matching placed instance directly', (
    tester,
  ) async {
    final instance = WidgetInstance(
      widgetId: 21,
      widthDp: 110,
      heightDp: 60,
      breakpoint: WidgetBreakpoint.compact,
      configuration: WidgetConfiguration.defaults(widgetId: 21),
    );
    await tester.pumpWidget(
      _app(
        WidgetManagementScreen(
          gateway: _FakeWidgetConfigurationGateway(
            instances: <WidgetInstance>[instance],
            pendingId: 21,
          ),
          habits: const <Habit>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('widget-basic-editor')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('localized Basic editor saves only its widget instance', (
    tester,
  ) async {
    final gateway = _FakeWidgetConfigurationGateway();
    final configuration = WidgetConfiguration.defaults(widgetId: 17);
    await tester.pumpWidget(
      _app(
        WidgetBasicEditor(
          instance: WidgetInstance(
            widgetId: 17,
            widthDp: 250,
            heightDp: 120,
            breakpoint: WidgetBreakpoint.mediumHero,
            configuration: configuration,
          ),
          habits: <Habit>[_habit('train', 'Training', '🏋️')],
          gateway: gateway,
        ),
      ),
    );

    expect(find.text('Widget-Einstellungen'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'Training');
    await tester.scrollUntilVisible(
      find.text('One-Tap Completion'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('One-Tap Completion'));
    await tester.tap(find.byKey(const Key('widget-save')));
    await tester.pumpAndSettle();

    expect(gateway.saved, hasLength(1));
    expect(gateway.saved.single.widgetId, 17);
    expect(gateway.saved.single.displayName, 'Training');
    expect(gateway.saved.single.oneTapCompletion, isFalse);
  });

  testWidgets('launcher configuration back action cancels the host flow', (
    tester,
  ) async {
    final gateway = _FakeWidgetConfigurationGateway();
    await tester.pumpWidget(
      _app(
        WidgetBasicEditor(
          instance: WidgetInstance(
            widgetId: 18,
            widthDp: 110,
            heightDp: 110,
            breakpoint: WidgetBreakpoint.compactSquare,
            configuration: WidgetConfiguration.defaults(widgetId: 18),
          ),
          habits: const <Habit>[],
          gateway: gateway,
          configurationLaunch: true,
        ),
      ),
    );

    await tester.tap(find.byType(BackButton));
    await tester.pump();

    expect(gateway.cancelCount, 1);
    expect(gateway.saved, isEmpty);
  });
}

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('de'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

Habit _habit(String id, String name, String icon) => Habit(
  id: id,
  name: name,
  color: '#285943',
  icon: icon,
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'Health',
  createdAt: DateTime.utc(2026, 8, 21),
  isActive: true,
);

final class _FakeWidgetConfigurationGateway
    implements WidgetConfigurationGateway {
  _FakeWidgetConfigurationGateway({
    this.instances = const <WidgetInstance>[],
    this.pendingId,
  });

  final List<WidgetConfiguration> saved = <WidgetConfiguration>[];
  final List<WidgetInstance> instances;
  final int? pendingId;
  int cancelCount = 0;

  @override
  Future<void> cancelWidgetConfiguration() async => cancelCount += 1;

  @override
  Future<List<WidgetInstance>> listWidgetInstances() async => instances;

  @override
  Future<int?> pendingWidgetConfiguration() async => pendingId;

  @override
  Future<void> resetWidgetConfiguration(int widgetId) async {}

  @override
  Future<void> saveWidgetConfiguration(
    WidgetConfiguration configuration,
  ) async => saved.add(configuration);
}
