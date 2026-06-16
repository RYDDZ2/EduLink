import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/study_hub_model.dart';
import '../models/user_model.dart';
import '../services/study_hub_service.dart';
import '../services/supabase_study_hub_service.dart';
import '../widgets/common_widgets.dart';

void _openFullScreenImage(BuildContext context, String url) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: InteractiveViewer(
          child: Center(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    ),
  );
}

class ThreadDetailScreen extends StatefulWidget {
  final StudyHubThread thread;
  final String hubId;
  final AppUser currentUser;

  const ThreadDetailScreen({
    super.key,
    required this.thread,
    required this.hubId,
    required this.currentUser,
  });

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final _replyController = TextEditingController();
  bool _isSubmitting = false;

  String? _attachmentPath;
  String? _attachmentName;
  String? _attachmentType;
  String? _attachmentMime;
  String? _attachmentExt;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile == null) return;
    final ext = xfile.name.split('.').last;
    setState(() {
      _attachmentPath = xfile.path;
      _attachmentName = xfile.name;
      _attachmentType = 'image';
      _attachmentMime = 'image/$ext';
      _attachmentExt = ext;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt',
      ],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    setState(() {
      _attachmentPath = file.path;
      _attachmentName = file.name;
      _attachmentType = 'doc';
      _attachmentMime = _mimeFromExt(file.extension ?? '');
      _attachmentExt = file.extension;
    });
  }

  void _clearAttachment() {
    setState(() {
      _attachmentPath = null;
      _attachmentName = null;
      _attachmentType = null;
      _attachmentMime = null;
      _attachmentExt = null;
    });
  }

  String _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty && _attachmentPath == null) return;

    setState(() => _isSubmitting = true);
    try {
      String? uploadedUrl;
      if (_attachmentPath != null) {
        uploadedUrl = await SupabaseStudyHubService.uploadAttachment(
          hubId: widget.hubId,
          userId: widget.currentUser.id,
          kind: _attachmentType!,
          filePath: _attachmentPath!,
          fileExt: _attachmentExt ?? '',
          mime: _attachmentMime,
        );
      }

      await StudyHubService.createReply(
        hubId: widget.hubId,
        threadId: widget.thread.id,
        content: text,
        authorId: widget.currentUser.id,
        authorName: widget.currentUser.name,
        authorInitials: widget.currentUser.initials,
        authorAvatarColor: '#E1F5EE',
        attachmentUrl: uploadedUrl,
        attachmentType: _attachmentType,
        attachmentName: _attachmentName,
      );
      _replyController.clear();
      _clearAttachment();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} hr yang lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam yang lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mnt yang lalu';
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Detail Diskusi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Original Post
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AvatarWidget(
                            initials: thread.authorInitials,
                            bgColorHex: thread.authorAvatarColor,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  thread.authorName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  _formatTime(thread.createdAt),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        thread.title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.4),
                      ),
                      if (thread.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: thread.tags
                              .map((tag) => TagChip(label: tag))
                              .toList(),
                        ),
                      ],
                      if (thread.attachmentUrl != null) ...[
                        const SizedBox(height: 12),
                        if (thread.attachmentType == 'image')
                          GestureDetector(
                            onTap: () => _openFullScreenImage(
                                context, thread.attachmentUrl!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                thread.attachmentUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    height: 160,
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)),
                                  );
                                },
                              ),
                            ),
                          )
                        else if (thread.attachmentType == 'doc')
                          _DocTile(
                            url: thread.attachmentUrl!,
                            name: thread.attachmentName ?? 'Dokumen',
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Balasan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<StudyHubReply>>(
                  stream: StudyHubService.repliesStream(
                      widget.hubId, widget.thread.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final replies = snapshot.data ?? [];
                    if (replies.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            'Belum ada balasan.\nJadilah yang pertama!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: replies.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) => _ReplyCard(reply: replies[i]),
                    );
                  },
                ),
              ],
            ),
          ),

          // Reply input bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_attachmentPath != null) ...[
                  _LocalAttachmentPreview(
                    path: _attachmentPath!,
                    name: _attachmentName ?? '',
                    type: _attachmentType ?? 'doc',
                    onRemove: _clearAttachment,
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    if (_attachmentPath == null) ...[
                      IconButton(
                        icon: const Icon(Icons.image_outlined, size: 22),
                        color: Colors.black45,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _pickImage,
                        tooltip: 'Lampirkan gambar',
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon:
                            const Icon(Icons.attach_file_rounded, size: 22),
                        color: Colors.black45,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _pickFile,
                        tooltip: 'Lampirkan file',
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: InputDecoration(
                          hintText: 'Tulis balasan...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitReply(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _isSubmitting
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send_rounded),
                            color: const Color(0xFF085041),
                            onPressed: _submitReply,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  final StudyHubReply reply;

  const _ReplyCard({required this.reply});

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} hr yang lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam yang lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mnt yang lalu';
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                initials: reply.authorInitials,
                bgColorHex: reply.authorAvatarColor,
                size: 32,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.authorName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _formatTime(reply.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reply.content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              reply.content,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87, height: 1.4),
            ),
          ],
          if (reply.attachmentUrl != null) ...[
            const SizedBox(height: 10),
            if (reply.attachmentType == 'image')
              GestureDetector(
                onTap: () =>
                    _openFullScreenImage(context, reply.attachmentUrl!),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      reply.attachmentUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 120,
                          color: Colors.grey.shade100,
                          child: const Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                        );
                      },
                    ),
                  ),
                ),
              )
            else if (reply.attachmentType == 'doc')
              _DocTile(
                url: reply.attachmentUrl!,
                name: reply.attachmentName ?? 'Dokumen',
              ),
          ],
        ],
      ),
    );
  }
}

class _DocTile extends StatefulWidget {
  final String url;
  final String name;

  const _DocTile({required this.url, required this.name});

  @override
  State<_DocTile> createState() => _DocTileState();
}

class _DocTileState extends State<_DocTile> {
  bool _isDownloading = false;

  Future<void> _download() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final dir = await getTemporaryDirectory();
      final safeName =
          widget.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(response.bodyBytes);
      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Tidak bisa membuka file: ${result.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh file: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _download,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.description_outlined,
                color: Colors.blue.shade700, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Ketuk untuk membuka',
                    style: TextStyle(
                        fontSize: 11, color: Colors.blue.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isDownloading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.blue.shade600),
              )
            else
              Icon(Icons.download_rounded,
                  color: Colors.blue.shade600, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LocalAttachmentPreview extends StatelessWidget {
  final String path;
  final String name;
  final String type;
  final VoidCallback onRemove;

  const _LocalAttachmentPreview({
    required this.path,
    required this.name,
    required this.type,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (type == 'image') {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(path),
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child:
                    const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined,
              color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                size: 16, color: Colors.blue.shade400),
          ),
        ],
      ),
    );
  }
}
