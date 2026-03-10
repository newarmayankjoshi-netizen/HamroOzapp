import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'auth_page.dart';
import 'services/security_service.dart';
import 'package:hamro_oz/utils/map_utils.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = toStringKeyMap(doc.data());
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown User',
      recipientId: data['recipientId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }
}

class UserChatPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const UserChatPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<UserChatPage> createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _securityService = SecurityService();
  final _focusNode = FocusNode();
  late Stream<QuerySnapshot> _messagesStream;
  String? _currentUserId;
  String? _currentUserName;
  int? _lastMessageCount;

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthState.currentUserId;
    _currentUserName = AuthState.currentUserName;
    _initializeMessagesStream();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newUserId = AuthState.currentUserId;
    final newUserName = AuthState.currentUserName;
    if (newUserId != _currentUserId || newUserName != _currentUserName) {
      _currentUserId = newUserId;
      _currentUserName = newUserName;
      _initializeMessagesStream();
      _lastMessageCount = null;
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant UserChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.otherUserId != widget.otherUserId) {
      _lastMessageCount = null;
    }
  }

  void _initializeMessagesStream() {
    final currentUserId = AuthState.currentUserId;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      try {
        _messagesStream = FirebaseFirestore.instance
            .collection('messages')
            .where(
              Filter.or(
                Filter('senderId', isEqualTo: currentUserId),
                Filter('recipientId', isEqualTo: currentUserId),
              ),
            )
            .snapshots();
      } catch (e) {
        _messagesStream = Stream.empty();
      }
    } else {
      _messagesStream = Stream.empty();
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUserId = AuthState.currentUserId;
    final currentUserName = AuthState.currentUserName;
    if (currentUserId == null || currentUserName == null) return;

    final sanitizedMessage = _securityService.sanitizeInput(
      _messageController.text.trim(),
      maxLength: 1000,
    );

    if (sanitizedMessage.isEmpty) return;

    if (_securityService.containsProhibitedContent(sanitizedMessage)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message contains prohibited content.'),
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': currentUserId,
        'senderName': currentUserName,
        'recipientId': widget.otherUserId,
        'content': sanitizedMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'direct_message',
      });

      _messageController.clear();

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(timestamp);
    } else {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserName), elevation: 1),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error loading messages: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final allMessages = snapshot.data?.docs.map((d) => ChatMessage.fromFirestore(d)).toList() ?? [];

                final messages = allMessages.where((message) {
                  return (message.senderId == _currentUserId && message.recipientId == widget.otherUserId) ||
                      (message.senderId == widget.otherUserId && message.recipientId == _currentUserId);
                }).toList()
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                if (_lastMessageCount != messages.length) {
                  _lastMessageCount = messages.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  });
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('Start a conversation with ${widget.otherUserName}', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                final List<List<ChatMessage>> groups = [];
                for (final m in messages) {
                  if (groups.isEmpty || groups.last.last.senderId != m.senderId) {
                    groups.add([m]);
                  } else {
                    groups.last.add(m);
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  itemBuilder: (context, gIndex) {
                    final group = groups[gIndex];
                    final first = group.first;
                    final last = group.last;
                    final isOwn = first.senderId == _currentUserId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isOwn) ...[
                            CircleAvatar(radius: 16, backgroundColor: theme.colorScheme.primary, child: Text(first.senderName.isNotEmpty ? first.senderName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 8),
                          ],

                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: isOwn ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
                              child: Column(
                                crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (!isOwn) Text(first.senderName, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                  ...group.map((m) => Padding(padding: const EdgeInsets.only(top: 6), child: Text(m.content, style: theme.textTheme.bodyMedium?.copyWith(color: isOwn ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)))),
                                  const SizedBox(height: 6),
                                  Text(_formatTimestamp(last.timestamp), style: theme.textTheme.bodySmall?.copyWith(color: (isOwn ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface).withValues(alpha: 0.7), fontSize: 10)),
                                ],
                              ),
                            ),
                          ),

                          if (isOwn) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(radius: 16, backgroundColor: theme.colorScheme.primary, child: Text(_currentUserName?.isNotEmpty == true ? _currentUserName![0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.colorScheme.surface, border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 1))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    autofocus: false,
                    decoration: InputDecoration(hintText: 'Type a message...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _sendMessage, icon: const Icon(Icons.send), style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}