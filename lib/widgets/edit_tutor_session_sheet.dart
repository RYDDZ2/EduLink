import 'package:flutter/material.dart';

import '../models/tutor_session_model.dart';
import '../widgets/common_widgets.dart';

class EditTutorSessionSheet extends StatefulWidget {
  final TutorSession session;
  final Future<void> Function(TutorSession) onUpdated;

  const EditTutorSessionSheet({
    super.key,
    required this.session,
    required this.onUpdated,
  });

  @override
  State<EditTutorSessionSheet> createState() => _EditTutorSessionSheetState();
}

class _EditTutorSessionSheetState extends State<EditTutorSessionSheet> {
  late final TextEditingController _subjectsCtrl;
  late final TextEditingController _daysCtrl;
  late final TextEditingController _kpCtrl;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _subjectsCtrl =
        TextEditingController(text: widget.session.subjects.join(', '));
    _daysCtrl =
        TextEditingController(text: widget.session.daysAvailability.join(', '));
    _kpCtrl = TextEditingController(text: widget.session.kp.toString());
    final start = widget.session.timeAvailabilityMinutes.isNotEmpty
        ? widget.session.timeAvailabilityMinutes[0]
        : 15 * 60;
    final end = widget.session.timeAvailabilityMinutes.length > 1
        ? widget.session.timeAvailabilityMinutes[1]
        : 20 * 60;
    _startTime = TimeOfDay(hour: start ~/ 60, minute: start % 60);
    _endTime = TimeOfDay(hour: end ~/ 60, minute: end % 60);
  }

  @override
  void dispose() {
    _subjectsCtrl.dispose();
    _daysCtrl.dispose();
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
                    'Edit Sesi Tutor',
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
                          onTap: () => _pickTime(true))),
                  const SizedBox(width: 10),
                  const Text('–',
                      style: TextStyle(fontSize: 16, color: Colors.black45)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _TimePickerTile(
                          label: 'Selesai',
                          time: _endTime,
                          onTap: () => _pickTime(false))),
                ],
              ),
              const SizedBox(height: 14),
              _label('KP ditawarkan untuk student'),
              const SizedBox(height: 6),
              _field(_kpCtrl, '60', keyboardType: TextInputType.number),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                      child: EduButton(
                          label: 'Batal', onTap: () => Navigator.pop(context))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: EduButton(
                          label: 'Simpan',
                          isPrimary: true,
                          onTap: _isSaving ? () {} : _submit)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
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
    final days =
        _daysCtrl.text.trim().isEmpty ? <String>[] : [_daysCtrl.text.trim()];
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    setState(() => _isSaving = true);

    try {
      await widget.onUpdated(
        TutorSession(
          id: widget.session.id,
          tutorId: widget.session.tutorId,
          tutorName: widget.session.tutorName,
          tutorInitials: widget.session.tutorInitials,
          tutorAvatarColor: widget.session.tutorAvatarColor,
          subjects: subjects,
          rating: widget.session.rating,
          reviewCount: widget.session.reviewCount,
          kp: int.tryParse(_kpCtrl.text) ?? widget.session.kp,
          timeAvailabilityMinutes: [startMinutes, endMinutes],
          daysAvailability: days,
          isAvailableNow: widget.session.isAvailableNow,
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerTile(
      {required this.label, required this.time, required this.onTap});

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
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.black38)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text('$h.$m',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
