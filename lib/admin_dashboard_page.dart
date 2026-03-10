import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hamro_oz/utils/map_utils.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_page.dart';
import 'services/firebase_bootstrap.dart';
import 'admin_verification_review_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

// Use shared helper `toStringKeyMap` from `lib/utils/map_utils.dart`.

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  

  @override
  void initState() {
    super.initState();
    _ensureAuthClaims();
  }

  Future<void> _ensureAuthClaims() async {
    try {
      await FirebaseBootstrap.tryInit();
      await FirebaseBootstrap.ensureSignedIn();
      final fUser = FirebaseAuth.instance.currentUser;
      if (fUser != null) {
        try {
          await fUser.getIdToken(true);
        } catch (_) {}
      }
    } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    // Check if user is admin
    final currentUser = AuthState.currentUser;
    final isAdmin = currentUser?.role == 'Admin' ||
        currentUser?.email == 'hamroozapp@gmail.com';

    final views = <Widget>[
      const ReportsManagementTab(),
      const UsersManagementTab(),
      const AnalyticsTab(),
      if (isAdmin) const VerificationsTab(),
    ];

    // Ensure selected index is valid for the current set of views
    final idx = _selectedIndex < views.length ? _selectedIndex : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: IndexedStack(index: idx, children: views),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF2563EB),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (i) {
          if (i >= 0 && i < views.length) setState(() => _selectedIndex = i);
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
          const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          const BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          if (isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: 'Verifications'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class VerificationsTab extends StatefulWidget {
  const VerificationsTab({super.key});

  @override
  State<VerificationsTab> createState() => _VerificationsTabState();
}

class _VerificationsTabState extends State<VerificationsTab> {
  String _filter = 'pending'; // pending, approved, rejected
  final Set<String> _optimisticRemoved = <String>{};
  final Map<String, String> _userNameCache = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Name resolution now performed by `_prefetchDisplayNames` and the
  // `_userNameCache` is used directly when rendering; helper removed.

  Future<List<Map<String, dynamic>>> _fetchPendingViaFunction([String status = 'pending']) async {
    // Ensure Firebase is initialized and signed-in before calling Functions.
    await FirebaseBootstrap.tryInit();
    await FirebaseBootstrap.ensureSignedIn();
    // Ensure the Firebase ID token is fresh so custom claims are present
    final fUser = FirebaseAuth.instance.currentUser;
    if (fUser != null) {
      try {
        await fUser.getIdToken(true);
      } catch (e) {
        debugPrint('getIdToken refresh failed: $e');
      }
    }

    // Requested status is passed as-is; server supports explicit statuses or 'all'.
    final requestedStatusParam = status;

    final callable = FirebaseFunctions.instance.httpsCallable('listPendingSubmissions');
    HttpsCallableResult result;
    try {
      result = await callable.call(<String, dynamic>{'status': requestedStatusParam});
    } catch (e) {
      // If permission-denied, try refreshing ID token once and retry
      debugPrint('First call to listPendingSubmissions failed: $e');
      try {
        if (fUser != null) await fUser.getIdToken(true);
        result = await callable.call();
      } catch (e2) {
          debugPrint('Retry call to listPendingSubmissions failed: $e2');
          // Attempt to call diagnostic `debugCaller` to surface what claims the server sees
          try {
            final debugFn = FirebaseFunctions.instance.httpsCallable('debugCaller');
            final dbgRes = await debugFn.call();
            debugPrint('debugCaller returned: ${dbgRes.data}');
            // Show a dialog with the server-visible token info to help troubleshooting.
            // Only attempt to show UI if the widget is still mounted.
            if (mounted) {
              await showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Server token diagnostics'),
                  content: SingleChildScrollView(child: Text(dbgRes.data.toString())),
                  actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
                ),
              );
            }
          } catch (dbgErr) {
            debugPrint('debugCaller failed: $dbgErr');
          }
          // Re-throw the original error so the UI shows the failure state.
          rethrow;
      }
    }
    final data = result.data;
    if (data == null) return <Map<String, dynamic>>[];

    List itemsRaw = [];
    if (data is List) {
      itemsRaw = data;
    } else if (data is Map && data['items'] is List) {
      itemsRaw = data['items'] as List;
    } else if (data is Map && data['result'] is Map && data['result']['items'] is List) {
      // some runtimes wrap the result under `result`
      itemsRaw = data['result']['items'] as List;
    } else {
      return <Map<String, dynamic>>[];
    }

    var items = <Map<String, dynamic>>[];
    for (var e in itemsRaw) {
      if (e is Map) {
        final m = <String, dynamic>{};
        e.forEach((k, v) {
          m[k.toString()] = v;
        });
        items.add(m);
      } else {
        items.add({'value': e});
      }
    }
    // Kick off background prefetching of display names for these items.
    Future.microtask(() => _prefetchDisplayNames(items));
    return items;
  }

  // Prefetch display names for the list of items to avoid per-tile async work.
  // This fills `_userNameCache` for any userIds referenced by the returned items.
  Future<void> _prefetchDisplayNames(List<Map<String, dynamic>> items) async {
    final ids = <String>{};
    for (final e in items) {
      final data = e['data'] is Map ? toStringKeyMap(e['data']) : <String, dynamic>{};
      if ((data['ownerName'] ?? '').toString().trim().isNotEmpty) continue;
      // extract userId from path if present
      final path = (e['path'] ?? '') as String? ?? '';
      final parts = path.split('/');
      if (parts.length >= 4) ids.add(parts[1]);
    }

    // Remove ids already cached
    ids.removeWhere((id) => id.isEmpty || _userNameCache.containsKey(id));
    if (ids.isEmpty) return;

    // Limit concurrency to avoid spamming the platform
    const int concurrency = 6;
    final remaining = ids.toList();
    while (remaining.isNotEmpty) {
      final batch = remaining.take(concurrency).toList();
      remaining.removeRange(0, batch.length);
      try {
        final futures = batch.map((uid) async {
          try {
            final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
            if (doc.exists) {
              final data = toStringKeyMap(doc.data());
              final name = (data['name'] ?? data['displayName'] ?? data['email'] ?? uid).toString();
              _userNameCache[uid] = name;
            } else {
              _userNameCache[uid] = uid;
            }
          } catch (_) {
            _userNameCache[uid] = uid;
          }
        });
        await Future.wait(futures);
        if (mounted) setState(() {});
      } catch (_) {
        // swallow; caching best-effort
      }
    }
  }

  Future<int> _countForStatus(String status) async {
    try {
      final items = await _fetchPendingViaFunction('all');
      if (status == 'all') return items.length;
      // No special 'reviewed' grouping; count specific statuses directly.
      return items.where((d) {
        final st = (d['data'] is Map && d['data']['status'] != null) ? d['data']['status'].toString().toLowerCase() : '';
        return st == status.toLowerCase();
      }).length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _approve(String userId, String submissionId) async {
    // Use server-side callable to perform review (avoids client permission issues)
    await FirebaseBootstrap.tryInit();
    await FirebaseBootstrap.ensureSignedIn();
    final fUser = FirebaseAuth.instance.currentUser;
    if (fUser != null) {
      try {
        await fUser.getIdToken(true);
      } catch (_) {}
    }

    // Optimistically remove from list before server confirm
    if (mounted) setState(() => _optimisticRemoved.add(submissionId));
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('reviewSubmission');
      await callable.call(<String, dynamic>{
        'userId': userId,
        'submissionId': submissionId,
        'status': 'approved',
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission approved')));
    } catch (e) {
      debugPrint('reviewSubmission approve failed: $e');
      // rollback optimistic removal
      if (mounted) setState(() => _optimisticRemoved.remove(submissionId));
      // As a fallback, surface a helpful diagnostic dialog
      try {
        final debugFn = FirebaseFunctions.instance.httpsCallable('debugCaller');
        final dbgRes = await debugFn.call();
        if (!mounted) rethrow;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Server token diagnostics'),
            content: SingleChildScrollView(child: Text(dbgRes.data.toString())),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
          ),
        );
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _approveWithLevel(String userId, String submissionId, int level) async {
    await FirebaseBootstrap.tryInit();
    await FirebaseBootstrap.ensureSignedIn();
    final fUser = FirebaseAuth.instance.currentUser;
    if (fUser != null) {
      try {
        await fUser.getIdToken(true);
      } catch (_) {}
    }

    if (mounted) setState(() => _optimisticRemoved.add(submissionId));
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('reviewSubmission');
      await callable.call(<String, dynamic>{
        'userId': userId,
        'submissionId': submissionId,
        'status': 'approved',
        'setContributorLevel': level,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission approved (level $level)')));
    } catch (e) {
      debugPrint('reviewSubmission approve failed: $e');
      if (mounted) setState(() => _optimisticRemoved.remove(submissionId));
      rethrow;
    }
  }

  Future<void> _reject(String userId, String submissionId) async {
    final reason = await _promptReason();
    if (reason == null) return;

    // Use server-side callable to perform review (avoids client permission issues)
    await FirebaseBootstrap.tryInit();
    await FirebaseBootstrap.ensureSignedIn();
    final fUser = FirebaseAuth.instance.currentUser;
    if (fUser != null) {
      try {
        await fUser.getIdToken(true);
      } catch (_) {}
    }

    // Optimistically remove from list
    if (mounted) setState(() => _optimisticRemoved.add(submissionId));
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('reviewSubmission');
      await callable.call(<String, dynamic>{
        'userId': userId,
        'submissionId': submissionId,
        'status': 'rejected',
        'reason': reason,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission rejected')));
    } catch (e) {
      debugPrint('reviewSubmission reject failed: $e');
      // rollback optimistic removal
      if (mounted) setState(() => _optimisticRemoved.remove(submissionId));
      try {
        final debugFn = FirebaseFunctions.instance.httpsCallable('debugCaller');
        final dbgRes = await debugFn.call();
        if (!mounted) rethrow;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Server token diagnostics'),
            content: SingleChildScrollView(child: Text(dbgRes.data.toString())),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
          ),
        );
      } catch (_) {}
      rethrow;
    }
  }

  Future<String?> _promptReason() async {
    String? text;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection reason'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter reason for rejection'),
          onChanged: (v) => text = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
        ],
      ),
    );
    if (ok != true) return null;
    return text?.trim().isEmpty == true ? null : text?.trim();
  }

  Future<void> _showSubmissionModal(String userId, String submissionId) async {
    await FirebaseBootstrap.tryInit();
    await FirebaseBootstrap.ensureSignedIn();
    final fUser = FirebaseAuth.instance.currentUser;
    if (fUser != null) {
      try {
        await fUser.getIdToken(true);
      } catch (_) {}
    }

    Map<String, dynamic> submission = <String, dynamic>{};
    List<dynamic> audits = <dynamic>[];
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getSubmissionDetails');
      final res = await callable.call(<String, dynamic>{'userId': userId, 'submissionId': submissionId});
      final data = res.data as Map<String, dynamic>? ?? {};
      submission = (data['submission'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      audits = (data['audits'] as List<dynamic>?) ?? <dynamic>[];
    } catch (e) {
      debugPrint('getSubmissionDetails failed: $e');
      // Try a best-effort Firestore fallback so admins can still review while
      // the server-side indexed query (audit composite index) is building.
      try {
        final docSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('id_submissions')
            .doc(submissionId)
            .get();
        if (docSnap.exists) {
          submission = toStringKeyMap(docSnap.data());
        }

        try {
          final auditsSnap = await FirebaseFirestore.instance
              .collection('admin')
              .doc('verification_audit')
              .collection(userId)
              .orderBy('at', descending: true)
              .get();
          final filtered = auditsSnap.docs.map((d) => toStringKeyMap(d.data())).where((m) => (m['submissionId']?.toString() ?? '') == submissionId).toList();
          audits = filtered;
        } catch (aErr) {
          debugPrint('audit fallback failed: $aErr');
          audits = <dynamic>[];
        }
      } catch (fbErr) {
        debugPrint('Firestore fallback failed: $fbErr');
        if (!mounted) return;
        await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Failed to load'), content: Text(e.toString()), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
        return;
      }
      // continue to show the modal using any data we managed to load
    }

    if (!mounted) return;

    // Prefetch owner's display name for this submission (best-effort).
    unawaited(_prefetchDisplayNames([
      <String, dynamic>{'data': submission, 'path': 'users/$userId/id_submissions/$submissionId'}
    ]));

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Review submission'),
          content: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (submission['imageUrl'] != null) Image.network(submission['imageUrl'], height: 200, fit: BoxFit.contain),
              const SizedBox(height: 8),
              Text('Type: ${submission['type'] ?? 'unknown'}'),
              const SizedBox(height: 8),
              if (submission['ocr'] != null)
                Text('OCR excerpt: ${(submission['ocr']['fullText'] ?? '').toString().substring(0, (submission['ocr']['fullText'] ?? '').toString().length > 200 ? 200 : (submission['ocr']['fullText'] ?? '').toString().length)}'),
              const SizedBox(height: 12),
              const Text('Recent audits:'),
              const SizedBox(height: 8),
              if (audits.isEmpty) const Text('(no audit entries)'),
              if (audits.isNotEmpty)
                ...audits.take(5).map((a) {
                  final m = (a as Map?) ?? <String, dynamic>{};
                  final at = m['at']?.toString() ?? '';
                  final action = m['action']?.toString() ?? '';
                  final reviewer = m['reviewerId']?.toString() ?? '';
                  return Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('$at — $action by $reviewer'));
                }),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
            OutlinedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _reject(userId, submissionId);
              },
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final level = await showDialog<int>(
                  context: context,
                  builder: (dctx) => SimpleDialog(
                    title: const Text('Select contributor level'),
                    children: [
                      SimpleDialogOption(onPressed: () => Navigator.pop(dctx, 1), child: const Text('Level 1')),
                      SimpleDialogOption(onPressed: () => Navigator.pop(dctx, 2), child: const Text('Level 2')),
                      SimpleDialogOption(onPressed: () => Navigator.pop(dctx, 3), child: const Text('Level 3')),
                    ],
                  ),
                );
                if (level != null) {
                  await _approveWithLevel(userId, submissionId, level);
                } else {
                  await _approve(userId, submissionId);
                }
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by user name, id, or path',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh list',
                onPressed: () => setState(() {}),
              ),
            ]),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                  FilterChip(
                    label: FutureBuilder<int>(
                        future: _countForStatus('pending'),
                        builder: (ctx, snap) => Text('Pending${snap.hasData ? ' (${snap.data})' : ''}')),
                    selected: _filter == 'pending',
                    selectedColor: Colors.blue.shade100,
                    onSelected: (_) => setState(() => _filter = 'pending'),
                  ),
                  // 'Reviewed' filter removed per request.
                  FilterChip(
                    label: FutureBuilder<int>(
                        future: _countForStatus('approved'),
                        builder: (ctx, snap) => Text('Approved${snap.hasData ? ' (${snap.data})' : ''}')),
                    selected: _filter == 'approved',
                    selectedColor: Colors.blue.shade100,
                    onSelected: (_) => setState(() => _filter = 'approved'),
                  ),
                  FilterChip(
                    label: FutureBuilder<int>(
                        future: _countForStatus('rejected'),
                        builder: (ctx, snap) => Text('Rejected${snap.hasData ? ' (${snap.data})' : ''}')),
                    selected: _filter == 'rejected',
                    selectedColor: Colors.blue.shade100,
                    onSelected: (_) => setState(() => _filter = 'rejected'),
                  ),
                ]),
            ),
          ]),
        ),
        Expanded(
          child: _filter == 'pending'
              ? FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchPendingViaFunction(),
                  builder: (context, snap) {
                    if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snap.data!;
                      if (docs.isEmpty) return const Center(child: Text('No submissions found'));
                      // apply search query first
                      final q = _searchQuery.toLowerCase();
                      final matched = docs.where((d) {
                        if (q.isEmpty) return true;
                        final data = toStringKeyMap(d['data']);
                        final owner = (data['ownerName'] ?? '').toString().toLowerCase();
                        final path = ((d['path'] ?? '') as String).toLowerCase();
                        final id = ((d['id'] ?? '') as String).toLowerCase();
                        return owner.contains(q) || path.contains(q) || id.contains(q);
                      }).toList();
                      final filteredDocs = matched.where((d) => !(_optimisticRemoved.contains(d['id'] as String? ?? ''))).toList();
                      if (filteredDocs.isEmpty) return const Center(child: Text('No submissions found'));
                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, idx) {
                        final d = filteredDocs[idx];
                        final data = toStringKeyMap(d['data']);
                        // path is like users/{userId}/id_submissions/{submissionId}
                        final path = (d['path'] as String?) ?? '';
                        final parts = path.split('/');
                        String userId = '';
                        if (parts.length >= 4) userId = parts[1];
                        final submissionId = d['id'] as String? ?? '';
                        return InkWell(
                           onTap: () async {
                            debugPrint('VerificationsTab: opening quick review modal for userId=$userId submissionId=$submissionId');
                            await _showSubmissionModal(userId, submissionId);
                            if (!mounted) return;
                            setState(() {});
                          },
                          child: Card(
                            margin: const EdgeInsets.all(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                                // Prefer stored ownerName, otherwise look in cache; fall back to uid.
                                                Builder(builder: (ctx) {
                                                  final ownerName = (data['ownerName'] ?? '').toString().trim();
                                                  final display = ownerName.isNotEmpty
                                                      ? ownerName
                                                      : (_userNameCache.containsKey(userId) ? _userNameCache[userId]! : '(loading...)');
                                                  return Expanded(child: Text('User: $display', style: Theme.of(context).textTheme.titleMedium));
                                                }),
                                  IconButton(
                                    icon: const Icon(Icons.history),
                                    tooltip: 'Open review and history',
                                    onPressed: () async {
                                      debugPrint('VerificationsTab: history pressed for userId=$userId submissionId=$submissionId');
                                      await _showSubmissionModal(userId, submissionId);
                                      if (!mounted) return;
                                      setState(() {});
                                    },
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                Text('Type: ${data['type'] ?? 'unknown'}'),
                                const SizedBox(height: 8),
                                if (data['imageUrl'] != null) Image.network(data['imageUrl'], height: 200, fit: BoxFit.contain),
                                const SizedBox(height: 8),
                                if (data['ocr'] != null) Text('OCR excerpt: ${(data['ocr']['fullText'] ?? '').toString().substring(0, (data['ocr']['fullText'] ?? '').toString().length > 200 ? 200 : (data['ocr']['fullText'] ?? '').toString().length)}'),
                                const SizedBox(height: 8),
                                if (data['fraudChecks'] != null) Text('Fraud checks: ${data['fraudChecks'].toString()}'),
                                const SizedBox(height: 8),
                                Row(children: [
                                  ElevatedButton(onPressed: () => _showSubmissionModal(userId, submissionId), child: const Text('Approve')),
                                  const SizedBox(width: 8),
                                  OutlinedButton(onPressed: () => _reject(userId, submissionId), child: const Text('Reject')),
                                ])
                              ]),
                            ),
                          ),
                        );
                      },
                    );
                  },
                )
              : FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchPendingViaFunction(_filter),
                  builder: (context, snap) {
                    if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snap.data!;
                    if (docs.isEmpty) return const Center(child: Text('No submissions found'));
                    final q = _searchQuery.toLowerCase();
                    final matched = docs.where((d) {
                      if (q.isEmpty) return true;
                      final data = toStringKeyMap(d['data']);
                      final owner = (data['ownerName'] ?? '').toString().toLowerCase();
                      final path = ((d['path'] ?? '') as String).toLowerCase();
                      final id = ((d['id'] ?? '') as String).toLowerCase();
                      return owner.contains(q) || path.contains(q) || id.contains(q);
                    }).toList();
                    final filteredDocs = matched.where((d) => !(_optimisticRemoved.contains(d['id'] as String? ?? ''))).toList();
                    if (filteredDocs.isEmpty) return const Center(child: Text('No submissions found'));
                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, idx) {
                        final d = filteredDocs[idx];
                        final data = toStringKeyMap(d['data']);
                        // path is like users/{userId}/id_submissions/{submissionId}
                        final path = (d['path'] as String?) ?? '';
                        final parts = path.split('/');
                        String userId = '';
                        if (parts.length >= 4) userId = parts[1];
                        final submissionId = d['id'] as String? ?? '';
                        return InkWell(
                          onTap: () async {
                            debugPrint('VerificationsTab: opening quick review modal for userId=$userId submissionId=$submissionId');
                            await _showSubmissionModal(userId, submissionId);
                            if (!mounted) return;
                            setState(() {});
                          },
                          child: Card(
                            margin: const EdgeInsets.all(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  // Prefer stored ownerName, otherwise look in cache; fall back to uid.
                                  Builder(builder: (ctx) {
                                    final ownerName = (data['ownerName'] ?? '').toString().trim();
                                    final display = ownerName.isNotEmpty
                                        ? ownerName
                                        : (_userNameCache.containsKey(userId) ? _userNameCache[userId]! : '(loading...)');
                                    return Expanded(child: Text('User: $display', style: Theme.of(context).textTheme.titleMedium));
                                  }),
                                  IconButton(
                                    icon: const Icon(Icons.history),
                                    tooltip: 'Open review and history',
                                    onPressed: () async {
                                      debugPrint('VerificationsTab: history pressed for userId=$userId submissionId=$submissionId');
                                      final ctxLocal = context;
                                      final res = await Navigator.of(ctxLocal).push(MaterialPageRoute(builder: (c) => AdminVerificationReviewPage(userId: userId, submissionId: submissionId)));
                                      if (!ctxLocal.mounted) return;
                                      setState(() {});
                                      try {
                                        if (res is Map && res['action'] == 'approved') {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission approved')));
                                        } else if (res is Map && res['action'] == 'rejected') {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission rejected')));
                                        }
                                      } catch (_) {}
                                    },
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                Text('Type: ${data['type'] ?? 'unknown'}'),
                                const SizedBox(height: 8),
                                if (data['imageUrl'] != null) Image.network(data['imageUrl'], height: 200, fit: BoxFit.contain),
                                const SizedBox(height: 8),
                                if (data['ocr'] != null) Text('OCR excerpt: ${(data['ocr']['fullText'] ?? '').toString().substring(0, (data['ocr']['fullText'] ?? '').toString().length > 200 ? 200 : (data['ocr']['fullText'] ?? '').toString().length)}'),
                                const SizedBox(height: 8),
                                if (data['fraudChecks'] != null) Text('Fraud checks: ${data['fraudChecks'].toString()}'),
                                const SizedBox(height: 8),
                                Row(children: [
                                  if ((data['status']?.toString().toLowerCase() ?? '') == 'approved' ||
                                      (data['status']?.toString().toLowerCase() ?? '') == 'rejected')
                                    Text('Status: ${data['status']?.toString() ?? ''}'),
                                  if ((data['status']?.toString().toLowerCase() ?? '') != 'approved' &&
                                      (data['status']?.toString().toLowerCase() ?? '') != 'rejected') ...[
                                    ElevatedButton(onPressed: () => _approve(userId, submissionId), child: const Text('Approve')),
                                    const SizedBox(width: 8),
                                    OutlinedButton(onPressed: () => _reject(userId, submissionId), child: const Text('Reject')),
                                  ]
                                ])
                              ]),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

}

class ReportsManagementTab extends StatefulWidget {
  const ReportsManagementTab({super.key});

  @override
  State<ReportsManagementTab> createState() => _ReportsManagementTabState();
}

class _ReportsManagementTabState extends State<ReportsManagementTab> {
  String _filterStatus = 'all'; // 'all', 'pending', 'resolved', 'dismissed'
  final TextEditingController _reportsSearchController = TextEditingController();
  String _reportsQuery = '';

  Stream<QuerySnapshot> _getReportsStream() {
    return FirebaseFirestore.instance
        .collection('user_reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  // counts computed from live stream below to avoid mismatches between
  // separate queries and the displayed stream.

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _reportsSearchController,
                  decoration: const InputDecoration(
                    hintText: 'Search reports by user, id, or text',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _reportsQuery = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh reports',
                onPressed: () => setState(() {}),
              ),
            ]),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _getReportsStream(),
              builder: (ctx, snap) {
                final docs = snap.data?.docs ?? [];
                int all = docs.length;
                int pending = 0;
                int resolved = 0;
                int dismissed = 0;
                for (final d in docs) {
                  final s = (toStringKeyMap(d.data())['status'] ?? '').toString().toLowerCase();
                  if (s == 'pending') pending++;
                  if (s == 'resolved') resolved++;
                  if (s == 'dismissed') dismissed++;
                }
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                        ChoiceChip(
                          label: Text(all > 0 ? 'All ($all)' : 'All'),
                          selected: _filterStatus == 'all',
                          selectedColor: Colors.blue,
                          backgroundColor: Colors.blue.shade50,
                          labelStyle: TextStyle(color: _filterStatus == 'all' ? Colors.white : Colors.black87),
                          onSelected: (selected) { if (selected) setState(() => _filterStatus = 'all'); },
                        ),
                        ChoiceChip(
                          label: Text(pending > 0 ? 'Pending ($pending)' : 'Pending'),
                          selected: _filterStatus == 'pending',
                          selectedColor: Colors.orange,
                          backgroundColor: Colors.orange.shade50,
                          labelStyle: TextStyle(color: _filterStatus == 'pending' ? Colors.white : Colors.black87),
                          onSelected: (selected) { if (selected) setState(() => _filterStatus = 'pending'); },
                        ),
                        ChoiceChip(
                          label: Text(resolved > 0 ? 'Resolved ($resolved)' : 'Resolved'),
                          selected: _filterStatus == 'resolved',
                          selectedColor: Colors.green,
                          backgroundColor: Colors.green.shade50,
                          labelStyle: TextStyle(color: _filterStatus == 'resolved' ? Colors.white : Colors.black87),
                          onSelected: (selected) { if (selected) setState(() => _filterStatus = 'resolved'); },
                        ),
                        ChoiceChip(
                          label: Text(dismissed > 0 ? 'Dismissed ($dismissed)' : 'Dismissed'),
                          selected: _filterStatus == 'dismissed',
                          selectedColor: Colors.grey,
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: TextStyle(color: _filterStatus == 'dismissed' ? Colors.white : Colors.black87),
                          onSelected: (selected) { if (selected) setState(() => _filterStatus = 'dismissed'); },
                        ),
                  ]),
                );
              },
            ),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getReportsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allReports = snapshot.data?.docs ?? [];
              final q = _reportsQuery.toLowerCase();
              final filteredByStatus = _filterStatus == 'all'
                  ? allReports
                  : allReports.where((doc) {
                      final data = toStringKeyMap(doc.data());
                      return (data['status'] ?? '').toString().toLowerCase() == _filterStatus;
                    }).toList();
              final filteredReports = q.isEmpty
                  ? filteredByStatus
                  : filteredByStatus.where((doc) {
                      final data = toStringKeyMap(doc.data());
                      final text = ('${data.values.join(' ')} ${doc.id}').toLowerCase();
                      return text.contains(q);
                    }).toList();

              if (filteredReports.isEmpty) {
                return Center(
                  child: Text(
                    _filterStatus == 'all'
                        ? 'No reports found.'
                        : 'No $_filterStatus reports found.',
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredReports.length,
                itemBuilder: (context, index) {
                  final report = filteredReports[index];
                  final data = toStringKeyMap(report.data());

                  return ReportCard(
                    reportId: report.id,
                    reportData: data,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ReportCard extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const ReportCard({
    super.key,
    required this.reportId,
    required this.reportData,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  String _status = 'pending';
  bool _isUpdating = false;
  String? _reporterName;
  String? _reportedUserName;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _status = widget.reportData['status'] ?? 'pending';
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUserData = true;
    });

    try {
      final reportedByUserId = widget.reportData['reportedByUserId'] as String?;
      final reportedUserId = widget.reportData['reportedUserId'] as String?;

      // Fetch reporter information
      if (reportedByUserId != null) {
        final reporterDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(reportedByUserId)
            .get();

        if (reporterDoc.exists) {
          final reporterData = reporterDoc.data();
          _reporterName = reporterData?['name'] as String? ??
                         reporterData?['email'] as String? ??
                         'User $reportedByUserId';
        } else {
          _reporterName = 'User $reportedByUserId';
        }
      }

      // Fetch reported user information
      if (reportedUserId != null) {
        final reportedUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(reportedUserId)
            .get();

        if (reportedUserDoc.exists) {
          final reportedUserData = reportedUserDoc.data();
          _reportedUserName = reportedUserData?['name'] as String? ??
                             reportedUserData?['email'] as String? ??
                             'User $reportedUserId';
        } else {
          _reportedUserName = 'User $reportedUserId';
        }
      }
    } catch (e) {
      // Fallback to user IDs if fetching fails
      _reporterName = widget.reportData['reportedByUserId'] ?? 'Unknown';
      _reportedUserName = widget.reportData['reportedUserId'] ?? 'Unknown';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  Future<void> _updateReportStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('user_reports')
          .doc(widget.reportId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _status = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report marked as $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update report: $e')),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _deleteReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text(
          'Are you sure you want to permanently delete this report? '
          'This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('user_reports')
          .doc(widget.reportId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully')),
        );
        // The report will disappear from the list due to the stream
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = widget.reportData['timestamp'] as Timestamp?;
    final reason = widget.reportData['reason'] as String?;
    final details = widget.reportData['details'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Report: ${reason ?? 'Unknown'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingUserData) ...[
              const SizedBox(
                height: 20,
                child: LinearProgressIndicator(),
              ),
            ] else ...[
              Text(
                'Reported User: ${_reportedUserName ?? 'Unknown'}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'Reported By: ${_reporterName ?? 'Unknown'}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (createdAt != null) ...[
              Text(
                'Date: ${_formatDate(createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (details != null && details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Details: $details',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_status == 'pending') ...[
                  TextButton(
                    onPressed: _isUpdating ? null : () => _updateReportStatus('dismissed'),
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isUpdating ? null : () => _updateReportStatus('resolved'),
                    child: const Text('Mark Resolved'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      if (_status == 'dismissed') ...[
                        TextButton(
                          onPressed: _isUpdating ? null : _deleteReport,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          child: const Text('Delete Report'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'Status: ${_status.toUpperCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;

    switch (_status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'Resolved';
        break;
      case 'dismissed':
        color = Colors.grey;
        label = 'Dismissed';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class UsersManagementTab extends StatelessWidget {
  const UsersManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final userData = toStringKeyMap(userDoc.data());

            return UserManagementCard(
              userId: userDoc.id,
              userData: userData,
            );
          },
        );
      },
    );
  }
}

class UserManagementCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserManagementCard({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = userData['name'] as String? ?? 'Unknown';
    final email = userData['email'] as String? ?? 'No email';
    final role = userData['role'] as String? ?? 'User';
    final reportsCount = userData['reportsCount'] as int? ?? 0;
    final badges = (userData['badges'] as List<dynamic>?)?.cast<String>() ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: reportsCount > 0 ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: reportsCount > 0 ? Colors.red.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Reports: $reportsCount',
                    style: TextStyle(
                      color: reportsCount > 0 ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Role: $role',
              style: theme.textTheme.bodySmall,
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: badges.map((badge) => Chip(
                  label: Text(
                    badge,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(color: theme.colorScheme.primary),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAnalyticsData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard('Total Users', data['totalUsers']?.toString() ?? '0'),
            _buildStatCard('Total Reports', data['totalReports']?.toString() ?? '0'),
            _buildStatCard('Pending Reports', data['pendingReports']?.toString() ?? '0'),
            _buildStatCard('Reviewed Reports', data['reviewedReports']?.toString() ?? '0'),
            _buildStatCard('Users with Reports', data['usersWithReports']?.toString() ?? '0'),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getAnalyticsData() async {
    try {
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final reportsSnap = await FirebaseFirestore.instance.collection('user_reports').get();

      final totalUsers = usersSnap.docs.length;
      final totalReports = reportsSnap.docs.length;

      final pendingReports = reportsSnap.docs
          .where((doc) => (doc.data()['status'] ?? 'pending') == 'pending')
          .length;

      final reviewedReports = reportsSnap.docs
          .where((doc) => doc.data()['status'] == 'reviewed')
          .length;

      final usersWithReports = usersSnap.docs
          .where((doc) => (doc.data()['reportsCount'] ?? 0) > 0)
          .length;

      return {
        'totalUsers': totalUsers,
        'totalReports': totalReports,
        'pendingReports': pendingReports,
        'reviewedReports': reviewedReports,
        'usersWithReports': usersWithReports,
      };
    } catch (e) {
      return {};
    }
  }
}

