class AiResumeAtsOptimizer {
  /// Extracts keyword phrases from user-provided text.
  ///
  /// Safety rules:
  /// - Only extracts from the prompt (no invented keywords)
  /// - Filters out very short/common words
  /// - Returns phrases suitable for ATS-friendly resume sections
  static List<String> extractKeywords(
    String prompt, {
    int maxKeywords = 18,
  }) {
    final normalized = prompt.replaceAll('\r', '\n');
    final candidates = <String>[];

    // 1) Prefer explicit Skills: lines
    final skillsLine = _extractSkillsLine(normalized);
    if (skillsLine != null) {
      candidates.addAll(
        skillsLine
            .split(RegExp(r'[,;\u2022\-]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      );
    }

    // 2) Include short bullet items (often skills/tools)
    candidates.addAll(
      _extractBullets(normalized)
          .where((b) => b.length <= 50)
          .map((b) => b.trim())
          .where((b) => b.isNotEmpty),
    );

    // 3) Include common ATS acronyms/terms that appear as tokens (e.g., POS, WHS)
    for (final m in RegExp(r'\b[A-Z]{2,6}\b').allMatches(prompt)) {
      final token = m.group(0);
      if (token != null) candidates.add(token);
    }

    // 4) Include multi-word phrases that look like skills (basic heuristic)
    candidates.addAll(
      _extractLikelySkillPhrases(normalized),
    );

    final cleaned = <String>[];
    final seen = <String>{};

    for (final c in candidates) {
      final t = _cleanKeyword(c);
      if (t == null) continue;
      final key = t.toLowerCase();
      if (seen.add(key)) cleaned.add(t);
      if (cleaned.length >= maxKeywords) break;
    }

    return cleaned;
  }

  /// Reorders and augments skills to prioritize prompt keywords, while staying capped.
  static List<String> optimizeKeySkills({
    required List<String> explicitSkills,
    required List<String> suggestedSkills,
    required List<String> keywords,
    int maxSkills = 15,
  }) {
    final out = <String>[];
    final seen = <String>{};

    void add(String s) {
      if (out.length >= maxSkills) return;
      final t = s.trim();
      if (t.isEmpty) return;
      final key = t.toLowerCase();
      if (seen.add(key)) out.add(t);
    }

    // 1) Always keep user skills first
    for (final s in explicitSkills) {
      add(s);
    }

    // 2) Then add extracted keywords (only if they look like a skill)
    for (final k in keywords) {
      if (_looksLikeSkill(k)) add(k);
    }

    // 3) Finally fill from suggestions
    for (final s in suggestedSkills) {
      add(s);
    }

    return out;
  }

  static bool _looksLikeSkill(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    if (t.length > 42) return false;
    // Avoid full sentences.
    if (t.contains('.') || t.contains('\n')) return false;
    // Avoid labels.
    if (t.endsWith(':')) return false;
    return true;
  }

  static String? _cleanKeyword(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return null;

    // Strip trailing punctuation.
    t = t.replaceAll(RegExp(r'[\s\-–—:;,.]+$'), '');

    // Reject ultra-short tokens.
    if (t.length < 2) return null;

    // Remove common stopwords-only values.
    final lower = t.toLowerCase();
    const stop = {
      'and',
      'or',
      'the',
      'a',
      'an',
      'to',
      'of',
      'in',
      'for',
      'with',
      'on',
      'at',
      'as',
      'from',
      'by',
      'i',
      'my',
      'me',
      'we',
      'our',
      'you',
      'your',
      'role',
      'job',
      'position',
      'experience',
      'skills',
    };
    if (stop.contains(lower)) return null;

    // Collapse whitespace.
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Title-case a bit for display, but preserve acronyms.
    if (RegExp(r'^[A-Z]{2,6}$').hasMatch(t)) return t;

    return _capitalizePhrase(t);
  }

  static String _capitalizePhrase(String t) {
    // Keep common abbreviations as-is.
    final parts = t.split(' ');
    final out = <String>[];
    for (final p in parts) {
      if (p.isEmpty) continue;
      if (RegExp(r'^[A-Z]{2,6}$').hasMatch(p)) {
        out.add(p);
        continue;
      }
      out.add(p.substring(0, 1).toUpperCase() + p.substring(1));
    }
    return out.join(' ');
  }

  static String? _extractSkillsLine(String raw) {
    final lines = raw.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('skills:')) {
        return trimmed.substring('skills:'.length).trim();
      }
    }
    return null;
  }

  static List<String> _extractBullets(String raw) {
    final lines = raw.replaceAll('\r', '\n').split('\n');
    final bullets = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('•')) {
        bullets.add(trimmed.substring(1).trim());
      } else if (trimmed.startsWith('- ')) {
        bullets.add(trimmed.substring(2).trim());
      } else if (trimmed.startsWith('* ')) {
        bullets.add(trimmed.substring(2).trim());
      }
    }
    return bullets;
  }

  static List<String> _extractLikelySkillPhrases(String raw) {
    final lower = raw.toLowerCase();
    final common = <String>[
      'customer service',
      'cash handling',
      'pos',
      'point of sale',
      'food safety',
      'infection control',
      'manual handling',
      'data entry',
      'microsoft office',
      'microsoft 365',
      'inventory management',
      'rf scanning',
      'route planning',
      'cctv',
      'incident reporting',
      'conflict de-escalation',
      'ticketing systems',
      'troubleshooting',
      'time management',
      'attention to detail',
      'workplace health & safety',
      'whs',
    ];

    final out = <String>[];
    for (final phrase in common) {
      if (lower.contains(phrase)) out.add(phrase);
    }
    return out;
  }
}
