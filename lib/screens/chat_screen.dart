import 'package:flutter/material.dart';

import '../models/marketplace_models.dart';
import '../models/user_model.dart';
import '../services/marketplace_service.dart';

class ChatScreen extends StatefulWidget {
  final TutoringSession session;
  final AppUser currentUser;

  const ChatScreen({
    super.key,
    required this.session,
    required this.currentUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherName = widget.session.otherName(widget.currentUser.id);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherName, style: const TextStyle(fontSize: 16)),
            Text(
              widget.session.status == 'active'
                  ? 'Sesi aktif'
                  : 'Sesi berakhir',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'end') _confirmEndSession();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'end',
                child: Text('Akhiri sesi'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: MarketplaceService.messages(widget.session.id),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <ChatMessage>[];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada pesan',
                      style: TextStyle(color: Colors.black38),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    final message = messages[index];
                    final isMine = message.senderId == widget.currentUser.id;
                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.74,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.black87 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isMine
                              ? null
                              : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: isMine ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      enabled: widget.session.isActive,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: widget.session.isActive
                            ? 'Tulis pesan...'
                            : 'Sesi sudah berakhir',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed:
                        widget.session.isActive && !_isSending ? _send : null,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    _messageCtrl.clear();
    try {
      await MarketplaceService.sendMessage(
        sessionId: widget.session.id,
        sender: widget.currentUser,
        text: text,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _confirmEndSession() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Akhiri sesi?'),
        content: const Text('Student atau tutor dapat mengakhiri sesi ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await MarketplaceService.endSession(widget.session.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Akhiri'),
          ),
        ],
      ),
    );
  }
}
