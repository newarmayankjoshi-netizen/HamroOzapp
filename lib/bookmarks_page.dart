import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/bookmark_service.dart';
import 'auth_page.dart';
import 'jobs_page.dart';
import 'rooms_page.dart';
import 'item_detail_page.dart';
import 'events_page.dart';
import 'marketplace_page.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  final int _pageSize = 20;
  late int _limit;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _limit = _pageSize;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final pos = _scrollController.position.pixels;
    if (pos >= max - 200) {
      setState(() {
        _limit += _pageSize;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  Future<void> _openTarget(BuildContext context, Map<String, dynamic> data) async {
    final targetType = data['targetType'] as String? ?? '';
    final targetId = data['targetId'] as String? ?? '';
    try {
      if (targetType == 'community_jobs') {
        final doc = await FirebaseFirestore.instance.collection('community_jobs').doc(targetId).get();
        if (!doc.exists) return;
        if (!mounted) return;
        final d = doc.data()!;
        final job = Job(
          id: doc.id,
          title: d['title'] ?? '',
          company: d['company'] ?? '',
          location: d['location'] ?? '',
          description: d['description'] ?? '',
          jobType: d['jobType'] ?? '',
          salary: d['salary'] ?? '',
          phoneNumber: d['phoneNumber'] ?? '',
          email: d['email'] ?? '',
          category: d['category'] ?? '',
          sourceUrl: d['sourceUrl'] ?? '',
          imageUrl: d['imageUrl'] ?? '',
          createdBy: d['createdBy'] ?? '',
          postedDate: (d['postedDate'] is Timestamp) ? (d['postedDate'] as Timestamp).toDate() : DateTime.now(),
        );
        if (!mounted) return;
        Navigator.push(this.context, MaterialPageRoute(builder: (_) => JobDetailPage(job: job, currentUserId: AuthState.currentUserId ?? 'guest')));
        return;
      }

      if (targetType == 'community_rooms') {
        final doc = await FirebaseFirestore.instance.collection('community_rooms').doc(targetId).get();
        if (!doc.exists) return;
        if (!mounted) return;
        final d = doc.data()!;
        final room = Room(
          id: doc.id,
          title: d['title'] ?? '',
          suburb: d['suburb'] ?? '',
          city: d['city'] ?? '',
          pricePerWeek: (d['pricePerWeek'] is num) ? (d['pricePerWeek'] as num).toDouble() : 0.0,
          roomType: d['roomType'] ?? '',
          description: d['description'] ?? '',
          address: d['address'] ?? '',
          phoneNumber: d['phoneNumber'] ?? '',
          email: d['email'] ?? '',
          landlordName: d['landlordName'] ?? '',
          photoUrl: d['photoUrl'] ?? '',
          photoPaths: List<String>.from(d['photoUrls'] ?? []),
          amenities: List<String>.from(d['amenities'] ?? []),
          createdBy: d['createdBy'] ?? '',
          postedDate: (d['postedDate'] is Timestamp) ? (d['postedDate'] as Timestamp).toDate() : DateTime.now(),
          latitude: d['latitude'] is num ? (d['latitude'] as num).toDouble() : null,
          longitude: d['longitude'] is num ? (d['longitude'] as num).toDouble() : null,
          viewCount: d['viewCount'] ?? 0,
          isClosed: d['isClosed'] ?? false,
          closedReason: d['closedReason'],
        );
        if (!mounted) return;
        Navigator.push(this.context, MaterialPageRoute(builder: (_) => RoomDetailPage(room: room, viewerUserId: AuthState.currentUserId ?? 'guest')));
        return;
      }

      if (targetType == 'marketplace_items') {
        final doc = await FirebaseFirestore.instance.collection('marketplace_items').doc(targetId).get();
        if (!doc.exists) return;
        if (!mounted) return;
        final d = doc.data()!;
        final item = MarketplaceItem(
          id: doc.id,
          title: d['title'] ?? '',
          description: d['description'] ?? '',
          price: (d['price'] is num) ? (d['price'] as num).toDouble() : 0.0,
          category: d['category'] ?? '',
          condition: d['condition'] ?? '',
          location: d['location'] ?? '',
          sellerId: d['createdBy'] ?? '',
          sellerName: d['sellerName'] ?? '',
          sellerPhone: d['sellerPhone'],
          postedDate: (d['postedDate'] is Timestamp) ? (d['postedDate'] as Timestamp).toDate() : DateTime.now(),
          images: List<String>.from(d['images'] ?? []),
          viewCount: d['viewCount'] ?? 0,
          isClosed: d['isClosed'] ?? false,
        );
        if (!mounted) return;
        Navigator.push(this.context, MaterialPageRoute(builder: (_) => ItemDetailPage(item: item)));
        return;
      }

      if (targetType == 'community_events') {
        final doc = await FirebaseFirestore.instance.collection('community_events').doc(targetId).get();
        if (!doc.exists) return;
        if (!mounted) return;
        final d = doc.data()!;
        final event = Event.fromMap(Map<String, dynamic>.from(d), doc.id);
        if (!mounted) return;
        Navigator.push(this.context, MaterialPageRoute(builder: (_) => EventDetailPage(event: event, currentUserId: AuthState.currentUserId)));
        return;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthState.currentUserId;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bookmarks')),
        body: const Center(child: Text('Please sign in to view bookmarks.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: BookmarkService.streamBookmarks(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];

          // Sort by createdAt (newest first) when possible.
          docs.sort((a, b) {
            final aTs = (a.data()['createdAt'] is Timestamp) ? (a.data()['createdAt'] as Timestamp).millisecondsSinceEpoch : 0;
            final bTs = (b.data()['createdAt'] is Timestamp) ? (b.data()['createdAt'] as Timestamp).millisecondsSinceEpoch : 0;
            return bTs.compareTo(aTs);
          });

          if (docs.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _limit = _pageSize;
                });
                await FirebaseFirestore.instance.collection('bookmarks').where('userId', isEqualTo: uid).get();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  // Add a small buffer to avoid minor bottom overflows on some devices.
                  height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom + 40,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark_outline, size: 72, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No bookmarks yet', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplacePage())),
                          child: const Text('Browse items'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // Show a paginated list view — client-side pagination driven by a
          // scroll controller. The stream provides all docs; we only render
          // up to `_limit` items and increase the limit when the user scrolls.
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _limit = _pageSize;
              });
              await FirebaseFirestore.instance.collection('bookmarks').where('userId', isEqualTo: uid).get();
            },
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24),
              // Only render up to [_limit] items; more will be loaded as the
              // user scrolls.
              itemCount: docs.take(_limit).length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final d = docs.take(_limit).toList()[index];
                final data = d.data();
                final title = (data['title'] as String?) ?? '${data['targetType']}/${data['targetId']}';
                final targetType = (data['targetType'] as String?) ?? '';
                final targetId = (data['targetId'] as String?) ?? '';
                final imageUrl = _pickImageUrlFromData(data);
                final createdAt = data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : null;

                final typeInfo = _typeLabelAndColor(targetType);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: imageUrl != null
                      ? Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).cardColor,
                            image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                          ),
                        )
                      : null,
                  title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeInfo['bg'] as Color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            typeInfo['label'] as String,
                            style: TextStyle(fontSize: 12, color: typeInfo['fg'] as Color),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!(targetType == 'marketplace_items' || targetType == 'community_events' || targetType == 'community_rooms' || targetType == 'community_jobs'))
                          Expanded(
                            child: Text(_collectionDisplayName(targetType), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          ),
                        // move short timestamp to the end of the subtitle to free up trailing space
                        if (createdAt != null) ...[
                          const SizedBox(width: 8),
                          Text(_formatDateShort(createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ],
                    ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      try {
                        await BookmarkService.removeBookmark(uid, targetType, targetId);
                      } catch (_) {}
                    },
                  ),
                  onTap: () => _openTarget(context, data),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDateShort(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  String? _pickImageUrlFromData(Map<String, dynamic> data) {
    // Look for common image fields used across collections.
    if (data['photoUrl'] is String && (data['photoUrl'] as String).isNotEmpty) return data['photoUrl'] as String;
    if (data['imageUrl'] is String && (data['imageUrl'] as String).isNotEmpty) return data['imageUrl'] as String;
    if (data['images'] is List && (data['images'] as List).isNotEmpty) return (data['images'] as List).first as String;
    if (data['photoUrls'] is List && (data['photoUrls'] as List).isNotEmpty) return (data['photoUrls'] as List).first as String;
    return null;
  }

  Map<String, Object> _typeLabelAndColor(String targetType) {
    switch (targetType) {
      case 'community_jobs':
        return {'label': 'Job', 'bg': Colors.blue.shade50, 'fg': Colors.blue.shade800};
      case 'community_rooms':
        return {'label': 'Room', 'bg': Colors.green.shade50, 'fg': Colors.green.shade800};
      case 'marketplace_items':
        return {'label': 'Item', 'bg': Colors.orange.shade50, 'fg': Colors.orange.shade800};
      case 'community_events':
        return {'label': 'Event', 'bg': Colors.purple.shade50, 'fg': Colors.purple.shade800};
      default:
        return {'label': 'Other', 'bg': Colors.grey.shade200, 'fg': Colors.grey.shade800};
    }
  }

  String _collectionDisplayName(String targetType) {
    switch (targetType) {
      case 'community_jobs':
        return 'Community jobs';
      case 'community_rooms':
        return 'Community rooms';
      case 'marketplace_items':
        return 'Marketplace items';
      case 'community_events':
        return 'Community events';
      default:
        // Fallback: prettify by replacing underscores and capitalizing words
        final parts = targetType.split(RegExp(r'[_\/]')).map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}').toList();
        return parts.join(' ');
    }
  }
}
