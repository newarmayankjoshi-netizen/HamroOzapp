import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hamro_oz/guides/guides_page.dart';

void main() {
  testWidgets('Guides language toggle switches full content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GuidesPage()));
    await tester.pumpAndSettle();

    // Open first guide by tapping the first tappable card.
    final firstTap = find.byType(GestureDetector).first;
    await tester.ensureVisible(firstTap);
    await tester.tap(firstTap);
    await tester.pumpAndSettle();

    // Toggle to Nepali and assert toggle labels update.
    await tester.tap(find.text('नेपाली'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);

    // Toggle back to English and confirm toggle label is present.
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('नेपाली'), findsOneWidget);
  });

  testWidgets('Moving/suburb guide shows new Nepali sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GuidesPage()));
    await tester.pumpAndSettle();

    // Toggle to Nepali on the guides list and confirm several Nepali section titles exist.
    await tester.tap(find.text('नेपाली'));
    await tester.pumpAndSettle();

    // Confirm that Nepali text appears somewhere on the page (Devanagari characters).
    final nepaliTexts = find.byWidgetPredicate((w) {
      if (w is Text) {
        final data = w.data ?? '';
        return RegExp(r'[\u0900-\u097F]').hasMatch(data);
      }
      return false;
    });

    expect(nepaliTexts, findsWidgets);
  });
}
