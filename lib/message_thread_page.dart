import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'marketplace_page.dart';
import 'services/security_service.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isOwn;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isOwn,
  });
}

class MessageThreadPage extends StatefulWidget {
  final MarketplaceItem item;

  const MessageThreadPage({
    super.key,
    required this.item,
  });

  @override
  State<MessageThreadPage> createState() => _MessageThreadPageState();
}

class _MessageThreadPageState extends State<MessageThreadPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _securityService = SecurityService();
  final List<DateTime> _messageTimestamps = [];
  DateTime? _lastMessageSentAt;
  static const Duration _minMessageInterval = Duration(seconds: 2);
  static const int _maxMessagesPer5Min = 20;
  
  late List<Message> messages;
  final String _currentUserId = 'current_user';

  @override
  void initState() {
    super.initState();
    // Initialize with sample messages
    messages = [
      Message(
        id: '1',
        senderId: widget.item.sellerId,
        senderName: widget.item.sellerName,
        content: 'Hi! Is this item still available?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isOwn: false,
      ),
      Message(
        id: '2',
        senderId: _currentUserId,
        senderName: 'You',
        content: 'Yes, it is! Interested?',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isOwn: true,
      ),
      Message(
        id: '3',
        senderId: widget.item.sellerId,
        senderName: widget.item.sellerName,
        content: 'Can you provide more details about the condition?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isOwn: false,
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    final sanitizedMessage = _securityService.sanitizeInput(
      _messageController.text,
      maxLength: 1000,
    );

    if (sanitizedMessage.isEmpty) return;

    if (_securityService.containsProhibitedContent(sanitizedMessage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message contains prohibited content.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_canSendMessage()) {
      return;
    }

    setState(() {
      messages.add(
        Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: _currentUserId,
          senderName: 'You',
          content: sanitizedMessage,
          timestamp: DateTime.now(),
          isOwn: true,
        ),
      );
    });

    _messageController.clear();
    _scrollToBottom();
  }

  bool _canSendMessage() {
    final now = DateTime.now();

    if (_lastMessageSentAt != null &&
        now.difference(_lastMessageSentAt!) < _minMessageInterval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait before sending another message.'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    _messageTimestamps.removeWhere(
      (t) => now.difference(t) > const Duration(minutes: 5),
    );

    if (_messageTimestamps.length >= _maxMessagesPer5Min) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Too many messages. Please try again in a few minutes.'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    _messageTimestamps.add(now);
    _lastMessageSentAt = now;
    return true;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.sellerName),
            Text(
              widget.item.title,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _MessageBubble(
                  message: message,
                  theme: theme,
                  formatTime: _formatTime,
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: theme.dividerColor,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'[<>`"]')),
                    ],
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: theme.colorScheme.primary,
                  tooltip: 'Send message',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final ThemeData theme;
  final String Function(DateTime) formatTime;

  const _MessageBubble({
    required this.message,
    required this.theme,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: message.isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: message.isOwn
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isOwn
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: message.isOwn ? Colors.white : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatTime(message.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
