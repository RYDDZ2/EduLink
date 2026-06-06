import 'package:flutter/material.dart';
import '../models/help_request_model.dart';
import '../models/user_model.dart';
import '../widgets/common_widgets.dart';

class CreateRequestSheet extends StatefulWidget {
  final AppUser currentUser;
  final Future<void> Function(HelpRequest) onCreated;

  const CreateRequestSheet({
    super.key,
    required this.currentUser,
    required this.onCreated,
  });

  @override
  State<CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends State<CreateRequestSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _kpCtrl = TextEditingController(text: '40');
  final List<String> _selectedTags = [];
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
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _timeCtrl.dispose();
    _kpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final safeBottom = mediaQuery.viewPadding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: (keyboardInset > 0 ? keyboardInset : safeBottom) + 24,
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
                  'Buat Permintaan Bantuan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Judul permintaan'),
            const SizedBox(height: 6),
            _field(_titleCtrl, 'cth: Butuh bantuan laporan kimia – titrasi'),
            const SizedBox(height: 14),
            _label('Deskripsi kebutuhan'),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: _inputDeco(
                  'Jelaskan apa yang kamu butuhkan secara detail...'),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected ? Colors.black87 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: selected ? Colors.black87 : Colors.grey.shade300,
                      ),
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
            const SizedBox(height: 6),
            Text(
              'Tutor akan mendapat KP ini, kamu juga mendapat KP saat sesi dimulai.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: EduButton(
                    label: 'Batal',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: EduButton(
                    label: 'Buat Permintaan',
                    isPrimary: true,
                    onTap: _isSaving ? () {} : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final newRequest = HelpRequest(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.currentUser.id,
      userName: widget.currentUser.name,
      userInitials: widget.currentUser.initials,
      userAvatarColor: '#EEEDFE',
      title: _titleCtrl.text,
      description: _descCtrl.text,
      tags: _selectedTags,
      knowledgePoints: int.tryParse(_kpCtrl.text) ?? 40,
      status: RequestStatus.open,
      createdAt: DateTime.now(),
      availableTime: _timeCtrl.text,
    );
    try {
      await widget.onCreated(newRequest);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      );

  Widget _field(TextEditingController ctrl, String hint,
          {TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: _inputDeco(hint),
      );

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