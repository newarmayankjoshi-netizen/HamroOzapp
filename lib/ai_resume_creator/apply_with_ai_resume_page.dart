import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth_page.dart';
import '../services/firebase_bootstrap.dart';
import 'ai_resume_creator_page.dart';
import 'ai_resume_skill_suggester.dart';

class CloudResumeMetadata {
  final String storagePath;
  final String fileName;
  final int sizeBytes;
  final DateTime updatedAt;

  const CloudResumeMetadata({
    required this.storagePath,
    required this.fileName,
    required this.sizeBytes,
    required this.updatedAt,
  });

  static CloudResumeMetadata? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;

    final storagePath = (data['storagePath'] as String?) ?? '';
    final fileName = (data['fileName'] as String?) ?? '';
    final sizeBytes = (data['sizeBytes'] as num?)?.toInt() ?? 0;
    final updatedAtRaw = data['updatedAt'];

    DateTime updatedAt;
    if (updatedAtRaw is Timestamp) {
      updatedAt = updatedAtRaw.toDate();
    } else {
      updatedAt = DateTime.tryParse(updatedAtRaw?.toString() ?? '') ?? DateTime.now();
    }

    if (storagePath.trim().isEmpty) return null;

    return CloudResumeMetadata(
      storagePath: storagePath,
      fileName: fileName.trim().isEmpty ? 'resume.pdf' : fileName,
      sizeBytes: sizeBytes,
      updatedAt: updatedAt,
    );
  }
}

class AiResumeCloudStorage {
  static Future<CloudResumeMetadata?> getLatestMetadata({required String userId}) async {
    final doc = await FirebaseFirestore.instance
        .collection('user_resumes')
        .doc(userId)
        .get();
    return CloudResumeMetadata.fromDoc(doc);
  }

  static Future<Uint8List?> tryDownloadPdf(String storagePath) async {
    try {
      final bytes = await FirebaseStorage.instance.ref(storagePath).getData(10 * 1024 * 1024);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  static Future<CloudResumeMetadata> uploadPdf({
    required String userId,
    required Uint8List pdfBytes,
    required String fileName,
    String? jobId,
    String? jobTitle,
  }) async {
    final ts = DateTime.now().toUtc();
    final safeName = fileName.trim().isEmpty ? 'resume.pdf' : fileName.trim();
    final storagePath = 'user_resumes/$userId/${ts.microsecondsSinceEpoch}_$safeName';

    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putData(
      pdfBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );

    await FirebaseFirestore.instance.collection('user_resumes').doc(userId).set({
      'storagePath': storagePath,
      'fileName': safeName,
      'sizeBytes': pdfBytes.length,
      'updatedAt': FieldValue.serverTimestamp(),
      'jobId': ?jobId,
      'jobTitle': ?jobTitle,
    }, SetOptions(merge: true));

    return CloudResumeMetadata(
      storagePath: storagePath,
      fileName: safeName,
      sizeBytes: pdfBytes.length,
      updatedAt: DateTime.now(),
    );
  }
}

class ApplyWithAiResumePage extends StatefulWidget {
  /// The job object from the Jobs feature.
  ///
  /// Kept as `Object` to avoid circular imports with `jobs_page.dart`.
  /// Expected fields (accessed via `dynamic`):
  /// - id, title, company, location, description, category, email, phoneNumber
  final Object job;

  const ApplyWithAiResumePage({super.key, required this.job});

  @override
  State<ApplyWithAiResumePage> createState() => _ApplyWithAiResumePageState();
}

class _ApplyWithAiResumePageState extends State<ApplyWithAiResumePage> {
  bool _loading = true;
  String? _error;
  CloudResumeMetadata? _existing;

  String? _cloudUid;

  String get _userId => AuthState.currentUserId ?? '';

  Future<String?> _ensureCloudUid() async {
    await FirebaseBootstrap.tryInit();
    if (!FirebaseBootstrap.isReady) return null;

    await FirebaseBootstrap.ensureSignedIn();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return (uid == null || uid.trim().isEmpty) ? null : uid.trim();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cloudUid = await _ensureCloudUid();

      // We can still generate a resume without cloud storage.
      if (cloudUid == null) {
        final authErr = FirebaseBootstrap.lastAuthError;
        final setupHint = FirebaseBootstrap.authSetupHint();
        final authHint = authErr == null
            ? null
            : 'Firebase Auth error: ${authErr.toString()}\n'
          '${setupHint.trim().isEmpty ? '' : '\n${setupHint.trim()}'}';
        if (!mounted) return;
        setState(() {
          _cloudUid = null;
          _existing = null;
          _loading = false;
          _error = FirebaseBootstrap.isReady
              ? (authHint ?? 'Firebase Auth is not available. Resume won\'t be saved to cloud.')
              : 'Firebase is not configured on this device.';
        });
        return;
      }

      _cloudUid = cloudUid;
      final meta = await AiResumeCloudStorage.getLatestMetadata(userId: cloudUid);
      if (!mounted) return;
      setState(() {
        _existing = meta;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _buildTailoredPrompt(Object jobObject) {
    final job = jobObject as dynamic;
    final jobContext = [
      'Create a tailored Australian-style resume for this job.',
      'The output must be ATS-friendly: plain text, no tables, no columns, no icons, no emojis.',
      'Use clear section headings and bullet points. Keep it to 1–2 pages.',
      'Do not invent employers, dates, or qualifications. If information is missing, use placeholders like "[Company]" or omit safely.',
      '',
      'Job Title: ${job.title}',
      if (job.company.trim().isNotEmpty) 'Company: ${job.company}',
      if (job.location.trim().isNotEmpty) 'Location: ${job.location}',
      if (job.description.trim().isNotEmpty) 'Job Description: ${job.description}',
    ];

    final inferredSkills = AiResumeSkillSuggester.suggestSkills(
      '${job.title}\n${job.category}\n${job.description}',
      maxSuggestions: 10,
    );
    if (inferredSkills.isNotEmpty) {
      jobContext.add('Required Skills: ${inferredSkills.join(', ')}');
    }

    final userId = _userId;
    final user = userId.isEmpty ? null : AuthService.getUserById(userId);

    final userBlock = <String>[
      '',
      'User Details:',
      if (user != null) 'Name: ${user.name}',
      if (user == null && (AuthState.currentUserName ?? '').trim().isNotEmpty)
        'Name: ${AuthState.currentUserName}',
      if ((AuthState.currentUserEmail ?? '').trim().isNotEmpty)
        'Email: ${AuthState.currentUserEmail}',
      if (user?.phone != null && user!.phone!.trim().isNotEmpty)
        'Phone: ${user.phone}',
      if (user?.state != null && user!.state!.trim().isNotEmpty)
        'State: ${user.state}',
      if (user?.bio != null && user!.bio!.trim().isNotEmpty)
        'Experience: ${user.bio}',
      if (user?.languages != null && user!.languages!.isNotEmpty)
        'Languages: ${user.languages!.join(', ')}',
      '',
      'Task:',
      '- Tailor the resume to the job description and include relevant keywords naturally.',
      '- Highlight measurable impact (numbers, speed, quality, customer satisfaction) where possible.',
      '',
      'Resume format (use these headings):',
      '1) FULL NAME',
      '2) CONTACT (Phone | Email | Location)',
      '3) PROFESSIONAL SUMMARY (3–5 lines)',
      '4) KEY SKILLS (8–12 bullets)',
      '5) WORK EXPERIENCE (most recent first; 3–6 impact bullets per role)',
      '6) EDUCATION',
      '7) CERTIFICATIONS (if any)',
      '8) AVAILABILITY / WORK RIGHTS (if provided)',
      '9) REFERENCES ("Available on request")',
    ];

    return [...jobContext, ...userBlock].join('\n').trim();
  }

  Future<void> _showApplyOptions({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final job = widget.job as dynamic;
    final email = job.email.trim();
    final phone = job.phoneNumber.trim();

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply Options',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to apply. The resume PDF is ready to share.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email employer (attach resume)'),
                  subtitle: email.isEmpty ? const Text('No email provided') : Text(email),
                  enabled: true,
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
                    } catch (_) {
                      if (email.isNotEmpty) {
                        final uri = Uri(scheme: 'mailto', path: email);
                        await launchUrl(uri);
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sms_outlined),
                  title: const Text('SMS employer'),
                  subtitle: phone.isEmpty ? const Text('No phone provided') : Text(phone),
                  enabled: phone.isNotEmpty,
                  onTap: phone.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(context);
                          final uri = Uri(scheme: 'sms', path: phone);
                          await launchUrl(uri);
                        },
                ),
                ListTile(
                  leading: const Icon(Icons.call_outlined),
                  title: const Text('Call employer'),
                  subtitle: phone.isEmpty ? const Text('No phone provided') : Text(phone),
                  enabled: phone.isNotEmpty,
                  onTap: phone.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(context);
                          final uri = Uri(scheme: 'tel', path: phone);
                          await launchUrl(uri);
                        },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Download PDF'),
                  subtitle: const Text('Saves via print dialog / system share'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Printing.layoutPdf(
                      name: fileName,
                      onLayout: (_) async => pdfBytes,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share resume'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _useExistingResume() async {
    final meta = _existing;
    if (meta == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bytes = await AiResumeCloudStorage.tryDownloadPdf(meta.storagePath);
      if (!mounted) return;

      if (bytes == null) {
        setState(() {
          _loading = false;
          _error = 'Could not download your saved resume. Try generating a new one.';
        });
        return;
      }

      setState(() {
        _loading = false;
      });

      await _showApplyOptions(pdfBytes: bytes, fileName: meta.fileName);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _generateNewForJob() async {
    final prompt = _buildTailoredPrompt(widget.job);

    final result = await Navigator.push<AiResumeCreatorResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AiResumeCreatorPage(
          initialPrompt: prompt,
          returnResultOnDone: true,
          doneButtonText: 'Use this resume',
        ),
      ),
    );

    if (!mounted) return;
    if (result == null) return;

    // Save to Firebase (recommended) if Firebase is ready and we have an auth UID.
    final cloudUid = _cloudUid ?? await _ensureCloudUid();
    if (cloudUid != null) {
      try {
        await AiResumeCloudStorage.uploadPdf(
          userId: cloudUid,
          pdfBytes: result.pdfBytes,
          fileName: result.fileName,
          jobId: (widget.job as dynamic).id,
          jobTitle: (widget.job as dynamic).title,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume saved to your account.')),
          );
        }
        await _load();
      } catch (e) {
        // Best-effort, but show actionable error for permission issues.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save resume to cloud: $e')),
          );
        }
      }
    }

    await _showApplyOptions(pdfBytes: result.pdfBytes, fileName: result.fileName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = widget.job as dynamic;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply with AI'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                            Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Apply faster with a tailored resume',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Job: ${job.title}${job.company.trim().isEmpty ? '' : ' • ${job.company}'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null) ...[
                  Card(
                    color: const Color(0xFFFFF3CD),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_userId.isEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in recommended',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You can still generate a resume, but it won\'t be saved to your account unless you\'re logged in.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_existing != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved resume found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You already have a saved resume. What do you want to do?',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _useExistingResume,
                              icon: const Icon(Icons.description_outlined),
                              label: const Text('Use existing resume'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _generateNewForJob,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Generate new resume for this job'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No saved resume',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Let\'s generate a tailored resume using this job\'s details.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _generateNewForJob,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Open AI Resume Creator'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
