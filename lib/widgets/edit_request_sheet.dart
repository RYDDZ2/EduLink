import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/help_request_model.dart';
import '../services/supabase_request_image_service.dart';
import '../widgets/common_widgets.dart';

class EditRequestSheet extends StatefulWidget {
  final HelpRequest request;
  final Future<void> Function(HelpRequest) onUpdated;

  const EditRequestSheet({
    super.key,
    required this.request,
    required this.onUpdated,
  });

  @override
  State<EditRequestSheet> createState() => _EditRequestSheetState();
}

class _EditRequestSheetState extends State<EditRequestSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _kpCtrl;
  final _customTagCtrl = TextEditingController();
  final List<String> _selectedTags = <String>[];
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  bool _removeExistingImage = false;

  final List<String> _availableTags = [
    'Matematika',
    'Fisika',
    'Kimia',
    'Biologi',
    'Bahasa Inggris',
    'Bahasa Indonesia',
    'Sejarah',
    'Python',
    'Algoritma',
    'Laporan',
    'Essay',
    'Kalkulus',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.request.title);
    _descCtrl = TextEditingController(text: widget.request.description);
    _timeCtrl = TextEditingController(text: widget.request.availableTime ?? '');
    _kpCtrl =
        TextEditingController(text: widget.request.knowledgePoints.toString());
    _selectedTags.addAll(widget.request.tags);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _timeCtrl.dispose();
    _kpCtrl.dispose();
    _customTagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _pickedImage = picked;
      _removeExistingImage = false;
    });
  }

  void _addCustomTag() {
    final tag = _customTagCtrl.text.trim();
    if (tag.isEmpty) return;
    if (!_selectedTags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
      setState(() => _selectedTags.add(tag));
    }
    _customTagCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Permintaan Bantuan',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _label('Judul permintaan'),
              const SizedBox(height: 6),
              _field(_titleCtrl, 'Judul bantuan'),
              const SizedBox(height: 14),
              _label('Deskripsi'),
              const SizedBox(height: 6),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: _inputDeco('Jelaskan kebutuhanmu...'),
              ),
              const SizedBox(height: 14),
              _label('Waktu yang tersedia'),
              const SizedBox(height: 6),
              _field(_timeCtrl, 'cth: Malam ini, 19.00–21.00'),
              const SizedBox(height: 14),
              _label('Lampiran gambar (opsional)'),
              const SizedBox(height: 8),
              _buildImagePicker(),
              const SizedBox(height: 14),
              _label('Tag topik'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._availableTags.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () => setState(() {
                        selected
                            ? _selectedTags.remove(tag)
                            : _selectedTags.add(tag);
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              selected ? Colors.black87 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: selected
                                  ? Colors.black87
                                  : Colors.grey.shade300),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                selected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }),
                  ..._selectedTags
                      .where((tag) => !_availableTags.contains(tag))
                      .map(_buildCustomTagChip),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customTagCtrl,
                      onSubmitted: (_) => _addCustomTag(),
                      decoration: _inputDeco('Tambah tag custom...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addCustomTag,
                    icon: const Icon(Icons.add_circle_rounded),
                    color: Colors.black87,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _label('KP ditawarkan untuk tutor'),
              const SizedBox(height: 6),
              _field(_kpCtrl, '40', keyboardType: TextInputType.number),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: EduButton(
                        label: 'Batal', onTap: () => Navigator.pop(context)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: EduButton(
                      label: 'Simpan',
                      isPrimary: true,
                      onTap: _isSaving ? () {} : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl = widget.request.imageUrl;
      if (_pickedImage != null) {
        imageUrl = await SupabaseRequestImageService.uploadRequestImage(
          userId: widget.request.userId,
          xfile: _pickedImage!,
        );
      } else if (_removeExistingImage) {
        imageUrl = null;
      }

      await widget.onUpdated(
        HelpRequest(
          id: widget.request.id,
          userId: widget.request.userId,
          userName: widget.request.userName,
          userInitials: widget.request.userInitials,
          userAvatarColor: widget.request.userAvatarColor,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          tags: _selectedTags,
          knowledgePoints:
              int.tryParse(_kpCtrl.text) ?? widget.request.knowledgePoints,
          status: widget.request.status,
          createdAt: widget.request.createdAt,
          availableTime:
              _timeCtrl.text.trim().isEmpty ? null : _timeCtrl.text.trim(),
          imageUrl: imageUrl,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah gambar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildImagePicker() {
    final existingUrl = widget.request.imageUrl;

    if (_pickedImage != null) {
      return _imagePreview(
        image: Image.file(
          File(_pickedImage!.path),
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
        ),
        onRemove: () => setState(() => _pickedImage = null),
      );
    }

    if (!_removeExistingImage &&
        existingUrl != null &&
        existingUrl.trim().isNotEmpty) {
      return _imagePreview(
        image: Image.network(
          existingUrl,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade100,
            height: 160,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined,
                color: Colors.black26),
          ),
        ),
        onRemove: () => setState(() => _removeExistingImage = true),
      );
    }

    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: Colors.grey.shade500, size: 28),
            const SizedBox(height: 6),
            Text(
              'Tambah gambar dari galeri',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview({required Widget image, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: image,
        ),
        Positioned(
          right: 6,
          top: 6,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: () => setState(() => _selectedTags.remove(tag)),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
      );

  Widget _field(TextEditingController controller, String hint,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDeco(hint),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black45),
        ),
      );
}
