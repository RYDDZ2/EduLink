import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../models/marketplace_models.dart';
import '../models/user_model.dart';
import '../services/marketplace_service.dart';
import '../services/supabase_chat_attachment_service.dart';

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
  final _focusNode = FocusNode();
  bool _isSending = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _messageCtrl.dispose();
    _focusNode.dispose();
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
                return _buildMessageList(messages);
              },
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  // ------- Message list with date separators -------

  Widget _buildMessageList(List<ChatMessage> messages) {
    // Messages are in descending order (newest first) from stream.
    // Reverse to render oldest first, which is natural for chat.
    final reversed = messages.reversed.toList();
    final items = _buildItemsWithSeparators(reversed);

    return ListView.builder(
      reverse: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  List<Widget> _buildItemsWithSeparators(List<ChatMessage> messages) {
    if (messages.isEmpty) return const [];

    final items = <Widget>[];
    items.add(_buildDateDivider(messages.first.createdAt));

    for (int i = 0; i < messages.length; i++) {
      items.add(_buildMessageBubble(messages[i]));

      if (i + 1 < messages.length &&
          !_isSameDay(messages[i].createdAt, messages[i + 1].createdAt)) {
        items.add(_buildDateDivider(messages[i + 1].createdAt));
      }
    }

    return items;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Hari ini';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Kemarin';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      label = '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  // ------- Message bubble -------

  Widget _buildMessageBubble(ChatMessage message) {
    final isMine = message.senderId == widget.currentUser.id;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isMine ? Colors.black87 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isMine ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.text.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  bottom: message.attachmentUrl != null ? 8.0 : 0,
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
            if (message.attachmentUrl != null &&
                message.attachmentType == 'image')
              _buildImageAttachment(message, isMine),
            if (message.attachmentUrl != null &&
                (message.attachmentType == 'doc' ||
                    message.attachmentType == 'file'))
              _buildDocAttachment(message, isMine),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isMine ? Colors.white70 : Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAttachment(ChatMessage message, bool isMine) {
    return GestureDetector(
      onTap: () => _showImagePreview(message.attachmentUrl!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          message.attachmentUrl!,
          width: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: 220,
              height: 140,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              width: 220,
              height: 140,
              child: Center(child: Icon(Icons.broken_image_rounded)),
            );
          },
        ),
      ),
    );
  }

  void _showImagePreview(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImage(url: url),
      ),
    );
  }

  Widget _buildDocAttachment(ChatMessage message, bool isMine) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _downloadAndOpenFile(
        url: message.attachmentUrl!,
        fileName: message.attachmentName ?? 'Dokumen',
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _docIcon(message.attachmentName ?? ''),
              size: 20,
              color: isMine ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.attachmentName ?? 'Dokumen',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.download_rounded,
              size: 16,
              color: isMine ? Colors.white54 : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  IconData _docIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'txt':
        return Icons.article_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _downloadAndOpenFile({
    required String url,
    required String fileName,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mengunduh file...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final response = await http.get(Uri.parse(url));
      await file.writeAsBytes(response.bodyBytes);

      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka file: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  // ------- Chat input -------

  Widget _buildChatInput() {
    final isActive = widget.session.isActive;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Camera button - left of input field
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: InkWell(
                    onTap: _isSending ? null : _pickAndSendImage,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        size: 22,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              if (isActive) const SizedBox(width: 4),
              // Expanded text field with gallery & attach inside
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _messageCtrl,
                          focusNode: _focusNode,
                          enabled: isActive,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Tulis pesan...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      // Gallery button inside input
                      if (isActive)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2, right: 2),
                          child: InkWell(
                            onTap: _isSending ? null : _pickAndSendFromGallery,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.photo_library_rounded,
                                size: 20,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ),
                      // File attach button inside input
                      if (isActive)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2, right: 2),
                          child: InkWell(
                            onTap: _isSending ? null : _pickAndSendDoc,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.attach_file_rounded,
                                size: 20,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button outside input
              _isSending
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: isActive ? _send : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.black87 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ------- Actions -------

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

  Future<void> _pickAndSendImage() async {
    try {
      setState(() => _isSending = true);
      final xfile = await _picker.pickImage(source: ImageSource.camera);
      if (xfile == null) return;
      await _uploadAndSendImage(xfile);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendFromGallery() async {
    try {
      setState(() => _isSending = true);
      final xfile = await _picker.pickImage(source: ImageSource.gallery);
      if (xfile == null) return;
      await _uploadAndSendImage(xfile);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _uploadAndSendImage(XFile xfile) async {
    final ext = xfile.path.split('.').last;
    final mime = 'image/jpeg';
    final url = await SupabaseChatAttachmentService.uploadAttachment(
      sessionId: widget.session.id,
      senderId: widget.currentUser.id,
      kind: 'image',
      fileExt: ext,
      xfile: XFileLike(xfile.path),
      originalFileName: xfile.name,
      mime: mime,
    );

    await MarketplaceService.sendMessageImage(
      sessionId: widget.session.id,
      sender: widget.currentUser,
      text: _messageCtrl.text.trim(),
      imageUrl: url,
      imageName: xfile.name,
      mime: mime,
    );

    _messageCtrl.clear();
  }

  Future<void> _pickAndSendDoc() async {
    try {
      setState(() => _isSending = true);

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final path = file.path;
      if (path == null) return;

      final parts = file.name.split('.');
      final ext = (parts.length > 1 ? parts.last : 'bin').toLowerCase();

      final url = await SupabaseChatAttachmentService.uploadAttachment(
        sessionId: widget.session.id,
        senderId: widget.currentUser.id,
        kind: 'doc',
        fileExt: ext,
        xfile: XFileLike(path),
        originalFileName: file.name,
        mime: null,
      );

      await MarketplaceService.sendMessageDoc(
        sessionId: widget.session.id,
        sender: widget.currentUser,
        text: _messageCtrl.text.trim(),
        docUrl: url,
        docName: file.name,
        mime: null,
      );

      _messageCtrl.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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

// ------- Full screen image preview page -------

class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image_rounded,
                        color: Colors.white54, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Gagal memuat gambar',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
