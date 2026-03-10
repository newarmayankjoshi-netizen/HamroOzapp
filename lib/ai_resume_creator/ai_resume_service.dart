import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_resume_models.dart';
import 'ai_resume_ats_optimizer.dart';
import 'ai_resume_duty_suggester.dart';
import 'ai_resume_skill_suggester.dart';

class AiResumeService {
  static const _prefsEndpointKey = 'ai_resume_endpoint_url';

  static Future<void> setEndpointUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await prefs.remove(_prefsEndpointKey);
      return;
    }
    await prefs.setString(_prefsEndpointKey, trimmed);
  }

  static Future<String?> getEndpointUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_prefsEndpointKey);
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  static Future<ResumeGenerationResult> generateResumeFromPrompt({
    required ResumePromptInput input,
    required ResumeStyle style,
  }) async {
    final endpointUrl = await getEndpointUrl();
    if (endpointUrl != null) {
      try {
        final api = await _generateViaApi(
          endpointUrl: endpointUrl,
          input: input,
          style: style,
        );
        if (_looksCopiedOrUnstructured(api.resumeText, input.prompt)) {
          return ResumeGenerationResult(
            resumeText: _generateLocally(input: input, style: style),
            source: 'local',
          );
        }
        return api;
      } catch (_) {
        // Fall back to local generation.
      }
    }

    return ResumeGenerationResult(
      resumeText: _generateLocally(input: input, style: style),
      source: 'local',
    );
  }

  static Future<ResumeGenerationResult> generateResumeFromFormData({
    required ResumeFormData data,
    required ResumeStyle style,
    required ResumeTone tone,
    bool multiStep = true,
  }) async {
    final assembledPrompt = _buildGuidedPrompt(data: data, tone: tone);
    final input = ResumePromptInput(
      prompt: assembledPrompt,
      fullName: data.fullName.trim().isEmpty ? null : data.fullName.trim(),
      phone: data.phone.trim().isEmpty ? null : data.phone.trim(),
      email: data.email.trim().isEmpty ? null : data.email.trim(),
      suburb: data.suburb.trim().isEmpty ? null : data.suburb.trim(),
    );

    final endpointUrl = await getEndpointUrl();
    if (endpointUrl != null) {
      try {
        if (multiStep) {
          final text = await _generateResumeViaPipeline(
            endpointUrl: endpointUrl,
            data: data,
            tone: tone,
            style: style,
          );
          final trimmed = text.trim();
          if (_looksCopiedOrUnstructured(trimmed, assembledPrompt)) {
            return ResumeGenerationResult(
              resumeText: _generateLocallyFromFormData(data: data, tone: tone, style: style),
              source: 'local',
            );
          }
          return ResumeGenerationResult(resumeText: trimmed, source: 'api');
        }
        final api = await _generateViaApi(
          endpointUrl: endpointUrl,
          input: input,
          style: style,
        );
        if (_looksCopiedOrUnstructured(api.resumeText, assembledPrompt)) {
          return ResumeGenerationResult(
            resumeText: _generateLocallyFromFormData(data: data, tone: tone, style: style),
            source: 'local',
          );
        }
        return api;
      } catch (_) {
        // Fall back to local generation.
      }
    }

    return ResumeGenerationResult(
      resumeText: _generateLocallyFromFormData(data: data, tone: tone, style: style),
      source: 'local',
    );
  }

  static Future<String> generateAchievementBullets({
    required String endpointUrl,
    required String role,
    required String whatDidYouDo,
    required ResumeTone tone,
  }) async {
    final prompt = [
      'You are an expert Australian resume writer.',
      'Write 3–5 ATS-friendly achievement bullet points for this role.',
      'Use strong action verbs and add realistic metrics ONLY if the user provided numbers.',
      'Do not invent employers, dates, certifications, or KPIs.',
      '',
      'Tone: ${tone.name}',
      'Role: $role',
      'User input: $whatDidYouDo',
      '',
      'Output: bullets only, each starting with "• ".',
    ].join('\n');

    final out = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: prompt,
      style: ResumeStyle.modern,
      extra: {
        'task': 'achievement_generator',
      },
    );
    return out.trim();
  }

  static Future<String> generateCoverLetter({
    required String endpointUrl,
    required ResumeFormData data,
    required ResumeTone tone,
    String? existingCoverLetterText,
    String? companyName,
  }) async {
    final effectiveTone = _inferToneForJob(
      explicitTone: tone,
      jobCategory: data.jobCategory,
      targetJobTitle: data.targetJobTitle,
      industry: data.industry,
      jobDescription: data.targetJobDescription,
    );

    final templateName = _coverLetterTemplateName(
      tone: effectiveTone,
      jobCategory: data.jobCategory,
    );

    final jd = (data.targetJobDescription ?? '').trim();
    final profile = _buildGuidedPrompt(data: data, tone: effectiveTone);

    // If job description is missing, we can still generate a decent letter, but it won't be as tailored.
    // Keep it as a smaller single-shot request.
    if (jd.isEmpty) {
      final out = await _generateTextViaApi(
        endpointUrl: endpointUrl,
        prompt: [
          'You are an expert Australian cover letter writer.',
          'Write a professional cover letter using the proven structure:',
          '1) Intro: who I am + role + interest',
          '2) Fit: skills/experience + 2 achievements written as mini STAR examples (no invented facts)',
          '3) Company: personalize WITHOUT inventing details (use general interest)',
          '4) Closing: availability + call to action',
          '',
          'ATS constraints: plain text, no tables, no markdown, 280–420 words.',
          'STAR requirement: include 2 mini STAR examples inside paragraph 2 (2–4 sentences each).',
          'Hard rule: do NOT copy any input sentences verbatim; rewrite in your own words.',
          'Use template: $templateName',
          'Tone: ${effectiveTone.name}',
          if ((companyName ?? '').trim().isNotEmpty) 'Company: ${companyName!.trim()}',
          '',
          if ((existingCoverLetterText ?? '').trim().isNotEmpty) ...[
            'IMPROVE MODE: Rewrite and improve this existing cover letter:',
            existingCoverLetterText!.trim(),
            '',
          ],
          'Candidate resume/profile (structured):',
          profile,
          '',
          'Output: cover letter text only.',
        ].join('\n'),
        style: ResumeStyle.modern,
        extra: {'task': 'cover_letter_single_shot'},
      );

      final trimmed = out.trim();
      if (trimmed.isEmpty) return _generateCoverLetterLocally(data: data, tone: effectiveTone, companyName: companyName);
      return trimmed;
    }

    // Multi-step pipeline (better quality + less copying)

    // Stage 1: extract job signals
    final s1 = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: [
        'Stage 1: Read the job description and extract the essentials.',
        'Output format (plain text, headings allowed):',
        'REQUIRED SKILLS: (5–10 bullets)',
        'RESPONSIBILITIES: (5–10 bullets)',
        'ATS KEYWORDS: (10–18 comma-separated keywords)',
        'TONE: (one of: corporate, hospitality, cleaning, retail, IT, student)',
        'Hard rules: do NOT paste large chunks of the job description verbatim; summarize.',
        '',
        'Job description:',
        jd,
      ].join('\n'),
      style: ResumeStyle.modern,
      extra: {'pipelineStage': 1, 'task': 'cover_letter_extract_job'},
    );

    // Stage 2: extract candidate highlights
    final s2 = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: [
        'Stage 2: Extract the candidate\'s strongest, job-relevant points from the profile.',
        'Output:',
        'TOP MATCHING SKILLS: (5–10 bullets)',
        'BEST ACHIEVEMENTS: (3–6 bullets, written as achievements with outcomes)',
        'STAR STORIES: write 2 mini STAR examples based ONLY on the resume/profile (no invented facts).',
        'Format:',
        'STAR STORY 1:',
        'S: ...',
        'T: ...',
        'A: ...',
        'R: ...',
        'STAR STORY 2:',
        'S: ...',
        'T: ...',
        'A: ...',
        'R: ...',
        'AVAILABILITY/WORK RIGHTS: (1–2 bullets if provided)',
        'Hard rules: do NOT copy any sentences verbatim from the input; rewrite. Do NOT invent employers, dates, or numbers.',
        '',
        'Candidate resume/profile:',
        profile,
        '',
        'Job signals:',
        s1.trim(),
      ].join('\n'),
      style: ResumeStyle.modern,
      extra: {'pipelineStage': 2, 'task': 'cover_letter_extract_candidate'},
    );

    // Stage 3: match evidence to keywords
    final s3 = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: [
        'Stage 3: Match candidate evidence to the job requirements.',
        'Output: 6–10 bullets, each in the format:',
        'KEYWORD → evidence from candidate (short, factual)',
        'Hard rules: do NOT invent facts; do NOT paste job description lines.',
        '',
        'Job signals:',
        s1.trim(),
        '',
        'Candidate highlights:',
        s2.trim(),
      ].join('\n'),
      style: ResumeStyle.modern,
      extra: {'pipelineStage': 3, 'task': 'cover_letter_match'},
    );

    // Stage 4: draft letter using proven structure
    final s4 = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: [
        'Stage 4: Write the full cover letter (Australian English).',
        'Structure (must follow):',
        'Paragraph 1 — Introduction (who you are + role + interest)',
        'Paragraph 2 — Why you\'re a strong fit (skills/experience + 2 mini STAR examples from the resume/profile)',
        'Paragraph 3 — Why THIS company (personalize using job signals/values; no invented facts)',
        'Paragraph 4 — Closing (appreciation + availability + call to action)',
        '',
        'ATS constraints: plain text only, no tables, no markdown, 280–420 words.',
        'Hard rules:',
        '- Do NOT copy any input sentences verbatim.',
        '- Do NOT paste the job description.',
        '- Do NOT invent employers, certificates, or metrics.',
        '- STAR method: integrate two STAR mini-stories as part of Paragraph 2. Each should be 2–4 sentences and clearly show the Result.',
        '',
        'Template: $templateName',
        'Tone: ${effectiveTone.name}',
        if ((companyName ?? '').trim().isNotEmpty) 'Company: ${companyName!.trim()}',
        '',
        if ((existingCoverLetterText ?? '').trim().isNotEmpty) ...[
          'IMPROVE MODE: Rewrite and improve this existing cover letter, keeping true facts:',
          existingCoverLetterText!.trim(),
          '',
        ],
        'Job signals:',
        s1.trim(),
        '',
        'Candidate highlights:',
        s2.trim(),
        '',
        'Matched evidence:',
        s3.trim(),
        '',
        'Output: cover letter text only. No bullet lists; use professional paragraphs.',
      ].join('\n'),
      style: ResumeStyle.modern,
      extra: {'pipelineStage': 4, 'task': 'cover_letter_draft'},
    );

    // Stage 5: final rewrite / ATS polish
    final s5 = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: [
        'Stage 5: Polish the cover letter for clarity and ATS.',
        'Rules:',
        '- Keep 280–420 words',
        '- Remove repetition',
        '- Keep language job-relevant',
        '- Do not add any facts',
        '- Do not include markdown or tables',
        'Tone must match: ${effectiveTone.name}',
        'Template: $templateName',
        'STAR method must remain present (2 mini STAR examples).',
        '',
        'Draft letter:',
        s4.trim(),
        '',
        'Output: final cover letter only.',
      ].join('\n'),
      style: ResumeStyle.modern,
      extra: {'pipelineStage': 5, 'task': 'cover_letter_polish'},
    );

    final finalText = s5.trim();
    if (finalText.isEmpty) {
      return _generateCoverLetterLocally(data: data, tone: effectiveTone, companyName: companyName);
    }
    return finalText;
  }

  static ResumeTone _inferToneForJob({
    required ResumeTone explicitTone,
    required String? jobCategory,
    required String? targetJobTitle,
    required String? industry,
    required String? jobDescription,
  }) {
    final c = (jobCategory ?? '').trim().toLowerCase();
    if (c.isNotEmpty) {
      if (c.contains('restaurant')) return ResumeTone.hospitalityFriendly;
      if (c.contains('grocery')) return ResumeTone.retailFriendly;
      if (c.contains('clean')) return ResumeTone.professionalCorporate;
      if (c.contains('cash')) return ResumeTone.studentFriendly;
      if (c.contains('student')) return ResumeTone.studentFriendly;
      if (c.contains('community')) return ResumeTone.professionalCorporate;
    }

    final blob = [targetJobTitle, industry, jobDescription].whereType<String>().join(' ').toLowerCase();
    if (blob.contains('barista') || blob.contains('wait') || blob.contains('kitchen') || blob.contains('cafe') || blob.contains('restaurant')) {
      return ResumeTone.hospitalityFriendly;
    }
    if (blob.contains('retail') || blob.contains('cashier') || blob.contains('customer') || blob.contains('supermarket') || blob.contains('store')) {
      return ResumeTone.retailFriendly;
    }
    if (blob.contains('it') || blob.contains('developer') || blob.contains('software') || blob.contains('support') || blob.contains('helpdesk')) {
      return ResumeTone.itTech;
    }
    if (blob.contains('student') || blob.contains('part-time') || blob.contains('casual')) {
      return ResumeTone.studentFriendly;
    }
    if (blob.contains('clean') || blob.contains('housekeep') || blob.contains('janitor')) {
      return ResumeTone.professionalCorporate;
    }

    return explicitTone;
  }

  static String _coverLetterTemplateName({
    required ResumeTone tone,
    required String? jobCategory,
  }) {
    final c = (jobCategory ?? '').trim();
    if (c.isNotEmpty) return c;

    switch (tone) {
      case ResumeTone.hospitalityFriendly:
        return 'Hospitality cover letter';
      case ResumeTone.retailFriendly:
        return 'Retail cover letter';
      case ResumeTone.itTech:
        return 'IT cover letter';
      case ResumeTone.studentFriendly:
        return 'Student cover letter';
      case ResumeTone.minimalistModern:
        return 'Minimalist professional cover letter';
      case ResumeTone.professionalCorporate:
        return 'Corporate cover letter';
    }
  }

  static String generateCoverLetterLocally({
    required ResumeFormData data,
    required ResumeTone tone,
    String? companyName,
  }) {
    final role = (data.targetJobTitle ?? '').trim().isNotEmpty ? data.targetJobTitle!.trim() : 'the advertised role';
    final company = (companyName ?? '').trim().isNotEmpty ? companyName!.trim() : 'your team';
    final name = data.fullName.trim().isNotEmpty ? data.fullName.trim() : 'Your Name';
    final suburb = data.suburb.trim();

    final skillLine = (data.highlightSkills ?? data.skills).trim();
    final skills = skillLine.isEmpty
        ? const <String>[]
        : skillLine
            .split(RegExp(r'[,\n]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .take(5)
            .toList();

    String toneLine;
    switch (tone) {
      case ResumeTone.hospitalityFriendly:
        toneLine = 'friendly, customer-focused, and calm during busy shifts';
        break;
      case ResumeTone.retailFriendly:
        toneLine = 'helpful, reliable, and strong in teamwork and customer service';
        break;
      case ResumeTone.itTech:
        toneLine = 'structured, detail-oriented, and focused on troubleshooting and documentation';
        break;
      case ResumeTone.studentFriendly:
        toneLine = 'reliable, eager to learn, and flexible with shifts';
        break;
      case ResumeTone.minimalistModern:
        toneLine = 'clear, professional, and results-focused';
        break;
      case ResumeTone.professionalCorporate:
        toneLine = 'professional, dependable, and focused on quality outcomes';
        break;
    }

    final p1 = 'Dear Hiring Manager,\n\nI am writing to apply for $role. I am a $toneLine candidate${suburb.isNotEmpty ? ' based in $suburb' : ''}, and I am interested in contributing to $company.';

    final p2a = skills.isNotEmpty
        ? 'My strengths include ${skills.join(', ')}. I work well in fast-paced environments, follow procedures, and support the team to deliver consistent results.'
        : 'My strengths include reliability, clear communication, and a strong work ethic. I work well in fast-paced environments, follow procedures, and support the team to deliver consistent results.';

    // Best-effort STAR-style example from structured entries (no invented numbers).
    String? star;
    final entries = data.experienceEntries ?? const <ResumeExperienceEntry>[];
    if (entries.isNotEmpty) {
      final e = entries.first;
      final focus = [e.achievements, e.responsibilities]
          .where((s) => s.trim().isNotEmpty)
          .join(' ')
          .trim();
      if (focus.isNotEmpty) {
        star = 'For example, in my role as ${e.jobTitle}${e.company.trim().isEmpty ? '' : ' at ${e.company.trim()}'}, I supported busy operations by ${focus.length > 140 ? '${focus.substring(0, 140).trimRight()}…' : focus}. This demonstrates my ability to take ownership, follow standards, and deliver reliable outcomes.';
      }
    }

    final p2 = star == null ? p2a : '$p2a\n\n$star';

    final p3 = 'I am particularly interested in this opportunity because it aligns with my goal: ${data.careerGoal.trim().isEmpty ? 'to build a long-term role and contribute to a strong team' : data.careerGoal.trim()}. I would welcome the chance to discuss how I can support your business and meet the expectations in the job description.';

    final p4 = 'Thank you for your time and consideration. I am available ${data.availability.trim().isEmpty ? 'to start as discussed' : data.availability.trim()} and can be contacted on ${data.phone.trim().isEmpty ? 'your preferred contact method' : data.phone.trim()} or ${data.email.trim().isEmpty ? 'email' : data.email.trim()}.\n\nKind regards,\n$name';

    return [p1, p2, p3, p4].join('\n\n');
  }

  // Back-compat alias for older call sites.
  static String _generateCoverLetterLocally({
    required ResumeFormData data,
    required ResumeTone tone,
    String? companyName,
  }) {
    return generateCoverLetterLocally(
      data: data,
      tone: tone,
      companyName: companyName,
    );
  }

  static Future<String> generateInterviewPrep({
    required String endpointUrl,
    required ResumeFormData data,
    required ResumeTone tone,
  }) async {
    final prompt = [
      'You are an interview coach in Australia.',
      'Generate interview preparation for the target role.',
      'Do not invent facts.',
      '',
      'Tone: ${tone.name}',
      'Target job title: ${data.targetJobTitle ?? ''}',
      if ((data.targetJobDescription ?? '').trim().isNotEmpty) 'Job description:\n${data.targetJobDescription}',
      '',
      'Provide:',
      '1) 8 interview questions (mix behavioural + role-specific)',
      '2) 3 STAR answer outlines based on the user\'s experience summary',
      '3) 30-second elevator pitch',
      '4) What to say when calling the employer (script, 4–6 lines)',
      '',
      'User experience summary: ${data.summary}',
    ].join('\n');

    final out = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: prompt,
      style: ResumeStyle.modern,
      extra: {
        'task': 'interview_prep',
      },
    );
    return out.trim();
  }

  static Future<String> generateSkillGapSuggestions({
    required String endpointUrl,
    required ResumeFormData data,
    required ResumeTone tone,
  }) async {
    final prompt = [
      'Analyze skill gaps for a job application in Australia.',
      'Compare the job description vs the candidate experience.',
      'Return practical suggestions only.',
      '',
      'Tone: ${tone.name}',
      '',
      'Candidate skills: ${data.skills}',
      'Candidate experience summary: ${data.summary}',
      '',
      'Job description:\n${data.targetJobDescription ?? ''}',
      '',
      'Output sections:',
      'SKILLS YOU HAVE',
      'SKILLS TO IMPROVE',
      'COURSES/CERTIFICATIONS (Australia-friendly)',
    ].join('\n');

    final out = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: prompt,
      style: ResumeStyle.modern,
      extra: {
        'task': 'skill_gap',
      },
    );
    return out.trim();
  }

  static Future<ResumeGenerationResult> _generateViaApi({
    required String endpointUrl,
    required ResumePromptInput input,
    required ResumeStyle style,
  }) async {
    final uri = Uri.parse(endpointUrl);

    final payload = {
      'style': style.name,
      'locale': 'en-AU',
      'format': 'plain_text',
      'atsFriendly': true,
      'professionalTone': true,
      'input': input.toJson(),
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
      throw Exception('Resume API failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resume API returned invalid JSON');
    }

    final resumeText = decoded['resumeText'];
    if (resumeText is! String || resumeText.trim().isEmpty) {
      throw Exception('Resume API missing resumeText');
    }

    return ResumeGenerationResult(resumeText: resumeText.trim(), source: 'api');
  }

  static Future<String> _generateTextViaApi({
    required String endpointUrl,
    required String prompt,
    required ResumeStyle style,
    Map<String, dynamic>? extra,
  }) async {
    final uri = Uri.parse(endpointUrl);

    final payload = {
      'style': style.name,
      'locale': 'en-AU',
      'format': 'plain_text',
      'atsFriendly': true,
      'professionalTone': true,
      'input': {
        'prompt': prompt,
      },
      if (extra != null) ...extra,
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
      throw Exception('Resume API failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resume API returned invalid JSON');
    }

    final resumeText = decoded['resumeText'];
    if (resumeText is! String || resumeText.trim().isEmpty) {
      throw Exception('Resume API missing resumeText');
    }

    return resumeText;
  }

  static Future<String> _generateResumeViaPipeline({
    required String endpointUrl,
    required ResumeFormData data,
    required ResumeTone tone,
    required ResumeStyle style,
  }) async {
    final baseProfile = _buildGuidedPrompt(data: data, tone: tone);

    // Stage 1 — extract key skills
    final s1 = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: [
        'Stage 1: Extract the top 10–15 skills from the candidate profile and job description.',
        'Hard rule: do NOT copy sentences verbatim from the input; extract/normalize skills only.',
        'Output: one skill per line, no extra text.',
        '',
        baseProfile,
      ].join('\n'),
      style: style,
      extra: {'pipelineStage': 1, 'task': 'extract_skills'},
    );

    // Stage 2 — STAR achievements
    final s2 = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: [
        'Stage 2: Rewrite achievements using the STAR method (Situation/Task/Action/Result) into strong resume bullets.',
        'Rules: do not invent facts or numbers. Use user-provided metrics only. Output bullets only.',
        'Hard rule: do NOT copy input sentences verbatim; rewrite professionally.',
        '',
        'Extracted skills:\n$s1',
        '',
        baseProfile,
      ].join('\n'),
      style: style,
      extra: {'pipelineStage': 2, 'task': 'star_achievements'},
    );

    // Stage 3 — professional summary
    final s3 = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: [
        'Stage 3: Write a professional summary (3–5 lines) tailored to the target role.',
        'Rules: ATS-friendly plain text. No invented facts.',
        'Hard rule: do NOT copy the candidate profile text verbatim; rewrite in your own words.',
        '',
        'Extracted skills:\n$s1',
        '',
        baseProfile,
      ].join('\n'),
      style: style,
      extra: {'pipelineStage': 3, 'task': 'summary'},
    );

    // Stage 4 — build the resume
    final s4 = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: [
        'Stage 4: Build the full ATS-friendly resume in Australian style.',
        'Constraints: plain text, no tables/columns, consistent bullets, 1–2 pages.',
        'Use headings: FULL NAME, CONTACT, PROFESSIONAL SUMMARY, KEY SKILLS, WORK EXPERIENCE, EDUCATION, CERTIFICATIONS, AVAILABILITY/WORK RIGHTS, REFERENCES.',
        'Do not invent employers/dates/qualifications. If missing, omit safely or use placeholders.',
        'Hard rule: do NOT copy any sentences verbatim from the input profile; transform into a real resume.',
        '',
        'Professional summary:\n$s3',
        '',
        'STAR bullets:\n$s2',
        '',
        'Extracted skills:\n$s1',
        '',
        baseProfile,
      ].join('\n'),
      style: style,
      extra: {'pipelineStage': 4, 'task': 'build_resume'},
    );

    // Stage 5 — tailor to job description (optional)
    final jd = (data.targetJobDescription ?? '').trim();
    if (jd.isEmpty) return s4;

    final s5 = await _generateTextViaApi(
      endpointUrl: endpointUrl,
      prompt: [
        'Stage 5: Tailor the resume to the job description for ATS.',
        'Goals: highlight relevant skills, remove irrelevant content, add keywords naturally.',
        'Rules: do not invent facts.',
        'Hard rule: do NOT paste/copy the job description; incorporate keywords naturally.',
        '',
        'Job description:\n$jd',
        '',
        'Current resume:\n$s4',
        '',
        'Output: updated resume only (plain text).',
      ].join('\n'),
      style: style,
      extra: {'pipelineStage': 5, 'task': 'tailor_resume'},
    );

    return s5;
  }

  static bool _looksCopiedOrUnstructured(String output, String input) {
    final out = output.trim();
    if (out.isEmpty) return true;

    // If it already has strong resume structure, accept.
    final upper = out.toUpperCase();
    final hasHeadings = upper.contains('PROFESSIONAL SUMMARY') &&
        upper.contains('KEY SKILLS') &&
        (upper.contains('WORK EXPERIENCE') || upper.contains('EXPERIENCE'));
    if (hasHeadings) return false;

    // Heuristic: if multiple long input lines appear verbatim in output, it's a copy.
    final outLower = out.toLowerCase();
    final inLines = input
        .replaceAll('\r', '\n')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length >= 24)
        .take(14)
        .toList();

    var matches = 0;
    for (final line in inLines) {
      final l = line.toLowerCase();
      if (l.length >= 24 && outLower.contains(l)) {
        matches++;
        if (matches >= 3) return true;
      }
    }

    // If it lacks headings and is mostly paragraph text, treat as unstructured.
    final lines = out.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final longLines = lines.where((l) => l.trim().length >= 110).length;
    if (lines.length <= 8 && longLines >= 2) return true;

    return false;
  }

  static String _buildGuidedPrompt({
    required ResumeFormData data,
    required ResumeTone tone,
  }) {
    final lines = <String>[];

    lines.add('CANDIDATE PROFILE (Australia)');
    lines.add('Tone: ${tone.name}');
    if ((data.targetJobTitle ?? '').trim().isNotEmpty) {
      lines.add('Target job title: ${data.targetJobTitle}');
    }
    if ((data.industry ?? '').trim().isNotEmpty) {
      lines.add('Industry: ${data.industry}');
    }
    if ((data.experienceLevel ?? '').trim().isNotEmpty) {
      lines.add('Experience level: ${data.experienceLevel}');
    }

    lines.add('Career goal: ${data.careerGoal.trim()}');
    if (data.strengths != null && data.strengths!.trim().isNotEmpty) {
      lines.add('Strengths: ${data.strengths!.trim()}');
    }
    if (data.personalityTraits != null && data.personalityTraits!.trim().isNotEmpty) {
      lines.add('Personality traits: ${data.personalityTraits!.trim()}');
    }
    if (data.workStyle != null && data.workStyle!.trim().isNotEmpty) {
      lines.add('Work style: ${data.workStyle!.trim()}');
    }
    if (data.proudAchievements != null && data.proudAchievements!.trim().isNotEmpty) {
      lines.add('Proud achievements: ${data.proudAchievements!.trim()}');
    }

    if ((data.highlightSkills ?? '').trim().isNotEmpty) {
      lines.add('Skills to highlight: ${data.highlightSkills!.trim()}');
    }

    lines.add('Skills (raw): ${data.skills.trim()}');
    lines.add('Summary (raw): ${data.summary.trim()}');

    final existing = (data.existingResumeText ?? '').trim();
    if (existing.isNotEmpty) {
      lines.add('EXISTING RESUME (user-provided)');
      lines.add(existing);
    }

    if (data.experienceEntries != null && data.experienceEntries!.isNotEmpty) {
      lines.add('EXPERIENCE ENTRIES (structured)');
      for (final e in data.experienceEntries!) {
        lines.add('- Role: ${e.jobTitle}'.trim());
        if (e.company.trim().isNotEmpty) lines.add('  Company: ${e.company}'.trim());
        if (e.dates.trim().isNotEmpty) lines.add('  Dates: ${e.dates}'.trim());
        if (e.responsibilities.trim().isNotEmpty) {
          lines.add('  Responsibilities: ${e.responsibilities}'.trim());
        }
        if (e.achievements.trim().isNotEmpty) {
          lines.add('  Achievements: ${e.achievements}'.trim());
        }
        if (e.toolsUsed.trim().isNotEmpty) lines.add('  Tools: ${e.toolsUsed}'.trim());
        if (e.metrics.trim().isNotEmpty) lines.add('  Metrics: ${e.metrics}'.trim());
      }
    } else {
      lines.add('WORK EXPERIENCE (raw)');
      lines.add(data.workExperience.trim());
    }

    lines.add('EDUCATION (raw)');
    lines.add(data.education.trim());
    lines.add('CERTIFICATIONS (raw)');
    lines.add(data.certifications.trim());
    lines.add('LANGUAGES (raw)');
    lines.add(data.languages.trim());
    lines.add('AVAILABILITY (raw)');
    lines.add(data.availability.trim());
    if ((data.visaStatus ?? '').trim().isNotEmpty) {
      lines.add('WORK RIGHTS / VISA');
      lines.add(data.visaStatus!.trim());
    }

    final jd = (data.targetJobDescription ?? '').trim();
    if (jd.isNotEmpty) {
      lines.add('TARGET JOB DESCRIPTION');
      lines.add(jd);
    }

    return lines.join('\n').trim();
  }

  static String _generateLocally({
    required ResumePromptInput input,
    required ResumeStyle style,
  }) {
    final prompt = input.prompt.trim();

    final suggestedSkills = AiResumeSkillSuggester.suggestSkills(
      prompt,
      maxSuggestions: 12,
    );
    final explicitSkills = _extractExplicitSkills(prompt);
    final keywords = AiResumeAtsOptimizer.extractKeywords(
      prompt,
      maxKeywords: 18,
    );

    final mergedSkills = AiResumeAtsOptimizer.optimizeKeySkills(
      explicitSkills: explicitSkills,
      suggestedSkills: suggestedSkills,
      keywords: keywords,
      maxSkills: 15,
    );

    final experiences = _extractExperiences(prompt);

    final inferredRole = _inferTargetRoleFromText(prompt) ?? (experiences.isNotEmpty ? experiences.first.role : null);
    final inferredYears = _inferYearsOfExperience(prompt);
    final topSkills = mergedSkills.take(6).toList();

    final buffer = StringBuffer();

    // Header
    buffer.writeln('FULL NAME');
    buffer.writeln((input.fullName ?? '').trim().isEmpty ? 'Your Name' : input.fullName!.trim());
    buffer.writeln();
    buffer.writeln('CONTACT');
    final contactParts = <String>[];
    if ((input.suburb ?? '').trim().isNotEmpty) contactParts.add(input.suburb!.trim());
    if ((input.phone ?? '').trim().isNotEmpty) contactParts.add(input.phone!.trim());
    if ((input.email ?? '').trim().isNotEmpty) contactParts.add(input.email!.trim());
    buffer.writeln(contactParts.isEmpty ? 'Phone • Email • Location' : contactParts.join(' • '));
    buffer.writeln();

    buffer.writeln('PROFESSIONAL SUMMARY');
    buffer.writeln(_buildLocalSummary(
      role: inferredRole,
      years: inferredYears,
      suburb: input.suburb,
      topSkills: topSkills,
    ));
    buffer.writeln();

    if (mergedSkills.isNotEmpty) {
      buffer.writeln('KEY SKILLS');
      for (final s in mergedSkills) {
        buffer.writeln('• $s');
      }
      buffer.writeln();
    }

    if (experiences.isNotEmpty) {
      buffer.writeln('WORK EXPERIENCE');
      for (final exp in experiences.take(3)) {
        final headerParts = <String>[];
        if (exp.role.trim().isNotEmpty) headerParts.add(exp.role.trim());
        if (exp.company.trim().isNotEmpty) headerParts.add(exp.company.trim());
        final header = headerParts.join(' — ');
        buffer.writeln(header.isEmpty ? 'Experience' : header);

        final duties = AiResumeDutySuggester.suggestDutiesForRole(exp.role);
        for (final d in duties.take(5)) {
          buffer.writeln('• $d');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('REFERENCES');
    buffer.writeln('Available on request.');
    buffer.writeln();

    // Very small style-specific tweak (kept local generation simple & ATS-safe).
    if (style == ResumeStyle.creative) {
      buffer.writeln('NOTE');
      buffer.writeln('Portfolio available on request.');
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  static String _generateLocallyFromFormData({
    required ResumeFormData data,
    required ResumeTone tone,
    required ResumeStyle style,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('FULL NAME');
    buffer.writeln(data.fullName.trim().isEmpty ? 'Your Name' : data.fullName.trim());
    buffer.writeln();

    buffer.writeln('CONTACT');
    final contactParts = <String>[];
    if (data.suburb.trim().isNotEmpty) contactParts.add(data.suburb.trim());
    if (data.phone.trim().isNotEmpty) contactParts.add(data.phone.trim());
    if (data.email.trim().isNotEmpty) contactParts.add(data.email.trim());
    buffer.writeln(contactParts.isEmpty ? 'Phone • Email • Location' : contactParts.join(' • '));
    buffer.writeln();

    final topSkills = _splitToItems(data.highlightSkills ?? data.skills).take(8).toList();

    buffer.writeln('PROFESSIONAL SUMMARY');
    buffer.writeln(_buildLocalSummary(
      role: data.targetJobTitle,
      years: _inferYearsOfExperience(data.experienceLevel ?? ''),
      suburb: data.suburb,
      topSkills: topSkills,
      goal: data.careerGoal,
      strengths: data.strengths,
      tone: tone,
    ));
    buffer.writeln();

    if (topSkills.isNotEmpty) {
      buffer.writeln('KEY SKILLS');
      for (final s in topSkills) {
        buffer.writeln('• $s');
      }
      buffer.writeln();
    }

    buffer.writeln('WORK EXPERIENCE');
    if (data.experienceEntries != null && data.experienceEntries!.isNotEmpty) {
      for (final e in data.experienceEntries!.take(5)) {
        final headerParts = <String>[];
        if (e.jobTitle.trim().isNotEmpty) headerParts.add(e.jobTitle.trim());
        if (e.company.trim().isNotEmpty) headerParts.add(e.company.trim());
        final header = headerParts.join(' — ');
        buffer.writeln(header.isEmpty ? 'Experience' : header);
        if (e.dates.trim().isNotEmpty) {
          buffer.writeln(e.dates.trim());
        }

        final bullets = <String>[
          ..._splitToItems(e.achievements),
          ..._splitToItems(e.responsibilities),
        ];

        if (bullets.isNotEmpty) {
          for (final b in bullets.take(6)) {
            buffer.writeln('• ${_polishLocalBullet(b)}');
          }
        } else {
          final duties = AiResumeDutySuggester.suggestDutiesForRole(e.jobTitle);
          for (final d in duties.take(5)) {
            buffer.writeln('• $d');
          }
        }
        buffer.writeln();
      }
    } else if (data.workExperience.trim().isNotEmpty) {
      for (final line in _splitToItems(data.workExperience)) {
        buffer.writeln('• ${_polishLocalBullet(line)}');
      }
      buffer.writeln();
    } else {
      buffer.writeln('• Experience details available on request.');
      buffer.writeln();
    }

    if (data.education.trim().isNotEmpty) {
      buffer.writeln('EDUCATION');
      for (final item in _splitToItems(data.education)) {
        buffer.writeln('• ${_polishLocalBullet(item)}');
      }
      buffer.writeln();
    }

    if (data.certifications.trim().isNotEmpty) {
      buffer.writeln('CERTIFICATIONS');
      for (final item in _splitToItems(data.certifications)) {
        buffer.writeln('• ${_polishLocalBullet(item)}');
      }
      buffer.writeln();
    }

    if (data.languages.trim().isNotEmpty) {
      buffer.writeln('LANGUAGES');
      for (final item in _splitToItems(data.languages)) {
        buffer.writeln('• ${_polishLocalBullet(item)}');
      }
      buffer.writeln();
    }

    if (data.availability.trim().isNotEmpty || (data.visaStatus ?? '').trim().isNotEmpty) {
      buffer.writeln('AVAILABILITY / WORK RIGHTS');
      if (data.availability.trim().isNotEmpty) {
        buffer.writeln('• Availability: ${data.availability.trim()}');
      }
      if ((data.visaStatus ?? '').trim().isNotEmpty) {
        buffer.writeln('• Work rights: ${data.visaStatus!.trim()}');
      }
      buffer.writeln();
    }

    buffer.writeln('REFERENCES');
    buffer.writeln('Available on request.');
    buffer.writeln();

    // Small style-specific tweak (kept ATS-safe).
    if (style == ResumeStyle.creative) {
      buffer.writeln('NOTE');
      buffer.writeln('Portfolio available on request.');
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  static List<String> _splitToItems(String raw) {
    final cleaned = raw.replaceAll('\r', '\n').trim();
    if (cleaned.isEmpty) return const [];
    final parts = cleaned
        .split(RegExp(r'(\n+|\u2022|\*\s+|\-\s+|,|;)'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return _dedupePreserveOrder(parts);
  }

  static String _polishLocalBullet(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return t;
    t = t.replaceAll(RegExp(r'^[•\-*]+\s*'), '').trim();

    // Remove first-person framing.
    t = t.replaceAll(RegExp(r"^(i\s+|i'm\s+|i\s+have\s+)", caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\bresponsible\s+for\b', caseSensitive: false), 'Managed');
    t = t.replaceAll(RegExp(r'\bhelped\b', caseSensitive: false), 'Assisted');

    // If it doesn't start with a verb-like word, add a safe action verb.
    final startsWithWord = RegExp(r'^[A-Za-z]').hasMatch(t);
    final looksLikeVerb = RegExp(r'^(Delivered|Provided|Managed|Assisted|Supported|Maintained|Prepared|Handled|Operated|Coordinated|Completed|Improved|Ensured)\b')
        .hasMatch(t);
    if (startsWithWord && !looksLikeVerb) {
      t = 'Delivered $t';
    }

    // Sentence-style punctuation.
    if (!t.endsWith('.') && !t.endsWith(')')) {
      t = '$t.';
    }
    return t;
  }

  static String? _inferTargetRoleFromText(String raw) {
    final text = raw.replaceAll('\r', '\n');
    for (final re in <RegExp>[
      RegExp(r'^\s*target\s+job\s+title\s*:\s*(.+)$', multiLine: true, caseSensitive: false),
      RegExp(r'^\s*goal\s*:\s*(.+)$', multiLine: true, caseSensitive: false),
      RegExp(r'^\s*role\s*:\s*(.+)$', multiLine: true, caseSensitive: false),
    ]) {
      final m = re.firstMatch(text);
      final g = m?.group(1)?.trim();
      if (g != null && g.isNotEmpty) return g;
    }
    return null;
  }

  static int? _inferYearsOfExperience(String raw) {
    final m = RegExp(r'(\d{1,2})\s*(?:\+\s*)?(?:years|yrs)\b', caseSensitive: false).firstMatch(raw);
    if (m == null) return null;
    final v = int.tryParse(m.group(1) ?? '');
    return v;
  }

  static String _buildLocalSummary({
    required String? role,
    required int? years,
    required String? suburb,
    required List<String> topSkills,
    String? goal,
    String? strengths,
    ResumeTone? tone,
  }) {
    final safeRole = (role ?? '').trim();
    final safeGoal = (goal ?? '').trim();
    final safeSuburb = (suburb ?? '').trim();
    final safeStrengths = (strengths ?? '').trim();

    final parts = <String>[];

    final openerRole = safeRole.isNotEmpty ? safeRole : 'candidate';
    final yearsText = (years != null && years > 0) ? ' with $years+ years of experience' : '';
    parts.add('Reliable $openerRole$yearsText in fast-paced Australian workplaces.');

    if (topSkills.isNotEmpty) {
      parts.add('Known for ${topSkills.take(4).join(', ')} with a strong focus on quality, safety, and teamwork.');
    } else if (safeStrengths.isNotEmpty) {
      parts.add('Known for $safeStrengths with a strong focus on quality, safety, and teamwork.');
    }

    if (safeGoal.isNotEmpty) {
      parts.add('Seeking $safeGoal${safeSuburb.isNotEmpty ? ' in $safeSuburb' : ''}.');
    } else if (safeRole.isNotEmpty) {
      parts.add('Seeking a ${safeRole.toLowerCase()} role${safeSuburb.isNotEmpty ? ' in $safeSuburb' : ''}.');
    }

    // Small tone nuance (still ATS-safe and plain).
    if (tone == ResumeTone.hospitalityFriendly || tone == ResumeTone.retailFriendly) {
      parts.add('Customer-focused, friendly, and reliable during busy shifts.');
    }
    if (tone == ResumeTone.itTech) {
      parts.add('Comfortable with troubleshooting, documentation, and continuous improvement.');
    }

    return parts.join('\n');
  }

  static List<_ExtractedExperience> _extractExperiences(String raw) {
    final text = raw.replaceAll('\r', '\n');

    // Collect in order of appearance.
    final out = <_ExtractedExperience>[];
    final seen = <String>{};

    void add(String role, String company) {
      final r = role.trim();
      final c = company.trim();
      if (r.isEmpty && c.isEmpty) return;
      final key = '${r.toLowerCase()}|${c.toLowerCase()}';
      if (!seen.add(key)) return;
      out.add(_ExtractedExperience(role: r, company: c));
    }

    // Pattern 1: "Retail Assistant at ALDI" / "worked as ... at ..."
    final re1 = RegExp(
      r'(?:worked\s+as|work\s+as|experience\s+as|as)\s+([^\n,]{2,60}?)\s+(?:at|with|for)\s+([^\n,]{2,60})',
      caseSensitive: false,
    );
    for (final m in re1.allMatches(text)) {
      final role = m.group(1) ?? '';
      final company = m.group(2) ?? '';
      add(role, company);
    }

    // Pattern 2 (line-based): "Role @ Company" / "Role - Company" / "Role — Company"
    final lines = text.split('\n');
    for (final line in lines) {
      final t = line.trim();
      if (t.length < 6) continue;

      // Prefer explicit separators.
      final separators = <String>[' @ ', ' - ', ' — ', ' – '];
      for (final sep in separators) {
        final idx = t.indexOf(sep);
        if (idx > 0 && idx < t.length - sep.length) {
          final left = t.substring(0, idx).trim();
          final right = t.substring(idx + sep.length).trim();
          // Avoid capturing "Education - Diploma" etc.
          if (_looksLikeSectionLabel(left) || _looksLikeSectionLabel(right)) {
            continue;
          }
          if (_looksLikeRole(left) && right.isNotEmpty) {
            add(left, right);
          }
        }
      }

      // Pattern 3: "Role at Company" in a single line.
      final lower = t.toLowerCase();
      final atIdx = lower.indexOf(' at ');
      if (atIdx > 0 && atIdx < t.length - 4) {
        final left = t.substring(0, atIdx).trim();
        final right = t.substring(atIdx + 4).trim();
        if (_looksLikeRole(left) && right.isNotEmpty) {
          add(left, right);
        }
      }
    }

    return out;
  }

  static bool _looksLikeSectionLabel(String text) {
    final t = text.trim().toLowerCase();
    return t == 'education' ||
        t == 'skills' ||
        t == 'certifications' ||
        t == 'languages' ||
        t == 'availability' ||
        t == 'summary' ||
        t == 'goal' ||
        t == 'career goal';
  }

  static bool _looksLikeRole(String text) {
    final t = text.trim().toLowerCase();
    if (t.length < 3) return false;
    // Heuristic: require some role-like keyword to reduce false positives.
    const needles = [
      'assistant',
      'retail',
      'cashier',
      'barista',
      'reception',
      'admin',
      'support worker',
      'aged care',
      'driver',
      'delivery',
      'courier',
      'security',
      'guard',
      'warehouse',
      'picker',
      'cleaner',
      'cook',
      'chef',
    ];
    for (final n in needles) {
      if (t.contains(n)) return true;
    }
    return false;
  }

  static List<String> _extractExplicitSkills(String raw) {
    // Heuristic: look for a line starting with "skills:" and parse comma-separated terms.
    final lines = raw.replaceAll('\r', '\n').split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('skills:')) {
        final after = trimmed.substring('skills:'.length).trim();
        final parts = after
            .split(RegExp(r'[,;\u2022\-]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        return _dedupePreserveOrder(parts);
      }
    }

    // Fallback: take short bullet items as potential skills.
    final bullets = _extractBullets(raw)
        .where((b) => b.length <= 40 && !b.contains('.') && !b.contains(':'))
        .toList();
    return _dedupePreserveOrder(bullets);
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

    // De-duplicate while preserving order.
    final seen = <String>{};
    final out = <String>[];
    for (final b in bullets) {
      final key = b.toLowerCase();
      if (b.isNotEmpty && seen.add(key)) out.add(b);
    }
    return out;
  }

}

class _ExtractedExperience {
  final String role;
  final String company;

  const _ExtractedExperience({
    required this.role,
    required this.company,
  });
}
