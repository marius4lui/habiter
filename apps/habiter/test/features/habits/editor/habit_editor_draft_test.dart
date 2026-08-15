import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/habits/presentation/editor/habit_editor_draft.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:habiter/widgets/add_habit_sheet.dart';
import 'package:provider/provider.dart';

import '../../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test('edit draft roundtrips every persisted field including reminders', () {
    final habit = Habit(
      id: 'habit-1',
      name: 'Read',
      description: 'Long books',
      color: '#285943',
      icon: '📚',
      frequency: HabitFrequency.custom,
      targetCount: 2,
      category: 'Learning',
      customDays: <int>[1, 3, 5],
      createdAt: DateTime.utc(2025),
      isActive: false,
      notificationEnabled: true,
      notificationTime: '19:30',
    );

    final roundtrip = HabitEditorDraft.fromHabit(habit).toHabit(
      id: habit.id,
      createdAt: habit.createdAt,
      isActive: habit.isActive,
    );

    expect(roundtrip.toMap(), habit.toMap());
  });

  test('validation requires a name and days only for custom schedules', () {
    final invalid = HabitEditorDraft.initial().copyWith(
      frequency: HabitFrequency.custom,
      name: '   ',
    );
    expect(
      invalid.validate().keys,
      containsAll(<String>['name', 'customDays']),
    );

    final valid = invalid.copyWith(name: 'Walk', customDays: <int>[2, 4]);
    expect(valid.validate(), isEmpty);
  });

  test('reminder validation is opt-in and rejects malformed times', () {
    expect(
      HabitEditorDraft.initial().copyWith(name: 'Walk').validate(),
      isEmpty,
    );
    final invalid = HabitEditorDraft.initial().copyWith(
      name: 'Walk',
      notificationEnabled: true,
      notificationTime: 'tomorrow',
    );
    expect(invalid.validate(), contains('notificationTime'));
  });

  test('weekly targets cannot exceed the seven days in a week', () {
    final invalid = HabitEditorDraft.initial().copyWith(
      name: 'Walk',
      frequency: HabitFrequency.weekly,
      targetCount: 8,
    );

    expect(invalid.validate(), containsPair('targetCount', 'range'));
  });

  testWidgets('German editor is scrollable, keyboard-safe, and cancel-safe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
    final provider = HabitProvider(repository: repository);
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<HabitProvider>.value(
        value: provider,
        child: MaterialApp(
          locale: const Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const AddHabitSheet(),
                ),
                child: const Text('Editor öffnen'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Editor öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Neues Habit'), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-preview')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(TextFormField).first);
    final firstFocus = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, isNot(same(firstFocus)));

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect((await repository.load()).habits, isEmpty);
  });
}
