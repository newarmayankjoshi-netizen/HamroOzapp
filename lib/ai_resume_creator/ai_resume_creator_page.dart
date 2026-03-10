
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_resume_models.dart';
import 'ai_resume_pdf.dart';
import 'ai_resume_preview.dart';
import 'ai_resume_service.dart';
import 'ai_resume_storage.dart';
import 'ai_resume_templates.dart';
import 'saved_resumes_page.dart';

class AiResumeCreatorResult {
  final ResumePromptInput input;
  final ResumeStyle style;
  final ResumeGenerationResult result;
  final Uint8List pdfBytes;
  final String fileName;

  const AiResumeCreatorResult({
    required this.input,
    required this.style,
    required this.result,
    required this.pdfBytes,
    required this.fileName,
  });
}

class _PdfBytesResult {
  final Uint8List bytes;
  final String fileName;

  const _PdfBytesResult({required this.bytes, required this.fileName});
}

class AiResumeCreatorPage extends StatefulWidget {
  final String? initialPrompt;
  final String? initialFullName;
  final String? initialPhone;
  final String? initialEmail;
  final String? initialSuburb;

  /// When true, shows a "done" button on the preview and returns an
  /// [AiResumeCreatorResult] with PDF bytes via `Navigator.pop`.
  final bool returnResultOnDone;

  /// Overrides the done button label when [returnResultOnDone] is true.
  final String? doneButtonText;

  const AiResumeCreatorPage({
    super.key,
    this.initialPrompt,
    this.initialFullName,
    this.initialPhone,
    this.initialEmail,
    this.initialSuburb,
    this.returnResultOnDone = false,
    this.doneButtonText,
  });

  @override
  State<AiResumeCreatorPage> createState() => _AiResumeCreatorPageState();
}

class _AiResumeCreatorPageState extends State<AiResumeCreatorPage> {
  final _formKey = GlobalKey<FormState>();

  final ScrollController _pageScrollController = ScrollController();

  final _promptCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _suburbCtrl = TextEditingController();

  // Guided mode controllers
  final _targetJobTitleCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _highlightSkillsCtrl = TextEditingController();
  final _experienceLevelCtrl = TextEditingController();
  final _jobDescriptionCtrl = TextEditingController();

  final _careerGoalCtrl = TextEditingController();
  final _strengthsCtrl = TextEditingController();
  final _traitsCtrl = TextEditingController();
  final _workStyleCtrl = TextEditingController();
  final _proudAchievementsCtrl = TextEditingController();

  final _summaryCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _workExperienceCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _certificationsCtrl = TextEditingController();
  final _languagesCtrl = TextEditingController();
  final _availabilityCtrl = TextEditingController();
  final _visaCtrl = TextEditingController();
  final _existingResumeCtrl = TextEditingController();

  bool _guidedMode = true;
  int _guidedStep = 0;
  ResumeBuildMode _buildMode = ResumeBuildMode.createNew;
  ResumeTone _tone = ResumeTone.professionalCorporate;
  String? _jobCategory;
  final List<ResumeExperienceEntry> _experienceEntries = <ResumeExperienceEntry>[];

  ResumeStyle _style = ResumeStyle.modern;
  bool _isGenerating = false;
  ResumeGenerationResult? _result;

  static const _lastResumeKey = 'ai_resume_last_text';

  static const _prefsToneKey = 'ai_resume_pref_tone';
  static const _prefsJobCategoryKey = 'ai_resume_pref_job_category';
  static const _prefsHighlightSkillsKey = 'ai_resume_pref_highlight_skills';

  static const List<String> _jobCategories = [
    'Nepalese Restaurant',
    'Grocery Store',
    'Cleaning Job',
    'Cash Job',
    'Student Job',
    'Community Referral',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _prefillFromWidget();
    _guidedMode = (widget.initialPrompt ?? '').trim().isEmpty;
    _loadLastResume();
    _loadPersonalization();
  }

  Future<void> _loadPersonalization() async {
    // Avoid overriding job-tailored quick-prompt flows.
    if ((widget.initialPrompt ?? '').trim().isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final toneName = prefs.getString(_prefsToneKey);
    final cat = prefs.getString(_prefsJobCategoryKey);
    final hs = prefs.getString(_prefsHighlightSkillsKey);
    if (!mounted) return;

    setState(() {
      if (toneName != null) {
        for (final t in ResumeTone.values) {
          if (t.name == toneName) {
            _tone = t;
            break;
          }
        }
      }
      if (cat != null && cat.trim().isNotEmpty) {
        _jobCategory = cat.trim();
      }
      if (hs != null && hs.trim().isNotEmpty && _highlightSkillsCtrl.text.trim().isEmpty) {
        _highlightSkillsCtrl.text = hs.trim();
      }
    });
  }

  Future<void> _savePersonalization() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsToneKey, _tone.name);
    if ((_jobCategory ?? '').trim().isNotEmpty) {
      await prefs.setString(_prefsJobCategoryKey, _jobCategory!.trim());
    }
    final hs = _highlightSkillsCtrl.text.trim();
    if (hs.isNotEmpty) {
      await prefs.setString(_prefsHighlightSkillsKey, hs);
    }
  }

  void _prefillFromWidget() {
    if ((widget.initialPrompt ?? '').trim().isNotEmpty) {
      _promptCtrl.text = widget.initialPrompt!.trim();
    }
    if ((widget.initialFullName ?? '').trim().isNotEmpty) {
      _nameCtrl.text = widget.initialFullName!.trim();
    }
    if ((widget.initialPhone ?? '').trim().isNotEmpty) {
      _phoneCtrl.text = widget.initialPhone!.trim();
    }
    if ((widget.initialEmail ?? '').trim().isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!.trim();
    }
    if ((widget.initialSuburb ?? '').trim().isNotEmpty) {
      _suburbCtrl.text = widget.initialSuburb!.trim();
    }
  }

  Future<void> _loadLastResume() async {
    // If the caller supplied a prompt (ex: job-tailored flow), avoid showing an
    // unrelated previous resume preview.
    if ((widget.initialPrompt ?? '').trim().isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_lastResumeKey);
    if (!mounted) return;
    if (last != null && last.trim().isNotEmpty) {
      setState(() {
        _result = ResumeGenerationResult(resumeText: last.trim(), source: 'saved');
      });
    }
  }

  void _openSavedResumes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedResumesPage()),
    );
  }

  Future<void> _configureAiEndpoint() async {
    final current = await AiResumeService.getEndpointUrl();
    final ctrl = TextEditingController(text: current ?? '');
    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('AI Endpoint Configuration'),
          content: SizedBox(
            width: 700,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the URL of your resume API endpoint. If empty, the app uses a local fallback generator.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Endpoint URL',
                    hintText: 'https://your-api.example.com/resume',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ctrl.text = '';
              },
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;
    await AiResumeService.setEndpointUrl(ctrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ctrl.text.trim().isEmpty
              ? 'AI endpoint cleared. Using local generator.'
              : 'AI endpoint saved.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _promptCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _suburbCtrl.dispose();

    _targetJobTitleCtrl.dispose();
    _industryCtrl.dispose();
    _highlightSkillsCtrl.dispose();
    _experienceLevelCtrl.dispose();
    _jobDescriptionCtrl.dispose();

    _careerGoalCtrl.dispose();
    _strengthsCtrl.dispose();
    _traitsCtrl.dispose();
    _workStyleCtrl.dispose();
    _proudAchievementsCtrl.dispose();

    _summaryCtrl.dispose();
    _skillsCtrl.dispose();
    _workExperienceCtrl.dispose();
    _educationCtrl.dispose();
    _certificationsCtrl.dispose();
    _languagesCtrl.dispose();
    _availabilityCtrl.dispose();
    _visaCtrl.dispose();
    _existingResumeCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _generate() async {
    final valid = _guidedMode
        ? _validateGuidedInputs()
        : (_formKey.currentState?.validate() == true);
    if (!valid) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      ResumeGenerationResult result;
      ResumePromptInput storageInput;

      if (_guidedMode) {
        final form = _buildFormDataFromGuided();
        result = await AiResumeService.generateResumeFromFormData(
          data: form,
          style: _style,
          tone: _tone,
          multiStep: true,
        );

        // Store a reproducible prompt snapshot for history.
        storageInput = ResumePromptInput(
          prompt: _buildGuidedStoragePrompt(form),
          fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          suburb: _suburbCtrl.text.trim().isEmpty ? null : _suburbCtrl.text.trim(),
        );
      } else {
        final input = ResumePromptInput(
          prompt: _promptCtrl.text.trim(),
          fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          suburb: _suburbCtrl.text.trim().isEmpty ? null : _suburbCtrl.text.trim(),
        );

        result = await AiResumeService.generateResumeFromPrompt(
          input: input,
          style: _style,
        );
        storageInput = input;
      }

      await AiResumeStorage.add(input: storageInput, style: _style, result: result);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastResumeKey, result.resumeText);
      if (_guidedMode) {
        // Best-effort personalization memory.
        await _savePersonalization();
      }

      if (!mounted) return;
      setState(() {
        _result = result;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.source == 'api'
                ? 'Resume generated (AI endpoint)'
                : 'Resume generated (local fallback)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate resume: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  bool _validateGuidedInputs() {
    final goal = _careerGoalCtrl.text.trim();
    final hasWork = _experienceEntries.isNotEmpty || _workExperienceCtrl.text.trim().isNotEmpty;
    if (goal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your career goal.')),
      );
      return false;
    }

    if (_buildMode == ResumeBuildMode.improveExisting && _existingResumeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste your existing resume to use Improve mode.')),
      );
      return false;
    }

    if (!hasWork) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one experience entry (or paste work experience).')),
      );
      return false;
    }

    final hasSkills = _skillsCtrl.text.trim().isNotEmpty || _highlightSkillsCtrl.text.trim().isNotEmpty;
    if (!hasSkills) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a few skills to highlight (or fill Skills).')),
      );
      return false;
    }

    return true;
  }

  String _buildGuidedStoragePrompt(ResumeFormData form) {
    final parts = <String>[];
    parts.add('GUIDED RESUME INPUT');
    if ((form.targetJobTitle ?? '').trim().isNotEmpty) parts.add('Target: ${form.targetJobTitle}');
    if ((form.industry ?? '').trim().isNotEmpty) parts.add('Industry: ${form.industry}');
    parts.add('Goal: ${form.careerGoal}');
    if ((form.highlightSkills ?? '').trim().isNotEmpty) parts.add('Highlight skills: ${form.highlightSkills}');
    if ((form.strengths ?? '').trim().isNotEmpty) parts.add('Strengths: ${form.strengths}');
    if ((form.workStyle ?? '').trim().isNotEmpty) parts.add('Work style: ${form.workStyle}');
    if ((form.proudAchievements ?? '').trim().isNotEmpty) parts.add('Proud achievements: ${form.proudAchievements}');
    if (form.experienceEntries != null && form.experienceEntries!.isNotEmpty) {
      parts.add('Experience entries: ${form.experienceEntries!.length}');
      for (final e in form.experienceEntries!.take(3)) {
        parts.add('- ${e.jobTitle}${e.company.isEmpty ? '' : ' @ ${e.company}'}');
      }
    } else if (form.workExperience.trim().isNotEmpty) {
      parts.add('Work experience pasted');
    }
    if ((form.targetJobDescription ?? '').trim().isNotEmpty) parts.add('Tailoring: job description included');
    return parts.join('\n');
  }

  ResumeFormData _buildFormDataFromGuided() {
    final skillsRaw = _skillsCtrl.text.trim().isNotEmpty
        ? _skillsCtrl.text.trim()
        : (_highlightSkillsCtrl.text.trim().isNotEmpty
            ? _highlightSkillsCtrl.text.trim()
            : '');

    final summaryRaw = _summaryCtrl.text.trim().isNotEmpty
        ? _summaryCtrl.text.trim()
        : 'Please create a summary based on my experience and the target role.';

    return ResumeFormData(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      suburb: _suburbCtrl.text.trim(),
      careerGoal: _careerGoalCtrl.text.trim(),
      summary: summaryRaw,
      strengths: _strengthsCtrl.text.trim().isEmpty ? null : _strengthsCtrl.text.trim(),
      personalityTraits: _traitsCtrl.text.trim().isEmpty ? null : _traitsCtrl.text.trim(),
      workStyle: _workStyleCtrl.text.trim().isEmpty ? null : _workStyleCtrl.text.trim(),
      proudAchievements: _proudAchievementsCtrl.text.trim().isEmpty ? null : _proudAchievementsCtrl.text.trim(),
      jobCategory: (_jobCategory ?? '').trim().isEmpty ? null : _jobCategory!.trim(),
      targetJobTitle: _targetJobTitleCtrl.text.trim().isEmpty ? null : _targetJobTitleCtrl.text.trim(),
      industry: _industryCtrl.text.trim().isEmpty ? null : _industryCtrl.text.trim(),
      highlightSkills: _highlightSkillsCtrl.text.trim().isEmpty ? null : _highlightSkillsCtrl.text.trim(),
      experienceLevel: _experienceLevelCtrl.text.trim().isEmpty ? null : _experienceLevelCtrl.text.trim(),
      skills: skillsRaw,
      workExperience: _workExperienceCtrl.text.trim(),
      experienceEntries: _experienceEntries.isEmpty ? null : List<ResumeExperienceEntry>.from(_experienceEntries),
      existingResumeText: _buildMode == ResumeBuildMode.improveExisting
          ? (_existingResumeCtrl.text.trim().isEmpty ? null : _existingResumeCtrl.text.trim())
          : null,
      education: _educationCtrl.text.trim(),
      certifications: _certificationsCtrl.text.trim(),
      languages: _languagesCtrl.text.trim(),
      availability: _availabilityCtrl.text.trim(),
      visaStatus: _visaCtrl.text.trim().isEmpty ? null : _visaCtrl.text.trim(),
      targetJobDescription: _jobDescriptionCtrl.text.trim().isEmpty ? null : _jobDescriptionCtrl.text.trim(),
    );
  }

  Future<void> _showTextResultDialog({
    required String title,
    required String text,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: SelectableText(text.trim().isEmpty ? '(empty)' : text.trim()),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _getEndpointUrlOrSnack() async {
    final url = await AiResumeService.getEndpointUrl();
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI endpoint is not configured. Open Settings to set it.')),
        );
      }
      return null;
    }
    return url;
  }

  Future<void> _generateCoverLetter() async {
    final form = _guidedMode ? _buildFormDataFromGuided() : null;
    if (form == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover letter works best in Guided mode.')),
      );
      return;
    }

    final existingCtrl = TextEditingController();
    final companyCtrl = TextEditingController();

    final go = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cover Letter'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For best results: paste the full job description in Guided mode.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Company name (optional)',
                      hintText: 'e.g., ABC Cleaning Services',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: existingCtrl,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Improve my existing cover letter (optional)',
                      hintText: 'Paste an old cover letter here to rewrite and tailor it.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
    if (go != true) return;

    final endpointUrl = await AiResumeService.getEndpointUrl();
    final companyName = companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim();
    final existingLetter = existingCtrl.text.trim().isEmpty ? null : existingCtrl.text.trim();

    final text = endpointUrl == null
        ? AiResumeService.generateCoverLetterLocally(
            data: form,
            tone: _tone,
            companyName: companyName,
          )
        : await AiResumeService.generateCoverLetter(
            endpointUrl: endpointUrl,
            data: form,
            tone: _tone,
            existingCoverLetterText: existingLetter,
            companyName: companyName,
          );

    if (endpointUrl == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI endpoint not configured. Generated a basic cover letter locally.'),
        ),
      );
    }

    await _showTextResultDialog(title: 'Cover Letter', text: text);
  }

  Future<void> _generateInterviewPrep() async {
    final endpointUrl = await _getEndpointUrlOrSnack();
    if (endpointUrl == null) return;
    final form = _guidedMode ? _buildFormDataFromGuided() : null;
    if (form == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interview prep works best in Guided mode.')),
      );
      return;
    }
    final text = await AiResumeService.generateInterviewPrep(
      endpointUrl: endpointUrl,
      data: form,
      tone: _tone,
    );
    await _showTextResultDialog(title: 'Interview Prep', text: text);
  }

  Future<void> _generateSkillGap() async {
    final endpointUrl = await _getEndpointUrlOrSnack();
    if (endpointUrl == null) return;
    final form = _guidedMode ? _buildFormDataFromGuided() : null;
    if (form == null || (form.targetJobDescription ?? '').trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a job description in Guided mode to get skill gap suggestions.')),
      );
      return;
    }
    final text = await AiResumeService.generateSkillGapSuggestions(
      endpointUrl: endpointUrl,
      data: form,
      tone: _tone,
    );
    await _showTextResultDialog(title: 'Skill Gap Suggestions', text: text);
  }

  Future<void> _addOrEditExperience({ResumeExperienceEntry? existing, int? index}) async {
    final titleCtrl = TextEditingController(text: existing?.jobTitle ?? '');
    final companyCtrl = TextEditingController(text: existing?.company ?? '');
    final datesCtrl = TextEditingController(text: existing?.dates ?? '');
    final respCtrl = TextEditingController(text: existing?.responsibilities ?? '');
    final achCtrl = TextEditingController(text: existing?.achievements ?? '');
    final toolsCtrl = TextEditingController(text: existing?.toolsUsed ?? '');
    final metricsCtrl = TextEditingController(text: existing?.metrics ?? '');

    Future<void> generateAchievements() async {
      final endpointUrl = await _getEndpointUrlOrSnack();
      if (endpointUrl == null) return;
      final role = titleCtrl.text.trim();
      final what = [respCtrl.text.trim(), metricsCtrl.text.trim()]
          .where((s) => s.isNotEmpty)
          .join('\n');
      if (role.isEmpty || what.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add job title and responsibilities/metrics first.')),
        );
        return;
      }
      final bullets = await AiResumeService.generateAchievementBullets(
        endpointUrl: endpointUrl,
        role: role,
        whatDidYouDo: what,
        tone: _tone,
      );
      achCtrl.text = bullets;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Experience' : 'Edit Experience'),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Job title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(labelText: 'Company'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: datesCtrl,
                    decoration: const InputDecoration(labelText: 'Dates (e.g., Jan 2023 – Dec 2024)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: respCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Responsibilities (bullets or short text)',
                      hintText: '- Customer service\n- Cash handling\n- Cleaning / closing duties',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: metricsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Numbers / metrics (KPIs)',
                      hintText: 'e.g., served 120+ customers/day, reduced prep time by 20%',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: toolsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Tools used',
                      hintText: 'e.g., Square POS, Excel, cleaning chemicals, Jira',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: achCtrl,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Achievements (bullets)',
                            hintText: '• Improved…\n• Reduced…\n• Increased…',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: generateAchievements,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate achievements (AI)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;

    final entry = ResumeExperienceEntry(
      jobTitle: titleCtrl.text.trim(),
      company: companyCtrl.text.trim(),
      dates: datesCtrl.text.trim(),
      responsibilities: respCtrl.text.trim(),
      achievements: achCtrl.text.trim(),
      toolsUsed: toolsCtrl.text.trim(),
      metrics: metricsCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      if (index != null && index >= 0 && index < _experienceEntries.length) {
        _experienceEntries[index] = entry;
      } else {
        _experienceEntries.add(entry);
      }
    });
  }

  Future<void> _exportPdf() async {
    final bytesResult = await _buildPdfBytes();
    if (bytesResult == null) return;

    await Printing.layoutPdf(
      onLayout: (format) async => bytesResult.bytes,
      name: bytesResult.fileName,
    );
  }

  Future<void> _doneAndReturn() async {
    if (!widget.returnResultOnDone) return;

    final result = _result;
    if (result == null) return;

    final bytesResult = await _buildPdfBytes();
    if (bytesResult == null) return;

    final input = ResumePromptInput(
      prompt: _promptCtrl.text.trim().isEmpty ? 'Resume' : _promptCtrl.text.trim(),
      fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      suburb: _suburbCtrl.text.trim().isEmpty ? null : _suburbCtrl.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(
      context,
      AiResumeCreatorResult(
        input: input,
        style: _style,
        result: result,
        pdfBytes: bytesResult.bytes,
        fileName: bytesResult.fileName,
      ),
    );
  }

  Future<_PdfBytesResult?> _buildPdfBytes() async {
    final result = _result;
    if (result == null) return null;

    final input = ResumePromptInput(
      prompt: _promptCtrl.text.trim().isEmpty ? 'Resume' : _promptCtrl.text.trim(),
      fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      suburb: _suburbCtrl.text.trim().isEmpty ? null : _suburbCtrl.text.trim(),
    );

    final doc = AiResumePdf.buildPdf(input: input, result: result, style: _style);
    final bytes = await doc.save();

    final fileName = (input.fullName == null || input.fullName!.trim().isEmpty)
        ? 'resume.pdf'
        : 'resume_${input.fullName!.trim().replaceAll(' ', '_')}.pdf';

    return _PdfBytesResult(bytes: bytes, fileName: fileName);
  }

  Widget _sectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = AiResumeTemplates.templates;
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Creator'),
        actions: [
          IconButton(
            tooltip: 'AI endpoint',
            onPressed: _configureAiEndpoint,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Saved resumes',
            onPressed: _openSavedResumes,
            icon: const Icon(Icons.bookmark_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          ScrollConfiguration(
            behavior: const _AiResumeCreatorScrollBehavior(),
            child: Scrollbar(
              controller: _pageScrollController,
              thumbVisibility: true,
              child: ListView(
                controller: _pageScrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                children: [
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Create a professional, ATS-friendly resume in minutes',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Write a short prompt about your experience. The generator will format it into an ATS-friendly resume and suggest relevant skills.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Input Mode'),
                      DropdownButtonFormField<bool>(
                        initialValue: _guidedMode,
                        items: const [
                          DropdownMenuItem(value: true, child: Text('Guided (best results)')),
                          DropdownMenuItem(value: false, child: Text('Quick Prompt (fast)')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _guidedMode = v;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Choose how you want to build your resume',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_guidedMode)
                        Text(
                          'Guided mode collects richer details and uses a multi-step AI pipeline (skills → STAR achievements → summary → ATS resume → job tailoring).',
                          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
                        )
                      else
                        Text(
                          'Quick Prompt mode is a single prompt box (useful when pre-filled from a job).',
                          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              if (_guidedMode)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Guided Resume Builder'),
                        Stepper(
                          currentStep: _guidedStep,
                          onStepTapped: (i) => setState(() => _guidedStep = i),
                          onStepContinue: () {
                            setState(() {
                              if (_guidedStep < 4) _guidedStep++;
                            });
                          },
                          onStepCancel: () {
                            setState(() {
                              if (_guidedStep > 0) _guidedStep--;
                            });
                          },
                          controlsBuilder: (context, details) {
                            final isLast = _guidedStep >= 4;
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  if (!isLast)
                                    FilledButton(
                                      onPressed: details.onStepContinue,
                                      child: const Text('Next'),
                                    )
                                  else
                                    FilledButton.icon(
                                      onPressed: _isGenerating ? null : _generate,
                                      icon: const Icon(Icons.auto_awesome),
                                      label: const Text('Generate Resume'),
                                    ),
                                  const SizedBox(width: 12),
                                  if (_guidedStep > 0)
                                    OutlinedButton(
                                      onPressed: details.onStepCancel,
                                      child: const Text('Back'),
                                    ),
                                ],
                              ),
                            );
                          },
                          steps: [
                            Step(
                              title: const Text('Target & Style'),
                              isActive: _guidedStep >= 0,
                              content: Column(
                                children: [
                                  DropdownButtonFormField<ResumeBuildMode>(
                                    initialValue: _buildMode,
                                    items: const [
                                      DropdownMenuItem(
                                        value: ResumeBuildMode.createNew,
                                        child: Text('Create new resume'),
                                      ),
                                      DropdownMenuItem(
                                        value: ResumeBuildMode.improveExisting,
                                        child: Text('Improve my existing resume'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _buildMode = v);
                                    },
                                    decoration: const InputDecoration(labelText: 'Mode'),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<ResumeTone>(
                                    initialValue: _tone,
                                    items: const [
                                      DropdownMenuItem(
                                        value: ResumeTone.professionalCorporate,
                                        child: Text('Professional corporate'),
                                      ),
                                      DropdownMenuItem(
                                        value: ResumeTone.hospitalityFriendly,
                                        child: Text('Hospitality-friendly'),
                                      ),
                                      DropdownMenuItem(
                                        value: ResumeTone.retailFriendly,
                                        child: Text('Retail-friendly'),
                                      ),
                                      DropdownMenuItem(
                                        value: ResumeTone.itTech,
                                        child: Text('IT / Tech'),
                                      ),
                                      DropdownMenuItem(
                                        value: ResumeTone.minimalistModern,
                                        child: Text('Minimalist modern'),
                                      ),
                                      DropdownMenuItem(
                                        value: ResumeTone.studentFriendly,
                                        child: Text('Student-friendly'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _tone = v);
                                    },
                                    decoration: const InputDecoration(labelText: 'Rewrite style (tone)'),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: (_jobCategory != null && _jobCategories.contains(_jobCategory))
                                        ? _jobCategory
                                        : null,
                                    items: [
                                      for (final c in _jobCategories)
                                        DropdownMenuItem(
                                          value: c,
                                          child: Text(c),
                                        ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        _jobCategory = v;
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Job category (helps auto-tone + templates)',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _targetJobTitleCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Job title you want',
                                      hintText: 'e.g., Barista, Cleaner, Retail Assistant',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _industryCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Industry',
                                      hintText: 'e.g., Hospitality, Retail, Cleaning, IT',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _experienceLevelCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Experience level',
                                      hintText: 'e.g., Student / Junior / 2 years / Senior',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _highlightSkillsCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Skills you want to highlight',
                                      hintText: 'Comma separated, e.g., Customer service, POS, Food safety',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _jobDescriptionCtrl,
                                    maxLines: 6,
                                    decoration: const InputDecoration(
                                      labelText: 'Job description (optional, for tailoring)',
                                      hintText: 'Paste the job description here to tailor your resume for ATS.',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _sectionTitle('Resume Style (PDF)'),
                                  DropdownButtonFormField<ResumeStyle>(
                                    initialValue: _style,
                                    selectedItemBuilder: (context) {
                                      return [
                                        for (final t in templates)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(t.icon, size: 18),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Text(
                                                  t.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ];
                                    },
                                    items: [
                                      for (final t in templates)
                                        DropdownMenuItem(
                                          value: t.style,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(t.icon, size: 18),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(t.title, overflow: TextOverflow.ellipsis),
                                                    Text(
                                                      t.subtitle,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: const Color(0xFF6B7280),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _style = v);
                                    },
                                    decoration: const InputDecoration(labelText: 'Style'),
                                  ),
                                ],
                              ),
                            ),
                            Step(
                              title: const Text('Branding'),
                              isActive: _guidedStep >= 1,
                              content: Column(
                                children: [
                                  TextField(
                                    controller: _careerGoalCtrl,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Career goal (required)',
                                      hintText: 'e.g., Full-time Barista role in Sydney; grow into supervisor',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _strengthsCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Strengths',
                                      hintText: 'e.g., Fast learner, friendly service, reliable, detail-oriented',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _traitsCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Personality traits',
                                      hintText: 'e.g., calm under pressure, proactive, team player',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _workStyleCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Work style',
                                      hintText: 'e.g., prefers clear checklists, works well in busy shifts',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _proudAchievementsCtrl,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: 'Achievements you’re proud of',
                                      hintText: 'e.g., trained new staff, improved customer feedback, reduced errors',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _summaryCtrl,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: 'About you (optional)',
                                      hintText: 'Short description; AI will rewrite it into a professional summary.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Step(
                              title: const Text('Experience'),
                              isActive: _guidedStep >= 2,
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_buildMode == ResumeBuildMode.improveExisting) ...[
                                    TextField(
                                      controller: _existingResumeCtrl,
                                      maxLines: 8,
                                      decoration: const InputDecoration(
                                        labelText: 'Paste your existing resume (required for Improve mode)',
                                        hintText: 'Paste your current resume here. AI will rewrite and optimize it.',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Text(
                                    'Structured experience entries (recommended)',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  for (int i = 0; i < _experienceEntries.length; i++)
                                    Card(
                                      child: ListTile(
                                        title: Text(_experienceEntries[i].jobTitle.isEmpty
                                            ? 'Experience ${i + 1}'
                                            : _experienceEntries[i].jobTitle),
                                        subtitle: Text([
                                          _experienceEntries[i].company,
                                          _experienceEntries[i].dates,
                                        ].where((s) => s.trim().isNotEmpty).join(' • ')),
                                        trailing: IconButton(
                                          tooltip: 'Remove',
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () {
                                            setState(() {
                                              _experienceEntries.removeAt(i);
                                            });
                                          },
                                        ),
                                        onTap: () => _addOrEditExperience(existing: _experienceEntries[i], index: i),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _addOrEditExperience(),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add experience'),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Or paste work experience (optional fallback)',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _workExperienceCtrl,
                                    maxLines: 6,
                                    decoration: const InputDecoration(
                                      labelText: 'Work experience (raw)',
                                      hintText: 'Role @ Company (Dates)\n- Responsibilities\n- Achievements',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Step(
                              title: const Text('Skills & Details'),
                              isActive: _guidedStep >= 3,
                              content: Column(
                                children: [
                                  TextField(
                                    controller: _skillsCtrl,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: 'Skills (recommended)',
                                      hintText: 'Comma or newline separated',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _educationCtrl,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: 'Education',
                                      hintText: 'e.g., Diploma of Hospitality (TAFE), 2023',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _certificationsCtrl,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: 'Certifications',
                                      hintText: 'e.g., RSA, First Aid, White Card',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _languagesCtrl,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Languages',
                                      hintText: 'e.g., Nepali, English, Hindi',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _availabilityCtrl,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Availability',
                                      hintText: 'e.g., Full-time, weekends, immediate start',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _visaCtrl,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Work rights / visa status (optional)',
                                      hintText: 'e.g., Permanent Resident, Student visa (20 hrs/week)',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Step(
                              title: const Text('Contact'),
                              isActive: _guidedStep >= 4,
                              content: Column(
                                children: [
                                  TextField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(labelText: 'Full name (optional)'),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _phoneCtrl,
                                          decoration: const InputDecoration(labelText: 'Phone (optional)'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _emailCtrl,
                                          decoration: const InputDecoration(labelText: 'Email (optional)'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _suburbCtrl,
                                    decoration: const InputDecoration(labelText: 'Suburb / City (optional)'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Your Prompt'),
                          TextFormField(
                            controller: _promptCtrl,
                            maxLines: 10,
                            decoration: const InputDecoration(
                              labelText: 'Tell us about your experience',
                              hintText:
                                  'Example:\nI have 2 years experience as a Barista in Sydney.\n- Customer service\n- Cash handling\nEducation: Diploma of Hospitality\nGoal: Full-time Barista role',
                            ),
                            validator: _required,
                          ),

                          _sectionTitle('Contact (Optional)'),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full name (optional)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone (optional)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Email (optional)',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _suburbCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Suburb / City (optional)',
                            ),
                          ),

                          _sectionTitle('Resume Style'),
                          DropdownButtonFormField<ResumeStyle>(
                            initialValue: _style,
                            selectedItemBuilder: (context) {
                              return [
                                for (final t in templates)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(t.icon, size: 18),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          t.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                              ];
                            },
                            items: [
                              for (final t in templates)
                                DropdownMenuItem(
                                  value: t.style,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(t.icon, size: 18),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.title,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              t.subtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: const Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _style = v;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Style',
                            ),
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isGenerating ? null : _generate,
                              child: const Text('Generate Resume'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (result != null) ...[
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Resume Preview',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              'source: ${result.source}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: AiResumeFormattedPreview(resumeText: result.resumeText),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _exportPdf,
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                                label: const Text('Export PDF'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _generateCoverLetter,
                                icon: const Icon(Icons.mail_outline),
                                label: const Text('Cover Letter'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _generateInterviewPrep,
                                icon: const Icon(Icons.question_answer_outlined),
                                label: const Text('Interview Prep'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _generateSkillGap,
                                icon: const Icon(Icons.track_changes_outlined),
                                label: const Text('Skill Gap'),
                              ),
                            ),
                          ],
                        ),
                        if (widget.returnResultOnDone) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _doneAndReturn,
                              icon: const Icon(Icons.check),
                              label: Text(widget.doneButtonText ?? 'Use this resume'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          if (_isGenerating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.18),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Generating…'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AiResumeCreatorScrollBehavior extends MaterialScrollBehavior {
  const _AiResumeCreatorScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };
}
