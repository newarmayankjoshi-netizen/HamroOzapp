import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

import 'ai_resume_creator/apply_with_ai_resume_page.dart';
import 'services/security_service.dart';
import 'auth_page.dart';
import 'profile_page.dart';
import 'services/adzuna_jobs_service.dart';
import 'services/firebase_bootstrap.dart';
import 'utils/user_prefill_helper.dart';
import 'services/verification_service.dart';
import 'services/bookmark_service.dart';

// Local community job categories tailored for Nepalese life in Australia.
const String kNepalAusJobCategoryOther = 'Other';

// The exact set of categories shown to users.
const List<String> kNepalAusJobCategoriesUi = [
  'Nepalese Restaurant',
  'Grocery Store',
  'Cleaning Job',
  'Cash Job',
  'Student Job',
  'Community Referral',
];

// Safety bucket for legacy/imported categories.
const List<String> kNepalAusJobCategoriesAll = [
  ...kNepalAusJobCategoriesUi,
  kNepalAusJobCategoryOther,
];

const Map<String, IconData> kNepalAusJobCategoryIcons = {
  'Nepalese Restaurant': Icons.restaurant,
  'Grocery Store': Icons.local_grocery_store,
  'Cleaning Job': Icons.cleaning_services,
  'Cash Job': Icons.attach_money,
  'Student Job': Icons.school,
  'Community Referral': Icons.groups,
  'Other': Icons.work_outline,
};

const Map<String, Color> kNepalAusJobCategoryColors = {
  'Nepalese Restaurant': Color(0xFFEF4444),
  'Grocery Store': Color(0xFF22C55E),
  'Cleaning Job': Color(0xFF14B8A6),
  'Cash Job': Color(0xFFF59E0B),
  'Student Job': Color(0xFF3B82F6),
  'Community Referral': Color(0xFF8B5CF6),
  'Other': Color(0xFF6B7280),
};

const Map<String, String> kNepalAusJobCategoryDescriptions = {
  'Nepalese Restaurant': 'Cook, kitchen hand, waiter, barista',
  'Grocery Store': 'Cashier, stock, deli, customer help',
  'Cleaning Job': 'House, office, hotel cleaning',
  'Cash Job': 'Cash shifts / immediate start',
  'Student Job': 'Part-time roles suitable for students',
  'Community Referral': 'Jobs shared by community members',
  'Other': 'Anything else',
};

String _normalizeJobCategory(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return kNepalAusJobCategoryOther;

  final normalized = value.toLowerCase();
  for (final c in kNepalAusJobCategoriesAll) {
    if (c.toLowerCase() == normalized) return c;
  }

  // Legacy / external category mapping into the 6 buckets.
  if (normalized.contains('nepal') &&
      (normalized.contains('restaurant') || normalized.contains('hospital'))) {
    return 'Nepalese Restaurant';
  }
  if (normalized.contains('restaurant') ||
      normalized.contains('hospital') ||
      normalized.contains('cafe') ||
      normalized.contains('barista') ||
      normalized.contains('wait')) {
    return 'Nepalese Restaurant';
  }
  if (normalized.contains('grocery') ||
      normalized.contains('retail') ||
      normalized.contains('shop') ||
      normalized.contains('store') ||
      normalized.contains('supermarket')) {
    return 'Grocery Store';
  }
  if (normalized.contains('clean') ||
      normalized.contains('housekeep') ||
      normalized.contains('janitor')) {
    return 'Cleaning Job';
  }
  if (normalized.contains('cash')) {
    return 'Cash Job';
  }
  if (normalized.contains('student') ||
      normalized.contains('part-time') ||
      normalized.contains('casual')) {
    return 'Student Job';
  }
  if (normalized.contains('referral') ||
      normalized.contains('community') ||
      normalized.contains('recommended')) {
    return 'Community Referral';
  }

  // Best-effort mapping of common legacy categories.
  if (normalized.contains('education') ||
      normalized.contains('tutor') ||
      normalized.contains('teaching')) {
    return 'Student Job';
  }
  if (normalized.contains('sales') ||
      normalized.contains('customer') ||
      normalized.contains('service') ||
      normalized.contains('admin') ||
      normalized.contains('reception')) {
    return 'Grocery Store';
  }
  if (normalized.contains('transport') ||
      normalized.contains('delivery') ||
      normalized.contains('driver') ||
      normalized.contains('courier') ||
      normalized.contains('logistics')) {
    return 'Student Job';
  }

  return kNepalAusJobCategoryOther;
}

String _extractAustralianStateAbbr(String location) {
  final match = RegExp(
    r'\b(NSW|VIC|QLD|WA|SA|TAS|ACT|NT)\b',
    caseSensitive: false,
  ).firstMatch(location);
  final abbr = match?.group(1)?.toUpperCase() ?? '';
  if (abbr.isNotEmpty) return abbr;

  // Some sources (like Adzuna) often return full state names.
  final normalized = location.toLowerCase();
  if (normalized.contains('new south wales')) return 'NSW';
  if (normalized.contains('victoria')) return 'VIC';
  if (normalized.contains('queensland')) return 'QLD';
  if (normalized.contains('western australia')) return 'WA';
  if (normalized.contains('south australia')) return 'SA';
  if (normalized.contains('tasmania')) return 'TAS';
  if (normalized.contains('australian capital territory') ||
      RegExp(r'\bcanberra\b').hasMatch(normalized)) {
    return 'ACT';
  }
  if (normalized.contains('northern territory')) return 'NT';

  // Capital cities (helps when the source returns only city names).
  if (RegExp(r'\bsydney\b').hasMatch(normalized)) return 'NSW';
  if (RegExp(r'\bmelbourne\b').hasMatch(normalized)) return 'VIC';
  if (RegExp(r'\bbrisbane\b').hasMatch(normalized)) return 'QLD';
  if (RegExp(r'\bperth\b').hasMatch(normalized)) return 'WA';
  if (RegExp(r'\badelaide\b').hasMatch(normalized)) return 'SA';
  if (RegExp(r'\bhobart\b').hasMatch(normalized)) return 'TAS';
  if (RegExp(r'\bdarwin\b').hasMatch(normalized)) return 'NT';

  return '';
}

class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String jobType; // Full-time, Part-time, Contract
  final String salary;
  final String phoneNumber;
  final String email;
  final String category;
  final String sourceUrl;
  final String imageUrl;
  final String createdBy; // User ID who created the job
  final DateTime postedDate;
  final int viewCount;
  final bool isClosed;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.jobType,
    required this.salary,
    required this.phoneNumber,
    required this.email,
    required this.category,
    this.sourceUrl = '',
    this.imageUrl = '',
    required this.createdBy,
    required this.postedDate,
    this.viewCount = 0,
    this.isClosed = false,
  });

  Job copyWith({
    String? title,
    String? company,
    String? location,
    String? description,
    String? jobType,
    String? salary,
    String? phoneNumber,
    String? email,
    String? category,
    String? sourceUrl,
    String? imageUrl,
    DateTime? postedDate,
    int? viewCount,
    bool? isClosed,
  }) {
    return Job(
      id: id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      description: description ?? this.description,
      jobType: jobType ?? this.jobType,
      salary: salary ?? this.salary,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      category: category ?? this.category,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy,
      postedDate: postedDate ?? this.postedDate,
      viewCount: viewCount ?? this.viewCount,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

class JobsPage extends StatefulWidget {
  final bool enableAdzuna;
  final String? filterUserId;
  final String? titleOverride;

  const JobsPage({
    super.key,
    this.enableAdzuna = true,
    this.filterUserId,
    this.titleOverride,
  });

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  // Community jobs are loaded from Firebase Firestore (collection: community_jobs)
  // Adzuna jobs are loaded via API and merged into the list.

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _communityJobsCol =>
      FirebaseFirestore.instance.collection('community_jobs');

  static DateTime _readFirestoreDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static int _readFirestoreInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Job _jobFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Job(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      company: (data['company'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      jobType: (data['jobType'] ?? '').toString(),
      salary: (data['salary'] ?? '').toString(),
      phoneNumber: (data['phoneNumber'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      category: _normalizeJobCategory((data['category'] ?? '').toString()),
      sourceUrl: (data['sourceUrl'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      postedDate: _readFirestoreDate(data['postedDate']),
      viewCount: _readFirestoreInt(data['viewCount']),
      isClosed: data['isClosed'] == true,
    );
  }

  Stream<List<Job>> _communityJobsStream() {
    Query<Map<String, dynamic>> query = _communityJobsCol;

    final filterUserId = widget.filterUserId;
    if (filterUserId != null && filterUserId.isNotEmpty) {
      // Avoid composite index requirement for (createdBy == X) + orderBy(postedDate).
      // We'll sort client-side.
      query = query.where('createdBy', isEqualTo: filterUserId);
      return query.snapshots().map(
        (snapshot) => snapshot.docs.map(_jobFromDoc).toList(growable: false),
      );
    }

    if (_showingMyJobs) {
      query = query.where('createdBy', isEqualTo: currentUserId);
    } else {
      query = query.orderBy('postedDate', descending: true);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(_jobFromDoc).toList(growable: false),
    );
  }

  Future<void> _deleteCommunityJob(Job job) async {
    // Best-effort delete of the associated image in Firebase Storage.
    try {
      await FirebaseStorage.instance
          .ref()
          .child('community_jobs')
          .child(job.id)
          .child('cover')
          .delete();
    } catch (_) {
      // Ignore.
    }
    await _communityJobsCol.doc(job.id).delete();
  }

  Future<void> _setCommunityJobClosed(Job job, bool isClosed) async {
    await _communityJobsCol.doc(job.id).update({'isClosed': isClosed});
  }

  Future<void> _updateCommunityJob(Job job) async {
    await _communityJobsCol.doc(job.id).update({
      'title': job.title,
      'company': job.company,
      'location': job.location,
      'description': job.description,
      'jobType': job.jobType,
      'salary': job.salary,
      'phoneNumber': job.phoneNumber,
      'email': job.email,
      'category': job.category,
      'stateAbbr': _extractAustralianStateAbbr(job.location),
    });
  }

  final AdzunaJobsService _adzunaJobsService = AdzunaJobsService();
  List<Job> _adzunaJobs = const [];
  List<Job> _adzunaJobsAustralia = const [];
  bool _isLoadingAdzunaJobs = false;
  String? _adzunaLoadError;

  DateTime? _adzunaRateLimitedUntil;

  static const int _adzunaResultsPerPage = 40;
  String _adzunaActiveQueryState = 'ALL';
  int _adzunaCurrentPage = 1;
  bool _adzunaHasMore = true;

  final Map<String, int> _adzunaTotalCountByState = {};
  final Set<String> _adzunaCountLoading = {};

  // Cache the first page of Adzuna jobs per state so state-card counts remain
  // consistent even when the selected state changes.
  final Map<String, List<Job>> _adzunaJobsByState = {};

  @override
  void initState() {
    super.initState();
    FirebaseBootstrap.tryInit().then((_) {
      if (!mounted) return;
      setState(() {});
    });

    final isUserFiltered =
        widget.filterUserId != null && widget.filterUserId!.isNotEmpty;

    if (widget.enableAdzuna && !isUserFiltered) {
      _loadAdzunaJobsForAustralia();
      // Warm up accurate state-card counts slowly to avoid hitting rate limits.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _warmUpAdzunaStateCounts();
      });
    }
  }

  @override
  void dispose() {
    _adzunaJobsService.dispose();
    super.dispose();
  }

  String get currentUserId => AuthState.currentUserId ?? 'guest';
  bool _showingMyJobs = false;

  // UI state variables
  String _searchQuery = '';
  String _selectedJobType = 'All Types';
  String _selectedCategoryFilter = 'All Categories';
  String _selectedLocationFilter = 'All Locations';
  String _selectedStateFilter = 'All States';
  double _maxSalaryFilter = 200000;

  final List<String> _jobTypes = [
    'All Types',
    'Full-time',
    'Part-time',
    'Contract',
  ];

  final List<String> _locations = [
    'All Locations',
    'Sydney, NSW',
    'Melbourne, VIC',
    'Brisbane, QLD',
    'Perth, WA',
    'Adelaide, SA',
    'Canberra, ACT',
  ];

  final List<String> _categoryFilters = const [
    'All Categories',
    ...kNepalAusJobCategoriesUi,
  ];

  // State cards (intentionally no 'All States' card)
  final List<String> _auStates = const [
    'NSW',
    'VIC',
    'QLD',
    'WA',
    'SA',
    'TAS',
    'ACT',
    'NT',
  ];

  String _mapAdzunaContractToJobType(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.contains('part')) return 'Part-time';
    if (v.contains('contract') || v.contains('temporary')) return 'Contract';
    return 'Full-time';
  }

  Job _mapAdzunaJobToJob(AdzunaJob j) {
    final stateAbbr = j.stateAbbr.trim();
    final locationText =
        (stateAbbr.isNotEmpty &&
            !RegExp(
              r'\b' + RegExp.escape(stateAbbr) + r'\b',
            ).hasMatch(j.location))
        ? '${j.location}, $stateAbbr'
        : j.location;

    return Job(
      id: j.id,
      title: j.title,
      company: j.company,
      location: locationText,
      description: j.description.trim().isEmpty
          ? 'No description available.'
          : j.description,
      jobType: _mapAdzunaContractToJobType(j.contractType),
      salary: j.salary,
      phoneNumber: '',
      email: '',
      category: _normalizeJobCategory(j.category),
      sourceUrl: j.redirectUrl,
      imageUrl: '',
      createdBy: AdzunaJobsService.sourceId,
      postedDate: j.postedDate,
    );
  }

  int _countAdzunaAustraliaForState(String stateAbbr) {
    int count = 0;
    for (final job in _adzunaJobsAustralia) {
      if (_extractAustralianStateAbbr(job.location) == stateAbbr) {
        count++;
      }
    }
    return count;
  }

  bool get _isAdzunaRateLimited {
    final until = _adzunaRateLimitedUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  Future<void> _warmUpAdzunaStateCounts() async {
    if (_showingMyJobs) return;
    for (final state in _auStates) {
      if (!mounted) return;
      if (_isAdzunaRateLimited) return;
      await _ensureAdzunaCountForState(state);
      // Small delay between requests to reduce 429 risk.
      await Future.delayed(const Duration(milliseconds: 650));
    }
  }

  Future<void> _ensureAdzunaCountForState(String stateAbbr) async {
    if (_adzunaTotalCountByState.containsKey(stateAbbr)) return;
    if (_adzunaCountLoading.contains(stateAbbr)) return;
    if (_isAdzunaRateLimited) return;

    _adzunaCountLoading.add(stateAbbr);
    try {
      final count = await _adzunaJobsService.fetchJobCount(
        stateAbbr: stateAbbr,
      );
      if (!mounted) return;
      if (count != null) {
        setState(() {
          _adzunaTotalCountByState[stateAbbr] = count;
        });
      }
    } on AdzunaRateLimitException catch (e) {
      final retry = e.retryAfterSeconds ?? 60;
      if (!mounted) return;
      setState(() {
        _adzunaRateLimitedUntil = DateTime.now().add(Duration(seconds: retry));
        _adzunaLoadError = e.toString();
      });
    } catch (_) {
      // Ignore; we'll fall back to Australia distribution.
    } finally {
      _adzunaCountLoading.remove(stateAbbr);
    }
  }

  Future<void> _loadMoreAdzunaJobs() async {
    if (_isLoadingAdzunaJobs) return;
    if (!_adzunaHasMore) return;
    if (_showingMyJobs) return;
    if (_isAdzunaRateLimited) {
      setState(() {
        _adzunaLoadError = 'Adzuna is rate limited. Please wait and try again.';
      });
      return;
    }

    final nextPage = _adzunaCurrentPage + 1;

    setState(() {
      _isLoadingAdzunaJobs = true;
      _adzunaLoadError = null;
    });

    try {
      final meta = await _adzunaJobsService.fetchJobsPage(
        stateAbbr: _adzunaActiveQueryState,
        resultsPerPage: _adzunaResultsPerPage,
        page: nextPage,
      );

      final mapped = meta.jobs.map(_mapAdzunaJobToJob).toList(growable: false);
      final existingIds = _adzunaJobs.map((e) => e.id).toSet();
      final toAdd = mapped
          .where((e) => !existingIds.contains(e.id))
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _adzunaCurrentPage = nextPage;
        _adzunaJobs = [..._adzunaJobs, ...toAdd];

        if (_adzunaActiveQueryState == 'ALL') {
          _adzunaJobsAustralia = _adzunaJobs;
        } else {
          _adzunaJobsByState[_adzunaActiveQueryState] = _adzunaJobs;
        }

        // If fewer than a page returned, assume no more pages.
        _adzunaHasMore = meta.jobs.length >= _adzunaResultsPerPage;
        _isLoadingAdzunaJobs = false;
      });
    } on AdzunaRateLimitException catch (e) {
      final retry = e.retryAfterSeconds ?? 60;
      if (!mounted) return;
      setState(() {
        _isLoadingAdzunaJobs = false;
        _adzunaRateLimitedUntil = DateTime.now().add(Duration(seconds: retry));
        _adzunaLoadError = e.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAdzunaJobs = false;
        _adzunaLoadError = e.toString();
      });
    }
  }

  Future<void> _loadAdzunaJobsForAustralia() async {
    if (_isLoadingAdzunaJobs) return;
    if (_isAdzunaRateLimited) {
      setState(() {
        _adzunaLoadError = 'Adzuna is rate limited. Please wait and try again.';
      });
      return;
    }

    setState(() {
      _isLoadingAdzunaJobs = true;
      _adzunaLoadError = null;
    });

    try {
      final meta = await _adzunaJobsService.fetchJobsPage(
        stateAbbr: 'ALL',
        resultsPerPage: _adzunaResultsPerPage,
        page: 1,
      );
      final mapped = meta.jobs.map(_mapAdzunaJobToJob).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _adzunaActiveQueryState = 'ALL';
        _adzunaCurrentPage = 1;
        _adzunaHasMore = meta.jobs.length >= _adzunaResultsPerPage;
        _adzunaJobs = mapped;
        _adzunaJobsAustralia = mapped;
        _isLoadingAdzunaJobs = false;
        if (mapped.isEmpty) {
          _adzunaLoadError = 'No Adzuna jobs found right now.';
        }
      });
    } on AdzunaRateLimitException catch (e) {
      if (!mounted) return;
      final retry = e.retryAfterSeconds ?? 60;
      setState(() {
        _isLoadingAdzunaJobs = false;
        _adzunaRateLimitedUntil = DateTime.now().add(Duration(seconds: retry));
        _adzunaLoadError = e.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAdzunaJobs = false;
        _adzunaLoadError = e.toString();
      });
    }
  }

  Future<void> _loadAdzunaJobsForState(String stateAbbr) async {
    if (_isLoadingAdzunaJobs) return;
    if (_isAdzunaRateLimited) {
      setState(() {
        _adzunaLoadError = 'Adzuna is rate limited. Please wait and try again.';
      });
      return;
    }

    final cached = _adzunaJobsByState[stateAbbr];
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _adzunaActiveQueryState = stateAbbr;
        _adzunaCurrentPage = 1;
        _adzunaHasMore = cached.length >= _adzunaResultsPerPage;
        _adzunaJobs = cached;
        _adzunaLoadError = null;
      });
      _ensureAdzunaCountForState(stateAbbr);
      return;
    }

    setState(() {
      _isLoadingAdzunaJobs = true;
      _adzunaLoadError = null;
      _adzunaJobs = const [];
    });

    try {
      final meta = await _adzunaJobsService.fetchJobsPage(
        stateAbbr: stateAbbr,
        resultsPerPage: _adzunaResultsPerPage,
        page: 1,
      );
      final mapped = meta.jobs.map(_mapAdzunaJobToJob).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _adzunaActiveQueryState = stateAbbr;
        _adzunaCurrentPage = 1;
        _adzunaHasMore = meta.jobs.length >= _adzunaResultsPerPage;
        _adzunaJobs = mapped;
        _adzunaJobsByState[stateAbbr] = mapped;
        _isLoadingAdzunaJobs = false;
        if (mapped.isEmpty) {
          _adzunaLoadError = 'No Adzuna jobs found for $stateAbbr right now.';
        }
      });
      _ensureAdzunaCountForState(stateAbbr);
    } on AdzunaRateLimitException catch (e) {
      if (!mounted) return;
      final retry = e.retryAfterSeconds ?? 60;
      setState(() {
        _isLoadingAdzunaJobs = false;
        _adzunaRateLimitedUntil = DateTime.now().add(Duration(seconds: retry));
        _adzunaLoadError = e.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAdzunaJobs = false;
        _adzunaLoadError = e.toString();
      });
    }
  }

  // Helper method to parse salary from string like "$80,000 - $120,000"
  double _extractMinSalary(String salaryStr) {
    try {
      final parts = salaryStr.replaceAll('\$', '').split('-');
      return double.parse(parts[0].trim().replaceAll(',', ''));
    } catch (e) {
      return 0;
    }
  }

  void _showDeleteConfirmation(BuildContext context, Job job) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Delete Job'),
        content: Text('Are you sure you want to delete this job posting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final current = AuthState.currentUserId ?? 'guest';
              final allowed = await VerificationService.canPost(current);
              if (!allowed) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Only verified contributors may delete jobs.'), backgroundColor: Colors.red),
                );
                return;
              }
              try {
                await _deleteCommunityJob(job);
                if (!context.mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Job deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterUserId = widget.filterUserId;
    final isUserFiltered = filterUserId != null && filterUserId.isNotEmpty;
    return StreamBuilder<List<Job>>(
      stream: _firebaseReady
          ? _communityJobsStream()
          : Stream<List<Job>>.empty(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final communityJobs = snapshot.data ?? const <Job>[];

        final effectiveShowingMyJobs = isUserFiltered ? true : _showingMyJobs;
        final effectiveUserId = filterUserId ?? currentUserId;

        bool matchesSearch(Job job) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return job.title.toLowerCase().contains(q) ||
              job.company.toLowerCase().contains(q) ||
              job.description.toLowerCase().contains(q);
        }

        bool matchesJobType(Job job) {
          if (_selectedJobType == 'All Types') return true;
          return job.jobType == _selectedJobType;
        }

        bool matchesCategory(Job job) {
          if (_selectedCategoryFilter == 'All Categories') return true;
          return _normalizeJobCategory(job.category) == _selectedCategoryFilter;
        }

        bool matchesLocation(Job job) {
          if (_selectedLocationFilter == 'All Locations') return true;
          final city = _selectedLocationFilter.split(',')[0];
          return job.location.contains(city);
        }

        bool matchesSalary(Job job) {
          final minSalary = _extractMinSalary(job.salary);
          return minSalary <= _maxSalaryFilter;
        }

          // Apply filters
          List<Job> baseJobs = effectiveShowingMyJobs
          ? communityJobs
            .where((job) => job.createdBy == effectiveUserId && !job.isClosed)
            .toList()
          : [...communityJobs.where((job) => !job.isClosed), ..._adzunaJobs];

        // Search / type / location / salary filters
        baseJobs = baseJobs
            .where(matchesSearch)
            .where(matchesJobType)
            .where(matchesCategory)
            .where(matchesLocation)
            .where(matchesSalary)
            .toList();

        // State counts (after other filters, before state filter)
        // IMPORTANT: counts must not depend on the currently loaded Adzuna list
        // (which changes when a state is selected).
        final Map<String, int> stateCounts = {};

        // Count community jobs (filtered) by state.
        final communityForCounts =
          (effectiveShowingMyJobs
              ? communityJobs.where((j) => j.createdBy == effectiveUserId && !j.isClosed)
              : communityJobs.where((j) => !j.isClosed))
                .where(matchesSearch)
                .where(matchesJobType)
                .where(matchesCategory)
                .where(matchesLocation)
                .where(matchesSalary)
                .toList(growable: false);

        for (final job in communityForCounts) {
          final abbr = _extractAustralianStateAbbr(job.location);
          if (abbr.isEmpty) continue;
          stateCounts[abbr] = (stateCounts[abbr] ?? 0) + 1;
        }

        // Add Adzuna counts without spamming the API:
        // - if we have a cached state page (user tapped it), use that
        // - otherwise use an accurate cached totalCount (if available)
        // - otherwise use the Australia-wide list distribution (best-effort)
        if (!effectiveShowingMyJobs) {
          for (final state in _auStates) {
            final cachedTotal = _adzunaTotalCountByState[state];
            final cachedPage = _adzunaJobsByState[state];

            final int adzunaCount =
                cachedTotal ??
                ((cachedPage != null && cachedPage.isNotEmpty)
                    ? cachedPage.length
                    : _countAdzunaAustraliaForState(state));

            if (adzunaCount == 0) continue;
            stateCounts[state] = (stateCounts[state] ?? 0) + adzunaCount;
          }
        }

        // State filter
        List<Job> jobsToShow = baseJobs;
        if (_selectedStateFilter != 'All States') {
          jobsToShow = jobsToShow
              .where(
                (job) =>
                    _extractAustralianStateAbbr(job.location) ==
                    _selectedStateFilter,
              )
              .toList();
        }

        // Sort: open first, then newest first
        jobsToShow.sort((a, b) {
          final closedCompare = (a.isClosed ? 1 : 0).compareTo(
            b.isClosed ? 1 : 0,
          );
          if (closedCompare != 0) return closedCompare;
          return b.postedDate.compareTo(a.postedDate);
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.titleOverride ?? 'Job Listings'),
            actions: isUserFiltered
                ? null
                : [
                    IconButton(
                      icon: Icon(_showingMyJobs ? Icons.work : Icons.person),
                      onPressed: () {
                        setState(() {
                          _showingMyJobs = !_showingMyJobs;
                        });

                        if (!_showingMyJobs &&
                            _adzunaJobs.isEmpty &&
                            !_isLoadingAdzunaJobs &&
                            widget.enableAdzuna) {
                          _loadAdzunaJobsForAustralia();
                        }
                      },
                      tooltip: _showingMyJobs
                          ? 'View All Jobs'
                          : 'View My Jobs',
                    ),
                  ],
          ),
          floatingActionButton: isUserFiltered
              ? null
              : FutureBuilder<bool>(
                  future: VerificationService.canPost(currentUserId),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final allowed = snap.data == true;
                    if (!allowed) {
                      return FloatingActionButton.extended(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Only verified contributors can post jobs.')),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Post Job'),
                      );
                    }
                    return FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateJobPage()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Post Job'),
                    );
                  },
                ),
          body: SafeArea(
            child: Column(
              children: [
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Card(
                      color: const Color(0xFFFFF3CD),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFB45309),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Community jobs failed to load. ${snapshot.error}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search jobs...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () => _showFiltersBottomSheet(context),
                        tooltip: 'Filters',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ),
                  ),
                ),

                // Active Filters Chips
                if (_selectedJobType != 'All Types' ||
                    _selectedCategoryFilter != 'All Categories' ||
                    _selectedLocationFilter != 'All Locations' ||
                    _selectedStateFilter != 'All States' ||
                    _maxSalaryFilter < 200000)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedJobType != 'All Types')
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(_selectedJobType),
                                onDeleted: () {
                                  setState(() {
                                    _selectedJobType = 'All Types';
                                  });
                                },
                              ),
                            ),
                          if (_selectedCategoryFilter != 'All Categories')
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(_selectedCategoryFilter),
                                onDeleted: () {
                                  setState(() {
                                    _selectedCategoryFilter = 'All Categories';
                                  });
                                },
                              ),
                            ),
                          if (_selectedLocationFilter != 'All Locations')
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(
                                  _selectedLocationFilter.split(',')[0],
                                ),
                                onDeleted: () {
                                  setState(() {
                                    _selectedLocationFilter = 'All Locations';
                                  });
                                },
                              ),
                            ),
                          if (_selectedStateFilter != 'All States')
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(_selectedStateFilter),
                                onDeleted: () {
                                  setState(() {
                                    _selectedStateFilter = 'All States';
                                  });

                                  if (!_showingMyJobs &&
                                      !_isLoadingAdzunaJobs) {
                                    _loadAdzunaJobsForAustralia();
                                  }
                                },
                              ),
                            ),
                          if (_maxSalaryFilter < 200000)
                            Chip(
                              label: Text(
                                'Under \$${_maxSalaryFilter.toInt()}',
                              ),
                              onDeleted: () {
                                setState(() {
                                  _maxSalaryFilter = 200000;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Australian state cards (no 'All States' card)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    height: 74,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _auStates.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final state = _auStates[index];
                        final isSelected = _selectedStateFilter == state;
                        final int count = stateCounts[state] ?? 0;

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setState(() {
                              _selectedStateFilter = state;
                            });

                            if (!_showingMyJobs) {
                              _loadAdzunaJobsForState(state);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 110,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  state,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$count job${count == 1 ? '' : 's'}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                              .withValues(alpha: 0.8)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                if (!_showingMyJobs && _isLoadingAdzunaJobs)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: LinearProgressIndicator(),
                  ),
                if (!_showingMyJobs && _adzunaLoadError != null && AuthState.isAdmin)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      _adzunaLoadError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),

                // Results Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${jobsToShow.length} job${jobsToShow.length == 1 ? '' : 's'} found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Jobs Grid
                Expanded(
                  child: jobsToShow.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showingMyJobs
                                    ? Icons.work_off_outlined
                                    : Icons.search_off,
                                size: 64,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _showingMyJobs
                                    ? 'No jobs posted yet'
                                    : 'No jobs found',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _showingMyJobs
                                    ? 'Tap the button below to post your first job'
                                    : 'Try adjusting your filters',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      // Show one card per row to match Events list style
                                      crossAxisCount: 1,
                                      childAspectRatio: 3.0,
                                      // Increase card height to display more information
                                      mainAxisExtent: 220,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: jobsToShow.length,
                                itemBuilder: (context, index) {
                                  final job = jobsToShow[index];
                                  return JobCard(
                                    job: job,
                                    onTap: () {
                                      final jobToOpen = job;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => JobDetailPage(
                                            job: jobToOpen,
                                            currentUserId: currentUserId,
                                          ),
                                        ),
                                      ).then((result) {
                                        if (!context.mounted) return;
                                        if (result is! JobDetailResult) return;

                                        if (result.deletedId != null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Job deleted'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        if (result.updatedJob != null) {
                                          final updated = result.updatedJob!;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                updated.isClosed
                                                    ? 'Job closed'
                                                    : 'Job updated',
                                              ),
                                            ),
                                          );
                                        }
                                      });
                                    },
                                    currentUserId: currentUserId,
                                    onEdit: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditJobPage(
                                            job: job,
                                            onJobUpdated: (updatedJob) {
                                              _updateCommunityJob(updatedJob)
                                                  .then((_) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Job updated',
                                                        ),
                                                      ),
                                                    );
                                                  })
                                                  .catchError((e) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Failed to update: $e',
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  });
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    onDelete: () {
                                      _showDeleteConfirmation(context, job);
                                    },
                                    onToggleClosed: () {
                                      if (job.isClosed) {
                                        _setCommunityJobClosed(job, false)
                                            .then((_) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Job reopened'),
                                                ),
                                              );
                                            })
                                            .catchError((e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to reopen: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            });
                                        return;
                                      }

                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Close Job Listing',
                                          ),
                                          content: const Text(
                                            'Closing will hide your job from the public job list. You can reopen it later from My Jobs.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _setCommunityJobClosed(
                                                      job,
                                                      true,
                                                    )
                                                    .then((_) {
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Job closed',
                                                          ),
                                                        ),
                                                      );
                                                    })
                                                    .catchError((e) {
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Failed to close: $e',
                                                          ),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    });
                                              },
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            if (!_showingMyJobs && _adzunaHasMore)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoadingAdzunaJobs
                                        ? null
                                        : _loadMoreAdzunaJobs,
                                    child: Text(
                                      _isLoadingAdzunaJobs
                                          ? 'Loading…'
                                          : 'Load more jobs',
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String jobType = _selectedJobType;
        String category = _selectedCategoryFilter;
        String location = _selectedLocationFilter;
        double maxSalary = _maxSalaryFilter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              jobType = 'All Types';
                              category = 'All Categories';
                              location = 'All Locations';
                              maxSalary = 200000;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: jobType,
                      items: _jobTypes
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => jobType = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Job type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      items: _categoryFilters
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => category = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: location,
                      items: _locations
                          .map(
                            (l) => DropdownMenuItem(value: l, child: Text(l)),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => location = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Max salary: ${maxSalary >= 200000 ? 'Any' : '\$${maxSalary.toInt()}'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      value: maxSalary,
                      min: 0,
                      max: 200000,
                      divisions: 20,
                      label: maxSalary >= 200000
                          ? 'Any'
                          : '\$${maxSalary.toInt()}',
                      onChanged: (v) => setModalState(() => maxSalary = v),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _selectedJobType = jobType;
                            _selectedCategoryFilter = category;
                            _selectedLocationFilter = location;
                            _maxSalaryFilter = maxSalary;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final String currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleClosed;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.currentUserId = '',
    this.onEdit,
    this.onDelete,
    this.onToggleClosed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = job.imageUrl.trim().isNotEmpty;
    final stateAbbr = _extractAustralianStateAbbr(job.location);
    final isOwner = currentUserId.isNotEmpty && currentUserId == job.createdBy;

    final combined =
        '${job.title}\n${job.company}\n${job.location}\n${job.description}\n${job.jobType}\n${job.salary}\n${job.phoneNumber}\n${job.email}\n${job.category}';
    final prohibited = securityService.findProhibitedTerms(combined);
    final lower = combined.toLowerCase();
    final suspicious =
        _JobDetailPageState._suspiciousPhrases
            .where((p) => lower.contains(p))
            .toSet()
            .toList(growable: false);

    JobScamLikelihood likelihood = JobScamLikelihood.low;
    if (combined.trim().isEmpty) {
      likelihood = JobScamLikelihood.unknown;
    } else if (prohibited.isNotEmpty) {
      likelihood = JobScamLikelihood.high;
    } else if (suspicious.length >= 2) {
      likelihood = JobScamLikelihood.medium;
    } else if (suspicious.isNotEmpty) {
      likelihood = JobScamLikelihood.medium;
    }

    Color badgeBg;
    Color badgeFg;
    switch (likelihood) {
      case JobScamLikelihood.high:
        badgeBg = const Color(0xFFFEE2E2);
        badgeFg = const Color(0xFF991B1B);
        break;
      case JobScamLikelihood.medium:
        badgeBg = const Color(0xFFFFF3CD);
        badgeFg = const Color(0xFF92400E);
        break;
      case JobScamLikelihood.low:
        badgeBg = const Color(0xFFDCFCE7);
        badgeFg = const Color(0xFF166534);
        break;
      case JobScamLikelihood.unknown:
        badgeBg = const Color(0xFFE5E7EB);
        badgeFg = const Color(0xFF374151);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Icon Placeholder
            Container(
              height: 96,
              color: theme.colorScheme.primaryContainer,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      job.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) {
                        return const SizedBox.shrink();
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: theme.colorScheme.primaryContainer,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 36,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getJobTypeColor(job.jobType).withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            job.jobType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getJobTypeColor(job.jobType),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (job.isClosed)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'CLOSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: badgeFg.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'AI: ${likelihood.label}',
                          style: TextStyle(
                            color: badgeFg,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      job.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Company
                    Text(
                      job.company,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Salary
                    Text(
                      job.salary,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            job.location,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (stateAbbr.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              stateAbbr,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                size: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${job.viewCount} views',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getDaysAgoText(job.postedDate),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 9,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOwner)
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                  onPressed: onEdit,
                                  icon: const Icon(Icons.edit),
                                  color: theme.colorScheme.primary,
                                  tooltip: 'Edit',
                                  padding: EdgeInsets.zero,
                                  iconSize: 14,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 1),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                  onPressed: onToggleClosed,
                                  icon: Icon(
                                    job.isClosed
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  color: job.isClosed
                                      ? Colors.green
                                      : Colors.orange,
                                  tooltip: job.isClosed ? 'Reopen' : 'Close',
                                  padding: EdgeInsets.zero,
                                  iconSize: 14,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 1),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                  onPressed: onDelete,
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  tooltip: 'Delete',
                                  padding: EdgeInsets.zero,
                                  iconSize: 14,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getJobTypeColor(String jobType) {
    switch (jobType) {
      case 'Full-time':
        return Colors.green;
      case 'Part-time':
        return Colors.orange;
      case 'Contract':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDaysAgoText(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}

class JobDetailPage extends StatefulWidget {
  final Job job;
  final String currentUserId;

  const JobDetailPage({
    super.key,
    required this.job,
    required this.currentUserId,
  });

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

enum JobScamLikelihood { high, medium, low, unknown }

extension JobScamLikelihoodLabel on JobScamLikelihood {
  String get label {
    switch (this) {
      case JobScamLikelihood.high:
        return 'High risk';
      case JobScamLikelihood.medium:
        return 'Medium risk';
      case JobScamLikelihood.low:
        return 'Low risk';
      case JobScamLikelihood.unknown:
        return 'Unknown';
    }
  }
}

class JobSafetyAnalysis {
  final JobScamLikelihood likelihood;
  final List<String> prohibitedTerms;
  final List<String> suspiciousPhrases;

  const JobSafetyAnalysis({
    required this.likelihood,
    required this.prohibitedTerms,
    required this.suspiciousPhrases,
  });
}

class _JobDetailPageState extends State<JobDetailPage> {
  late Job _job;
  Future<JobSafetyAnalysis>? _safetyAnalysisFuture;
  bool _isBookmarked = false;

  static const List<String> _suspiciousPhrases = [
    'deposit',
    'pay now',
    'pay upfront',
    'upfront',
    'training fee',
    'fee required',
    'registration fee',
    'bond',
    'gift card',
    'crypto',
    'bitcoin',
    'verification code',
    'otp',
    'urgent',
    'kindly',
    'click link',
    'telegram',
    'whatsapp',
    'dm me',
    'direct message',
    'easy money',
    'work from home',
    'no interview',
    'no experience',
  ];

  bool _isCommunityJob(Job job) =>
      job.createdBy.trim().isNotEmpty &&
      job.createdBy != AdzunaJobsService.sourceId;

  Future<JobSafetyAnalysis> _analyzeJob() async {
    final job = _job;
    final combined =
        '${job.title}\n${job.company}\n${job.location}\n${job.description}\n${job.jobType}\n${job.salary}\n${job.phoneNumber}\n${job.email}\n${job.category}';
    final prohibited = securityService.findProhibitedTerms(combined);

    final lower = combined.toLowerCase();
    final suspicious =
        _suspiciousPhrases
            .where((p) => lower.contains(p))
            .toSet()
            .toList(growable: false)
          ..sort();

    JobScamLikelihood likelihood = JobScamLikelihood.low;
    if (combined.trim().isEmpty) {
      likelihood = JobScamLikelihood.unknown;
    } else if (prohibited.isNotEmpty) {
      likelihood = JobScamLikelihood.high;
    } else if (suspicious.length >= 2) {
      likelihood = JobScamLikelihood.medium;
    } else if (suspicious.isNotEmpty) {
      likelihood = JobScamLikelihood.medium;
    }

    return JobSafetyAnalysis(
      likelihood: likelihood,
      prohibitedTerms: prohibited,
      suspiciousPhrases: suspicious,
    );
  }

  void _openAiSafetyDetails(JobSafetyAnalysis analysis) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobSafetyCheckDetailPage(job: _job, analysis: analysis),
      ),
    );
  }

  Future<void> _incrementViewCountIfNeeded() async {
    final job = _job;
    if (!_isCommunityJob(job)) return;
    if (widget.currentUserId == job.createdBy) return;

    try {
      await FirebaseFirestore.instance
          .collection('community_jobs')
          .doc(job.id)
          .update({'viewCount': FieldValue.increment(1)});
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _setClosed(bool closed) async {
    final job = _job;
    if (!_isCommunityJob(job)) return;
    await FirebaseFirestore.instance
        .collection('community_jobs')
        .doc(job.id)
        .update({'isClosed': closed});
  }

  Future<void> _deleteJob() async {
    final job = _job;
    if (!_isCommunityJob(job)) return;

    try {
      await FirebaseStorage.instance
          .ref()
          .child('community_jobs')
          .child(job.id)
          .child('cover')
          .delete();
    } catch (_) {
      // Ignore.
    }

    await FirebaseFirestore.instance
        .collection('community_jobs')
        .doc(job.id)
        .delete();
  }

  Future<void> _updateJob(Job updatedJob) async {
    if (!_isCommunityJob(updatedJob)) return;
    await FirebaseFirestore.instance
        .collection('community_jobs')
        .doc(updatedJob.id)
        .update({
          'title': updatedJob.title,
          'company': updatedJob.company,
          'location': updatedJob.location,
          'description': updatedJob.description,
          'jobType': updatedJob.jobType,
          'salary': updatedJob.salary,
          'phoneNumber': updatedJob.phoneNumber,
          'email': updatedJob.email,
          'category': updatedJob.category,
          'stateAbbr': _extractAustralianStateAbbr(updatedJob.location),
        });
  }

  Future<void> _openSourceUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid job URL')));
      }
      return;
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open job URL')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _safetyAnalysisFuture = _analyzeJob();
    // Increment view count for community jobs (best-effort).
    Future.microtask(_incrementViewCountIfNeeded);
    Future.microtask(() async {
      final uid = AuthState.currentUserId;
      if (uid != null) {
        final bookmarked = await BookmarkService.isBookmarked(uid, 'community_jobs', _job.id);
        if (!mounted) return;
        setState(() => _isBookmarked = bookmarked);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rootContext = context;
    final job = _job;
    final isOwner = widget.currentUserId == job.createdBy;
    final hasSourceUrl = job.sourceUrl.trim().isNotEmpty;
    final hasImage = job.imageUrl.trim().isNotEmpty;
    final showAdvertiserInfo =
        _isCommunityJob(job) &&
        !isOwner &&
        job.createdBy.trim().isNotEmpty &&
        job.createdBy != 'guest';
    final advertiserName =
        AuthService.getUserById(job.createdBy)?.name ??
        (job.company.trim().isNotEmpty ? job.company : 'Job Advertiser');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            tooltip: _isBookmarked ? 'Remove bookmark' : 'Bookmark',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              developer.log('BookmarkDebug: currentUser uid=${user?.uid} email=${user?.email}', name: 'BookmarkDebug');
              final messenger = ScaffoldMessenger.of(context);
              developer.log('BookmarkDebug: projectId=${Firebase.app().options.projectId}', name: 'BookmarkDebug');
              if (user == null) {
                if (!mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('Please sign in to bookmark items.')));
                return;
              }
              final uid = user.uid;
              final previous = _isBookmarked;
              setState(() => _isBookmarked = !previous);
              try {
                final ok = await BookmarkService.toggleBookmark(uid, 'community_jobs', _job.id, title: _job.title);
                if (!mounted) return;
                if (!ok) {
                  setState(() => _isBookmarked = previous);
                  messenger.showSnackBar(const SnackBar(content: Text('Bookmark failed')));
                }
              } catch (e) {
                if (!mounted) return;
                setState(() => _isBookmarked = previous);
                messenger.showSnackBar(SnackBar(content: Text('Bookmark failed: $e')));
              }
            },
          ),
          
          if (isOwner) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                // capture messenger and navigator before async gap
                final messenger = ScaffoldMessenger.of(rootContext);
                final navigator = Navigator.of(rootContext);
                final current = AuthState.currentUserId ?? 'guest';
                final allowed = await VerificationService.canPost(current);
                if (!allowed) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Only verified contributors may edit jobs.'), backgroundColor: Colors.red),
                  );
                  return;
                }
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => EditJobPage(
                      job: job,
                      onJobUpdated: (updatedJob) {
                        _updateJob(updatedJob)
                            .then((_) {
                              if (!mounted) return;
                              setState(() {
                                _job = updatedJob;
                              });
                              navigator.pop();
                              Future.microtask(() {
                                if (rootContext.mounted) {
                                  navigator.pop(
                                    JobDetailResult.updated(updatedJob),
                                  );
                                }
                              });
                            })
                            .catchError((e) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            });
                      },
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: job.isClosed ? 'Reopen listing' : 'Close listing',
              icon: Icon(
                job.isClosed ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                if (job.isClosed) {
                  _setClosed(false)
                      .then((_) {
                        if (!rootContext.mounted) return;
                        Navigator.pop(
                          rootContext,
                          JobDetailResult.updated(
                            job.copyWith(isClosed: false),
                          ),
                        );
                      })
                      .catchError((e) {
                        if (!rootContext.mounted) return;
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          SnackBar(
                            content: Text('Failed to reopen: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      });
                  return;
                }

                showDialog(
                  context: rootContext,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Close Job Listing'),
                    content: const Text(
                      'Closing will hide your job from the public job list. You can reopen it later from My Jobs.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _setClosed(true)
                              .then((_) {
                                if (!rootContext.mounted) return;
                                Navigator.pop(
                                  rootContext,
                                  JobDetailResult.updated(
                                    job.copyWith(isClosed: true),
                                  ),
                                );
                              })
                              .catchError((e) {
                                if (!rootContext.mounted) return;
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to close: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              });
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: rootContext,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete Job'),
                    content: const Text(
                      'Are you sure you want to delete this job posting? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                        FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          final messenger = ScaffoldMessenger.of(rootContext);
                          final current = AuthState.currentUserId ?? 'guest';
                          final allowed = await VerificationService.canPost(current);
                          if (!allowed) {
                            if (!rootContext.mounted) return;
                            // ignore: use_build_context_synchronously
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Only verified contributors may delete jobs.'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          _deleteJob()
                              .then((_) {
                                if (!rootContext.mounted) return;
                                Navigator.pop(
                                  rootContext,
                                  JobDetailResult.deleted(job.id),
                                );
                              })
                              .catchError((e) {
                                if (!rootContext.mounted) return;
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              });
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (matches marketplace item detail structure)
            Container(
              height: 300,
              color: theme.colorScheme.primaryContainer,
              child: Center(
                child: hasImage
                    ? Image.network(
                        job.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stack) {
                          return Icon(
                            Icons.work_outline,
                            size: 100,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                      )
                    : Icon(
                        Icons.work_outline,
                        size: 100,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Salary (headline)
                  if (job.salary.trim().isNotEmpty) ...[
                    Text(
                      job.salary,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (job.isClosed) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: const Text('CLOSED'),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF991B1B),
                          ),
                          backgroundColor: const Color(0xFFFEE2E2),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                  if (job.company.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      job.company,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: job.location,
                          ),
                          const Divider(height: 24),
                          _DetailRow(
                            icon: Icons.work_outline,
                            label: 'Job Type',
                            value: job.jobType,
                          ),
                          if (job.salary.trim().isNotEmpty) ...[
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Icons.attach_money_outlined,
                              label: 'Salary',
                              value: job.salary,
                            ),
                          ],
                          if (job.phoneNumber.trim().isNotEmpty) ...[
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Icons.call_outlined,
                              label: 'Phone',
                              value: job.phoneNumber,
                            ),
                          ],
                          if (job.email.trim().isNotEmpty) ...[
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: job.email,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  InkWell(
                    onTap: () async {
                      final analysis =
                          await (_safetyAnalysisFuture ?? _analyzeJob());
                      if (!context.mounted) return;
                      _openAiSafetyDetails(analysis);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FutureBuilder<JobSafetyAnalysis>(
                          future: _safetyAnalysisFuture,
                          builder: (context, snapshot) {
                            final analysis = snapshot.data;
                            JobScamLikelihood likelihood =
                                JobScamLikelihood.unknown;
                            String subtitle = 'Tap to view details';
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              subtitle = 'Checking listing… (tap for details)';
                            } else if (snapshot.hasError) {
                              subtitle =
                                  'Could not run AI check (tap for safety tips)';
                            } else if (analysis != null) {
                              likelihood = analysis.likelihood;
                              subtitle = 'Tap to view red flags and advice';
                            }

                            Color badgeBg;
                            Color badgeFg;
                            switch (likelihood) {
                              case JobScamLikelihood.high:
                                badgeBg = const Color(0xFFFEE2E2);
                                badgeFg = const Color(0xFF991B1B);
                                break;
                              case JobScamLikelihood.medium:
                                badgeBg = const Color(0xFFFFF3CD);
                                badgeFg = const Color(0xFF92400E);
                                break;
                              case JobScamLikelihood.low:
                                badgeBg = const Color(0xFFDCFCE7);
                                badgeFg = const Color(0xFF166534);
                                break;
                              case JobScamLikelihood.unknown:
                                badgeBg = const Color(0xFFE5E7EB);
                                badgeFg = const Color(0xFF374151);
                                break;
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.shield_outlined, color: badgeFg),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Safety Check',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: badgeFg.withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Text(
                                          'AI Safety Check: ${likelihood.label}',
                                          style: TextStyle(
                                            color: badgeFg,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        subtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: const Color(0xFF374151),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: badgeFg),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (showAdvertiserInfo) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Job Advertiser Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            rootContext,
                            MaterialPageRoute(
                              builder: (_) => ProfilePage(
                                profileUserId: job.createdBy,
                                displayNameOverride: advertiserName,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      advertiserName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'View profile',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF6B7280),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isOwner
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            rootContext,
                            MaterialPageRoute(
                              builder: (_) => ApplyWithAiResumePage(job: job),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome, size: 20),
                        label: const Text('Apply with AI Resume'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (hasSourceUrl)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () =>
                              _openSourceUrl(rootContext, job.sourceUrl),
                          icon: const Icon(Icons.open_in_new, size: 20),
                          label: const Text('View Job Listing'),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: job.email.trim().isEmpty
                                  ? null
                                  : () => _handleContactTap(job.email, false),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.email_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Email'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: job.phoneNumber.trim().isEmpty
                                  ? null
                                  : () => _handleContactTap(
                                      job.phoneNumber,
                                      true,
                                    ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.call, size: 20),
                                  SizedBox(width: 8),
                                  Text('Call'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void _handleContactTap(String value, bool isPhone) async {
    if (isPhone) {
      final Uri phoneUri = Uri(scheme: 'tel', path: value);
      try {
        await launchUrl(phoneUri);
      } catch (e) {
        _showErrorMessage('Could not launch phone dialer');
      }
    } else {
      final Uri emailUri = Uri(scheme: 'mailto', path: value);
      try {
        await launchUrl(emailUri);
      } catch (e) {
        _showErrorMessage('Could not launch email client');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class JobSafetyCheckDetailPage extends StatelessWidget {
  final Job job;
  final JobSafetyAnalysis analysis;

  const JobSafetyCheckDetailPage({
    super.key,
    required this.job,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final likelihood = analysis.likelihood;

    Future<void> openScamwatchReport() async {
      final Uri url = Uri.parse('https://www.scamwatch.gov.au/report-a-scam');
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Scamwatch website')),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Scamwatch website')),
          );
        }
      }
    }

    Color badgeBg;
    Color badgeFg;
    switch (likelihood) {
      case JobScamLikelihood.high:
        badgeBg = const Color(0xFFFEE2E2);
        badgeFg = const Color(0xFF991B1B);
        break;
      case JobScamLikelihood.medium:
        badgeBg = const Color(0xFFFFF3CD);
        badgeFg = const Color(0xFF92400E);
        break;
      case JobScamLikelihood.low:
        badgeBg = const Color(0xFFDCFCE7);
        badgeFg = const Color(0xFF166534);
        break;
      case JobScamLikelihood.unknown:
        badgeBg = const Color(0xFFE5E7EB);
        badgeFg = const Color(0xFF374151);
        break;
    }

    Widget buildChip(String text) {
      return Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI Safety Check')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: badgeFg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: badgeFg.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            'AI Safety Check: ${likelihood.label}',
                            style: TextStyle(
                              color: badgeFg,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'This is a heuristic safety scan. Always verify the employer independently.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF374151),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (analysis.prohibitedTerms.isNotEmpty) ...[
            Text(
              'Prohibited / risky terms detected',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              children: analysis.prohibitedTerms.map(buildChip).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (analysis.suspiciousPhrases.isNotEmpty) ...[
            Text(
              'Suspicious phrases',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              children: analysis.suspiciousPhrases.map(buildChip).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            color: const Color(0xFFF9FAFB),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety tips',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _Bullet(
                    text:
                        'Never pay money (training fee, deposit, bond) to secure a job.',
                  ),
                  const _Bullet(
                    text:
                        'Confirm the employer using an official website / phone number you find independently.',
                  ),
                  const _Bullet(
                    text:
                        'Avoid sharing passport, visa, TFN, or bank details until you trust the employer and have a legitimate contract.',
                  ),
                  const _Bullet(
                    text:
                        'Be cautious with links, “verify code/OTP” requests, or messaging apps pushing off-platform.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFF3F4F6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.report_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'If you suspect a job scam, report it to Scamwatch (ACCC).',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: openScamwatchReport,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Scamwatch'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class JobDetailResult {
  final Job? updatedJob;
  final String? deletedId;

  const JobDetailResult._({this.updatedJob, this.deletedId});

  const JobDetailResult.updated(Job job) : this._(updatedJob: job);

  const JobDetailResult.deleted(String id) : this._(deletedId: id);
}

class EditJobPage extends StatefulWidget {
  final Job job;
  final Function(Job) onJobUpdated;

  const EditJobPage({super.key, required this.job, required this.onJobUpdated});

  @override
  State<EditJobPage> createState() => _EditJobPageState();
}

class _EditJobPageState extends State<EditJobPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _salaryController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _selectedJobType;
  late String _selectedCategory;

  final List<String> _jobTypes = ['Full-time', 'Part-time', 'Contract'];
  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.job.title);
    _companyController = TextEditingController(text: widget.job.company);
    _locationController = TextEditingController(text: widget.job.location);
    _descriptionController = TextEditingController(
      text: widget.job.description,
    );
    _salaryController = TextEditingController(text: widget.job.salary);
    _phoneController = TextEditingController(text: widget.job.phoneNumber);
    _emailController = TextEditingController(text: widget.job.email);
    _selectedJobType = widget.job.jobType;
    _selectedCategory = _normalizeJobCategory(widget.job.category);

    // Keep the UI list restricted to the 6 categories, but if a legacy job is
    // categorized as "Other", include it so the dropdown doesn't crash.
    _categories = List<String>.of(kNepalAusJobCategoriesUi);
    if (_selectedCategory == kNepalAusJobCategoryOther) {
      _categories.add(kNepalAusJobCategoryOther);
    }
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = kNepalAusJobCategoriesUi.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    final messenger = ScaffoldMessenger.of(context);
    if (_formKey.currentState!.validate()) {
      // Validate email and phone using SecurityService
      if (!securityService.isValidEmail(_emailController.text)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address')),
        );
        return;
      }

      if (!securityService.isValidPhoneNumber(_phoneController.text)) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid Australian phone number'),
          ),
        );
        return;
      }

      final updatedJob = Job(
        id: widget.job.id,
        title: securityService.sanitizeInput(_titleController.text),
        company: securityService.sanitizeInput(_companyController.text),
        location: securityService.sanitizeInput(_locationController.text),
        description: securityService.sanitizeInput(_descriptionController.text),
        jobType: _selectedJobType,
        salary: securityService.sanitizeInput(_salaryController.text),
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        category: _selectedCategory,
        createdBy: widget.job.createdBy,
        postedDate: widget.job.postedDate,
        isClosed: widget.job.isClosed,
      );
      widget.onJobUpdated(updatedJob);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
        title: const Text('Edit Job'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.maybePop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Job Title *',
                hintText: 'e.g., Software Engineer',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a job title';
                }
                if (value.length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Company Field
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                hintText: 'e.g., Tech Corp',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a company name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Location Field
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location *',
                hintText: 'e.g., Sydney, NSW',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Job Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedJobType,
              decoration: const InputDecoration(labelText: 'Job Type *'),
              items: _jobTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedJobType = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Salary Field
            TextFormField(
              controller: _salaryController,
              decoration: const InputDecoration(
                labelText: 'Salary Range *',
                hintText: 'e.g., \$80,000 - \$120,000 per year',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a salary range';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Phone Field
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Contact Phone *',
                hintText: '+61 2 9234 5678',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a contact phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Contact Email *',
                hintText: 'hr@company.com.au',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a contact email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Job Description *',
                hintText: 'Describe the job responsibilities and requirements',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a job description';
                }
                if (value.length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Submit Button (full-width)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitForm,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Update Job'),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Filter Dialog Widget
class FilterDialog extends StatefulWidget {
  final Function(
    DateTimeRange?,
    String,
    double?,
    double?,
    String,
    String,
    String,
  )
  onApplyFilters;
  final VoidCallback onClearFilters;
  final DateTimeRange? initialDateRange;
  final String initialKeyword;
  final double? initialMinSalary;
  final double? initialMaxSalary;
  final String initialCity;
  final String initialState;
  final String initialSuburb;

  const FilterDialog({
    super.key,
    required this.onApplyFilters,
    required this.onClearFilters,
    this.initialDateRange,
    this.initialKeyword = '',
    this.initialMinSalary,
    this.initialMaxSalary,
    this.initialCity = '',
    this.initialState = '',
    this.initialSuburb = '',
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late DateTimeRange? _selectedDateRange;
  late TextEditingController _keywordController;
  late TextEditingController _minSalaryController;
  late TextEditingController _maxSalaryController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _suburbController;

  final List<String> _australianStates = [
    'NSW',
    'VIC',
    'QLD',
    'WA',
    'SA',
    'TAS',
    'ACT',
    'NT',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.initialDateRange;
    _keywordController = TextEditingController(text: widget.initialKeyword);
    _minSalaryController = TextEditingController(
      text: widget.initialMinSalary?.toString() ?? '',
    );
    _maxSalaryController = TextEditingController(
      text: widget.initialMaxSalary?.toString() ?? '',
    );
    _cityController = TextEditingController(text: widget.initialCity);
    _stateController = TextEditingController(text: widget.initialState);
    _suburbController = TextEditingController(text: widget.initialSuburb);
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _suburbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Jobs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2193b0),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Date Range Filter
                Text(
                  'Posted Date',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final result = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedDateRange = result;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2193b0),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _selectedDateRange == null
                        ? 'Select Date Range'
                        : '${_selectedDateRange!.start.toString().split(' ')[0]} - ${_selectedDateRange!.end.toString().split(' ')[0]}',
                  ),
                ),
                SizedBox(height: 16),
                // Keyword Search
                Text(
                  'Search Keywords',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _keywordController,
                  decoration: InputDecoration(
                    hintText: 'Job title, company, or keyword',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                SizedBox(height: 16),
                // Salary Range
                Text(
                  'Salary Range',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minSalaryController,
                        decoration: InputDecoration(
                          hintText: 'Min',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxSalaryController,
                        decoration: InputDecoration(
                          hintText: 'Max',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Location Filters
                Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _suburbController,
                  decoration: InputDecoration(
                    hintText: 'Suburb/City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _stateController.text.isEmpty
                      ? null
                      : _stateController.text,
                  items: _australianStates.map((state) {
                    return DropdownMenuItem(value: state, child: Text(state));
                  }).toList(),
                  decoration: InputDecoration(
                    hintText: 'State',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _stateController.text = value ?? '';
                    });
                  },
                ),
                SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _keywordController.clear();
                          _minSalaryController.clear();
                          _maxSalaryController.clear();
                          _cityController.clear();
                          _stateController.clear();
                          _suburbController.clear();
                          setState(() {
                            _selectedDateRange = null;
                          });
                          widget.onClearFilters();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFF2193b0)),
                        ),
                        child: Text(
                          'Clear',
                          style: TextStyle(color: Color(0xFF2193b0)),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApplyFilters(
                            _selectedDateRange,
                            _keywordController.text,
                            _minSalaryController.text.isEmpty
                                ? null
                                : double.tryParse(_minSalaryController.text),
                            _maxSalaryController.text.isEmpty
                                ? null
                                : double.tryParse(_maxSalaryController.text),
                            _cityController.text,
                            _stateController.text,
                            _suburbController.text,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2193b0),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Categories Page - Browse jobs by category
class CategoriesPage extends StatefulWidget {
  final List<Job> jobs;
  final Function(String) onCategorySelected;

  const CategoriesPage({
    super.key,
    required this.jobs,
    required this.onCategorySelected,
  });

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final List<String> categories = kNepalAusJobCategoriesUi;

  final Map<String, IconData> categoryIcons = kNepalAusJobCategoryIcons;
  final Map<String, Color> categoryColors = kNepalAusJobCategoryColors;
  final Map<String, String> categoryDescriptions =
      kNepalAusJobCategoryDescriptions;

  @override
  Widget build(BuildContext context) {
    // Filter categories to only show those with jobs
    final categoriesWithJobs = categories.where((category) {
      final jobCount = widget.jobs
          .where((job) => job.category == category)
          .length;
      return jobCount > 0;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Browse Categories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2193b0),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: categoriesWithJobs.isEmpty
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6dd5ed).withValues(alpha: 0.2),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No categories available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Come back when jobs are posted',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6dd5ed).withValues(alpha: 0.2),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore job categories',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2193b0),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Find your perfect opportunity by category',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final category = categoriesWithJobs[index];
                        final jobCount = widget.jobs
                            .where((job) => job.category == category)
                            .length;

                        return CategoryCard(
                          category: category,
                          jobCount: jobCount,
                          description: categoryDescriptions[category] ?? '',
                          icon: categoryIcons[category] ?? Icons.category,
                          color: categoryColors[category] ?? Color(0xFF2193b0),
                          onTap: () {
                            widget.onCategorySelected(category);
                            Navigator.pop(context);
                          },
                        );
                      }, childCount: categoriesWithJobs.length),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }
}

// Category Card Widget
class CategoryCard extends StatefulWidget {
  final String category;
  final int jobCount;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.jobCount,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.color, widget.color.withValues(alpha: 0.75)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(10),
                    child: Icon(widget.icon, color: Colors.white, size: 28),
                  ),
                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          '${widget.jobCount} ${widget.jobCount == 1 ? 'job' : 'jobs'} available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Jobs by Category Page
class JobsByCategoryPage extends StatefulWidget {
  final String category;
  final List<Job> allJobs;

  const JobsByCategoryPage({
    super.key,
    required this.category,
    required this.allJobs,
  });

  @override
  State<JobsByCategoryPage> createState() => _JobsByCategoryPageState();
}

class _JobsByCategoryPageState extends State<JobsByCategoryPage> {
  late List<Job> categoryJobs;

  // Filter variables
  DateTimeRange? _selectedDateRange;
  String _searchKeyword = '';
  double? _minSalary;
  double? _maxSalary;
  String _selectedCity = '';
  String _selectedState = '';
  String _selectedSuburb = '';
  bool _hasActiveFilters = false;

  // Helper method to parse salary from string like "$80,000 - $120,000"
  double _extractMinSalary(String salaryStr) {
    try {
      final parts = salaryStr.replaceAll('\$', '').split('-');
      return double.parse(parts[0].trim().replaceAll(',', ''));
    } catch (e) {
      return 0;
    }
  }

  // Filter jobs based on active filters
  List<Job> _getFilteredJobs(List<Job> jobsList) {
    return jobsList.where((job) {
      // Filter by date range
      if (_selectedDateRange != null) {
        if (job.postedDate.isBefore(_selectedDateRange!.start) ||
            job.postedDate.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }

      // Filter by keywords (title, company, description)
      if (_searchKeyword.isNotEmpty) {
        final keyword = _searchKeyword.toLowerCase();
        if (!job.title.toLowerCase().contains(keyword) &&
            !job.company.toLowerCase().contains(keyword) &&
            !job.description.toLowerCase().contains(keyword)) {
          return false;
        }
      }

      // Filter by salary range
      if (_minSalary != null || _maxSalary != null) {
        final jobMinSalary = _extractMinSalary(job.salary);
        if (_minSalary != null && jobMinSalary < _minSalary!) {
          return false;
        }
        if (_maxSalary != null && jobMinSalary > _maxSalary!) {
          return false;
        }
      }

      // Filter by location (city, state, suburb)
      if (_selectedCity.isNotEmpty ||
          _selectedState.isNotEmpty ||
          _selectedSuburb.isNotEmpty) {
        final locationParts = job.location.toLowerCase().split(',');
        final jobSuburb = locationParts.isNotEmpty
            ? locationParts[0].trim()
            : '';
        final jobState = locationParts.length > 1
            ? locationParts[1].trim()
            : '';

        if (_selectedCity.isNotEmpty &&
            !jobSuburb.contains(_selectedCity.toLowerCase())) {
          return false;
        }

        if (_selectedState.isNotEmpty &&
            !jobState.contains(_selectedState.toLowerCase())) {
          return false;
        }

        if (_selectedSuburb.isNotEmpty &&
            !jobSuburb.contains(_selectedSuburb.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _updateFilterStatus() {
    setState(() {
      _hasActiveFilters =
          _selectedDateRange != null ||
          _searchKeyword.isNotEmpty ||
          _minSalary != null ||
          _maxSalary != null ||
          _selectedCity.isNotEmpty ||
          _selectedState.isNotEmpty ||
          _selectedSuburb.isNotEmpty;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _searchKeyword = '';
      _minSalary = null;
      _maxSalary = null;
      _selectedCity = '';
      _selectedState = '';
      _selectedSuburb = '';
      _hasActiveFilters = false;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        onApplyFilters:
            (dateRange, keyword, minSalary, maxSalary, city, state, suburb) {
              setState(() {
                _selectedDateRange = dateRange;
                _searchKeyword = keyword;
                _minSalary = minSalary;
                _maxSalary = maxSalary;
                _selectedCity = city;
                _selectedState = state;
                _selectedSuburb = suburb;
              });
              _updateFilterStatus();
              Navigator.pop(context);
            },
        onClearFilters: _clearFilters,
        initialDateRange: _selectedDateRange,
        initialKeyword: _searchKeyword,
        initialMinSalary: _minSalary,
        initialMaxSalary: _maxSalary,
        initialCity: _selectedCity,
        initialState: _selectedState,
        initialSuburb: _selectedSuburb,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    categoryJobs = widget.allJobs
        .where((job) => job.category == widget.category)
        .toList();
    categoryJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.category} Jobs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2193b0),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter jobs',
                ),
                if (_hasActiveFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: 12,
                      height: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final filteredJobs = _getFilteredJobs(categoryJobs);
          final sortedJobs = List<Job>.from(filteredJobs)
            ..sort((a, b) => b.postedDate.compareTo(a.postedDate));

          return filteredJobs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasActiveFilters ? Icons.search_off : Icons.work_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        _hasActiveFilters
                            ? 'No jobs match your filters'
                            : 'No jobs in this category',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _hasActiveFilters
                            ? 'Try adjusting your filters'
                            : 'Check back later for new opportunities',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      if (_hasActiveFilters) SizedBox(height: 16),
                      if (_hasActiveFilters)
                        ElevatedButton(
                          onPressed: _clearFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2193b0),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Clear Filters'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: sortedJobs.length,
                  itemBuilder: (context, index) {
                    final job = sortedJobs[index];
                    return JobCard(
                      job: job,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                JobDetailPage(job: job, currentUserId: AuthState.currentUserId ?? 'guest'),
                          ),
                        ).then((result) {
                          if (!mounted) return;
                          if (result is! JobDetailResult) return;

                          if (result.deletedId != null) {
                            setState(() {
                              categoryJobs.removeWhere(
                                (j) => j.id == result.deletedId,
                              );
                            });
                            return;
                          }

                          if (result.updatedJob != null) {
                            final updated = result.updatedJob!;
                            setState(() {
                              final idx = categoryJobs.indexWhere(
                                (j) => j.id == updated.id,
                              );
                              if (idx != -1) categoryJobs[idx] = updated;
                            });
                          }
                        });
                      },
                      currentUserId: AuthState.currentUserId ?? 'guest',
                      onDelete: () {
                        setState(() {
                          categoryJobs.removeWhere((j) => j.id == job.id);
                        });
                      },
                    );
                  },
                );
        },
      ),
    );
  }
}

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedJobType = 'Full-time';
  String _selectedCategory = kNepalAusJobCategoriesUi.first;
  bool _isSubmitting = false;
  Uint8List? _pickedImageBytes;

  final List<String> _jobTypes = ['Full-time', 'Part-time', 'Contract'];
  final List<String> _categories = kNepalAusJobCategoriesUi;

  @override
  void initState() {
    super.initState();
    // Best-effort: prefill contact fields from signed-in user
    populateContactControllers(
      phoneController: _phoneController,
      emailController: _emailController,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _pickedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      // ignore: use_build_context_synchronously
      final messenger = ScaffoldMessenger.of(context);
      final createdBy = AuthState.currentUserId ?? 'guest';
      final allowed = await VerificationService.canPost(createdBy);
      if (!allowed) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        messenger.showSnackBar(
          const SnackBar(content: Text('Only verified contributors may post jobs.')),
        );
        return;
      }
      // Validate email and phone using SecurityService
      if (!securityService.isValidEmail(_emailController.text)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address')),
        );
        return;
      }

      if (!securityService.isValidPhoneNumber(_phoneController.text)) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid Australian phone number'),
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final createdBy = AuthState.currentUserId ?? 'guest';
        final title = securityService.sanitizeInput(_titleController.text);
        final company = securityService.sanitizeInput(_companyController.text);
        final location = securityService.sanitizeInput(
          _locationController.text,
        );
        final description = securityService.sanitizeInput(
          _descriptionController.text,
        );
        final salary = securityService.sanitizeInput(_salaryController.text);

        final doc = FirebaseFirestore.instance
            .collection('community_jobs')
            .doc();

        String imageUrl = '';
        if (_pickedImageBytes != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('community_jobs')
              .child(doc.id)
              .child('cover');

          await ref.putData(
            _pickedImageBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          imageUrl = await ref.getDownloadURL();
        }

        await doc.set({
          'title': title,
          'company': company,
          'location': location,
          'description': description,
          'jobType': _selectedJobType,
          'salary': salary,
          'phoneNumber': _phoneController.text,
          'email': _emailController.text,
          'category': _selectedCategory,
          'sourceUrl': '',
          'imageUrl': imageUrl,
          'createdBy': createdBy,
          'postedDate': FieldValue.serverTimestamp(),
          'viewCount': 0,
          'isClosed': false,
          'stateAbbr': _extractAustralianStateAbbr(location),
        });

        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(const SnackBar(content: Text('Job posted')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _isSubmitting
              ? null
              : () {
                  Navigator.maybePop(context);
                },
        ),
        title: const Text('Post a Job'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Optional image
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Image (optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_pickedImageBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _pickedImageBytes!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : _pickImage,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Change'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _pickedImageBytes = null;
                                      });
                                    },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickImage,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Add photo'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tip: Add a workplace photo or logo to build trust.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Job Title *',
                hintText: 'e.g., Software Engineer',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a job title';
                }
                if (value.length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Company Field
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                hintText: 'e.g., Tech Corp',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a company name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Location Field
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location *',
                hintText: 'e.g., Sydney, NSW',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Job Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedJobType,
              decoration: const InputDecoration(labelText: 'Job Type *'),
              items: _jobTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedJobType = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Salary Field
            TextFormField(
              controller: _salaryController,
              decoration: const InputDecoration(
                labelText: 'Salary Range *',
                hintText: '\$80,000 - \$120,000 per year',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a salary range';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Phone Field
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Contact Phone *',
                hintText: '+61 2 9234 5678',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a contact phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Contact Email *',
                hintText: 'hr@company.com.au',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a contact email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Job Description *',
                hintText: 'Describe the job responsibilities and requirements',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a job description';
                }
                if (value.length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),


            // Submit Button (full width)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Post Job'),
                ),
              ),
            ),

            const SizedBox(height: 12),

            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
