import 'package:flutter/material.dart';

import '../models/tutor_session_model.dart';
import '../models/user_model.dart';
import 'common_widgets.dart';

class CreateTutorSessionSheet extends StatefulWidget {
  final AppUser currentUser;
  final Future<void> Function(TutorSession) onCreated;

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
  final _kpCtrl = TextEditingController(text: '60');

  TimeOfDay _startTime = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);

  bool _isSaving = false;

  @override
  void dispose() {
    _subjectsCtrl.dispose();
    _daysCtrl.dispose();
    _kpCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'Jam mulai' : 'Jam selesai',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
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
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
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
                      imageUrl: widget.currentUser.profileImageUrl,
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
              Row(
                children: [
                  Expanded(
                    child: _TimePickerTile(
                      label: 'Mulai',
                      time: _startTime,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '–',
                    style: TextStyle(fontSize: 16, color: Colors.black45),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimePickerTile(
                      label: 'Selesai',
                      time: _endTime,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _label('KP ditawarkan untuk student'),
              const SizedBox(height: 6),
              _field(_kpCtrl, '60', keyboardType: TextInputType.number),
              const SizedBox(height: 6),
              Text(
                'Student akan mendapat KP ini, kamu juga mendapat KP saat sesi dimulai.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
    if (_subjectsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mata pelajaran tidak boleh kosong')),
      );
      return;
    }

    final subjects = _subjectsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() => _isSaving = true);

    // store jam as minutes since midnight (typed, not string)
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    final daysAvailability = _daysCtrl.text.trim().isEmpty
        ? const <String>[]
        : [_daysCtrl.text.trim()];

    final session = TutorSession(
      id: 'new',
      tutorId: widget.currentUser.id,
      tutorName: widget.currentUser.name,
      tutorInitials: widget.currentUser.initials,
      tutorAvatarColor: '#E1F5EE',
      subjects: subjects,
      rating: 5,
      reviewCount: 0,
      kp: int.tryParse(_kpCtrl.text) ?? 60,
      timeAvailabilityMinutes: [startMinutes, endMinutes],
      daysAvailability: daysAvailability,
      isAvailableNow: false,
      tutorJabatan: widget.currentUser.jabatanLabel,
    );

    try {
      await widget.onCreated(session);
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

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black38),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  '$h.$m',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
