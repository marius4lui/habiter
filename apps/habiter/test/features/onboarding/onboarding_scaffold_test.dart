import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/onboarding_scaffold.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/theme/app_theme.dart';

void main() {
  for (final size in const <Size>[
    Size(320, 720),
    Size(412, 915),
    Size(900, 900),
  ]) {
    testWidgets('editorial scaffold fits ${size.width.toInt()}dp canvas', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app());

      expect(
        find.byKey(const ValueKey<String>('onboarding-editorial-canvas')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('onboarding-segmented-progress')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('onboarding-progress-8')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('editorial scaffold supports dark mode and 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(dark: true, textScale: 2));

    expect(find.text('Grow with intention'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editorial scaffold uses theme colors in high contrast', (
    tester,
  ) async {
    await tester.pumpWidget(_app(highContrast: true));

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey<String>('onboarding-editorial-canvas')),
    );
    expect(scaffold.backgroundColor, buildAppTheme().colorScheme.surface);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({
  bool dark = false,
  double textScale = 1,
  bool highContrast = false,
}) => MaterialApp(
  locale: const Locale('en'),
  theme: buildAppTheme(),
  darkTheme: buildDarkTheme(),
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      highContrast: highContrast,
    ),
    child: child!,
  ),
  home: OnboardingScaffold(
    step: OnboardingStep.rhythm,
    title: 'Grow with intention',
    subtitle: 'A calm rhythm makes a habit easier to keep.',
    onBack: () {},
    body: const SizedBox(height: 260, child: Placeholder()),
    primaryAction: const FilledButton(
      onPressed: _noop,
      child: Text('Continue'),
    ),
    secondaryAction: const TextButton(onPressed: _noop, child: Text('Later')),
  ),
);

void _noop() {}
