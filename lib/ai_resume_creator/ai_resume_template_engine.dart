class ResumeTemplateDocument {
  final List<ResumeTemplateSection> sections;

  const ResumeTemplateDocument({
    required this.sections,
  });
}

class ResumeTemplateSection {
  final String title;
  final List<ResumeTemplateLine> lines;

  const ResumeTemplateSection({
    required this.title,
    required this.lines,
  });
}

enum ResumeTemplateLineKind {
  text,
  bullet,
}

class ResumeTemplateLine {
  final ResumeTemplateLineKind kind;
  final String text;

  const ResumeTemplateLine({
    required this.kind,
    required this.text,
  });
}

class AiResumeTemplateEngine {
  static ResumeTemplateDocument parsePlainText(String raw) {
    final normalized = raw.replaceAll('\r', '\n');
    final lines = normalized.split('\n');

    final sections = <ResumeTemplateSection>[];
    String? currentTitle;
    final currentLines = <ResumeTemplateLine>[];

    void flush() {
      final title = (currentTitle ?? '').trim();
      if (title.isEmpty && currentLines.isEmpty) return;
      sections.add(
        ResumeTemplateSection(
          title: title.isEmpty ? 'RESUME' : title,
          lines: List.unmodifiable(currentLines),
        ),
      );
      currentTitle = null;
      currentLines.clear();
    }

    for (final rawLine in lines) {
      final trimmed = rawLine.trimRight();
      final line = trimmed.trim();

      if (line.isEmpty) {
        // Skip extra blank lines, but keep section separation natural.
        continue;
      }

      if (_isHeading(line)) {
        if (currentTitle != null || currentLines.isNotEmpty) {
          flush();
        }
        currentTitle = line;
        continue;
      }

      final bullet = _parseBullet(line);
      if (bullet != null) {
        currentLines.add(
          ResumeTemplateLine(kind: ResumeTemplateLineKind.bullet, text: bullet),
        );
      } else {
        currentLines.add(
          ResumeTemplateLine(kind: ResumeTemplateLineKind.text, text: line),
        );
      }
    }

    flush();

    return ResumeTemplateDocument(sections: List.unmodifiable(sections));
  }

  static String? _parseBullet(String line) {
    final t = line.trim();
    if (t.startsWith('•')) return t.substring(1).trim();
    if (t.startsWith('- ')) return t.substring(2).trim();
    if (t.startsWith('* ')) return t.substring(2).trim();
    return null;
  }

  static bool _isHeading(String line) {
    final t = line.trim();
    if (t.length < 3 || t.length > 60) return false;
    if (t.endsWith('.') || t.endsWith(':')) return false;

    // Heuristic: headings are usually ALL CAPS in our generator.
    // Accept digits and common punctuation used in headings.
    final looksLikeCaps = RegExp(r'^[A-Z0-9][A-Z0-9 &()/_\-]{2,}$').hasMatch(t);
    if (!looksLikeCaps) return false;

    // Must contain at least one letter.
    return RegExp(r'[A-Z]').hasMatch(t);
  }
}
