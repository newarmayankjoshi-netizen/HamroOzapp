class AiResumeDutySuggester {
  /// Returns realistic duty bullets for a detected role.
  ///
  /// Design goals:
  /// - Generic and safe (no invented dates, metrics, or claims)
  /// - ATS-friendly wording
  /// - Short, skimmable bullets
  static List<String> suggestDutiesForRole(String roleText) {
    final role = roleText.trim();
    final lower = role.toLowerCase();

    final duties = <String>[];

    void addAll(List<String> items) {
      for (final d in items) {
        final t = d.trim();
        if (t.isNotEmpty) duties.add(t);
      }
    }

    if (_matchesAny(lower, ['retail', 'sales assistant', 'shop assistant', 'store assistant', 'cashier'])) {
      addAll([
        'Assisted customers with product enquiries and recommendations',
        'Operated POS (Point of Sale) and processed cash/card transactions',
        'Handled refunds/exchanges in line with store policies',
        'Replenished stock, faced shelves, and maintained store presentation',
        'Supported stocktake, pricing checks, and ticketing/label updates',
        'Maintained a clean and safe shop floor and back-of-house area',
      ]);
    }

    if (_matchesAny(lower, ['barista', 'cafe', 'hospitality'])) {
      addAll([
        'Prepared espresso-based coffee and beverages to consistent quality',
        'Provided friendly customer service and managed order flow',
        'Operated POS, processed payments, and balanced accuracy with speed',
        'Maintained food safety, hygiene, and cleaning routines',
        'Restocked items and supported opening/closing duties',
      ]);
    }

    if (_matchesAny(lower, ['reception', 'receptionist', 'front desk'])) {
      addAll([
        'Managed front-desk reception, greeting visitors and handling enquiries',
        'Answered phones, directed calls, and took accurate messages',
        'Scheduled appointments and maintained calendars',
        'Managed email correspondence and basic document processing',
        'Maintained tidy reception area and supported general office tasks',
      ]);
    }

    if (_matchesAny(lower, ['admin', 'administrator', 'administration', 'office assistant'])) {
      addAll([
        'Provided administrative support including data entry and document handling',
        'Maintained filing systems and assisted with record management',
        'Coordinated basic scheduling and internal communications',
        'Prepared and formatted documents (Word/Excel/Outlook)',
      ]);
    }

    if (_matchesAny(lower, ['security', 'guard'])) {
      addAll([
        'Performed patrols and monitored premises for safety and security risks',
        'Managed access control and responded to incidents professionally',
        'Completed incident reports and maintained accurate records',
        'Used de-escalation skills to handle difficult situations safely',
      ]);
    }

    if (_matchesAny(lower, ['driver', 'delivery', 'courier'])) {
      addAll([
        'Completed deliveries safely and on time using GPS navigation',
        'Performed basic vehicle safety checks and followed road rules',
        'Communicated with customers to confirm delivery details',
        'Handled proof of delivery and maintained accurate records',
      ]);
    }

    if (_matchesAny(lower, ['warehouse', 'picker', 'pick pack', 'packing', 'storeperson'])) {
      addAll([
        'Picked and packed orders accurately against pick slips or RF scanner',
        'Loaded/unloaded goods and maintained safe manual handling practices',
        'Supported inventory counts and basic stock control tasks',
        'Kept work areas clean and complied with WHS requirements',
      ]);
    }

    if (_matchesAny(lower, ['cleaner', 'cleaning', 'housekeeping'])) {
      addAll([
        'Completed cleaning tasks including vacuuming, mopping, and sanitising surfaces',
        'Followed safe chemical handling and infection control procedures',
        'Worked efficiently to meet timeframes while maintaining quality',
      ]);
    }

    if (_matchesAny(lower, ['support worker', 'aged care', 'disability', 'carer'])) {
      addAll([
        'Provided person-centred support with respect and professionalism',
        'Assisted with daily living tasks while maintaining dignity and safety',
        'Completed basic documentation and communicated with the care team',
        'Followed infection control and manual handling procedures',
      ]);
    }

    if (duties.isEmpty) {
      // Generic fallback if we can’t classify the role.
      addAll([
        'Supported day-to-day operations and completed tasks reliably',
        'Communicated effectively with customers and team members',
        'Followed workplace policies and safety procedures',
      ]);
    }

    return _dedupePreserveOrder(duties).take(6).toList();
  }

  static bool _matchesAny(String lower, List<String> needles) {
    for (final n in needles) {
      if (lower.contains(n)) return true;
    }
    return false;
  }

  static List<String> _dedupePreserveOrder(List<String> items) {
    final out = <String>[];
    final seen = <String>{};
    for (final s in items) {
      final t = s.trim();
      if (t.isEmpty) continue;
      final k = t.toLowerCase();
      if (seen.add(k)) out.add(t);
    }
    return out;
  }
}
