import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ai_resume_models.dart';

class SavedResumeEntry {
  final String id;
  final String title;
  final DateTime createdAt;
  final ResumeStyle style;
  final ResumePromptInput input;
  final ResumeGenerationResult result;

  const SavedResumeEntry({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.style,
    required this.input,
    required this.result,
  });

  SavedResumeEntry copyWith({
    String? title,
  }) {
    return SavedResumeEntry(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      style: style,
      input: input,
      result: result,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'style': style.name,
      'input': input.toJson(),
      'result': {
        'resumeText': result.resumeText,
        'source': result.source,
      },
    };
  }

  static SavedResumeEntry fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?) ?? '';
    final title = (json['title'] as String?) ?? '';
    final createdAtRaw = (json['createdAt'] as String?) ?? '';
    final styleRaw = (json['style'] as String?) ?? 'modern';

    final inputJson = json['input'];
    final dataJson = json['data'];
    final resultJson = json['result'];

    if (id.trim().isEmpty) throw Exception('Missing id');
    if (title.trim().isEmpty) throw Exception('Missing title');

    final createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();

    final style = ResumeStyle.values.firstWhere(
      (s) => s.name == styleRaw,
      orElse: () => ResumeStyle.modern,
    );

    ResumePromptInput input;

    // New schema: prompt-based input
    if (inputJson is Map<String, dynamic>) {
      final prompt = (inputJson['prompt'] as String?) ?? '';
      input = ResumePromptInput(
        prompt: prompt,
        fullName: inputJson['fullName'] as String?,
        phone: inputJson['phone'] as String?,
        email: inputJson['email'] as String?,
        suburb: inputJson['suburb'] as String?,
      );
    } else if (dataJson is Map<String, dynamic>) {
      // Backward compatibility: old schema stored a structured form.
      final fullName = (dataJson['fullName'] as String?) ?? '';
      final phone = (dataJson['phone'] as String?) ?? '';
      final email = (dataJson['email'] as String?) ?? '';
      final suburb = (dataJson['suburb'] as String?) ?? '';

      final promptParts = <String>[];
      final careerGoal = (dataJson['careerGoal'] as String?) ?? '';
      final summary = (dataJson['summary'] as String?) ?? '';
      final skills = (dataJson['skills'] as String?) ?? '';
      final workExperience = (dataJson['workExperience'] as String?) ?? '';
      final education = (dataJson['education'] as String?) ?? '';
      final certifications = (dataJson['certifications'] as String?) ?? '';
      final languages = (dataJson['languages'] as String?) ?? '';
      final availability = (dataJson['availability'] as String?) ?? '';
      final visaStatus = (dataJson['visaStatus'] as String?) ?? '';

      if (careerGoal.trim().isNotEmpty) {
        promptParts.add('Career goal: ${careerGoal.trim()}');
      }
      if (summary.trim().isNotEmpty) {
        promptParts.add('Summary: ${summary.trim()}');
      }
      if (skills.trim().isNotEmpty) {
        promptParts.add('Skills: ${skills.trim()}');
      }
      if (workExperience.trim().isNotEmpty) {
        promptParts.add('Work experience:\n${workExperience.trim()}');
      }
      if (education.trim().isNotEmpty) {
        promptParts.add('Education:\n${education.trim()}');
      }
      if (certifications.trim().isNotEmpty) {
        promptParts.add('Certifications: ${certifications.trim()}');
      }
      if (languages.trim().isNotEmpty) {
        promptParts.add('Languages: ${languages.trim()}');
      }
      if (availability.trim().isNotEmpty) {
        promptParts.add('Availability: ${availability.trim()}');
      }
      if (visaStatus.trim().isNotEmpty) {
        promptParts.add('Visa status: ${visaStatus.trim()}');
      }

      input = ResumePromptInput(
        prompt: promptParts.join('\n\n').trim(),
        fullName: fullName.isEmpty ? null : fullName,
        phone: phone.isEmpty ? null : phone,
        email: email.isEmpty ? null : email,
        suburb: suburb.isEmpty ? null : suburb,
      );
    } else {
      throw Exception('Invalid input');
    }

    if (resultJson is! Map<String, dynamic>) {
      throw Exception('Invalid result');
    }

    final resumeText = (resultJson['resumeText'] as String?) ?? '';
    final source = (resultJson['source'] as String?) ?? 'saved';

    return SavedResumeEntry(
      id: id,
      title: title,
      createdAt: createdAt,
      style: style,
      input: input,
      result: ResumeGenerationResult(resumeText: resumeText, source: source),
    );
  }
}

class AiResumeStorage {
  static const _key = 'ai_resume_saved_entries_v1';

  static Future<List<SavedResumeEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    final out = <SavedResumeEntry>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        try {
          out.add(SavedResumeEntry.fromJson(item));
        } catch (_) {
          // Skip invalid entries.
        }
      }
    }

    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  static Future<void> saveAll(List<SavedResumeEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<SavedResumeEntry> add({
    required ResumePromptInput input,
    required ResumeStyle style,
    required ResumeGenerationResult result,
  }) async {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final name = (input.fullName ?? '').trim();
    final titleName = name.isNotEmpty ? name : 'Resume';
    final title = '$titleName — ${now.year}-${_two(now.month)}-${_two(now.day)}';

    final entry = SavedResumeEntry(
      id: id,
      title: title,
      createdAt: now,
      style: style,
      input: input,
      result: result,
    );

    final all = await loadAll();
    final updated = [entry, ...all];
    await saveAll(updated);

    return entry;
  }

  static Future<void> delete(String id) async {
    final all = await loadAll();
    final updated = all.where((e) => e.id != id).toList();
    await saveAll(updated);
  }

  static Future<void> rename(String id, String newTitle) async {
    final title = newTitle.trim();
    if (title.isEmpty) return;

    final all = await loadAll();
    final updated = all
        .map((e) => e.id == id ? e.copyWith(title: title) : e)
        .toList();
    await saveAll(updated);
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
