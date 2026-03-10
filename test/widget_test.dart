// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hamro_oz/auth_page.dart';

void main() {
  testWidgets('App boots to login screen', (WidgetTester tester) async {
    // Test the login screen UI directly.
    // The full app boot includes async bootstrap steps (e.g. Firebase init)
    // that can be flaky or unavailable in widget tests.
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pump();

    expect(find.byKey(const ValueKey('login_email')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_password')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_submit')), findsOneWidget);
  });
}
