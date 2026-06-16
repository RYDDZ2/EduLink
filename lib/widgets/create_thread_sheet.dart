import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/study_hub_model.dart';
import '../models/user_model.dart';
import '../services/study_hub_service.dart';
import '../services/supabase_study_hub_service.dart';

class CreateThreadSheet extends StatefulWidget {
  final StudyHub hub;
  final AppUser currentUser;

  const CreateThreadSheet({
    super.key,
    required this.hub,
    required this.currentUser,
  });

  @override
  State<CreateThreadSheet> createState() => _CreateThreadSheetState();
}

class _CreateThreadSheetState extends State<CreateThreadSheet> {
  final _titleController = TextEditingController();
  final _selectedTags = <String>{};
  bool _isLoading = false;

  String? _attachmentPath;
  String? _attachmentName;
  String? _attachmentType;
  String? _attachmentMime;
  String? _attachmentExt;

  @override
  void dispose() {
    _titleController.dispose();
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

  Future<void> _createThread() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Topik diskusi tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? uploadedUrl;
      if (_attachmentPath != null) {
        uploadedUrl = await SupabaseStudyHubService.uploadAttachment(
          hubId: widget.hub.id,
          userId: widget.currentUser.id,
          kind: _attachmentType!,
          filePath: _attachmentPath!,
          fileExt: _attachmentExt ?? '',
          mime: _attachmentMime,
        );
      }

      await StudyHubService.createThread(
        hubId: widget.hub.id,
        title: _titleController.text.trim(),
        authorId: widget.currentUser.id,
        authorName: widget.currentUser.name,
        authorInitials: widget.currentUser.initials,
        authorAvatarColor: '#E1F5EE',
        tags: _selectedTags.toList(),
        attachmentUrl: uploadedUrl,
        attachmentType: _attachmentType,
        attachmentName: _attachmentName,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diskusi berhasil dimulai')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Buat Diskusi Baru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Topik / Pertanyaan *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Apa yang ingin Anda diskusikan?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tag Diskusi (Opsional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.hub.tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lampiran (Opsional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_attachmentPath != null) ...[
              _LocalAttachmentPreview(
                path: _attachmentPath!,
                name: _attachmentName ?? '',
                type: _attachmentType ?? 'doc',
                onRemove: _clearAttachment,
              ),
              const SizedBox(height: 8),
            ] else
              Row(
                children: [
                  _AttachButton(
                    icon: Icons.image_outlined,
                    label: 'Gambar',
                    onTap: _pickImage,
                  ),
                  const SizedBox(width: 10),
                  _AttachButton(
                    icon: Icons.description_outlined,
                    label: 'File',
                    onTap: _pickFile,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createThread,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF085041),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Mulai Diskusi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
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
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(path),
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined,
              color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child:
                Icon(Icons.close_rounded, size: 18, color: Colors.blue.shade400),
          ),
        ],
      ),
    );
  }
}
