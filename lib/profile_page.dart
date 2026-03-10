import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';
import 'auth_page.dart';
import 'jobs_page.dart';
import 'marketplace_page.dart';
import 'rooms_page.dart';
import 'services/user_stats_service.dart';
import 'services/security_service.dart';
import 'services/notification_service.dart';
import 'services/follow_service.dart';
import 'settings_page.dart';
import 'user_chat_page.dart';
import 'verify_identity_page.dart';
import 'edit_profile_page.dart';
import 'bookmarks_page.dart';
import 'help_support_page.dart';
import 'followers_page.dart';

class ProfilePage extends StatefulWidget {
  final String? profileUserId;
  final String? displayNameOverride;

  const ProfilePage({super.key, this.profileUserId, this.displayNameOverride});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class UserReviewsPage extends StatelessWidget {
  final String userId;
  final String displayName;

  const UserReviewsPage({
    super.key,
    required this.userId,
    required this.displayName,
  });

  static DateTime _readCreatedAt(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static int? _readRating(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (Firebase.apps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reviews')),
        body: const Center(child: Text('Reviews are not available offline.')),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('user_reviews')
        .where('targetUserId', isEqualTo: userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load reviews.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? const [];
          final reviews =
              docs
                  .map((d) {
                    final data = d.data();
                    final rating = _readRating(data['rating']);
                    final createdAt = _readCreatedAt(data['createdAt']);
                    final comment = (data['comment'] ?? '').toString();
                    final reviewerUserId = (data['reviewerUserId'] ?? '')
                        .toString();
                    return (
                      rating: rating,
                      createdAt: createdAt,
                      comment: comment,
                      reviewerUserId: reviewerUserId,
                    );
                  })
                  .where((r) => r.rating != null)
                  .toList(growable: false)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final ratingValues = reviews
              .map((r) => r.rating)
              .whereType<int>()
              .where((v) => v >= 1 && v <= 5)
              .toList(growable: false);

          final count = ratingValues.length;
          final average = count == 0
              ? null
              : ratingValues.reduce((a, b) => a + b) / count;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          average == null
                              ? 'No reviews yet'
                              : '${average.toStringAsFixed(1)} ($count reviews)',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (reviews.isEmpty)
                const Center(child: Text('No reviews yet.'))
              else
                ...reviews.map((r) {
                  final reviewerName =
                      AuthService.getUserById(r.reviewerUserId)?.name ??
                      'Community member';

                  final stars = List.generate(5, (i) {
                    final filled = (r.rating ?? 0) >= (i + 1);
                    return Icon(
                      filled ? Icons.star : Icons.star_border,
                      size: 16,
                      color: filled
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF9CA3AF),
                    );
                  });

                  final date =
                      '${r.createdAt.day.toString().padLeft(2, '0')}/${r.createdAt.month.toString().padLeft(2, '0')}/${r.createdAt.year}';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  reviewerName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                date,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(children: stars),
                          if (r.comment.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              r.comment.trim(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _ProfilePageState extends State<ProfilePage> {
  final bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showContributorCongrats = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _idSubmissionListener;
  String? _latestSubmissionStatus;
  String? _latestSubmissionReviewReason;
  String? _previousSubmissionStatus;

  // Profile user ID (can be different from current user for viewing other profiles)
  late final String? _profileUserId;
  late final bool _isSelf;

  // Australian states and territories (unused here; state selection moved to EditProfilePage)

  // Common languages (moved to EditProfilePage)

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  List<String> _badges = [];

  // Image picker moved to EditProfilePage
  final _securityService = SecurityService();

  // In-app password change removed; using password-reset email flow instead.

  User? _currentUser;

  Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('user_reviews')
        .where('targetUserId', isEqualTo: userId)
        .snapshots();
  }

  ({double? average, int count}) _computeRatingSummary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return (average: null, count: 0);
    var sum = 0;
    var count = 0;
    for (final d in docs) {
      final data = d.data();
      final v = data['rating'];
      final r = (v is int)
          ? v
          : (v is num)
          ? v.toInt()
          : int.tryParse(v?.toString() ?? '');
      if (r == null) continue;
      if (r < 1 || r > 5) continue;
      sum += r;
      count += 1;
    }
    if (count == 0) return (average: null, count: 0);
    return (average: sum / count, count: count);
  }

  void _openReviews() {
    final user = _currentUser;
    final userId = _profileUserId!;
    if (user == null) return;

    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reviews are not available offline')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserReviewsPage(userId: userId, displayName: user.name),
      ),
    );
  }

  void _openFollowersPage(BuildContext context) {
    final user = _currentUser;
    final userId = _profileUserId;
    if (user == null || userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowersPage(
          userId: userId,
          userName: user.name,
          showFollowers: true,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _profileUserId = widget.profileUserId ?? AuthState.currentUserId;
    _isSelf = _profileUserId == AuthState.currentUserId;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = _profileUserId;
    if (userId != null) {
      User? user = AuthService.getUserById(userId);

      // If user not in local cache, try to fetch from Firestore
      if (user == null && Firebase.apps.isNotEmpty) {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          if (snap.exists) {
            final data = snap.data() ?? {};
            user = User(
              id: userId,
              email: (data['email'] as String?) ?? '',
              passwordHash: '',
              name:
                  (data['name'] as String?) ??
                  widget.displayNameOverride ??
                  'User',
              phone: data['phone'] as String?,
              state: data['state'] as String?,
              location: data['location'] as String?,
              role: (data['role'] as String?) ?? 'User',
              birthday: data['birthday'] != null
                  ? (data['birthday'] is Timestamp
                        ? (data['birthday'] as Timestamp).toDate()
                        : DateTime.tryParse(data['birthday'].toString()))
                  : null,
              profilePicture: data['profilePicture'] as String?,
              bio: data['bio'] as String?,
              languages: (data['languages'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList(),
              badges:
                  (data['badges'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  const [],
              rating: (data['rating'] as num?)?.toDouble(),
              ratingCount: data['ratingCount'] as int?,
              showPhone: (data['showPhone'] as bool?) ?? false,
              showEmail: (data['showEmail'] as bool?) ?? false,
              createdAt: data['createdAt'] != null
                  ? (data['createdAt'] is Timestamp
                        ? (data['createdAt'] as Timestamp).toDate()
                        : DateTime.tryParse(data['createdAt'].toString()) ??
                              DateTime.now())
                  : DateTime.now(),
            );
            // Cache the user for future use
            AuthService.upsertUser(user);
          }
        } catch (e) {
          debugPrint('Failed to fetch user from Firestore: $e');
        }
      }

      if (user == null) {
        // User not found in local cache or Firestore, create a minimal user object
        // This can happen when viewing seller profiles from marketplace items
        final minimalUser = User(
          id: userId,
          email: 'unknown@example.com', // Placeholder email for unknown users
          passwordHash: '', // Empty password hash for unknown users
          name: widget.displayNameOverride ?? 'Unknown User',
          phone: null,
          bio: null,
          location: null,
          role: 'User',
          badges: [],
          showPhone: false,
          showEmail: false,
          state: null,
          birthday: null,
          profilePicture: null,
          languages: null,
          createdAt: DateTime.now(),
        );
        setState(() {
          _currentUser = minimalUser;
          _nameController.text = minimalUser.name;
          _phoneController.text = minimalUser.phone ?? '';
          _bioController.text = minimalUser.bio ?? '';
          _locationController.text = minimalUser.location ?? '';
          _badges = List<String>.from(minimalUser.badges);
        });
        return;
      }
      final resolvedUser = user;

      setState(() {
        _currentUser = resolvedUser;
        _nameController.text = resolvedUser.name;
        _phoneController.text = resolvedUser.phone ?? '';
        _bioController.text = resolvedUser.bio ?? '';
        _locationController.text = resolvedUser.location ?? '';
        _badges = List<String>.from(resolvedUser.badges);
      });
      // Check authoritative contributor level / verified badge in Firestore
      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get()
            .then((snap) {
              if (!snap.exists) return;
              final data = snap.data() ?? {};
              final level = (data['contributorLevel'] ?? 0) is int
                  ? (data['contributorLevel'] ?? 0) as int
                  : int.tryParse(
                          (data['contributorLevel'] ?? '0').toString(),
                        ) ??
                        0;
              final verified = (data['verifiedBadge'] ?? false) as bool;
              if ((level >= 2) || verified) {
                if (!mounted) return;
                setState(() {
                  _showContributorCongrats = true;
                });
              }

              // Auto-assign 'trusted' badge client-side when basic criteria met.
              // Criteria: account age >= 30 days AND at least 3 reviews received.
              // This attempts an idempotent `arrayUnion` write; if Firestore rules
              // prevent the write the failure is ignored and the UI keeps showing
              // progress information.
              if (_isSelf) {
                Future.microtask(() async {
                  try {
                    final createdRaw = data['createdAt'];
                    DateTime? createdAt;
                    if (createdRaw is Timestamp) {
                      createdAt = createdRaw.toDate();
                    } else if (createdRaw is DateTime) {
                      createdAt = createdRaw;
                    }
                    // Fallback: if resolved user object has createdAt, use that
                    if (createdAt == null) {
                      try {
                        createdAt = _currentUser?.createdAt;
                      } catch (_) {}
                    }
                    if (createdAt == null) return;
                    final accountAgeDays = DateTime.now()
                        .difference(createdAt)
                        .inDays;
                    if (accountAgeDays < 30) return;

                    final reviewsSnap = await FirebaseFirestore.instance
                        .collection('user_reviews')
                        .where('targetUserId', isEqualTo: userId)
                        .get();
                    final reviewCount = reviewsSnap.docs.length;
                    if (reviewCount < 3) return;

                    // If criteria met and user doesn't already have trusted badge, add it.
                    final badgesRaw = data['badges'];
                    final hasTrusted =
                        badgesRaw is List && badgesRaw.contains('trusted') ||
                        _badges.contains('trusted');
                    if (!hasTrusted) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .set({
                            'badges': FieldValue.arrayUnion(['trusted']),
                            'trustedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                      if (!mounted) return;
                      setState(() {
                        if (!_badges.contains('trusted')) {
                          _badges.add('trusted');
                        }
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Congratulations — you are now Trusted!',
                            ),
                          ),
                        );
                      }
                    }
                  } catch (_) {
                    // ignore failures (rules may prevent client-side badge writes)
                  }
                });
              }
            })
            .catchError((_) {});

        // Listen for the latest id_submissions document for this user so
        // we can show pending/rejected messages and disable repeat submissions.
        try {
          final q = FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('id_submissions')
              .orderBy('createdAt', descending: true)
              .limit(1);
          _idSubmissionListener?.cancel();
          _idSubmissionListener = q.snapshots().listen((snap) {
            if (!mounted) return;
            if (snap.docs.isEmpty) {
              setState(() {
                _latestSubmissionStatus = null;
                _latestSubmissionReviewReason = null;
              });
              return;
            }
            final doc = snap.docs.first;
            final data = doc.data();
            final newStatus = (data['status'] as String?);
            final newReason = (data['reviewReason'] as String?);

            // If status changed and this is the current user's profile,
            // surface a notification for approved / rejected transitions.
            final shouldNotify =
                _isSelf &&
                _previousSubmissionStatus != null &&
                _previousSubmissionStatus != newStatus;

            if (shouldNotify &&
                (newStatus == 'approved' ||
                    newStatus == 'rejected' ||
                    newStatus == 'auto_rejected')) {
              final title = newStatus == 'approved'
                  ? 'Verification approved'
                  : 'Verification rejected';
              final body = (newStatus == 'approved')
                  ? 'Your identity verification has been approved. Thank you!'
                  : 'Your identity verification was rejected${newReason != null && newReason.trim().isNotEmpty ? ': $newReason' : '.'}';

              // Show an in-app SnackBar and a dialog so the user notices the change.
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(body)));
                // Also show a system/local notification so the user receives
                // the update when the app is in background or not focused.
                NotificationService().showNotification(
                  title: title,
                  body: body,
                );
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(title),
                    content: Text(body),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.bookmark_outline),
                        title: const Text('Bookmarks'),
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          await Future<void>.delayed(
                            const Duration(milliseconds: 50),
                          );
                          if (!mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookmarksPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }
            }

            setState(() {
              _previousSubmissionStatus = _latestSubmissionStatus;
              _latestSubmissionStatus = newStatus;
              _latestSubmissionReviewReason = newReason;
            });
          });
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _idSubmissionListener?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    // password controllers removed
    super.dispose();
  }

  // Password reset functionality moved to `SettingsPage`.

  // Profile picture picker moved to EditProfilePage; kept out of this view to avoid duplicate code.

  // Language selection UI moved to EditProfilePage; this helper is no longer used here.

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isOAuthUser = _currentUser!.passwordHash.isEmpty;

    final profileUserId = _profileUserId;
    final canLoadReviews = profileUserId != null && Firebase.apps.isNotEmpty;

    Widget buildPublicCard({double? rating, int? ratingCount}) {
      return _UserCardPublicView(
        user: _currentUser!,
        theme: theme,
        rating: rating,
        ratingCount: ratingCount,
        onTapRating: _openReviews,
        onMessage: _messageUser,
        onCall: _makeCall,
        onProvideReview: _provideReview,
        onViewListings: () => _showListingsSheet(context, isSelf: false),
        onReport: () => _reportUser(context),
      );
    }

    if (!_isSelf) {
      if (!canLoadReviews) {
        return buildPublicCard(
          rating: _currentUser!.rating,
          ratingCount: _currentUser!.ratingCount,
        );
      }

      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _reviewsStream(profileUserId),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          final summary = _computeRatingSummary(docs);
          return buildPublicCard(
            rating: summary.average,
            ratingCount: summary.count,
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Navigate to full-screen edit page
              final res = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
              // If the edit page saved changes, reload the user data
              if (res == true) _loadUserData();
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: LinearProgressIndicator(),
                ),
              if (Firebase.apps.isEmpty)
                _SelfHeader(
                  user: _currentUser!,
                  theme: theme,
                  badges: _badges,
                  rating: _currentUser!.rating,
                  ratingCount: _currentUser!.ratingCount,
                  onTapRating: _openReviews,
                  onViewListings: () =>
                      _showListingsSheet(context, isSelf: true),
                  onViewFollowers: () => _openFollowersPage(context),
                  joinedAt: _currentUser!.createdAt,
                  statsFuture: UserStatsService.tryLoad(_currentUser!.id),
                )
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _reviewsStream(_currentUser!.id),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? const [];
                    final summary = _computeRatingSummary(docs);
                    return _SelfHeader(
                      user: _currentUser!,
                      theme: theme,
                      badges: _badges,
                      rating: summary.average,
                      ratingCount: summary.count,
                      onTapRating: _openReviews,
                      onViewListings: () =>
                          _showListingsSheet(context, isSelf: true),
                      onViewFollowers: () => _openFollowersPage(context),
                      joinedAt: _currentUser!.createdAt,
                      statsFuture: UserStatsService.tryLoad(_currentUser!.id),
                    );
                  },
                ),
              const SizedBox(height: 16),

              if (_showContributorCongrats && _isSelf)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.celebration, color: Color(0xFF065F46)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Congratulations! You are now a Contributor. Together, we can create a stronger, more supportive, and better-connected Nepalese community across Australia.',
                            style: TextStyle(color: Colors.green.shade900),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Dismiss',
                          icon: Icon(Icons.close, color: Colors.green.shade900),
                          onPressed: () =>
                              setState(() => _showContributorCongrats = false),
                        ),
                      ],
                    ),
                  ),
                ),

              // Become a Contributor (only show if not already approved)
              if (!(_showContributorCongrats ||
                  _latestSubmissionStatus == 'approved'))
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Card(
                    elevation: 0,
                    color: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _latestSubmissionStatus == 'pending'
                          ? null
                          : () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                showDragHandle: true,
                                builder: (ctx) => const VerifyIdentityPage(),
                              );
                              _loadUserData();
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.volunteer_activism,
                                size: 32,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Become a Contributor',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Help build our community and unlock special features.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Menu-style list items
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Account settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('View profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final res = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        );
                        if (res == true) _loadUserData();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Get help'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Show submission status messages for the current user
              if (_isSelf && !_showContributorCongrats)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                  child: () {
                    if (_latestSubmissionStatus == 'pending') {
                      return Card(
                        color: Colors.amber.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.hourglass_top,
                                color: Color(0xFF92400E),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your request is being reviewed by admin',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_latestSubmissionStatus == 'rejected' ||
                        _latestSubmissionStatus == 'auto_rejected') {
                      final reason = (_latestSubmissionReviewReason ?? '')
                          .trim();
                      return Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFF991B1B),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Your request was rejected, tap Become a contributor button to send request again.',
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (reason.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Reason: $reason',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  }(),
                ),

              const SizedBox(height: 22),

              // OAuth Badge
              if (isOAuthUser)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'OAuth Account',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Inline profile form removed; edits happen in EditProfilePage.

              // Error/Success Messages
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // Profile form removed — edits happen on EditProfilePage
              const SizedBox(height: 16),

              // Profile actions moved to Settings or EditProfilePage
            ],
          ),
        ),
      ),
    );
  }

  // Profile field builder consolidated into EditProfilePage; removed to avoid duplication.

  // Date formatting helper moved/unused; use helpers from EditProfilePage or shared util if needed.

  Future<void> _makeCall() async {
    final user = _currentUser;
    if (user == null) return;
    if (!user.showPhone || user.phone == null || user.phone!.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number not available')),
        );
      }
      return;
    }

    final phoneNumber = user.phone!.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      // ignore: deprecated_member_use
      if (await canLaunchUrl(phoneUri)) {
        // ignore: deprecated_member_use
        await launchUrl(phoneUri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone call')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone call')),
        );
      }
    }
  }

  Future<void> _messageUser() async {
    final user = _currentUser;
    if (user == null) return;

    final currentUserId = AuthState.currentUserId;
    if (currentUserId == null) return;

    // Don't allow messaging yourself
    if (currentUserId == user.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot message yourself')),
        );
      }
      return;
    }

    final canSms = user.showPhone && (user.phone ?? '').trim().isNotEmpty;
    final canEmail = user.showEmail && (user.email).trim().isNotEmpty;

    final publicName = (user.name.trim().split(' ').firstOrNull ?? user.name)
        .trim();
    final message =
        'Hi ${publicName.isEmpty ? 'there' : publicName}, I saw your profile on Nepalese in Australia. Is it ok to chat?';

    // If only one external option is available, open chat directly
    if (!canSms && !canEmail) {
      _openChatWithUser(user.id, user.name);
      return;
    }

    if (canSms && !canEmail) {
      await _launchSms(user.phone!, message);
      return;
    }
    if (!canSms && canEmail) {
      await _launchEmail(user.email, subject: 'Hello', body: message);
      return;
    }

    // Show options including in-app messaging
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message ${publicName.isEmpty ? 'User' : publicName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('In-App Message'),
                  subtitle: const Text('Start a conversation within the app'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openChatWithUser(user.id, user.name);
                  },
                ),
                if (canSms)
                  ListTile(
                    leading: const Icon(Icons.sms_outlined),
                    title: const Text('SMS'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _launchSms(user.phone!, message);
                    },
                  ),
                if (canEmail)
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _launchEmail(user.email, subject: 'Hello', body: message);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchSms(String phone, String body) async {
    final cleanedNumber = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanedNumber,
      queryParameters: <String, String>{'body': body},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open messaging app')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open messaging app')),
        );
      }
    }
  }

  Future<void> _launchEmail(
    String email, {
    required String subject,
    required String body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: <String, String>{'subject': subject, 'body': body},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  void _openChatWithUser(String userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UserChatPage(otherUserId: userId, otherUserName: userName),
      ),
    );
  }

  Future<void> _provideReview() async {
    final user = _currentUser;
    final reviewerId = AuthState.currentUserId;
    if (user == null) return;
    if (reviewerId == null || reviewerId.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to provide a review')),
        );
      }
      return;
    }
    if (reviewerId == user.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot review yourself')),
        );
      }
      return;
    }

    final commentController = TextEditingController();
    var rating = 0;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Provide review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rating'),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      final selected = value <= rating;
                      return IconButton(
                        tooltip: '$value star${value == 1 ? '' : 's'}',
                        onPressed: () => setDialogState(() => rating = value),
                        icon: Icon(
                          selected ? Icons.star : Icons.star_border,
                          color: selected
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF9CA3AF),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    maxLength: 240,
                    decoration: const InputDecoration(
                      labelText: 'Comment (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: rating == 0
                            ? null
                            : () => Navigator.pop(dialogContext, true),
                        child: Text(
                          rating == 0 ? 'Submit' : 'Submit ($rating★)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    final rawComment = commentController.text;
    commentController.dispose();
    if (submitted != true) return;

    final sanitizedComment = _securityService.sanitizeInput(
      rawComment,
      maxLength: 240,
    );
    if (_securityService.containsProhibitedContent(sanitizedComment)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment contains prohibited content')),
        );
      }
      return;
    }

    final oldAvg = user.rating ?? 0.0;
    final oldCount = user.ratingCount ?? 0;
    final newCount = oldCount + 1;
    final newAvg = ((oldAvg * oldCount) + rating) / newCount;

    _updateUserAggregatesInMemory(user, newAvg, newCount);

    if (mounted) {
      setState(() {
        _currentUser = User(
          id: user.id,
          email: user.email,
          passwordHash: user.passwordHash,
          name: user.name,
          phone: user.phone,
          state: user.state,
          location: user.location,
          role: user.role,
          birthday: user.birthday,
          profilePicture: user.profilePicture,
          bio: user.bio,
          languages: user.languages,
          badges: user.badges,
          rating: newAvg,
          ratingCount: newCount,
          showPhone: user.showPhone,
          showEmail: user.showEmail,
          createdAt: user.createdAt,
        );
      });
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('user_reviews').add({
          'targetUserId': user.id,
          'reviewerUserId': reviewerId,
          'rating': rating,
          'comment': sanitizedComment,
          'createdAt': Timestamp.now(),
        });
      } catch (_) {
        // Best-effort.
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted. Thank you!')),
      );
    }
  }

  void _updateUserAggregatesInMemory(
    User user,
    double rating,
    int ratingCount,
  ) {
    AuthService.upsertUser(
      User(
        id: user.id,
        email: user.email,
        passwordHash: user.passwordHash,
        name: user.name,
        phone: user.phone,
        state: user.state,
        location: user.location,
        role: user.role,
        birthday: user.birthday,
        profilePicture: user.profilePicture,
        bio: user.bio,
        languages: user.languages,
        badges: user.badges,
        rating: rating,
        ratingCount: ratingCount,
        showPhone: user.showPhone,
        showEmail: user.showEmail,
        createdAt: user.createdAt,
      ),
    );
  }

  Future<void> _showListingsSheet(
    BuildContext context, {
    required bool isSelf,
  }) async {
    final profileUserId = _profileUserId;
    final statsFuture = (profileUserId == null)
        ? Future<UserStats?>.value(null)
        : UserStatsService.tryLoad(profileUserId);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        Future<void> closeAndNavigate(Widget page) async {
          Navigator.pop(context);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          if (!mounted) return;
          await Navigator.push(
            this.context,
            MaterialPageRoute(builder: (_) => page),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSelf ? 'My Listings' : 'Listings',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSelf
                      ? 'Only shows listings posted by you.'
                      : 'Only shows listings posted by this user.',
                ),
                const SizedBox(height: 14),
                FutureBuilder<UserStats?>(
                  future: statsFuture,
                  builder: (context, snapshot) {
                    final stats = snapshot.data;
                    final roomsCount = stats?.roomsPosted;
                    final jobsCount = stats?.jobsPosted;
                    // Removed unused variable 'eventsCount'
                    final itemsCount = stats?.itemsForSale;
                    final itemsSoldCount = stats?.itemsSold;

                    String fmt(int? v) => v == null ? '—' : v.toString();

                    Widget trailingCount(String text) => Text(
                      text,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    );

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.home_outlined),
                          title: const Text('Rooms'),
                          trailing: trailingCount(fmt(roomsCount)),
                          onTap: () {
                            if (profileUserId == null ||
                                profileUserId.isEmpty) {
                              closeAndNavigate(const RoomsPage());
                              return;
                            }
                            closeAndNavigate(
                              RoomsPage(
                                filterUserId: profileUserId,
                                titleOverride: isSelf ? 'My Rooms' : 'Rooms',
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.work_outline),
                          title: const Text('Jobs'),
                          trailing: trailingCount(fmt(jobsCount)),
                          onTap: () {
                            if (profileUserId == null ||
                                profileUserId.isEmpty) {
                              closeAndNavigate(
                                const JobsPage(enableAdzuna: false),
                              );
                              return;
                            }
                            closeAndNavigate(
                              JobsPage(
                                enableAdzuna: false,
                                filterUserId: profileUserId,
                                titleOverride: isSelf ? 'My Jobs' : 'Jobs',
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.shopping_bag_outlined),
                          title: const Text('Buy & Sell'),
                          subtitle: itemsSoldCount == null
                              ? null
                              : Text('Sold: ${fmt(itemsSoldCount)}'),
                          trailing: trailingCount(fmt(itemsCount)),
                          onTap: () {
                            if (profileUserId == null ||
                                profileUserId.isEmpty) {
                              closeAndNavigate(const MarketplacePage());
                              return;
                            }
                            closeAndNavigate(
                              MarketplacePage(
                                filterSellerId: profileUserId,
                                titleOverride: isSelf
                                    ? 'My Buy & Sell'
                                    : 'Buy & Sell',
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reportUser(BuildContext context) async {
    final reportData = await showDialog<_ReportData>(
      context: context,
      builder: (context) => const _ReportUserDialog(),
    );

    if (reportData != null && context.mounted) {
      try {
        // Submit report to Firestore
        await FirebaseFirestore.instance.collection('user_reports').add({
          'reportedUserId': _profileUserId,
          'reportedByUserId': AuthState.currentUserId,
          'reason': reportData.reason,
          'details': reportData.details,
          'status': 'pending', // pending, reviewed, dismissed
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Report submitted successfully. Our team will review it within 24 hours.',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit report: $e')),
          );
        }
      }
    }
  }
}

class _ReportData {
  final String reason;
  final String details;

  const _ReportData({required this.reason, required this.details});
}

class _ReportUserDialog extends StatefulWidget {
  const _ReportUserDialog();

  @override
  State<_ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<_ReportUserDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();

  static const List<String> _reportReasons = [
    'Spam or unwanted content',
    'Harassment or bullying',
    'Inappropriate content',
    'Fraud or scam',
    'Fake account',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Report User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us keep the community safe by reporting inappropriate behavior.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Reason for report:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
              child: Column(
                children: _reportReasons
                    .map(
                      (reason) => RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Additional details (optional):',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Please provide any additional context or details...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedReason != null
              ? () => Navigator.pop(
                  context,
                  _ReportData(
                    reason: _selectedReason!,
                    details: _detailsController.text.trim(),
                  ),
                )
              : null,
          child: const Text('Submit Report'),
        ),
      ],
    );
  }
}

class _SelfHeader extends StatelessWidget {
  final User user;
  final ThemeData theme;
  final List<String> badges;
  final double? rating;
  final int? ratingCount;
  final VoidCallback onTapRating;
  final VoidCallback onViewListings;
  final VoidCallback onViewFollowers;
  final DateTime joinedAt;
  final Future<UserStats?> statsFuture;

  const _SelfHeader({
    required this.user,
    required this.theme,
    required this.badges,
    required this.rating,
    required this.ratingCount,
    required this.onTapRating,
    required this.onViewListings,
    required this.onViewFollowers,
    required this.joinedAt,
    required this.statsFuture,
  });

  @override
  Widget build(BuildContext context) {
    final yearsOnApp = DateTime.now().difference(joinedAt).inDays ~/ 365;
    final location = user.location?.isNotEmpty == true
        ? user.location!
        : user.state?.isNotEmpty == true
        ? '${user.state}, Australia'
        : 'Australia';

    return Column(
      children: [
        // Main profile card
        Card(
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Profile photo and name
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Profile photo with verified badge
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage:
                                (user.profilePicture != null &&
                                    user.profilePicture!.isNotEmpty)
                                ? FileImage(File(user.profilePicture!))
                                      as ImageProvider
                                : null,
                            child:
                                (user.profilePicture == null ||
                                    user.profilePicture!.isEmpty)
                                ? Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 44,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          // Verified badge
                          if (badges.contains('verified') ||
                              badges.contains('trusted'))
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE91E63),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        user.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // Location
                      Text(
                        location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right side: Stats
                Expanded(
                  flex: 2,
                  child: FutureBuilder<UserStats?>(
                    future: statsFuture,
                    builder: (context, snap) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trusted Badge status
                          _TrustedBadgeIndicator(
                            isTrusted: badges.contains('trusted'),
                            accountAgeDays: DateTime.now()
                                .difference(joinedAt)
                                .inDays,
                            reviewCount: ratingCount ?? 0,
                          ),
                          const Divider(height: 24),
                          // Reviews stat
                          InkWell(
                            onTap: onTapRating,
                            child: _StatItem(
                              value: (ratingCount ?? 0).toString(),
                              label: 'Reviews',
                            ),
                          ),
                          const Divider(height: 24),
                          // Years on app
                          _StatItem(
                            value: yearsOnApp < 1
                                ? '<1'
                                : yearsOnApp.toString(),
                            label: 'Years on HamroOZ',
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // My Listings & Followers cards (styled like Become a Contributor)
        FutureBuilder<UserStats?>(
          future: statsFuture,
          builder: (context, snap) {
            final s = snap.data;
            final hasListings =
                (s?.roomsPosted ?? 0) > 0 ||
                (s?.jobsPosted ?? 0) > 0 ||
                (s?.itemsForSale ?? 0) > 0;
            final totalListings =
                (s?.roomsPosted ?? 0) +
                (s?.jobsPosted ?? 0) +
                (s?.itemsForSale ?? 0);

            return Column(
              children: [
                // My Listings card
                _FeatureCard(
                  icon: Icons.list_alt_outlined,
                  iconColor: Colors.blue.shade700,
                  title: 'My Listings',
                  subtitle: hasListings
                      ? 'You have $totalListings active listing${totalListings == 1 ? '' : 's'}'
                      : 'View and manage your posted listings',
                  showNewBadge: hasListings,
                  onTap: onViewListings,
                ),
                const SizedBox(height: 8),
                // Followers card
                _FeatureCard(
                  icon: Icons.people_outline,
                  iconColor: Colors.deepOrange,
                  title: 'Followers',
                  subtitle: 'See who follows you and who you follow',
                  showNewBadge: false,
                  onTap: onViewFollowers,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _TrustedBadgeIndicator extends StatelessWidget {
  final bool isTrusted;
  final int accountAgeDays;
  final int reviewCount;

  const _TrustedBadgeIndicator({
    required this.isTrusted,
    required this.accountAgeDays,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    if (isTrusted) {
      // Already trusted - show badge
      return Row(
        children: [
          Icon(Icons.verified, color: Colors.green.shade600, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trusted',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              Text(
                'Verified member',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      );
    }

    // Not yet trusted - show progress
    final daysProgress = (accountAgeDays / 30).clamp(0.0, 1.0);
    final reviewsProgress = (reviewCount / 3).clamp(0.0, 1.0);
    final overallProgress = (daysProgress + reviewsProgress) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 6),
            Text(
              'Trusted Badge',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: overallProgress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              overallProgress >= 1.0 ? Colors.green : Colors.blue.shade400,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${accountAgeDays.clamp(0, 30)}/30 days • ${reviewCount.clamp(0, 3)}/3 reviews',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool showNewBadge;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.showNewBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (showNewBadge) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade400,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCardPublicView extends StatefulWidget {
  final User user;
  final ThemeData theme;
  final double? rating;
  final int? ratingCount;
  final VoidCallback onTapRating;
  final VoidCallback onMessage;
  final Future<void> Function() onCall;
  final VoidCallback onProvideReview;
  final VoidCallback onViewListings;
  final VoidCallback onReport;

  const _UserCardPublicView({
    required this.user,
    required this.theme,
    required this.rating,
    required this.ratingCount,
    required this.onTapRating,
    required this.onMessage,
    required this.onCall,
    required this.onProvideReview,
    required this.onViewListings,
    required this.onReport,
  });

  @override
  State<_UserCardPublicView> createState() => _UserCardPublicViewState();
}

class _UserCardPublicViewState extends State<_UserCardPublicView> {
  bool _isFollowing = false;
  bool _isLoadingFollow = true;
  bool _isToggling = false;
  int _followerCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    final currentUserId = AuthState.currentUserId;
    if (currentUserId == null || currentUserId == widget.user.id) {
      setState(() => _isLoadingFollow = false);
      return;
    }

    final isFollowing = await FollowService.isFollowing(
      currentUserId,
      widget.user.id,
    );
    final followerCount = await FollowService.getFollowerCount(widget.user.id);
    final followingCount = await FollowService.getFollowingCount(
      widget.user.id,
    );

    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
        _followerCount = followerCount;
        _followingCount = followingCount;
        _isLoadingFollow = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = AuthState.currentUserId;
    if (currentUserId == null || _isToggling) return;

    setState(() => _isToggling = true);

    final success = await FollowService.toggleFollow(
      currentUserId,
      widget.user.id,
    );

    if (mounted && success) {
      setState(() {
        _isFollowing = !_isFollowing;
        _followerCount += _isFollowing ? 1 : -1;
        _isToggling = false;
      });
    } else if (mounted) {
      setState(() => _isToggling = false);
    }
  }

  void _openFollowersPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowersPage(
          userId: widget.user.id,
          userName: widget.user.name,
          showFollowers: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final yearsOnApp =
        DateTime.now().difference(widget.user.createdAt).inDays ~/ 365;
    final location = widget.user.location?.isNotEmpty == true
        ? widget.user.location!
        : widget.user.state?.isNotEmpty == true
        ? '${widget.user.state}, Australia'
        : 'Australia';
    final badges = widget.user.badges;
    final hasVerifiedBadge =
        badges.contains('verified') || badges.contains('trusted');
    final languages = widget.user.languages;
    final bio = widget.user.bio;

    final currentUserId = AuthState.currentUserId;
    final canFollow = currentUserId != null && currentUserId != widget.user.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'report') {
                widget.onReport();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Report User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Main profile card (same style as _SelfHeader)
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side: Profile photo and name
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            // Profile photo with verified badge
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 56,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  backgroundImage:
                                      (widget.user.profilePicture != null &&
                                          widget
                                              .user
                                              .profilePicture!
                                              .isNotEmpty)
                                      ? FileImage(
                                              File(widget.user.profilePicture!),
                                            )
                                            as ImageProvider
                                      : null,
                                  child:
                                      (widget.user.profilePicture == null ||
                                          widget.user.profilePicture!.isEmpty)
                                      ? Text(
                                          widget.user.name.isNotEmpty
                                              ? widget.user.name[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 44,
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                // Verified badge
                                if (hasVerifiedBadge)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE91E63),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Name
                            Text(
                              widget.user.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            // Location
                            Text(
                              location,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right side: Stats
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Verified badge indicator
                            if (hasVerifiedBadge)
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.green.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        'Identity confirmed',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    color: Colors.grey.shade500,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Not verified',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            const Divider(height: 24),
                            // Reviews stat
                            InkWell(
                              onTap: widget.onTapRating,
                              child: _StatItem(
                                value: (widget.ratingCount ?? 0).toString(),
                                label: 'Reviews',
                              ),
                            ),
                            const Divider(height: 24),
                            // Years on app
                            _StatItem(
                              value: yearsOnApp < 1
                                  ? '<1'
                                  : yearsOnApp.toString(),
                              label: 'Years on HamroOZ',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Info section (languages, bio)
              if ((languages != null && languages.isNotEmpty) ||
                  (bio != null && bio.isNotEmpty))
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (languages != null && languages.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.language,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Speaks ${languages.join(', ')}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (bio != null && bio.isNotEmpty)
                            const SizedBox(height: 12),
                        ],
                        if (bio != null && bio.isNotEmpty)
                          Text(
                            bio,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Feature cards (Listings & Followers) - same style as self profile
              _FeatureCard(
                icon: Icons.list_alt_outlined,
                iconColor: Colors.blue.shade700,
                title: 'Listings',
                subtitle: 'View active listings by this user',
                showNewBadge: false,
                onTap: widget.onViewListings,
              ),
              const SizedBox(height: 8),
              _FeatureCard(
                icon: Icons.people_outline,
                iconColor: Colors.deepOrange,
                title: 'Followers',
                subtitle: _followerCount > 0
                    ? '$_followerCount followers · $_followingCount following'
                    : 'See connections',
                showNewBadge: false,
                onTap: () => _openFollowersPage(context),
              ),
              const SizedBox(height: 16),

              // Action buttons
              if (canFollow) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: _isLoadingFollow
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton.icon(
                          onPressed: _isToggling ? null : _toggleFollow,
                          icon: Icon(
                            _isFollowing
                                ? Icons.person_remove
                                : Icons.person_add,
                            size: 18,
                          ),
                          label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _isFollowing
                                ? Colors.grey.shade300
                                : theme.colorScheme.primary,
                            foregroundColor: _isFollowing
                                ? Colors.grey.shade700
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: widget.onMessage,
                  icon: const Icon(Icons.message_outlined, size: 18),
                  label: const Text('Message'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: widget.onCall,
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: widget.onProvideReview,
                        icon: const Icon(Icons.star_outline, size: 18),
                        label: const Text('Review'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
