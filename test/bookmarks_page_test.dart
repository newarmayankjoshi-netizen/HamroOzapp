import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamro_oz/bookmarks_page.dart';

void main() {
  testWidgets('shows sign in prompt when not signed in', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BookmarksPage()));
    await tester.pumpAndSettle();

    expect(find.text('Please sign in to view bookmarks.'), findsOneWidget);
  });
}
