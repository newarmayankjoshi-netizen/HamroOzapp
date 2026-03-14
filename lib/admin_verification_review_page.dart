import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_bootstrap.dart';

// Small helpers to extract concise fields from OCR fullText for reviewer cards
String _ocrFirstLineReview(String s) {
  final lines = s.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  return lines.isEmpty ? '' : lines.first;
}

String? _ocrFindIdReview(String s) {
  final m = RegExp(r'([A-Z0-9]{6,20})').firstMatch(s.replaceAll(RegExp(r'\s+'), ''));
  return m?.group(0);
}

String? _ocrFindDateReview(String s) {
  final m1 = RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})').firstMatch(s);
  if (m1 != null) return m1.group(0);
  final m2 = RegExp(r'(\d{1,2}\s+[A-Za-z]{3,}\s+\d{4})').firstMatch(s);
  return m2?.group(0);
}

class AdminVerificationReviewPage extends StatefulWidget {
  final String userId;
  final String submissionId;

  const AdminVerificationReviewPage({super.key, required this.userId, required this.submissionId});

  @override
  State<AdminVerificationReviewPage> createState() => _AdminVerificationReviewPageState();
}

class _AdminVerificationReviewPageState extends State<AdminVerificationReviewPage> {
  Map<String, dynamic>? _submission;
  List<Map<String, dynamic>> _audits = [];
  bool _loading = true;
  bool _acting = false;
  final Map<String, String> _userNameCache = {};

  Future<String> _resolveUserName(String uid) async {
    if (uid.isEmpty) return 'Unknown user';
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid]!;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        final name = data?['name'] ?? data?['displayName'] ?? data?['email'] ?? uid;
        final nameStr = name.toString();
        _userNameCache[uid] = nameStr;
        return nameStr;
      }
    } catch (_) {}
    _userNameCache[uid] = uid;
    return uid;
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      await FirebaseBootstrap.tryInit();
      await FirebaseBootstrap.ensureSignedIn();
      final fUser = FirebaseAuth.instance.currentUser;
      if (fUser != null) {
        try {
          await fUser.getIdToken(true);
        } catch (_) {}
      }

        try {
          final callable = FirebaseFunctions.instance.httpsCallable('getSubmissionDetails');
          final res = await callable.call(<String, dynamic>{'userId': widget.userId, 'submissionId': widget.submissionId});
          debugPrint('getSubmissionDetails callable returned: ${res.data}');
          final resData = res.data as Map<String, dynamic>? ?? {};
          final submission = resData['submission'] as Map<String, dynamic>?;
          final auditsRaw = resData['audits'] as List<dynamic>? ?? [];
          final audits = auditsRaw.whereType<Map<String, dynamic>>().toList();

          if (!mounted) return;
          setState(() {
            _submission = submission;
            _audits = List<Map<String, dynamic>>.from(audits);
          });
        } catch (e) {
          final err = e.toString().toLowerCase();
          if (err.contains('not-found') || err.contains('not found') || err.contains('no function') || err.contains('requires an index') || err.contains('requires an index') || err.contains('index')) {
            // Attempt a best-effort direct Firestore read as a fallback for environments
            // where the callable hasn't been deployed yet. This may fail due to rules.
            try {
              final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('id_submissions').doc(widget.submissionId).get();
              final auditsSnap = await FirebaseFirestore.instance.collection('admin').doc('verification_audit').collection(widget.userId).where('submissionId', isEqualTo: widget.submissionId).orderBy('at', descending: true).get();
              if (!mounted) return;
              setState(() {
                _submission = doc.exists ? doc.data() : null;
                _audits = auditsSnap.docs.map((d) => d.data()).whereType<Map<String, dynamic>>().toList();
              });
            } catch (fsErr) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load submission: callable missing and direct read failed: $fsErr')));
            }
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
          }
        }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approveWithLevel(int level) async {
    setState(() => _acting = true);
    try {
      await FirebaseBootstrap.tryInit();
      await FirebaseBootstrap.ensureSignedIn();
      final fUser = FirebaseAuth.instance.currentUser;
      if (fUser != null) {
        try {
          await fUser.getIdToken(true);
        } catch (_) {}
      }

      final callable = FirebaseFunctions.instance.httpsCallable('reviewSubmission');
      await callable.call(<String, dynamic>{
        'userId': widget.userId,
        'submissionId': widget.submissionId,
        'status': 'approved',
        'setContributorLevel': level,
      });

      if (!mounted) return;
      Navigator.of(context).pop({'action': 'approved', 'level': level});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approve failed: $e')));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reject submission'),
        content: TextField(controller: reasonController, decoration: const InputDecoration(hintText: 'Reason for rejection')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reject')),
        ],
      ),
    );
    if (ok != true) return;
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
      return;
    }

    setState(() => _acting = true);
    try {
      await FirebaseBootstrap.tryInit();
      await FirebaseBootstrap.ensureSignedIn();
      final fUser = FirebaseAuth.instance.currentUser;
      if (fUser != null) {
        try {
          await fUser.getIdToken(true);
        } catch (_) {}
      }

      final callable = FirebaseFunctions.instance.httpsCallable('reviewSubmission');
      await callable.call(<String, dynamic>{
        'userId': widget.userId,
        'submissionId': widget.submissionId,
        'status': 'rejected',
        'reason': reason,
      });

      if (!mounted) return;
      Navigator.of(context).pop({'action': 'rejected', 'reason': reason});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reject failed: $e')));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review verification')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (_submission != null) ...[
                  FutureBuilder<String>(
                    future: (_submission != null && (_submission!['ownerName'] ?? '').toString().trim().isNotEmpty)
                        ? Future.value((_submission!['ownerName'] ?? '').toString())
                        : _resolveUserName(widget.userId),
                    builder: (ctx, nameSnap) {
                      final owner = nameSnap.hasData ? nameSnap.data! : '';
                      final status = (_submission!['status'] ?? '').toString().toLowerCase();
                      Color statusColor = Colors.grey;
                      if (status == 'approved') statusColor = Colors.green;
                      if (status == 'rejected') statusColor = Colors.red;
                      if (status == 'pending') statusColor = Colors.orange;
                      return Row(
                        children: [
                          Expanded(child: Text(owner.isNotEmpty ? owner : 'Unknown user', style: Theme.of(context).textTheme.titleLarge)),
                          Chip(
                            label: Text(status.isNotEmpty ? status.toUpperCase() : 'UNKNOWN'),
                            backgroundColor: statusColor.withAlpha((0.12 * 255).round()),
                            labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_submission!['imageUrl'] != null)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(
                          _submission!['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Verification image failed to load: $error');
                            return const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey));
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_submission!['ocr'] != null)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 240),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('OCR excerpt', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Builder(builder: (ctx) {
                              final full = (_submission!['ocr']['fullText'] ?? '').toString();
                              final name = _ocrFirstLineReview(full);
                              final id = _ocrFindIdReview(full);
                              final dob = _ocrFindDateReview(full);
                              final hasAny = name.isNotEmpty || id != null || dob != null;
                              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (hasAny) ...[
                                  if (name.isNotEmpty) Text('Name: $name', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (id != null) Text('ID: $id'),
                                  if (dob != null) Text('DOB: $dob'),
                                ] else ...[
                                  Text(full.length > 200 ? '${full.substring(0, 200)}…' : full, maxLines: 6, overflow: TextOverflow.ellipsis),
                                ],
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => showDialog<void>(
                                    context: context,
                                    builder: (dctx) => AlertDialog(
                                      title: const Text('Full OCR'),
                                      content: SingleChildScrollView(child: SelectableText(full)),
                                      actions: [TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Close'))],
                                    ),
                                  ),
                                  child: const Text('View full OCR'),
                                ),
                              ]);
                            }),
                          ]),
                        ),
                      ),
                    ),
                  if (_submission!['fraudChecks'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Fraud checks: ${_submission!['fraudChecks'].toString()}'),
                  ],
                ] else ...[
                  const Text('Submission not found'),
                ],
                const SizedBox(height: 12),

                // Action buttons (centered, clearer styles)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _acting ? null : () => _approveWithLevel(2),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve (L2)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _acting ? null : () => _approveWithLevel(3),
                          icon: const Icon(Icons.verified, size: 18),
                          label: const Text('Approve (L3)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade200),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _acting ? null : _reject,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Audit history', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Expanded(
                  child: _audits.isEmpty
                      ? const Text('No audit records')
                      : ListView.builder(
                          itemCount: _audits.length,
                          itemBuilder: (context, i) {
                            final a = _audits[i];
                            final atObj = a['at'];
                            final reviewerId = (a['reviewerId'] ?? '').toString();
                            final action = (a['action'] ?? '').toString();
                            Color actionColor = Colors.grey;
                            if (action.toLowerCase() == 'approved') actionColor = Colors.green;
                            if (action.toLowerCase() == 'rejected') actionColor = Colors.red;
                            return ListTile(
                              leading: CircleAvatar(backgroundColor: actionColor.withAlpha((0.12 * 255).round()), child: Icon(action.toLowerCase() == 'approved' ? Icons.check : Icons.close, color: actionColor)),
                              title: Text(a['action'] ?? 'action'),
                              subtitle: FutureBuilder<String>(
                                future: _resolveUserName(reviewerId),
                                builder: (ctx, snap) {
                                  final reviewer = snap.hasData ? snap.data! : reviewerId;
                                  final reason = a['reason'] != null ? '\nReason: ${a['reason']}' : '';
                                  return Text('$reviewer$reason');
                                },
                              ),
                              trailing: Text(atObj is Timestamp ? atObj.toDate().toLocal().toString() : (atObj?.toString() ?? '')),
                            );
                          },
                        ),
                ),
              ]),
            ),
    );
  }
}
