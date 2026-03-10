import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/in_app_notification_service.dart';
import 'auth_page.dart';
import 'profile_page.dart';
import 'rooms_page.dart';
import 'jobs_page.dart';
import 'item_detail_page.dart';
import 'marketplace_page.dart';

/// Page to display user notifications.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String? get _currentUserId => AuthState.currentUserId;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Sign in to view notifications',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              if (value == 'mark_all_read') {
                await InAppNotificationService.markAllAsRead(_currentUserId!);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                    ),
                  );
                }
              } else if (value == 'clear_all') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear all notifications?'),
                    content: const Text(
                      'This will delete all your notifications. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await InAppNotificationService.deleteAllNotifications(
                      _currentUserId!);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 12),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Clear all', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: InAppNotificationService.streamNotifications(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you have new activity, it will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return _NotificationTile(
                notificationId: doc.id,
                data: data,
                userId: _currentUserId!,
                onTap: () => _handleNotificationTap(doc.id, data),
                onDismiss: () async {
                  await InAppNotificationService.deleteNotification(
                    _currentUserId!,
                    doc.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleNotificationTap(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Mark as read
    await InAppNotificationService.markAsRead(_currentUserId!, notificationId);

    if (!mounted) return;

    final type = data['type'] as String? ?? '';
    final fromUserId = data['fromUserId'] as String?;
    final notificationData = data['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case NotificationType.newFollower:
        if (fromUserId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilePage(profileUserId: fromUserId),
            ),
          );
        }
        break;

      case NotificationType.newRoom:
        final roomId = notificationData['listingId'] as String?;
        if (roomId != null) {
          _openRoom(roomId);
        }
        break;

      case NotificationType.newJob:
        final jobId = notificationData['listingId'] as String?;
        if (jobId != null) {
          _openJob(jobId);
        }
        break;

      case NotificationType.newItem:
        final itemId = notificationData['listingId'] as String?;
        if (itemId != null) {
          _openItem(itemId);
        }
        break;

      case NotificationType.newReview:
        // Navigate to reviews page
        if (fromUserId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilePage(profileUserId: _currentUserId),
            ),
          );
        }
        break;

      default:
        // For other types, just mark as read
        break;
    }
  }

  Future<void> _openRoom(String roomId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('community_rooms')
          .doc(roomId)
          .get();

      if (!doc.exists || !mounted) return;

      final d = doc.data()!;
      final room = Room(
        id: doc.id,
        title: d['title'] ?? '',
        suburb: d['suburb'] ?? '',
        city: d['city'] ?? '',
        pricePerWeek:
            (d['pricePerWeek'] is num) ? (d['pricePerWeek'] as num).toDouble() : 0.0,
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
        postedDate: (d['postedDate'] is Timestamp)
            ? (d['postedDate'] as Timestamp).toDate()
            : DateTime.now(),
        latitude: d['latitude'] is num ? (d['latitude'] as num).toDouble() : null,
        longitude: d['longitude'] is num ? (d['longitude'] as num).toDouble() : null,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomDetailPage(
            room: room,
            viewerUserId: _currentUserId ?? 'guest',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open room')),
        );
      }
    }
  }

  Future<void> _openJob(String jobId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('community_jobs')
          .doc(jobId)
          .get();

      if (!doc.exists || !mounted) return;

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
        postedDate: (d['postedDate'] is Timestamp)
            ? (d['postedDate'] as Timestamp).toDate()
            : DateTime.now(),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailPage(
            job: job,
            currentUserId: _currentUserId ?? 'guest',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open job')),
        );
      }
    }
  }

  Future<void> _openItem(String itemId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('marketplace_items')
          .doc(itemId)
          .get();

      if (!doc.exists || !mounted) return;

      final d = doc.data()!;
      final item = MarketplaceItem(
        id: doc.id,
        title: d['title'] ?? '',
        description: d['description'] ?? '',
        price: (d['price'] is num) ? (d['price'] as num).toDouble() : 0.0,
        category: d['category'] ?? '',
        condition: d['condition'] ?? '',
        location: d['location'] ?? '',
        sellerId: d['sellerId'] ?? '',
        sellerName: d['sellerName'] ?? '',
        sellerPhone: d['sellerPhone'],
        postedDate: (d['postedDate'] is Timestamp)
            ? (d['postedDate'] as Timestamp).toDate()
            : DateTime.now(),
        images: List<String>.from(d['images'] ?? []),
        viewCount: (d['viewCount'] is num) ? (d['viewCount'] as num).toInt() : 0,
        isClosed: d['isClosed'] ?? false,
        closedReason: d['closedReason'],
        closedAt: (d['closedAt'] is Timestamp)
            ? (d['closedAt'] as Timestamp).toDate()
            : null,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItemDetailPage(item: item),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open item')),
        );
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notificationId,
    required this.data,
    required this.userId,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? '';
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final isRead = data['read'] as bool? ?? false;
    final createdAt = data['createdAt'] as Timestamp?;
    final fromUserId = data['fromUserId'] as String?;

    final icon = _getIconForType(type);
    final iconColor = _getColorForType(type);
    final timeAgo = createdAt != null
        ? _formatTimeAgo(createdAt.toDate())
        : '';

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        color: isRead ? null : Colors.blue.shade50,
        child: ListTile(
          leading: fromUserId != null
              ? FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(fromUserId)
                      .get(),
                  builder: (context, snap) {
                    final userData = snap.data?.data() as Map<String, dynamic>?;
                    final profilePic = userData?['profilePicture'] as String?;
                    final name = userData?['name'] as String? ?? '?';

                    return Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: iconColor.withValues(alpha: 0.2),
                          backgroundImage: profilePic != null
                              ? NetworkImage(profilePic)
                              : null,
                          child: profilePic == null
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: iconColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(icon, size: 12, color: iconColor),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : CircleAvatar(
                  radius: 24,
                  backgroundColor: iconColor.withValues(alpha: 0.2),
                  child: Icon(icon, color: iconColor),
                ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (body.isNotEmpty)
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              if (timeAgo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
          trailing: !isRead
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case NotificationType.newFollower:
        return Icons.person_add;
      case NotificationType.newRoom:
        return Icons.home;
      case NotificationType.newJob:
        return Icons.work;
      case NotificationType.newItem:
        return Icons.shopping_bag;
      case NotificationType.newReview:
        return Icons.star;
      case NotificationType.verificationApproved:
        return Icons.verified;
      case NotificationType.verificationRejected:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case NotificationType.newFollower:
        return Colors.blue;
      case NotificationType.newRoom:
        return Colors.green;
      case NotificationType.newJob:
        return Colors.orange;
      case NotificationType.newItem:
        return Colors.purple;
      case NotificationType.newReview:
        return Colors.amber;
      case NotificationType.verificationApproved:
        return Colors.green;
      case NotificationType.verificationRejected:
        return Colors.red;
      case NotificationType.newMessage:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}w ago';
    } else {
      return '${(diff.inDays / 30).floor()}mo ago';
    }
  }
}
