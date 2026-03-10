class GuideAnswerService {
  static String answerFromGuide({
    required String guideTitle,
    required String guideContent,
    required String userMessage,
  }) {
    final msg = userMessage.trim();
    if (msg.isEmpty) return '';

    // Guardrails: keep answers grounded in the guide, Australia-focused, and
    // add safety notes for sensitive topics.
    final wantsNepali = _isLanguageOnlyRequest(msg) ? true : _wantsNepali(msg);
    final guardrail = _evaluateGuardrails(msg, wantsNepali: wantsNepali);
    if (guardrail.blockReply != null) {
      return guardrail.blockReply!.trim();
    }

    // Special-case: users often type “Explain this in Nepali”, which is a
    // language preference request more than a specific search query.
    final isLanguageOnlyRequest = _isLanguageOnlyRequest(msg);

    // Step 1: classify the question category BEFORE retrieval.
    // We then retrieve from only that category to reduce cross-topic answers.
    final category = isLanguageOnlyRequest
        ? _Category.general
        : _classifyCategory(msg);

    final intent = isLanguageOnlyRequest ? _Intent.general : _inferIntent(msg);

    final doc = _parseGuideContent(
      guideTitle: guideTitle,
      guideContent: guideContent,
    );
    final candidates = doc.sections.isEmpty
        ? [
            _ParsedSection(
              enTitle: guideTitle,
              neTitle: guideTitle,
              enBody: guideContent,
              neBody: guideContent,
              links: const [],
            ),
          ]
        : doc.sections;

    // Step 2: retrieve only from the classified category.
    // If the guide has no matching category sections, treat as retrieval failure.
    final categoryCandidates = isLanguageOnlyRequest
        ? candidates
        : _filterSectionsByCategory(candidates, category);

    final tokens = isLanguageOnlyRequest
        ? const <String>[]
        : _keywords(msg, wantsNepali: wantsNepali);
    final ranked =
        categoryCandidates
            .map(
              (s) => _ScoredSection(
                section: s,
                score: _scoreSection(s, tokens, wantsNepali: wantsNepali),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));

    // Confidence check: if we can’t find a grounded match in the guide,
    // fall back to safe general Australian guidance (where possible), otherwise
    // say so (don’t guess) and ask one clarifying question.
    if (!isLanguageOnlyRequest && tokens.isNotEmpty) {
      final confidence = _confidenceFromRanking(
        ranked,
        msg: msg,
        wantsNepali: wantsNepali,
      );
      if (!confidence.isConfident) {
        final fallback = _generalKnowledgeFallback(
          msg: msg,
          wantsNepali: wantsNepali,
          category: category,
          includeSensitiveNote: guardrail.isSensitiveTopic,
        );
        if (fallback != null) return fallback.trim();

        return _notFoundReply(
          msg: msg,
          wantsNepali: wantsNepali,
          includeSensitiveNote: guardrail.isSensitiveTopic,
        ).trim();
      }
    }

    final top = ranked
        .take(2)
        .where((s) => s.score > 0)
        .map((s) => s.section)
        .toList(growable: false);

    // If user is asking for websites/links, prefer sections that actually include links.
    final topWithLinks = ranked
        .where((s) => s.section.links.isNotEmpty)
        .take(3)
        .map((s) => s.section)
        .toList(growable: false);

    // If nothing matches by keywords (or the user only asked for Nepali),
    // use the first few sections so we can still produce a helpful summary.
    final fallback = ranked.isNotEmpty
        ? ranked.take(3).map((s) => s.section).toList(growable: false)
        : const <_ParsedSection>[];

    final picked = intent == _Intent.links && topWithLinks.isNotEmpty
        ? topWithLinks
        : (top.isNotEmpty ? top : fallback);

    var answer = wantsNepali
        ? _answerNepali(intent: intent, sections: picked, msg: msg)
        : _answerEnglish(intent: intent, sections: picked, msg: msg);

    // Append a short safety note for sensitive topics.
    if (guardrail.isSensitiveTopic) {
      answer = _appendSensitiveNote(answer, wantsNepali: wantsNepali);
    }

    // For some high-stakes categories, also suggest consulting the right
    // professional/authority (without overdoing it).
    answer = _appendProfessionalConsultNote(
      answer,
      msg: msg,
      wantsNepali: wantsNepali,
      category: category,
      alreadyHasSensitiveNote: guardrail.isSensitiveTopic,
    );

    return answer.trim();
  }

  static _GuardrailEvaluation _evaluateGuardrails(
    String msg, {
    required bool wantsNepali,
  }) {
    final isSensitive = _isSensitiveTopic(msg);

    // If the question is explicitly about another country, ask for confirmation.
    // (The guides are Australia-focused.)
    final otherCountry = _explicitOtherCountryContext(msg);
    if (otherCountry != null) {
      final reply = wantsNepali
          ? 'यो गाइड अस्ट्रेलिया-केन्द्रित हो। तपाईंलाई "$otherCountry" का लागि जानकारी चाहिएको हो कि अस्ट्रेलियाकै लागि?\n\nकुन राज्य/सहर (जस्तै NSW/VIC/QLD) मा हुनुहुन्छ भनेर पनि भन्नुभयो भने म गाइडको सही भाग देखाउँछु।'
          : 'This guide is Australia-focused. Do you want the answer for "$otherCountry" or for Australia?\n\nIf you tell me your state/territory (e.g., NSW/VIC/QLD), I can point to the closest matching guide section.';
      return _GuardrailEvaluation(
        isSensitiveTopic: isSensitive,
        blockReply: reply,
      );
    }

    return _GuardrailEvaluation(isSensitiveTopic: isSensitive);
  }

  static _Confidence _confidenceFromRanking(
    List<_ScoredSection> ranked, {
    required String msg,
    required bool wantsNepali,
  }) {
    if (ranked.isEmpty) return const _Confidence(false);
    final top = ranked.first;
    if (top.score < 3) return const _Confidence(false);

    // Require at least one relevant snippet line from the top section.
    final snippet = _extractRelevantSnippets(
      [top.section],
      msg,
      wantsNepali: wantsNepali,
    );
    if (snippet.isEmpty) return const _Confidence(false);

    return const _Confidence(true);
  }

  static String _notFoundReply({
    required String msg,
    required bool wantsNepali,
    required bool includeSensitiveNote,
  }) {
    final clarifying = _clarifyingQuestion(msg, wantsNepali: wantsNepali);

    final base = wantsNepali
        ? 'म यो प्रश्नको ठ्याक्कै उत्तर यो गाइडमा भेट्टाउन सकिनँ (अन्दाज नगरी भन्छु)।\n\n$clarifying\n\nTip: गाइडको वाक्य/लाइन copy गरेर पठाउनुभयो भने म त्यहीलाई आधार बनाएर बुझाइदिन्छु।'
        : 'I couldn’t find an exact answer to that in this guide (so I won’t guess).\n\n$clarifying\n\nTip: paste the exact sentence/line from the guide and I’ll explain it.';

    return includeSensitiveNote
        ? _appendSensitiveNote(base, wantsNepali: wantsNepali)
        : base;
  }

  static String _clarifyingQuestion(String msg, {required bool wantsNepali}) {
    final lower = msg.toLowerCase();
    final isDriving =
        lower.contains('licen') ||
        lower.contains('driving') ||
        msg.contains('लाइस') ||
        msg.contains('ड्राइभ');
    final isTax =
        lower.contains('tfn') ||
        lower.contains('abn') ||
        lower.contains('ato') ||
        lower.contains('tax') ||
        msg.contains('कर') ||
        msg.contains('ट्याक्स');
    final isVisa =
        lower.contains('visa') ||
        lower.contains('immi') ||
        lower.contains('immigration') ||
        msg.contains('भिसा') ||
        msg.contains('इमिग्रेशन');
    final isMedicare = lower.contains('medicare') || msg.contains('मेडिकेयर');
    final isCentrelink =
        lower.contains('centrelink') || msg.contains('सेन्टरलिङ्क');

    if (wantsNepali) {
      if (isDriving) {
        return 'एक कुरा बताइदिनुहोस्: तपाईं कुन राज्य/टेरेटोरी (NSW/VIC/QLD/WA/SA/TAS/ACT/NT) मा हुनुहुन्छ?';
      }
      if (isTax) {
        return 'एक कुरा स्पष्ट गरिदिनुहोस्: तपाईं TFN, ABN, कि कर (tax) को कुन भागबारे सोध्दै हुनुहुन्छ?';
      }
      if (isVisa) {
        return 'एक कुरा स्पष्ट गरिदिनुहोस्: तपाईंको भिसाको प्रकार/स्थिति के हो (जस्तै student, visitor, bridging)?';
      }
      if (isMedicare) {
        return 'एक कुरा स्पष्ट गरिदिनुहोस्: तपाईं Medicare eligibility, card आवेदन, कि account (myGov) बारे सोध्दै हुनुहुन्छ?';
      }
      if (isCentrelink) {
        return 'एक कुरा स्पष्ट गरिदिनुहोस्: Centrelink को कुन payment/service (jobseeker, family, rent assistance) बारे सोध्दै हुनुहुन्छ?';
      }
      return 'कृपया कुन भागबारे सोध्दै हुनुहुन्छ भनेर 1–2 शब्द (उदाहरण: “TFN apply”, “rent bond”, “driver licence”) थपिदिनुहोस्।';
    }

    if (isDriving) {
      return 'One quick question: which state/territory are you in (NSW/VIC/QLD/WA/SA/TAS/ACT/NT)?';
    }
    if (isTax) {
      return 'One quick question: are you asking about TFN, ABN, or a specific tax step?';
    }
    if (isVisa) {
      return 'One quick question: what is your visa type/status (e.g., student, visitor, bridging)?';
    }
    if (isMedicare) {
      return 'One quick question: do you mean Medicare eligibility, applying for a card, or myGov linking?';
    }
    if (isCentrelink) {
      return 'One quick question: which Centrelink payment/service are you asking about (e.g., JobSeeker, Family Tax Benefit)?';
    }
    return 'Can you share 1–2 keywords (e.g., “TFN apply”, “rent bond”, “driver licence”) so I can match the right guide section?';
  }

  static String _appendSensitiveNote(
    String answer, {
    required bool wantsNepali,
  }) {
    final note = wantsNepali
        ? '\n\nसावधानी: यो सामान्य जानकारी मात्र हो (कानुनी/कर/भिसा जस्ता विषयमा नियम बदलिन सक्छ)। आधिकारिक स्रोत पनि जाँच्नुहोस्: Services Australia (servicesaustralia.gov.au), ATO (ato.gov.au), Home Affairs (immi.homeaffairs.gov.au), Fair Work (fairwork.gov.au)। आवश्यक परे सम्बन्धित पेशेवरसँग पनि सल्लाह लिनुहोस् (जस्तै Registered Migration Agent, Tax Agent/Accountant, वा Solicitor)।'
        : '\n\nNote: This is general information only (rules can change for visa/tax/legal topics). Also check official sources: Services Australia (servicesaustralia.gov.au), ATO (ato.gov.au), Home Affairs (immi.homeaffairs.gov.au), Fair Work (fairwork.gov.au). If needed, consult a relevant professional (e.g., a Registered Migration Agent, a Tax Agent/Accountant, or a Solicitor).';
    return '${answer.trim()}$note';
  }

  static String _appendProfessionalConsultNote(
    String answer, {
    required String msg,
    required bool wantsNepali,
    required _Category category,
    required bool alreadyHasSensitiveNote,
  }) {
    // If we already appended the sensitive note, it already includes a
    // professional-consult suggestion.
    if (alreadyHasSensitiveNote) return answer;

    final lowerAnswer = answer.toLowerCase();
    if (lowerAnswer.contains('registered migration agent') ||
        lowerAnswer.contains('tax agent') ||
        lowerAnswer.contains('solicitor') ||
        lowerAnswer.contains('health professional') ||
        lowerAnswer.contains('gp')) {
      return answer;
    }

    final lowerMsg = msg.toLowerCase();

    // Health: encourage seeing a clinician for personal medical advice.
    if (category == _Category.health) {
      final note = wantsNepali
          ? '\n\nनोट: स्वास्थ्य सम्बन्धी कुरा व्यक्तिअनुसार फरक हुन्छ। लक्षण/आपतकालीन अवस्था छ भने GP/health professional सँग सल्लाह लिनुहोस् (आपतकालीन अवस्थामा 000)।'
          : '\n\nNote: Health advice depends on your situation. If you have symptoms or this feels urgent, talk to a GP/health professional (call 000 for emergencies).';
      return '${answer.trim()}$note';
    }

    // Driving/licensing: rules are state-based; point to the right authority.
    if (category == _Category.driving) {
      final note = wantsNepali
          ? '\n\nनोट: ड्राइभिङ/लाइसन्स नियम राज्य/टेरेटोरी अनुसार फरक हुन्छ। आफ्नो राज्यको रोड अथोरिटी/Service (जस्तै Service NSW, VicRoads, TMR QLD) को आधिकारिक जानकारी पनि जाँच्नुहोस्।'
          : '\n\nNote: Driving/licensing rules vary by state/territory. Also confirm with your state road authority (e.g., Service NSW, VicRoads, TMR QLD).';
      return '${answer.trim()}$note';
    }

    // Money category can be broad; only suggest a professional when it looks tax-like.
    if (category == _Category.money) {
      final looksTaxLike =
          lowerMsg.contains('tax') ||
          lowerMsg.contains('ato') ||
          lowerMsg.contains('tfn') ||
          lowerMsg.contains('abn') ||
          msg.contains('कर') ||
          msg.contains('ट्याक्स');
      if (looksTaxLike) {
        final note = wantsNepali
            ? '\n\nनोट: कर/ATO सम्बन्धी विषयमा तपाईंको अवस्था अनुसार फरक पर्न सक्छ। आवश्यक परे Registered Tax Agent/Accountant सँग सल्लाह लिनुहोस्।'
            : '\n\nNote: Tax/ATO topics can vary by your circumstances. If needed, consult a Registered Tax Agent/Accountant.';
        return '${answer.trim()}$note';
      }
    }

    return answer;
  }

  // ----------------------------
  // Intent category classification
  // ----------------------------

  static _Category _classifyCategory(String msg) {
    final lower = msg.toLowerCase();

    bool hasAny(Iterable<String> needles) => needles.any(lower.contains);
    bool hasAnyRaw(Iterable<String> needles) => needles.any(msg.contains);

    // Work rights / visa limits should win over “student jobs”.
    final looksWorkRights =
        hasAny([
          'work rights',
          'work limit',
          'working hours',
          'maximum hours',
          'minimum hours',
          'hours per fortnight',
          'fortnight',
          'student visa',
          'visa condition',
          'condition 8105',
          'immi',
          'home affairs',
          'fair work',
          'casual',
        ]) ||
        hasAnyRaw([
          'भिसा',
          'वर्क राइट',
          'काम गर्ने घण्टा',
          'घण्टा',
          'फोर्टनाइट',
          'वर्क लिमिट',
          'काम गर्ने अधिकार',
        ]);

    if (looksWorkRights) return _Category.workRights;

    final looksDriving =
        hasAny([
          'licence',
          'license',
          'driving',
          'learner',
          'p plate',
          'rego',
        ]) ||
        hasAnyRaw(['लाइस', 'ड्राइभ', 'लाइसेन्स', 'लाइसेन्स']);
    if (looksDriving) return _Category.driving;

    final looksHousing =
        hasAny([
          'rent',
          'rental',
          'bond',
          'lease',
          'room',
          'sharehouse',
          'flatmate',
          'realestate',
          'domain',
          'inspection',
          'suburb',
          'accommodation',
        ]) ||
        hasAnyRaw(['कोठा', 'रुम', 'भाडा', 'बन्ड', 'लिज', 'आवास']);
    if (looksHousing) return _Category.housing;

    final looksTransport =
        hasAny([
          'transport',
          'train',
          'bus',
          'tram',
          'metro',
          'opal',
          'myki',
          'go card',
          'top up',
          'timetable',
        ]) ||
        hasAnyRaw(['बस', 'ट्रेन', 'ट्राम', 'यातायात', 'कार्ड']);
    if (looksTransport) return _Category.transport;

    final looksMoney =
        hasAny([
          'bank',
          'account',
          'bsb',
          'card',
          'debit',
          'credit',
          'pay',
          'salary',
          'super',
          'tfn',
          'abn',
          'ato',
          'tax',
        ]) ||
        hasAnyRaw([
          'बैंक',
          'खाता',
          'कार्ड',
          'तलब',
          'कर',
          'ट्याक्स',
          'TFN',
          'ABN',
        ]);
    if (looksMoney) return _Category.money;

    final looksHealth =
        hasAny([
          'medicare',
          'gp',
          'doctor',
          'hospital',
          'health',
          'healthcare',
          'clinic',
          'ambulance',
          'pharmacy',
          'insurance',
          // Common symptom/urgent words.
          'fever',
          'sick',
          'pain',
          'injury',
          'bleeding',
          'breathing',
          'emergency',
        ]) ||
        hasAnyRaw([
          'मेडिकेयर',
          'डाक्टर',
          'अस्पताल',
          'स्वास्थ्य',
          'ज्वरो',
          'बिरामी',
          'दुखाइ',
          'आपतकाल',
        ]);
    if (looksHealth) return _Category.health;

    final looksEducation =
        hasAny([
          'university',
          'uni',
          'tafe',
          'course',
          'enrol',
          'enrollment',
          'student',
          'classes',
          'assignment',
        ]) ||
        hasAnyRaw([
          'युनिभर्सिटी',
          'विश्वविद्यालय',
          'कक्षा',
          'कोर्स',
          'विद्यार्थी',
        ]);
    if (looksEducation) return _Category.education;

    final looksStudentJobs =
        hasAny([
          'job',
          'jobs',
          'seek',
          'career',
          'resume',
          'cv',
          'interview',
          'apply',
          'application',
          'cover letter',
          'part-time',
          'casual job',
        ]) ||
        hasAnyRaw(['जागिर', 'काम खोज', 'रेजुमे', 'सीभी', 'इन्टरभ्यु']);
    if (looksStudentJobs) return _Category.studentJobs;

    return _Category.general;
  }

  static List<_ParsedSection> _filterSectionsByCategory(
    List<_ParsedSection> sections,
    _Category category,
  ) {
    if (category == _Category.general) return sections;

    final filtered = sections
        .where((s) => _inferSectionCategory(s) == category)
        .toList(growable: false);

    return filtered;
  }

  static _Category _inferSectionCategory(_ParsedSection s) {
    final hay = '${s.enTitle}\n${s.neTitle}\n${s.enBody}\n${s.neBody}'
        .toLowerCase();

    bool hasAny(Iterable<String> needles) => needles.any(hay.contains);

    if (hasAny([
      'visa',
      'work rights',
      'work limit',
      'hours per fortnight',
      'home affairs',
      'immigration',
      'fair work',
      '8105',
      'condition',
    ])) {
      return _Category.workRights;
    }

    if (hasAny([
      'resume',
      'cv',
      'interview',
      'job search',
      'seek',
      'apply',
      'cover letter',
      'student job',
    ])) {
      return _Category.studentJobs;
    }

    if (hasAny([
      'rent',
      'bond',
      'lease',
      'room',
      'accommodation',
      'sharehouse',
      'flatmate',
      'inspection',
      'suburb',
      'realestate',
      'domain',
    ])) {
      return _Category.housing;
    }

    if (hasAny([
      'transport',
      'opal',
      'myki',
      'go card',
      'train',
      'bus',
      'tram',
      'metro',
    ])) {
      return _Category.transport;
    }

    if (hasAny([
      'driver',
      'driving',
      'licence',
      'license',
      'learner',
      'p plate',
      'rego',
    ])) {
      return _Category.driving;
    }

    if (hasAny([
      'bank',
      'account',
      'tfn',
      'abn',
      'ato',
      'tax',
      'super',
      'salary',
      'pay',
    ])) {
      return _Category.money;
    }

    if (hasAny([
      'medicare',
      'healthcare',
      'gp',
      'doctor',
      'hospital',
      'health',
      'ambulance',
      'pharmacy',
      'insurance',
    ])) {
      return _Category.health;
    }

    if (hasAny([
      'university',
      'uni',
      'tafe',
      'course',
      'enrol',
      'enrollment',
      'assignment',
      'classes',
    ])) {
      return _Category.education;
    }

    return _Category.general;
  }

  // ----------------------------
  // Safe “general knowledge” fallback
  // ----------------------------
  static String? _generalKnowledgeFallback({
    required String msg,
    required bool wantsNepali,
    required _Category category,
    required bool includeSensitiveNote,
  }) {
    // Only provide fallback for well-known, stable FAQs. Otherwise, keep the
    // existing “don’t guess” behavior.
    final lower = msg.toLowerCase();

    String wrap(String text) {
      final out = includeSensitiveNote
          ? _appendSensitiveNote(text, wantsNepali: wantsNepali)
          : text;
      return out.trim();
    }

    if (category == _Category.workRights) {
      final asksHours =
          lower.contains('hour') ||
          lower.contains('fortnight') ||
          msg.contains('घण्टा');
      final mentionsStudent =
          lower.contains('student') ||
          lower.contains('student visa') ||
          msg.contains('विद्यार्थी');
      if (asksHours && mentionsStudent) {
        return wantsNepali
            ? wrap(
                'Student visa (Australia) को सामान्य नियम अनुसार: पढाइ भइरहेको बेला 48 hours per fortnight (प्रति 2 हप्ता) सम्म काम गर्न पाइन्छ, र आधिकारिक छुट्टी (course break) मा घण्टा सीमा प्रायः हुँदैन।\n\nयो तपाईंको visa conditions अनुसार फरक हुन सक्छ, त्यसैले Home Affairs र आफ्नो COE/visa grant letter हेर्नुहोस्। आवश्यक परे Registered Migration Agent सँग सल्लाह लिनुहोस्।',
              )
            : wrap(
                'General Australia info for student visa holders: during study periods you can usually work up to 48 hours per fortnight, and during official course breaks the limit is usually unrestricted.\n\nThis can vary by your visa conditions, so check Home Affairs and your visa grant/COE. If needed, consult a Registered Migration Agent.',
              );
      }
    }

    if (category == _Category.health) {
      final looksSymptomOrUrgent =
          lower.contains('fever') ||
          lower.contains('sick') ||
          lower.contains('pain') ||
          lower.contains('breath') ||
          lower.contains('bleed') ||
          lower.contains('emergency') ||
          msg.contains('ज्वरो') ||
          msg.contains('बिरामी') ||
          msg.contains('दुखाइ') ||
          msg.contains('आपतकाल');

      if (looksSymptomOrUrgent) {
        return wantsNepali
            ? wrap(
                'म स्वास्थ्य सम्बन्धी व्यक्तिगत निदान/उपचार गर्न सक्दिनँ, तर सामान्य मार्गदर्शन:\n\n- यदि गम्भीर लक्षण (सास फेर्न गाह्रो, छाती दुखाइ, बेहोस, धेरै रगत बग्नु) छ भने 000 मा फोन गर्नुहोस्।\n- अन्यथा GP/health professional सँग कुरा गर्नुहोस्, वा Healthdirect (1800 022 222) बाट नर्सको सल्लाह लिन सक्नुहुन्छ।\n\nयदि तपाईं कुन राज्य/सहर र लक्षण कति समयदेखि छ भन्नुभयो भने, म उपयुक्त सेवा खोज्ने गाइडको भाग देखाउन सक्छु।',
              )
            : wrap(
                'I can’t diagnose or provide personal medical treatment, but general guidance: \n\n- If you have severe symptoms (trouble breathing, chest pain, fainting, heavy bleeding), call 000.\n- Otherwise, talk to a GP/health professional, or call Healthdirect (1800 022 222) for nurse advice.\n\nIf you tell me your state/city and how long you’ve had the symptoms, I can point to the closest relevant guide section.',
              );
      }
    }

    return null;
  }

  static bool _isSensitiveTopic(String msg) {
    final lower = msg.toLowerCase();
    const sensitive = <String>{
      // English
      'visa',
      'immigration',
      'immi',
      'home affairs',
      'citizenship',
      'pr',
      'bridging',
      'tax',
      'ato',
      'tfn',
      'abn',
      'centrelink',
      'medicare',
      'legal',
      'law',
      'court',
      'police',
      'fine',
      'penalty',
      'work rights',
      'fair work',
      // Nepali (lowercase check still helps for latin words)
    };

    final nepaliSignals =
        msg.contains('भिसा') ||
        msg.contains('इमिग्रेशन') ||
        msg.contains('कर') ||
        msg.contains('ट्याक्स') ||
        msg.contains('कानुन') ||
        msg.contains('कानूनी') ||
        msg.contains('मेडिकेयर') ||
        msg.contains('सेन्टरलिङ्क') ||
        msg.contains('ATO') ||
        msg.contains('TFN') ||
        msg.contains('ABN');

    if (nepaliSignals) return true;
    return sensitive.any(lower.contains);
  }

  static String? _explicitOtherCountryContext(String msg) {
    final lower = msg.toLowerCase();
    final mentionsAustralia =
        lower.contains('australia') ||
        lower.contains('aussie') ||
        lower.contains('aus') ||
        msg.contains('अस्ट्रेलिया');
    if (mentionsAustralia) return null;

    // Only trigger when the user explicitly frames the question as being in/for another country.
    final patterns = <RegExp, String>{
      RegExp(r'\b(in|for)\s+(the\s+)?usa\b'): 'USA',
      RegExp(r'\b(in|for)\s+(the\s+)?united states\b'): 'USA',
      RegExp(r'\b(in|for)\s+(the\s+)?uk\b'): 'UK',
      RegExp(r'\b(in|for)\s+(the\s+)?united kingdom\b'): 'UK',
      RegExp(r'\b(in|for)\s+canada\b'): 'Canada',
      RegExp(r'\b(in|for)\s+new zealand\b'): 'New Zealand',
      RegExp(r'\b(in|for)\s+india\b'): 'India',
      RegExp(r'\b(in|for)\s+nepal\b'): 'Nepal',
    };
    for (final e in patterns.entries) {
      if (e.key.hasMatch(lower)) return e.value;
    }
    return null;
  }

  static bool _isLanguageOnlyRequest(String msg) {
    final lower = msg.toLowerCase().trim();
    final wantsNep = msg.contains('नेपाली') || lower.contains('nepali');
    if (!wantsNep) return false;

    // Examples: “Explain this in Nepali”, “Nepali please”, “नेपालीमा बुझाइदिनुहोस्”.
    final looksLikeExplainOnly =
        lower == 'explain this in nepali' ||
        lower == 'explain in nepali' ||
        lower == 'nepali please' ||
        lower == 'please explain in nepali' ||
        msg.trim() == 'नेपाली' ||
        msg.contains('नेपालीमा') ||
        msg.contains('नेपालीमा बुझाइ') ||
        msg.contains('नेपालीमा explain');

    // If they included other meaningful keywords, don’t treat it as language-only.
    final hasExtraKeywords = RegExp(r'[a-zA-Z]{4,}')
        .allMatches(lower)
        .any(
          (m) => !{
            'explain',
            'this',
            'in',
            'nepali',
            'please',
          }.contains(m.group(0)!),
        );

    return looksLikeExplainOnly || !hasExtraKeywords;
  }

  static bool _wantsNepali(String msg) {
    final lower = msg.toLowerCase();
    if (msg.contains('नेपाली') || msg.contains('नेप')) return true;
    return lower.contains('nepali') || lower.contains('nepali ');
  }

  static _Intent _inferIntent(String msg) {
    final lower = msg.toLowerCase();
    final nepali = msg;

    final wantsLinks =
        lower.contains('website') ||
        lower.contains('websites') ||
        lower.contains('site') ||
        lower.contains('sites') ||
        lower.contains('link') ||
        lower.contains('links') ||
        lower.contains('where to look') ||
        lower.contains('where can i') ||
        nepali.contains('वेबसाइट') ||
        nepali.contains('साइट') ||
        nepali.contains('लिंक');

    final wantsDocs =
        lower.contains('document') ||
        lower.contains('documents') ||
        lower.contains('bring') ||
        lower.contains('required') ||
        lower.contains('need') ||
        lower.contains('id') ||
        nepali.contains('कागजात') ||
        nepali.contains('दस्तावेज') ||
        nepali.contains('के चाहिन्छ');

    final wantsSteps =
        lower.contains('step') ||
        lower.contains('step-by-step') ||
        lower.contains('how do i') ||
        lower.contains('how to') ||
        lower.contains('apply') ||
        lower.contains('process') ||
        nepali.contains('कसरी') ||
        nepali.contains('स्टेप') ||
        nepali.contains('प्रक्रिया');

    final wantsFirst =
        lower.contains('what should i do first') ||
        lower.contains('what do i do first') ||
        lower.contains('first') ||
        lower.contains('start') ||
        nepali.contains('पहिलो') ||
        nepali.contains('सुरु');

    final wantsExplain =
        lower.contains('explain') ||
        lower.contains('what does this mean') ||
        lower.contains('what does it mean') ||
        lower.contains('meaning') ||
        nepali.contains('के हो') ||
        nepali.contains('अर्थ');

    if (wantsLinks) return _Intent.links;
    if (wantsDocs) return _Intent.documents;
    if (wantsFirst) return _Intent.first;
    if (wantsSteps) return _Intent.steps;
    if (wantsExplain) return _Intent.explain;
    return _Intent.general;
  }

  static String _answerEnglish({
    required _Intent intent,
    required List<_ParsedSection> sections,
    required String msg,
  }) {
    final b = StringBuffer();

    switch (intent) {
      case _Intent.links:
        b.writeln('Websites/links mentioned in this guide:');
        final links = _extractLinks(sections);
        if (links.isEmpty) {
          b.writeln(
            '- I couldn\'t find any explicit website links in this guide section.',
          );
        } else {
          for (final l in links.take(12)) {
            final label = l.label.trim().isEmpty ? 'Website' : l.label.trim();
            b.writeln('- $label — ${l.url}');
          }
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: false));
        break;

      case _Intent.documents:
        b.writeln(
          'Based on the guide, here are the likely documents/items you’ll need:',
        );
        final items = _extractDocumentLikeLines(sections, wantsNepali: false);
        if (items.isEmpty) {
          b.writeln(
            '- I couldn’t find a clear document list in this guide section.',
          );
          b.writeln(
            '  Try asking: “What documents are mentioned in this guide?”',
          );
        } else {
          for (final it in items.take(10)) {
            b.writeln('- $it');
          }
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: false));
        break;

      case _Intent.steps:
        b.writeln('Here’s a step-by-step answer pulled from the guide:');
        final steps = _extractSteps(sections, wantsNepali: false);
        if (steps.isEmpty) {
          final bullets = _extractBullets(sections, wantsNepali: false);
          if (bullets.isEmpty) {
            b.writeln('- I couldn’t find a clear step list in the guide text.');
            b.writeln('  Try asking: “Summarize the process as steps.”');
          } else {
            for (var i = 0; i < bullets.take(8).length; i++) {
              b.writeln('${i + 1}. ${bullets[i]}');
            }
          }
        } else {
          for (var i = 0; i < steps.take(10).length; i++) {
            b.writeln('${i + 1}. ${steps[i]}');
          }
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: false));
        break;

      case _Intent.first:
        final steps = _extractSteps(sections, wantsNepali: false);
        if (steps.isNotEmpty) {
          b.writeln('What to do first (from the guide):');
          b.writeln('1) ${steps.first}');
        } else {
          final bullets = _extractBullets(sections, wantsNepali: false);
          b.writeln('A good first step (from the guide):');
          b.writeln(
            bullets.isNotEmpty
                ? '1) ${bullets.first}'
                : '1) Open the most relevant section and follow the first checklist item.',
          );
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: false));
        break;

      case _Intent.explain:
        b.writeln('Here’s the part of the guide that matches your question:');
        final snippet = _extractRelevantSnippets(
          sections,
          msg,
          wantsNepali: false,
        );
        if (snippet.isEmpty) {
          b.writeln('- I couldn’t find an exact match in the guide text.');
          b.writeln(
            '  Tip: paste the exact sentence/phrase you want explained.',
          );
        } else {
          for (final line in snippet.take(8)) {
            b.writeln('- $line');
          }
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: false));
        break;

      case _Intent.general:
        b.writeln('Here’s what the guide says that’s most relevant:');
        final bullets = _extractBullets(sections, wantsNepali: false);
        if (bullets.isEmpty) {
          final snippet = _extractRelevantSnippets(
            sections,
            msg,
            wantsNepali: false,
          );
          for (final line in snippet.take(8)) {
            b.writeln('- $line');
          }
        } else {
          for (final line in bullets.take(8)) {
            b.writeln('- $line');
          }
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: false));
        break;
    }

    return b.toString();
  }

  static String _answerNepali({
    required _Intent intent,
    required List<_ParsedSection> sections,
    required String msg,
  }) {
    final b = StringBuffer();

    final hasNepali = sections.any(
      (s) =>
          s.neBody.trim().isNotEmpty &&
          !s.neBody.contains('Nepali translation not available'),
    );
    if (!hasNepali) {
      b.writeln('यो गाइडमा नेपाली सामग्री/अनुवाद उपलब्ध छैन जस्तो देखिन्छ।');
      b.writeln('तर म अङ्ग्रेजी भागबाटै सरल रूपमा बुझाइदिन्छु:');
      b.writeln('');
      return b.toString() +
          _answerEnglish(intent: intent, sections: sections, msg: msg);
    }

    switch (intent) {
      case _Intent.links:
        b.writeln('यो गाइडमा उल्लेख भएका वेबसाइट/लिंकहरू:');
        final links = _extractLinks(sections);
        if (links.isEmpty) {
          b.writeln('- यो भागमा स्पष्ट वेबसाइट लिंकहरू भेटिएन।');
        } else {
          for (final l in links.take(12)) {
            final label = l.label.trim().isEmpty ? 'Website' : l.label.trim();
            b.writeln('- $label — ${l.url}');
          }
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: true));
        break;

      case _Intent.documents:
        b.writeln('गाइडको आधारमा चाहिन सक्ने कागजात/चीजहरू:');
        final items = _extractDocumentLikeLines(sections, wantsNepali: true);
        if (items.isEmpty) {
          b.writeln('- यो भागमा स्पष्ट कागजात सूची भेटिएन।');
          b.writeln('  यस्तो सोध्नुहोस्: “यस गाइडमा कुन-कुन कागजात उल्लेख छ?”');
        } else {
          for (final it in items.take(10)) {
            b.writeln('- $it');
          }
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: true));
        break;

      case _Intent.steps:
        b.writeln('गाइडबाट स्टेप‑बाइ‑स्टेप (क्रम):');
        final steps = _extractSteps(sections, wantsNepali: true);
        if (steps.isEmpty) {
          final bullets = _extractBullets(sections, wantsNepali: true);
          if (bullets.isEmpty) {
            b.writeln('- गाइडमा स्पष्ट स्टेप सूची भेटिएन।');
            b.writeln(
              '  यस्तो सोध्नुहोस्: “यसलाई स्टेपको रूपमा सारांश दिनुहोस्।”',
            );
          } else {
            for (var i = 0; i < bullets.take(8).length; i++) {
              b.writeln('${i + 1}. ${bullets[i]}');
            }
          }
        } else {
          for (var i = 0; i < steps.take(10).length; i++) {
            b.writeln('${i + 1}. ${steps[i]}');
          }
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: true));
        break;

      case _Intent.first:
        final steps = _extractSteps(sections, wantsNepali: true);
        if (steps.isNotEmpty) {
          b.writeln('पहिलो के गर्ने? (गाइडबाट):');
          b.writeln('1) ${steps.first}');
        } else {
          final bullets = _extractBullets(sections, wantsNepali: true);
          b.writeln('पहिलो कदम (गाइडबाट):');
          b.writeln(
            bullets.isNotEmpty
                ? '1) ${bullets.first}'
                : '1) सबैभन्दा मिल्ने सेक्शन खोलेर पहिलो checklist item बाट सुरु गर्नुहोस्।',
          );
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: true));
        break;

      case _Intent.explain:
        b.writeln('तपाईंको प्रश्नसँग मिल्ने गाइडको अंश:');
        final snippet = _extractRelevantSnippets(
          sections,
          msg,
          wantsNepali: true,
        );
        if (snippet.isEmpty) {
          b.writeln('- ठ्याक्कै मिल्ने वाक्य/लाइन भेटिएन।');
          b.writeln(
            '  Tip: जुन वाक्य/फ्रेज बुझ्न चाहनुहुन्छ, त्यही copy गरेर पठाउनुहोस्।',
          );
        } else {
          for (final line in snippet.take(8)) {
            b.writeln('- $line');
          }
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: true));
        break;

      case _Intent.general:
        b.writeln('गाइडमा सबैभन्दा सम्बन्धित कुरा:');
        final bullets = _extractBullets(sections, wantsNepali: true);
        if (bullets.isEmpty) {
          final snippet = _extractRelevantSnippets(
            sections,
            msg,
            wantsNepali: true,
          );
          for (final line in snippet.take(8)) {
            b.writeln('- $line');
          }
        } else {
          for (final line in bullets.take(8)) {
            b.writeln('- $line');
          }
        }
        b.writeln('');
        b.writeln(_citeSections(sections, wantsNepali: true));
        break;
    }

    return b.toString();
  }

  static String _citeSections(
    List<_ParsedSection> sections, {
    required bool wantsNepali,
  }) {
    final titles = sections
        .map((s) => (wantsNepali ? s.neTitle : s.enTitle).trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .take(2)
        .toList(growable: false);

    if (titles.isEmpty) return '';
    return wantsNepali
        ? 'स्रोत (यो गाइडको सेक्शन): ${titles.join(' / ')}'
        : 'Source (guide sections): ${titles.join(' / ')}';
  }

  static List<String> _keywords(String msg, {required bool wantsNepali}) {
    if (wantsNepali) {
      final stop = <String>{
        'explain',
        'this',
        'in',
        'nepali',
        'please',
        'मा',
        'को',
        'कि',
        'के',
        'कसरी',
      };
      return msg
          .split(RegExp(r'\s+'))
          .map((t) => t.trim())
          .where((t) => t.length >= 2)
          .where((t) => !stop.contains(t.toLowerCase()))
          .take(12)
          .toList(growable: false);
    }

    final stop = <String>{
      'the',
      'and',
      'for',
      'with',
      'this',
      'that',
      'what',
      'does',
      'mean',
      'how',
      'do',
      'i',
      'a',
      'an',
      'to',
      'of',
      'in',
      'on',
      'it',
      'is',
      'are',
      'need',
      'required',
      'please',
      'can',
      'you',
      // Common query filler words.
      'best',
      'site',
      'sites',
      'website',
      'websites',
      'look',
      'search',
      'find',
    };

    final words = RegExp(
      r'[a-zA-Z0-9]{3,}',
    ).allMatches(msg.toLowerCase()).map((m) => m.group(0)!).toList();

    final expanded = <String>[];
    for (final w in words) {
      if (stop.contains(w)) continue;
      expanded.add(w);
      if (w == 'room') {
        expanded.addAll([
          'accommodation',
          'housing',
          'rental',
          'rent',
          'sharehouse',
          'flatmates',
          'realestate',
          'domain',
        ]);
      }
      if (w == 'accommodation') {
        expanded.addAll(['room', 'sharehouse', 'flatmates', 'rental']);
      }
    }

    final seen = <String>{};
    final out = <String>[];
    for (final w in expanded) {
      if (seen.add(w)) out.add(w);
      if (out.length >= 12) break;
    }
    return out;
  }

  static int _scoreSection(
    _ParsedSection s,
    List<String> tokens, {
    required bool wantsNepali,
  }) {
    if (tokens.isEmpty) return 0;
    final hay = (wantsNepali ? s.neBody : s.enBody).toLowerCase();
    var score = 0;
    for (final t in tokens) {
      final needle = t.toLowerCase();
      if (needle.length < 2) continue;
      if (hay.contains(needle)) score += 3;
      if ((wantsNepali ? s.neTitle : s.enTitle).toLowerCase().contains(
        needle,
      )) {
        score += 2;
      }

      for (final link in s.links) {
        final combined = '${link.label} ${link.url}'.toLowerCase();
        if (combined.contains(needle)) score += 2;
      }
    }

    if (s.links.isNotEmpty) score += 2;
    return score;
  }

  static List<_ParsedLink> _extractLinks(List<_ParsedSection> sections) {
    final out = <_ParsedLink>[];
    final seen = <String>{};

    for (final s in sections) {
      for (final l in s.links) {
        final key = l.url.trim().toLowerCase();
        if (key.isEmpty) continue;
        if (seen.add(key)) out.add(l);
      }

      final body = '${s.enBody}\n${s.neBody}';
      for (final url in _extractUrlsFromText(body)) {
        final key = url.trim().toLowerCase();
        if (key.isEmpty) continue;
        if (seen.add(key)) out.add(_ParsedLink(label: 'Website', url: url));
      }
    }

    return out;
  }

  static List<String> _extractUrlsFromText(String text) {
    final re = RegExp(
      r'((https?:\/\/)|(www\.))\S+|\b[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.(com\.au|gov\.au|org\.au|edu\.au|net\.au|com|org|net)\b[^\s]*',
      caseSensitive: false,
    );
    return re
        .allMatches(text)
        .map((m) => m.group(0)!)
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .take(20)
        .toList(growable: false);
  }

  static List<String> _extractSteps(
    List<_ParsedSection> sections, {
    required bool wantsNepali,
  }) {
    final out = <String>[];
    final re = RegExp(
      r'^\s*(\d+\.|\d+\)|step\s*\d+\s*[:\-])\s*',
      caseSensitive: false,
    );

    for (final s in sections) {
      final body = wantsNepali ? s.neBody : s.enBody;
      for (final raw in body.split('\n')) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        if (re.hasMatch(line)) {
          out.add(line.replaceFirst(re, '').trim());
        }
      }
    }

    return _uniqueClean(out);
  }

  static List<String> _extractBullets(
    List<_ParsedSection> sections, {
    required bool wantsNepali,
  }) {
    final out = <String>[];
    final bulletRe = RegExp(r'^\s*(•|\-|\*)\s+');
    for (final s in sections) {
      final body = wantsNepali ? s.neBody : s.enBody;
      for (final raw in body.split('\n')) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        if (bulletRe.hasMatch(line)) {
          out.add(line.replaceFirst(bulletRe, '').trim());
        }
      }
    }
    return _uniqueClean(out);
  }

  static List<String> _extractDocumentLikeLines(
    List<_ParsedSection> sections, {
    required bool wantsNepali,
  }) {
    final out = <String>[];

    final docKeywords = wantsNepali
        ? <String>[
            'पासपोर्ट',
            'भिसा',
            'कागजात',
            'ठेगाना',
            'पहिचान',
            'आईडी',
            'ID',
            'प्रमाण',
            'लाइसन्स',
            'अनुवाद',
          ]
        : <String>[
            'passport',
            'visa',
            'document',
            'documents',
            'proof',
            'address',
            'id',
            'identity',
            'certificate',
            'translation',
            'license',
            'licence',
          ];

    final bullets = _extractBullets(sections, wantsNepali: wantsNepali);
    for (final b in bullets) {
      final low = b.toLowerCase();
      if (docKeywords.any((k) => low.contains(k.toLowerCase()))) {
        out.add(b);
      }
    }

    // Also scan non-bullet lines around “Bring documents” etc.
    for (final s in sections) {
      final body = wantsNepali ? s.neBody : s.enBody;
      for (final raw in body.split('\n')) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        final low = line.toLowerCase();
        if (docKeywords.any((k) => low.contains(k.toLowerCase()))) {
          if (line.length <= 120) out.add(line);
        }
      }
    }

    return _uniqueClean(out);
  }

  static List<String> _extractRelevantSnippets(
    List<_ParsedSection> sections,
    String msg, {
    required bool wantsNepali,
  }) {
    final tokens = _keywords(msg, wantsNepali: wantsNepali);
    if (tokens.isEmpty) return const [];

    final out = <String>[];
    for (final s in sections) {
      final body = wantsNepali ? s.neBody : s.enBody;
      for (final raw in body.split('\n')) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        final low = line.toLowerCase();
        final matches = tokens
            .where((t) => low.contains(t.toLowerCase()))
            .length;
        if (matches >= 1 && line.length <= 160) {
          out.add(line);
        }
      }
    }
    return _uniqueClean(out);
  }

  static List<String> _uniqueClean(List<String> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final it in items) {
      final v = it.trim();
      if (v.isEmpty) continue;
      final key = v.toLowerCase();
      if (seen.add(key)) out.add(v);
    }
    return out;
  }

  static _ParsedGuideDoc _parseGuideContent({
    required String guideTitle,
    required String guideContent,
  }) {
    final lines = guideContent.split('\n');

    final sections = <_ParsedSection>[];

    _ParsedSection? current;
    var mode = _ParseMode.none;

    void flush() {
      if (current == null) return;
      final en = current!.enBody.trim();
      final ne = current!.neBody.trim();
      if (current!.enTitle.trim().isNotEmpty ||
          en.isNotEmpty ||
          ne.isNotEmpty) {
        sections.add(
          _ParsedSection(
            enTitle: current!.enTitle.trim(),
            neTitle: current!.neTitle.trim(),
            enBody: en,
            neBody: ne,
            links: current!.links,
          ),
        );
      }
      current = null;
      mode = _ParseMode.none;
    }

    for (final raw in lines) {
      final line = raw.trimRight();

      if (line.startsWith('SECTION (EN):')) {
        flush();
        current = _ParsedSection(
          enTitle: line.substring('SECTION (EN):'.length).trim(),
          neTitle: '',
          enBody: '',
          neBody: '',
          links: const [],
        );
        mode = _ParseMode.en;
        continue;
      }

      if (line.startsWith('SECTION (NE):')) {
        current ??= _ParsedSection(
          enTitle: guideTitle,
          neTitle: '',
          enBody: '',
          neBody: '',
          links: const [],
        );
        current = _ParsedSection(
          enTitle: current!.enTitle,
          neTitle: line.substring('SECTION (NE):'.length).trim(),
          enBody: current!.enBody,
          neBody: current!.neBody,
          links: current!.links,
        );
        mode = _ParseMode.ne;
        continue;
      }

      if (line == 'LINKS:') {
        mode = _ParseMode.links;
        continue;
      }

      if (current == null) {
        continue;
      }

      switch (mode) {
        case _ParseMode.en:
          current = _ParsedSection(
            enTitle: current!.enTitle,
            neTitle: current!.neTitle,
            enBody:
                '${current!.enBody}${current!.enBody.isEmpty ? '' : '\n'}${line.trim()}',
            neBody: current!.neBody,
            links: current!.links,
          );
          break;
        case _ParseMode.ne:
          current = _ParsedSection(
            enTitle: current!.enTitle,
            neTitle: current!.neTitle,
            enBody: current!.enBody,
            neBody:
                '${current!.neBody}${current!.neBody.isEmpty ? '' : '\n'}${line.trim()}',
            links: current!.links,
          );
          break;
        case _ParseMode.links:
          // Expect lines like: - Label: https://...
          final trimmed = line.trim();
          if (trimmed.startsWith('- ')) {
            final rest = trimmed.substring(2);
            final idx = rest.lastIndexOf('http');
            if (idx >= 0) {
              final label = rest.substring(0, idx).replaceAll(':', '').trim();
              final url = rest.substring(idx).trim();
              final nextLinks = [
                ...current!.links,
                _ParsedLink(label: label, url: url),
              ];
              current = _ParsedSection(
                enTitle: current!.enTitle,
                neTitle: current!.neTitle,
                enBody: current!.enBody,
                neBody: current!.neBody,
                links: nextLinks,
              );
            }
          }
          break;
        case _ParseMode.none:
          break;
      }
    }

    flush();

    return _ParsedGuideDoc(sections: sections);
  }
}

enum _Intent { general, steps, documents, first, explain, links }

enum _Category {
  workRights,
  studentJobs,
  housing,
  transport,
  driving,
  money,
  health,
  education,
  general,
}

enum _ParseMode { none, en, ne, links }

class _ParsedGuideDoc {
  final List<_ParsedSection> sections;

  _ParsedGuideDoc({required this.sections});
}

class _ParsedSection {
  final String enTitle;
  final String neTitle;
  final String enBody;
  final String neBody;
  final List<_ParsedLink> links;

  _ParsedSection({
    required this.enTitle,
    required this.neTitle,
    required this.enBody,
    required this.neBody,
    required this.links,
  });
}

class _ParsedLink {
  final String label;
  final String url;

  _ParsedLink({required this.label, required this.url});
}

class _ScoredSection {
  final _ParsedSection section;
  final int score;

  _ScoredSection({required this.section, required this.score});
}

class _GuardrailEvaluation {
  final bool isSensitiveTopic;
  final String? blockReply;

  _GuardrailEvaluation({required this.isSensitiveTopic, this.blockReply});
}

class _Confidence {
  final bool isConfident;

  const _Confidence(this.isConfident);
}
