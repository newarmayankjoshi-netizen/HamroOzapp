import 'package:hamro_oz/services/guide_answer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Classifies student work-hours as work_rights and retrieves only that section', () {
    const guideTitle = 'Student Essentials';
    const guideContent = '''
SECTION (EN): Work Rights / Visa Limits
Student visa holders can work up to 48 hours per fortnight during study periods.
You can work unlimited hours during official course breaks.

SECTION (EN): Student Jobs / Job Search
Common student jobs include retail, hospitality, cleaning, warehouse.
Try SEEK and Indeed.
''';

    final answer = GuideAnswerService.answerFromGuide(
      guideTitle: guideTitle,
      guideContent: guideContent,
      userMessage: 'What is the minimum hours a student can work?',
    );

    expect(answer, contains('48 hours per fortnight'));
    expect(answer, contains('Work Rights / Visa Limits'));
    // Should not drift into job-search advice when category filtering is working.
    expect(answer.toLowerCase(), isNot(contains('retail')));
    expect(answer.toLowerCase(), isNot(contains('seek')));
  });

  test('Falls back to safe general info for student work-hours when guide has no matching category', () {
    const guideTitle = 'Random Guide';
    const guideContent = '''
SECTION (EN): Housing
Rent and bond basics.
''';

    final answer = GuideAnswerService.answerFromGuide(
      guideTitle: guideTitle,
      guideContent: guideContent,
      userMessage: 'How many hours can I work on a student visa?',
    );

    expect(answer.toLowerCase(), contains('48'));
    expect(answer.toLowerCase(), contains('fortnight'));
    expect(answer.toLowerCase(), contains('home affairs'));
  });

  test('Sensitive note recommends consulting professionals', () {
    const guideTitle = 'Visa Guide';
    const guideContent = '''
SECTION (EN): Work Rights
Student visa condition 8105 applies.
''';

    final answer = GuideAnswerService.answerFromGuide(
      guideTitle: guideTitle,
      guideContent: guideContent,
      userMessage: 'What is condition 8105 on student visa?',
    );

    // Sensitive-topic note should include the new professional-consult line.
    expect(answer.toLowerCase(), contains('registered migration agent'));
  });

  test('Health answers suggest consulting a health professional when not sensitive', () {
    const guideTitle = 'Health Guide';
    const guideContent = '''
SECTION (EN): Healthcare / GP
If you feel unwell, you can book a GP appointment.
''';

    final answer = GuideAnswerService.answerFromGuide(
      guideTitle: guideTitle,
      guideContent: guideContent,
      userMessage: 'I have a fever. What should I do?',
    );

    expect(answer.toLowerCase(), contains('gp/health professional'));
  });
}
