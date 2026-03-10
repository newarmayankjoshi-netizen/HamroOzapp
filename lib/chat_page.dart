import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'auth_page.dart';
import 'user_chat_page.dart';
import 'package:hamro_oz/utils/map_utils.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String subject;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedItemId; // For marketplace inquiries
  final String? relatedItemTitle;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.subject,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.relatedItemId,
    this.relatedItemTitle,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = toStringKeyMap(doc.data());
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown User',
      recipientId: data['recipientId'] ?? '',
      subject: data['subject'] ?? 'No Subject',
      content: data['content'] ?? data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      relatedItemId: data['relatedItemId'],
      relatedItemTitle: data['relatedItemTitle'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'subject': subject,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'relatedItemId': relatedItemId,
      'relatedItemTitle': relatedItemTitle,
    };
  }
}

class ChatPage extends StatefulWidget {
  final bool embedInScaffold;

  const ChatPage({super.key, this.embedInScaffold = true});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Stream<QuerySnapshot> _messagesStream;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthState.currentUserId;
    _initializeMessagesStream();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newUserId = AuthState.currentUserId;
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _initializeMessagesStream();
      setState(() {});
    }
  }

  void _initializeMessagesStream() {
    final currentUserId = AuthState.currentUserId;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      try {
        // Only listen for messages that are sent to the current user (inbox)
        _messagesStream = FirebaseFirestore.instance
            .collection('messages')
            .where('recipientId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots();
      } catch (e) {
        _messagesStream = Stream.empty();
      }
    } else {
      _messagesStream = Stream.empty();
    }
  }

  Future<void> _markConversationAsRead(String senderId) async {
    final currentUserId = AuthState.currentUserId;
    if (currentUserId == null) return;
    try {
      final qs = await FirebaseFirestore.instance
          .collection('messages')
          .where('senderId', isEqualTo: senderId)
          .where('recipientId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in qs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      // ignore
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  // Simple deterministic avatar color based on sender id
  Color _avatarColor(String id) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.redAccent,
    ];
    final hash = id.codeUnits.fold<int>(0, (a, b) => a * 31 + b);
    return colors[(hash.abs()) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!AuthState.isLoggedIn || AuthState.currentUserId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/auth');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final content = StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          String errorMessage = 'Failed to load messages';
          String errorDetails = 'Please try again later';
          Widget? actionButton;

          if (AuthState.currentUserId == null || !AuthState.isLoggedIn) {
            errorMessage = 'Sign in required';
            errorDetails = 'You need to be signed in to view messages';
            actionButton = ElevatedButton(onPressed: () => Navigator.of(context).pushNamed('/auth'), child: const Text('Sign In'));
          } else if (error is FirebaseException) {
            // Detect Firestore 'requires an index' message and extract the console URL
            final errText = error.toString();
            final urlMatch = RegExp(r'https?://[^\s)]+create_composite[^\s)]*').firstMatch(errText);
            if (urlMatch != null) {
              final indexUrl = urlMatch.group(0);
              errorMessage = 'Index required';
              errorDetails = 'This query requires a Firestore index.';
              actionButton = ElevatedButton(
                onPressed: () {
                  if (indexUrl != null) Clipboard.setData(ClipboardData(text: indexUrl));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Index URL copied to clipboard. Open it in your browser to create the index.')));
                },
                child: const Text('Copy Index URL'),
              );
            }
            
            if (actionButton == null) {
              // fall through to other FirebaseException handling
            }
          } 
          else if (error is FirebaseException) {
            if (error.code == 'permission-denied') {
              errorMessage = 'Access denied';
              errorDetails = 'You may not be logged in properly. Try signing out and back in.';
              actionButton = ElevatedButton(
                onPressed: () async {
                  await AuthState.logout();
                  if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                },
                child: const Text('Sign Out & Re-login'),
              );
            } else if (error.code == 'unavailable') {
              errorMessage = 'Service unavailable';
              errorDetails = 'Please check your internet connection';
            }
          }

          // Ensure there's an action button for generic errors (Retry)
          actionButton ??= ElevatedButton(
            onPressed: () {
              _initializeMessagesStream();
              setState(() {});
            },
            child: const Text('Retry'),
          );

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    '$errorMessage — $errorDetails',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyMedium?.color),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                actionButton,
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final messages = snapshot.data!.docs.map((d) => ChatMessage.fromFirestore(d)).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No messages yet', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Messages from other users will appear here', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)), textAlign: TextAlign.center),
              ],
            ),
          );
        }

        // Group messages by sender to show a single conversation row per user
        final Map<String, List<ChatMessage>> bySender = {};
        for (final m in messages) {
          bySender.putIfAbsent(m.senderId, () => []).add(m);
        }

        // Create a list of conversation summaries (latest message per sender)
        final conversations = bySender.entries.map((e) {
          final list = e.value..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          final latest = list.first;
          final unreadCount = list.where((m) => !m.isRead).length;
          return {
            'senderId': e.key,
            'senderName': latest.senderName,
            'latest': latest,
            'unread': unreadCount,
          };
        }).toList()
          ..sort((a, b) => (b['latest'] as ChatMessage).timestamp.compareTo((a['latest'] as ChatMessage).timestamp));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final convo = conversations[index];
            final ChatMessage latest = convo['latest'] as ChatMessage;
            final int unread = convo['unread'] as int;
            final String senderId = convo['senderId'] as String;
            final String senderName = convo['senderName'] as String;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () async {
                  await _markConversationAsRead(senderId);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserChatPage(otherUserId: senderId, otherUserName: senderName)),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _avatarColor(senderId),
                        child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    senderName,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(_formatTimestamp(latest.timestamp), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // bubble-like preview
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(latest.content, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.85))),
                            ),
                          ],
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                          child: Text(unread.toString(), style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (widget.embedInScaffold) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final unreadCount = snapshot.data!.docs.where((doc) => !((toStringKeyMap(doc.data())['isRead'] ?? false))).length;
                if (unreadCount == 0) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: Text(unreadCount.toString(), style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ],
        ),
        body: content,
      );
    }

    return SafeArea(child: content);
  }

  
}