import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hamro_oz/guides/guides_page.dart';

void main() {
  testWidgets('Guides language toggle switches full content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GuidesPage()));
    await tester.pumpAndSettle();

    // Open first guide.
    final guidesList = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    ).first;
    final firstGuide = find.text('Landing in Australia for the First Time');
    await tester.scrollUntilVisible(firstGuide, 300, scrollable: guidesList);
    await tester.tap(firstGuide);
    await tester.pumpAndSettle();

    // Toggle to Nepali.
    await tester.tap(find.text('नेपाली'));
    await tester.pumpAndSettle();

    // Confirm Nepali title is shown.
    expect(find.text('अष्ट्रेलियामा पहिलो पटक अवतरण गर्नु'), findsOneWidget);

    // Open first section.
    await tester.tap(find.textContaining('इमिग्रेशन चेक'));
    await tester.pumpAndSettle();

    // Nepali should show translated body content (and not show fallback banner).
    expect(find.text('EN'), findsOneWidget);
    expect(find.textContaining('झुटो घोषणा'), findsOneWidget);
    expect(
      find.textContaining('नेपाली अनुवाद छिट्टै उपलब्ध हुनेछ'),
      findsNothing,
    );

    // Toggle back to English and confirm English body is shown.
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('नेपाली'), findsOneWidget);
    expect(find.textContaining('Documents Required'), findsOneWidget);
  });

  testWidgets('Moving/suburb guide shows new Nepali sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GuidesPage()));
    await tester.pumpAndSettle();

    // Open the Moving to a Better Suburb / Better Room guide.
    final guidesList = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    ).first;
    final movingGuide = find.text('Moving to a Better Suburb / Better Room');
    await tester.scrollUntilVisible(
      movingGuide,
      300,
      scrollable: guidesList,
    );
    final movingGuideTapTarget = find.ancestor(
      of: movingGuide,
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(movingGuideTapTarget);
    await tester.pumpAndSettle();
    await tester.tap(movingGuideTapTarget);
    await tester.pumpAndSettle();

    // Toggle to Nepali.
    await tester.tap(find.text('नेपाली'));
    await tester.pumpAndSettle();

    // Confirm the new section card titles appear in Nepali.
    final scrollable = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    ).first;

    final suburbGuides = find.textContaining('उपनगर गाइड');
    await tester.scrollUntilVisible(suburbGuides, 250, scrollable: scrollable);
    expect(suburbGuides, findsOneWidget);

    final bondLease = find.textContaining('बन्ड र लिज');
    await tester.scrollUntilVisible(bondLease, 250, scrollable: scrollable);
    expect(bondLease, findsOneWidget);

    final inspectionChecklist = find.textContaining('निरीक्षण चेकलिस्ट');
    await tester.scrollUntilVisible(
      inspectionChecklist,
      250,
      scrollable: scrollable,
    );
    expect(inspectionChecklist, findsOneWidget);

    final emergencyHousing = find.textContaining('आपतकालीन आवास');
    await tester.scrollUntilVisible(
      emergencyHousing,
      250,
      scrollable: scrollable,
    );
    expect(emergencyHousing, findsOneWidget);

    // Open one of the new sections and ensure Nepali body is present
    // (and no fallback banner is shown).
    await tester.tap(find.textContaining('बन्ड र लिज'));
    await tester.pumpAndSettle();

    expect(find.text('EN'), findsOneWidget);
    expect(
      find.textContaining('नेपाली अनुवाद छिट्टै उपलब्ध हुनेछ'),
      findsNothing,
    );
    expect(find.textContaining('Bond (बन्ड)'), findsOneWidget);
  });
}
