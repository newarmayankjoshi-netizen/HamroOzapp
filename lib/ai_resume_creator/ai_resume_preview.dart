import 'package:flutter/material.dart';

import 'ai_resume_template_engine.dart';

class AiResumeFormattedPreview extends StatelessWidget {
  final String resumeText;

  const AiResumeFormattedPreview({
    super.key,
    required this.resumeText,
  });

  TextStyle _sectionTitleStyle(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: const Color(0xFF111827),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = AiResumeTemplateEngine.parsePlainText(resumeText);

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in doc.sections) ...[
            Text(section.title, style: _sectionTitleStyle(context)),
            const SizedBox(height: 6),
            for (final line in section.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: line.kind == ResumeTemplateLineKind.bullet
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(line.text)),
                        ],
                      )
                    : Text(line.text),
              ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
