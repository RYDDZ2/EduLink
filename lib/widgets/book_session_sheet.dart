import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/tutor_session_model.dart';
import '../widgets/common_widgets.dart';

class BookSessionSheet extends StatefulWidget {
  final TutorSession tutor;
  final Function(Booking) onBooked;

  const BookSessionSheet({
    super.key,
    required this.tutor,
    required this.onBooked,
  });

  @override
  State<BookSessionSheet> createState() => _BookSessionSheetState();
}

class _BookSessionSheetState extends State<BookSessionSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _durationMinutes = 60;
  final _notesCtrl = TextEditingController();

  int get _kpCost => widget.tutor.kp;

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
                  'Pesan Sesi Tutor',
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
            // Tutor info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  AvatarWidget(
                    initials: widget.tutor.tutorInitials,
                    bgColorHex: widget.tutor.tutorAvatarColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tutor.tutorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.tutor.subjects.join(', '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  KpBadge(label: '${widget.tutor.kp} KP'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _label('Pilih tanggal'),
            const SizedBox(height: 6),
            _DatePickerTile(
              selectedDate: _selectedDate,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (d != null) setState(() => _selectedDate = d);
              },
            ),
            const SizedBox(height: 14),
            _label('Waktu mulai'),
            const SizedBox(height: 6),
            _TimePicker(
              selectedTime: _selectedTime,
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 15, minute: 0),
                );
                if (t != null) setState(() => _selectedTime = t);
              },
            ),
            const SizedBox(height: 14),
            _label('Durasi'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [60, 90, 120].map((dur) {
                final selected = _durationMinutes == dur;
                return GestureDetector(
                  onTap: () => setState(() => _durationMinutes = dur),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? Colors.black87 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? Colors.black87 : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '$dur menit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _label('Catatan untuk tutor (opsional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: _inputDeco('Topik spesifik yang ingin dibahas...'),
            ),
            const SizedBox(height: 16),
            // Cost summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFAC775).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total biaya',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  KpBadge(label: '$_kpCost KP'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _OutlineBtn(
                      label: 'Batal', onTap: () => Navigator.pop(context)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PrimaryBtn(label: 'Konfirmasi Pesan', onTap: _submit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal dan waktu dulu')),
      );
      return;
    }
    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final booking = Booking(
      id: 'book-${DateTime.now().millisecondsSinceEpoch}',
      tutorName: widget.tutor.tutorName,
      subject: widget.tutor.subjects.first,
      scheduledAt: dt,
      durationMinutes: _durationMinutes,
      kpCost: _kpCost,
      status: BookingStatus.pending,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );
    widget.onBooked(booking);
    Navigator.pop(context);
  }

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
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

class _DatePickerTile extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const _DatePickerTile({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Colors.black45),
            const SizedBox(width: 8),
            Text(
              selectedDate == null
                  ? 'Pilih tanggal'
                  : '${selectedDate!.day} ${months[selectedDate!.month]} ${selectedDate!.year}',
              style: TextStyle(
                fontSize: 13,
                color: selectedDate == null ? Colors.black38 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final TimeOfDay? selectedTime;
  final VoidCallback onTap;

  const _TimePicker({required this.selectedTime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 16, color: Colors.black45),
            const SizedBox(width: 8),
            Text(
              selectedTime == null
                  ? 'Pilih waktu'
                  : selectedTime!.format(context),
              style: TextStyle(
                fontSize: 13,
                color: selectedTime == null ? Colors.black38 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }
}