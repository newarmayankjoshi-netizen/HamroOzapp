class AiResumeSkillSuggester {
  /// Suggests ATS-friendly skills inferred from the prompt.
  ///
  /// Behavior goals:
  /// - Prioritize skills that match detected roles (barista/retail/etc.)
  /// - Keep ordering stable and "most relevant" first
  /// - Cap suggestions so the resume stays focused
  static List<String> suggestSkills(
    String prompt, {
    int maxSuggestions = 12,
  }) {
    final text = prompt.toLowerCase();
    if (text.trim().isEmpty) return const [];

    final scoresByKey = <String, int>{};
    final displayByKey = <String, String>{};
    final firstSeenIndex = <String, int>{};
    var nextIndex = 0;

    void addSkill(String skill, int score) {
      final trimmed = skill.trim();
      if (trimmed.isEmpty) return;
      final key = trimmed.toLowerCase();
      displayByKey.putIfAbsent(key, () => trimmed);
      firstSeenIndex.putIfAbsent(key, () => nextIndex++);
      final prev = scoresByKey[key];
      if (prev == null || score > prev) {
        scoresByKey[key] = score;
      }
    }

    final profiles = <_RoleProfile>[
      _RoleProfile(
        name: 'hospitality_barista',
        weight: 80,
        keywords: ['barista', 'cafe', 'coffee', 'hospitality', 'espresso'],
        skills: [
          'Customer service',
          'POS operation',
          'Cash handling',
          'Coffee preparation (espresso)',
          'Order taking',
          'Upselling',
          'Food safety & hygiene',
          'Speed and accuracy under pressure',
        ],
      ),
      _RoleProfile(
        name: 'retail',
        weight: 75,
        keywords: ['retail', 'store', 'sales assistant', 'cashier', 'shop'],
        skills: [
          'Customer service',
          'Point-of-sale (POS)',
          'Cash handling',
          'Merchandising',
          'Stock replenishment',
          'Sales & upselling',
          'Complaint handling',
        ],
      ),
      _RoleProfile(
        name: 'admin_reception',
        weight: 75,
        keywords: [
          'admin',
          'administrator',
          'reception',
          'receptionist',
          'front desk',
          'office',
          'data entry',
          'clerical',
        ],
        skills: [
          'Reception and front-desk support',
          'Phone etiquette',
          'Customer service',
          'Scheduling and coordination',
          'Calendar management',
          'Data entry',
          'Email correspondence',
          'Microsoft Office (Word/Excel/Outlook)',
          'Filing and document management',
        ],
      ),
      _RoleProfile(
        name: 'security',
        weight: 75,
        keywords: ['security', 'guard', 'patrol', 'cctv', 'crowd control'],
        skills: [
          'Access control',
          'Incident reporting',
          'Conflict de-escalation',
          'Situational awareness',
          'CCTV monitoring',
          'Patrol procedures',
          'Customer service',
        ],
      ),
      _RoleProfile(
        name: 'driving_delivery',
        weight: 70,
        keywords: [
          'driver',
          'delivery',
          'courier',
          'uber',
          'rideshare',
          'ride share',
          'truck',
          'van',
          'car',
        ],
        skills: [
          'Safe driving practices',
          'Route planning',
          'GPS navigation',
          'Time management',
          'Customer service',
          'Vehicle safety checks',
          'Proof of delivery processes',
        ],
      ),
      _RoleProfile(
        name: 'aged_care_support',
        weight: 80,
        keywords: ['aged care', 'disability', 'support worker', 'carer', 'caregiver'],
        skills: [
          'Person-centred care',
          'Empathy and active listening',
          'Infection control',
          'Documentation and reporting',
          'Manual handling (safety)',
          'Professional boundaries',
        ],
      ),
      _RoleProfile(
        name: 'cleaning',
        weight: 65,
        keywords: ['cleaner', 'cleaning', 'housekeeping', 'janitor'],
        skills: [
          'Cleaning and sanitising',
          'Chemical handling (safe use)',
          'Attention to detail',
          'Time management',
          'Workplace health & safety (WHS)',
        ],
      ),
      _RoleProfile(
        name: 'warehouse_logistics',
        weight: 70,
        keywords: ['warehouse', 'picker', 'pick pack', 'packing', 'forklift', 'rf', 'scanner'],
        skills: [
          'Pick packing',
          'RF scanning',
          'Inventory management',
          'Loading and unloading',
          'Workplace health & safety (WHS)',
        ],
      ),
      _RoleProfile(
        name: 'it_support',
        weight: 80,
        keywords: ['it support', 'helpdesk', 'help desk', 'desktop support', 'service desk'],
        skills: [
          'Customer support',
          'Troubleshooting',
          'Ticketing systems',
          'Windows & macOS basics',
          'Microsoft 365',
          'Networking fundamentals',
        ],
      ),
      _RoleProfile(
        name: 'construction',
        weight: 70,
        keywords: ['construction', 'labourer', 'laborer', 'site', 'trade assistant'],
        skills: [
          'Workplace health & safety (WHS)',
          'Tool handling (basic)',
          'Teamwork on-site',
          'Following instructions',
          'Physical stamina',
        ],
      ),
      _RoleProfile(
        name: 'kitchen_food',
        weight: 70,
        keywords: ['kitchen', 'chef', 'cook', 'restaurant', 'food prep'],
        skills: [
          'Food preparation',
          'Kitchen hygiene',
          'Time management',
          'Teamwork',
          'Food safety & hygiene',
        ],
      ),
    ];

    final impliesWork = _impliesWork(text);
    if (impliesWork) {
      for (final s in const [
        'Communication',
        'Teamwork',
        'Time management',
        'Problem solving',
        'Reliability',
        'Attention to detail',
      ]) {
        addSkill(s, 30);
      }
    }

    final matched = profiles.where((p) => p.matches(text)).toList();
    for (final profile in matched) {
      for (final s in profile.skills) {
        addSkill(s, profile.weight);
      }
    }

    final scored = scoresByKey.entries
        .map(
          (e) => _ScoredSkill(
            key: e.key,
            display: displayByKey[e.key] ?? e.key,
            score: e.value,
            firstIndex: firstSeenIndex[e.key] ?? 0,
          ),
        )
        .toList();

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.firstIndex.compareTo(b.firstIndex);
    });

    final out = <String>[];
    for (final s in scored) {
      out.add(s.display);
      if (out.length >= maxSuggestions) break;
    }
    return out;
  }

  static bool _impliesWork(String text) {
    return RegExp(r'\b(experience|worked|years?|months?|role|position|job)\b').hasMatch(text);
  }
}

class _RoleProfile {
  final String name;
  final int weight;
  final List<String> keywords;
  final List<String> skills;

  const _RoleProfile({
    required this.name,
    required this.weight,
    required this.keywords,
    required this.skills,
  });

  bool matches(String lowerText) {
    for (final k in keywords) {
      if (lowerText.contains(k)) return true;
    }
    return false;
  }
}

class _ScoredSkill {
  final String key;
  final String display;
  final int score;
  final int firstIndex;

  const _ScoredSkill({
    required this.key,
    required this.display,
    required this.score,
    required this.firstIndex,
  });
}
