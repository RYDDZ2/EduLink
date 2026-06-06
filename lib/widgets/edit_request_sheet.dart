import 'package:flutter/material.dart';

import '../models/help_request_model.dart';
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
  final List<String> _selectedTags = <String>[];
  bool _isSaving = false;

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
    super.dispose();
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
              _label('Tag topik'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _availableTags.map((tag) {
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
                        color: selected ? Colors.black87 : Colors.grey.shade100,
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
                          color: selected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
        ),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
