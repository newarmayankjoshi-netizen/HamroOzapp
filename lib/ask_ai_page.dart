import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/ask_ai_service.dart';

class AskAIPage extends StatefulWidget {
  final String guideTitle;
  final String guideContent;

  const AskAIPage({
    super.key,
    required this.guideTitle,
    required this.guideContent,
  });

  @override
  State<AskAIPage> createState() => _AskAIPageState();
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  final _ChatRole role;
  final String text;
  final DateTime createdAt;

  _ChatMessage({required this.role, required this.text, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();
}

class _AskAIPageState extends State<AskAIPage> {
  final _messages = <_ChatMessage>[];
  final _inputCtrl = TextEditingController();
  final _listCtrl = ScrollController();

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        role: _ChatRole.assistant,
        text:
            'Ask me anything about this guide. I will answer by looking at the guide content on this screen (no external AI needed).\n\nExamples:\n• Explain this in Nepali\n• What documents do I need?\n• What should I do first?\n• Explain this step by step',
      ),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _scrollToBottom() async {
    if (!_listCtrl.hasClients) return;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (!_listCtrl.hasClients) return;
    _listCtrl.animateTo(
      _listCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  String _historyKey() {
    final digest = sha1.convert(utf8.encode(widget.guideTitle));
    return 'ask_ai_history_${digest.toString()}';
  }

  Future<void> _rememberQuestion(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _historyKey();
    final existing = (prefs.getStringList(key) ?? const []).toList();

    existing.removeWhere(
      (q) => q.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    existing.insert(0, trimmed);

    final capped = existing.take(5).toList(growable: false);
    await prefs.setStringList(key, capped);
  }

  Future<void> _send() async {
    final userText = _inputCtrl.text.trim();
    if (userText.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(role: _ChatRole.user, text: userText));
      _inputCtrl.clear();
    });
    await _scrollToBottom();

    try {
      await _rememberQuestion(userText);
      final reply = await AskAiService.askGuideQuestion(
        guideTitle: widget.guideTitle,
        guideContent: widget.guideContent,
        userMessage: userText,
        recentQuestions: const [],
      );

      final effectiveReply = reply.trim().isEmpty
          ? 'I couldn\'t find a clear answer in this guide text. Try asking with more detail, or paste the exact sentence you want explained.'
          : reply;

      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(role: _ChatRole.assistant, text: effectiveReply),
        );
      });
      await _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ask AI failed: $e')));
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _ChatRole.assistant,
            text:
                'Sorry — I had trouble answering that. Please try again in a moment.',
          ),
        );
      });
      await _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Widget _bubble(_ChatMessage message) {
    final isUser = message.role == _ChatRole.user;
    final bg = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final fg = isUser ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            message.text,
            style: TextStyle(color: fg, height: 1.35),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask AI'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(34),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.guideTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _listCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _bubble(_messages[index]),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask a question about this guide…',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
