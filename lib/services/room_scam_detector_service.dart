import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../ai_resume_creator/ai_resume_service.dart';

enum ScamLikelihood {
  low,
  medium,
  high,
  unknown;

  static ScamLikelihood parse(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'low') return ScamLikelihood.low;
    if (v == 'medium') return ScamLikelihood.medium;
    if (v == 'high') return ScamLikelihood.high;
    return ScamLikelihood.unknown;
  }

  String get label {
    switch (this) {
      case ScamLikelihood.low:
        return 'Safe';
      case ScamLikelihood.medium:
        return 'Warning';
      case ScamLikelihood.high:
        return 'High Risk';
      case ScamLikelihood.unknown:
        return 'Unknown';
    }
  }
}

class RoomListingInput {
  final String title;
  final String suburb;
  final String city;
  final double pricePerWeek;
  final String roomType;
  final String description;
  final String address;
  final List<String> photoUrls;

  const RoomListingInput({
    required this.title,
    required this.suburb,
    required this.city,
    required this.pricePerWeek,
    required this.roomType,
    required this.description,
    required this.address,
    required this.photoUrls,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'suburb': suburb,
      'city': city,
      'pricePerWeek': pricePerWeek,
      'roomType': roomType,
      'description': description,
      'address': address,
      'photoCount': photoUrls.length,
      'photoUrls': photoUrls.take(8).toList(),
    };
  }

  String stableHash() {
    final bytes = utf8.encode(jsonEncode(toJson()));
    return sha1.convert(bytes).toString();
  }
}

class RoomScamAnalysis {
  final ScamLikelihood likelihood;
  final List<String> redFlags;
  final String explanation;
  final String advice;
  final List<String> saferAlternatives;
  final String source; // api|heuristic|cache

  const RoomScamAnalysis({
    required this.likelihood,
    required this.redFlags,
    required this.explanation,
    required this.advice,
    required this.saferAlternatives,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'likelihood': likelihood.name,
      'redFlags': redFlags,
      'explanation': explanation,
      'advice': advice,
      'saferAlternatives': saferAlternatives,
      'source': source,
    };
  }

  static RoomScamAnalysis fromJson(Map<String, dynamic> json) {
    final likelihood = ScamLikelihood.parse('${json['likelihood'] ?? ''}');

    final redFlagsDynamic = json['redFlags'];
    final redFlags = redFlagsDynamic is List
        ? redFlagsDynamic.whereType<String>().toList()
        : <String>[];

    final saferDynamic = json['saferAlternatives'];
    final saferAlternatives = saferDynamic is List
        ? saferDynamic.whereType<String>().toList()
        : <String>[];

    return RoomScamAnalysis(
      likelihood: likelihood == ScamLikelihood.unknown
          ? ScamLikelihood.parse('${json['scamLikelihood'] ?? ''}')
          : likelihood,
      redFlags: redFlags,
      explanation: (json['explanation'] ?? '').toString(),
      advice: (json['advice'] ?? '').toString(),
      saferAlternatives: saferAlternatives,
      source: (json['source'] ?? 'api').toString(),
    );
  }
}

class RoomScamDetectorService {
  static const _prefsCachePrefix = 'room_scam_analysis:';

  static RoomScamAnalysis quickAssess(RoomListingInput listing) {
    return _analyzeHeuristically(listing);
  }

  static Future<RoomScamAnalysis> analyze({
    required String roomId,
    required RoomListingInput listing,
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_prefsCachePrefix$roomId:${listing.stableHash()}';

    if (!forceRefresh) {
      final cached = prefs.getString(cacheKey);
      if (cached != null && cached.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(cached);
          if (decoded is Map<String, dynamic>) {
            final parsed = RoomScamAnalysis.fromJson(decoded);
            return RoomScamAnalysis(
              likelihood: parsed.likelihood,
              redFlags: parsed.redFlags,
              explanation: parsed.explanation,
              advice: parsed.advice,
              saferAlternatives: parsed.saferAlternatives,
              source: 'cache',
            );
          }
        } catch (_) {
          // Ignore cache parse errors.
        }
      }
    }

    final endpointUrl = await AiResumeService.getEndpointUrl();
    if (endpointUrl != null) {
      try {
        final api = await _analyzeViaApi(endpointUrl: endpointUrl, listing: listing);
        await prefs.setString(cacheKey, jsonEncode(api.toJson()));
        return api;
      } catch (_) {
        // Fall back to heuristic.
      }
    }

    final heuristic = _analyzeHeuristically(listing);
    await prefs.setString(cacheKey, jsonEncode(heuristic.toJson()));
    return heuristic;
  }

  static Future<RoomScamAnalysis> _analyzeViaApi({
    required String endpointUrl,
    required RoomListingInput listing,
  }) async {
    final prompt = _buildPrompt(listing);

    final uri = Uri.parse(endpointUrl);
    final payload = {
      'style': 'modern',
      'locale': 'en-AU',
      'format': 'plain_text',
      'atsFriendly': false,
      'professionalTone': true,
      'input': {
        'prompt': prompt,
      },
      'task': 'room_scam_detector',
      'responseFormat': 'json',
    };

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI endpoint failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('AI endpoint returned invalid JSON');
    }

    final text = decoded['resumeText'];
    if (text is! String || text.trim().isEmpty) {
      throw Exception('AI endpoint missing resumeText');
    }

    final parsed = _parseModelOutput(text);
    return RoomScamAnalysis(
      likelihood: parsed.likelihood,
      redFlags: parsed.redFlags,
      explanation: parsed.explanation,
      advice: parsed.advice,
      saferAlternatives: parsed.saferAlternatives,
      source: 'api',
    );
  }

  static String _buildPrompt(RoomListingInput listing) {
    return [
      'You are a safety assistant for Australian rental listings.',
      'Analyze the listing for potential scams or red flags. Be conservative: only flag what is reasonably suspicious.',
      'If unsure, choose MEDIUM and explain what to verify.',
      '',
      'LISTING (structured):',
      jsonEncode(listing.toJson()),
      '',
      'Check for red flags such as:',
      '- Unusually low price',
      '- No inspection allowed',
      '- Asking for bond/deposit upfront',
      '- No photos or obviously fake photos (if photoCount is 0, flag it)',
      '- No address or vague location',
      '- Urgent payment requests',
      '- Suspicious tone / pressure',
      '- Requests to message on WhatsApp/Telegram only',
      '- No contract or written agreement',
      '- Too good to be true offers',
      '',
      'Return STRICT JSON ONLY, with this schema:',
      '{',
      '  "scamLikelihood": "Low"|"Medium"|"High",',
      '  "redFlags": ["..."],',
      '  "explanation": "simple English, 2-6 sentences",',
      '  "advice": "actionable steps, 2-6 bullets or sentences",',
      '  "saferAlternatives": ["... up to 6 items ..."]',
      '}',
    ].join('\n');
  }

  static RoomScamAnalysis _parseModelOutput(String raw) {
    final trimmed = raw.trim();

    // Try extracting JSON block.
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      final jsonBlock = trimmed.substring(start, end + 1);
      try {
        final decoded = jsonDecode(jsonBlock);
        if (decoded is Map<String, dynamic>) {
          final likelihood = ScamLikelihood.parse('${decoded['scamLikelihood'] ?? ''}');
          final redFlagsDynamic = decoded['redFlags'];
          final redFlags = redFlagsDynamic is List
              ? redFlagsDynamic.whereType<String>().toList()
              : <String>[];

          final saferDynamic = decoded['saferAlternatives'];
          final saferAlternatives = saferDynamic is List
              ? saferDynamic.whereType<String>().toList()
              : <String>[];

          return RoomScamAnalysis(
            likelihood: likelihood,
            redFlags: redFlags,
            explanation: (decoded['explanation'] ?? '').toString().trim(),
            advice: (decoded['advice'] ?? '').toString().trim(),
            saferAlternatives: saferAlternatives,
            source: 'api',
          );
        }
      } catch (_) {
        // Fall through to plaintext parsing.
      }
    }

    // Plaintext fallback.
    final lower = trimmed.toLowerCase();
    ScamLikelihood likelihood = ScamLikelihood.unknown;
    if (lower.contains('high')) likelihood = ScamLikelihood.high;
    if (lower.contains('medium')) likelihood = ScamLikelihood.medium;
    if (lower.contains('low')) likelihood = ScamLikelihood.low;

    return RoomScamAnalysis(
      likelihood: likelihood == ScamLikelihood.unknown ? ScamLikelihood.medium : likelihood,
      redFlags: const [],
      explanation: trimmed,
      advice: 'Verify the address, insist on an inspection, and never send money before viewing and signing a written agreement.',
      saferAlternatives: const [
        'Insist on an in-person inspection (or live video walkthrough).',
        'Only pay bond through the official bond authority for your state.',
        'Use a written lease/contract and keep receipts.',
      ],
      source: 'api',
    );
  }

  static RoomScamAnalysis _analyzeHeuristically(RoomListingInput listing) {
    final redFlags = <String>[];
    var score = 0;

    final desc = listing.description.toLowerCase();
    final title = listing.title.toLowerCase();
    final address = listing.address.trim();

    bool hasAny(String pattern) {
      return desc.contains(pattern) || title.contains(pattern);
    }

    void flag(String label, int points) {
      redFlags.add(label);
      score += points;
    }

    // Photos.
    if (listing.photoUrls.isEmpty) {
      flag('No photos provided', 2);
    }

    // Vague location.
    if (address.isEmpty || address.length < 6) {
      flag('No clear address (vague location)', 2);
    }

    // Pressure / urgency.
    if (hasAny('urgent') || hasAny('asap') || hasAny('today only') || hasAny('must be today')) {
      flag('Urgent / pressure language', 2);
    }

    // Inspection refusal.
    if (hasAny('no inspection') || hasAny('inspection not allowed') || hasAny('no viewing') || hasAny('cannot view')) {
      flag('No inspection allowed', 3);
    }

    // Upfront payment.
    if (hasAny('bond upfront') || hasAny('deposit upfront') || hasAny('pay bond') || hasAny('send bond') || hasAny('pay first') || hasAny('pay now')) {
      flag('Asking for money upfront', 3);
    }

    // Off-platform messaging.
    if (hasAny('whatsapp') || hasAny('telegram') || hasAny('wechat') || hasAny('dm only') || hasAny('message only')) {
      flag('Pushing to message off-platform', 2);
    }

    // Too-good-to-be-true.
    if (hasAny('too good') || hasAny('limited time') || hasAny('guaranteed') || hasAny('free') || hasAny('no questions')) {
      flag('Too-good-to-be-true wording', 1);
    }

    // Low price heuristic (very rough).
    if (listing.pricePerWeek > 0 && listing.pricePerWeek < 100) {
      flag('Price looks unusually low', 2);
    } else if (listing.pricePerWeek > 0 && listing.pricePerWeek < 150 &&
        (listing.city.toUpperCase() == 'NSW' || listing.city.toUpperCase() == 'VIC' || listing.city.toUpperCase() == 'QLD')) {
      flag('Price may be low for this market (verify carefully)', 1);
    }

    ScamLikelihood likelihood;
    if (score >= 7) {
      likelihood = ScamLikelihood.high;
    } else if (score >= 4) {
      likelihood = ScamLikelihood.medium;
    } else {
      likelihood = ScamLikelihood.low;
    }

    final explanation = redFlags.isEmpty
        ? 'No obvious scam signals were detected from the text and metadata. Still verify identity and inspect before paying.'
        : 'Some signals in this listing match common rental scam patterns. It may still be legitimate, but you should verify before paying anything.';

    final advice = [
      'Do not send money before inspection and a written agreement.',
      'Ask for an in-person inspection (or a live video walkthrough).',
      'Request a written lease/contract and keep all receipts.',
      'Pay bond only via your state bond authority (never to a personal account).',
      'Verify the address and the person’s identity (agent/landlord).',
    ].join('\n');

    final safer = <String>[
      'Inspect in person and take photos for the condition report.',
      'Use official channels: lease + bond authority lodgement.',
      'Prefer listings with clear address, real photos, and normal payment timing.',
    ];

    return RoomScamAnalysis(
      likelihood: likelihood,
      redFlags: redFlags,
      explanation: explanation,
      advice: advice,
      saferAlternatives: safer,
      source: 'heuristic',
    );
  }
}
