import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/widgets/domain/widget_configuration.dart';
import 'package:habiter/features/widgets/domain/widget_configuration_gateway.dart';
import 'package:habiter/features/widgets/domain/widget_configuration_options.dart';
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
    await tester.scrollUntilVisible(
      find.byKey(const Key('widget-display-name')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('widget-display-name')),
      'Training',
    );
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
    expect(gateway.saved.single.breakpointOverrides, isEmpty);
  });

  testWidgets(
    'Advanced stays collapsed and enables one breakpoint explicitly',
    (tester) async {
      final gateway = _FakeWidgetConfigurationGateway();
      await tester.pumpWidget(
        _app(
          WidgetBasicEditor(
            instance: WidgetInstance(
              widgetId: 22,
              widthDp: 250,
              heightDp: 180,
              breakpoint: WidgetBreakpoint.large,
              configuration: WidgetConfiguration.defaults(widgetId: 22),
            ),
            habits: const <Habit>[],
            gateway: gateway,
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('widget-advanced')),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Overrides pro Breakpoint'), findsNothing);
      await tester.tap(find.byKey(const Key('widget-advanced')));
      await tester.pumpAndSettle();
      expect(find.text('Overrides pro Breakpoint'), findsOneWidget);
      for (final title in <String>[
        'Sichtbare Elemente',
        'Habit-Liste',
        'Fortschritt',
        'Completion Controls',
        'Theme Tokens',
        'Geometrie',
        'Typografie',
        'Zustandsspezifische UI',
        'Interaktionszuordnung',
      ]) {
        expect(find.text(title), findsOneWidget);
      }

      await tester.tap(find.byKey(const Key('widget-advanced-breakpoints')));
      await tester.pumpAndSettle();
      final compactOverride = tester.widget<SwitchListTile>(
        find.byKey(const Key('widget-override-compact')),
      );
      compactOverride.onChanged!(true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('widget-save')));
      await tester.pumpAndSettle();

      expect(gateway.saved, hasLength(1));
      expect(gateway.saved.single.breakpointOverrides.keys, <WidgetBreakpoint>[
        WidgetBreakpoint.compact,
      ]);
    },
  );

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

  testWidgets(
    'live preview switches size and preset changes save immediately',
    (tester) async {
      final gateway = _FakeWidgetConfigurationGateway();
      await tester.pumpWidget(
        _app(
          WidgetBasicEditor(
            instance: WidgetInstance(
              widgetId: 30,
              widthDp: 250,
              heightDp: 120,
              breakpoint: WidgetBreakpoint.mediumHero,
              configuration: WidgetConfiguration.defaults(widgetId: 30),
            ),
            habits: <Habit>[_habit('read', 'Lesen', '📚')],
            gateway: gateway,
          ),
        ),
      );

      expect(find.byKey(const Key('widget-live-preview')), findsOneWidget);
      final size = tester.widget<DropdownButton<WidgetBreakpoint>>(
        find.byKey(const Key('widget-preview-breakpoint')),
      );
      size.onChanged!(WidgetBreakpoint.extraLarge);
      await tester.pump();
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const Key('widget-preview-semantics')),
            )
            .properties
            .label,
        'Live-Widget-Vorschau in Größe Extra groß',
      );
      expect(find.byKey(const Key('widget-preview-segments')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('widget-preset')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final preset = tester.widget<DropdownButtonFormField<WidgetPreset>>(
        find.descendant(
          of: find.byKey(const Key('widget-preset')),
          matching: find.byWidgetPredicate(
            (widget) => widget is DropdownButtonFormField<WidgetPreset>,
          ),
        ),
      );
      preset.onChanged!(WidgetPreset.minimal);
      await tester.pump();
      expect(find.byKey(const Key('widget-preview-segments')), findsNothing);
      await tester.tap(find.byKey(const Key('widget-save')));
      await tester.pumpAndSettle();

      expect(gateway.saved.single.preset, WidgetPreset.minimal);
      expect(gateway.saved.single.contentMode, WidgetContentMode.minimal);
    },
  );

  testWidgets('copy and duplicate preserve target widget identity', (
    tester,
  ) async {
    final source = WidgetInstance(
      widgetId: 41,
      widthDp: 110,
      heightDp: 110,
      breakpoint: WidgetBreakpoint.compactSquare,
      configuration: WidgetConfiguration(
        widgetId: 41,
        displayName: 'Source',
        contentMode: WidgetContentMode.focus,
        themeMode: WidgetThemeMode.dark,
      ),
    );
    final gateway = _FakeWidgetConfigurationGateway();
    await tester.pumpWidget(
      _app(
        WidgetBasicEditor(
          instance: WidgetInstance(
            widgetId: 40,
            widthDp: 250,
            heightDp: 180,
            breakpoint: WidgetBreakpoint.large,
            configuration: WidgetConfiguration(
              widgetId: 40,
              displayName: 'Target',
            ),
          ),
          habits: const <Habit>[],
          gateway: gateway,
          otherInstances: <WidgetInstance>[source],
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('widget-copy-settings')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    final copy = tester.widget<OutlinedButton>(
      find.byKey(const Key('widget-copy-settings')),
    );
    copy.onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Source'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('widget-save')));
    await tester.pumpAndSettle();

    expect(gateway.saved.single.widgetId, 40);
    expect(gateway.saved.single.displayName, 'Target');
    expect(gateway.saved.single.contentMode, WidgetContentMode.focus);
    expect(gateway.saved.single.themeMode, WidgetThemeMode.dark);

    gateway.saved.clear();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _app(
        WidgetBasicEditor(
          instance: WidgetInstance(
            widgetId: 40,
            widthDp: 250,
            heightDp: 180,
            breakpoint: WidgetBreakpoint.large,
            configuration: WidgetConfiguration(
              widgetId: 40,
              displayName: 'Target',
              contentMode: WidgetContentMode.list,
            ),
          ),
          habits: const <Habit>[],
          gateway: gateway,
          otherInstances: <WidgetInstance>[source],
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('widget-duplicate-settings')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    final duplicate = tester.widget<OutlinedButton>(
      find.byKey(const Key('widget-duplicate-settings')),
    );
    duplicate.onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Source'));
    await tester.pumpAndSettle();

    expect(gateway.saved.single.widgetId, 41);
    expect(gateway.saved.single.displayName, 'Source');
    expect(gateway.saved.single.contentMode, WidgetContentMode.list);
  });

  testWidgets('reset restores the legacy default baseline', (tester) async {
    final gateway = _FakeWidgetConfigurationGateway();
    await tester.pumpWidget(
      _app(
        WidgetBasicEditor(
          instance: WidgetInstance(
            widgetId: 50,
            widthDp: 110,
            heightDp: 60,
            breakpoint: WidgetBreakpoint.compact,
            configuration: WidgetConfiguration.forPreset(
              widgetId: 50,
              preset: WidgetPreset.dashboard,
              displayName: 'Keep me',
            ),
          ),
          habits: const <Habit>[],
          gateway: gateway,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('widget-reset-default')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    tester
        .widget<OutlinedButton>(find.byKey(const Key('widget-reset-default')))
        .onPressed!();
    await tester.pump();
    await tester.tap(find.byKey(const Key('widget-save')));
    await tester.pumpAndSettle();

    expect(gateway.saved.single.displayName, 'Keep me');
    expect(gateway.saved.single.preset, WidgetPreset.defaults);
    expect(gateway.saved.single.contentMode, WidgetContentMode.auto);
    expect(gateway.saved.single.maximumHabits, isNull);
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
