import 'package:flutter/material.dart';

import '../models/tutor_session_model.dart';
import '../models/user_model.dart';
import 'common_widgets.dart';

class CreateTutorSessionSheet extends StatefulWidget {
  final AppUser currentUser;
  final Function(TutorSession) onCreated;

  const CreateTutorSessionSheet({
    super.key,
    required this.currentUser,
    required this.onCreated,
  });

  @override
  State<CreateTutorSessionSheet> createState() =>
      _CreateTutorSessionSheetState();
}

class _CreateTutorSessionSheetState extends State<CreateTutorSessionSheet> {
  final _subjectsCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: 'Senin-Jumat');
  final _timeCtrl = TextEditingController(text: '15.00-20.00');
  final _kpCtrl = TextEditingController(text: '60');
  bool _availableNow = true;

  @override
  void dispose() {
    _subjectsCtrl.dispose();
    _daysCtrl.dispose();
    _timeCtrl.dispose();
    _kpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                  'Daftar Sesi Tutor',
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  AvatarWidget(
                    initials: widget.currentUser.initials,
                    bgColorHex: '#E1F5EE',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.currentUser.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const StatusBadge(status: 'open'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _label('Mata pelajaran'),
            const SizedBox(height: 6),
            _field(_subjectsCtrl, 'cth: Kimia, Biologi'),
            const SizedBox(height: 14),
            _label('Hari tersedia'),
            const SizedBox(height: 6),
            _field(_daysCtrl, 'cth: Senin-Jumat'),
            const SizedBox(height: 14),
            _label('Jam tersedia'),
            const SizedBox(height: 6),
            _field(_timeCtrl, 'cth: 15.00-20.00'),
            const SizedBox(height: 14),
            _label('Knowledge Points per jam'),
            const SizedBox(height: 6),
            _field(_kpCtrl, '60', keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _availableNow,
              onChanged: (value) => setState(() => _availableNow = value),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tersedia sekarang',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              activeThumbColor: Colors.black87,
            ),
            const SizedBox(height: 18),
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
                    label: 'Daftarkan',
                    isPrimary: true,
                    onTap: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_subjectsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mata pelajaran tidak boleh kosong')),
      );
      return;
    }

    final subjects = _subjectsCtrl.text
        .split(',')
        .map((subject) => subject.trim())
        .where((subject) => subject.isNotEmpty)
        .toList();

    widget.onCreated(
      TutorSession(
        id: 'tutor-${DateTime.now().millisecondsSinceEpoch}',
        tutorId: widget.currentUser.id,
        tutorName: widget.currentUser.name,
        tutorInitials: widget.currentUser.initials,
        tutorAvatarColor: '#E1F5EE',
        subjects: subjects,
        rating: 5,
        reviewCount: 0,
        kpPerHour: int.tryParse(_kpCtrl.text) ?? 60,
        availability: [_daysCtrl.text, _timeCtrl.text],
        isAvailableNow: _availableNow,
      ),
    );
    Navigator.pop(context);
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      );

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
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
      ),
    );
  }
}
