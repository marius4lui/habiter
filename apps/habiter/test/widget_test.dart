// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:habiter/providers/habit_provider.dart';
import 'package:habiter/providers/app_lock_provider.dart';
import 'package:habiter/theme/app_theme.dart';

void main() {
  testWidgets('Shell renders nav destinations', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HabitProvider()),
          ChangeNotifierProvider(create: (_) => AppLockProvider()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.checklist_rtl),
                  label: 'Habits',
                ),
                NavigationDestination(
                  icon: Icon(Icons.query_stats),
                  label: 'Analytics',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
  });
}
