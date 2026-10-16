// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_app/main.dart';

void main() {
  testWidgets('account creation, sign in, and logout work on a phone', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(PlanningApp(api: _FakeTaskApi()));

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('auth-name')), 'Ruth');
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'ruth@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'planner123',
    );
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Today at a glance'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-avatar')), findsOneWidget);
    expect(
      find.text('Tap the edit icon to change and resize your photo'),
      findsOneWidget,
    );
    expect(find.text('Choose and resize photo'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Log out'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'ruth@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'planner123',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Today at a glance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeTaskApi extends TaskApi {
  @override
  Future<List<Task>> fetchTasks() async => [];

  @override
  Future<void> deleteTask(int id) async {}
}
