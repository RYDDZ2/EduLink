import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';

class MyBookingsTab extends StatelessWidget {
  final List<Booking> bookings;
  final Function(Booking) onUpdate;
  final Function(String id) onCancel;

  const MyBookingsTab({
    super.key,
    required this.bookings,
    required this.onUpdate,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: Colors.black12),
            SizedBox(height: 12),
            Text(
              'Belum ada pemesanan',
              style: TextStyle(color: Colors.black38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _BookingCard(
        booking: bookings[i],
        onEdit: () => _showEditSheet(context, bookings[i]),
        onCancel: () => _confirmCancel(context, bookings[i].id),
      ),
    );
  }

  void _showEditSheet(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditBookingSheet(
        booking: booking,
        onSave: onUpdate,
      ),
    );
  }

  void _confirmCancel(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('Batalkan Pemesanan?', style: TextStyle(fontSize: 16)),
        content: const Text(
          'KP yang sudah dibayar akan dikembalikan ke akunmu.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onCancel(id);
            },
            child:
                const Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.booking,
    required this.onEdit,
    required this.onCancel,
  });

  String get _statusKey {
    switch (booking.status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  String _formatDate(DateTime dt) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
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
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  bool get _canModify =>
      booking.status == BookingStatus.pending ||
      booking.status == BookingStatus.confirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.subject,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tutor: ${booking.tutorName}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: _statusKey),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              InfoChip(
                icon: Icons.calendar_today_rounded,
                label: _formatDate(booking.scheduledAt),
              ),
              InfoChip(
                icon: Icons.access_time_rounded,
                label: _formatTime(booking.scheduledAt),
              ),
              InfoChip(
                icon: Icons.timer_rounded,
                label: '${booking.durationMinutes} menit',
              ),
            ],
          ),
          if (booking.notes != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded,
                    size: 13, color: Colors.black38),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.notes!,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          Row(
            children: [
              KpBadge(label: '${booking.kpCost} KP'),
              const Spacer(),
              if (_canModify) ...[
                EduButton(
                  label: 'Ubah',
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                EduButton(
                  label: 'Batalkan',
                  icon: Icons.close_rounded,
                  isDanger: true,
                  onTap: onCancel,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EditBookingSheet extends StatefulWidget {
  final Booking booking;
  final Function(Booking) onSave;

  const _EditBookingSheet({required this.booking, required this.onSave});

  @override
  State<_EditBookingSheet> createState() => _EditBookingSheetState();
}

class _EditBookingSheetState extends State<_EditBookingSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _durationMinutes;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.booking.scheduledAt;
    _selectedTime = TimeOfDay.fromDateTime(widget.booking.scheduledAt);
    _durationMinutes = widget.booking.durationMinutes;
    _notesCtrl = TextEditingController(text: widget.booking.notes ?? '');
  }

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
                  'Ubah Pemesanan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.booking.subject} · ${widget.booking.tutorName}',
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
            const SizedBox(height: 16),
            _label('Tanggal baru'),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (d != null) setState(() => _selectedDate = d);
              },
              borderRadius: BorderRadius.circular(10),
              child: _fieldBox(
                icon: Icons.calendar_today_rounded,
                label:
                    '${_selectedDate.day} ${months[_selectedDate.month]} ${_selectedDate.year}',
              ),
            ),
            const SizedBox(height: 14),
            _label('Waktu mulai baru'),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (t != null) setState(() => _selectedTime = t);
              },
              borderRadius: BorderRadius.circular(10),
              child: _fieldBox(
                icon: Icons.access_time_rounded,
                label: _selectedTime.format(context),
              ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 6),
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
            _label('Catatan'),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Topik yang ingin dibahas...',
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
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Simpan Perubahan',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      );

  Widget _fieldBox({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  void _save() {
    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final updated = Booking(
      id: widget.booking.id,
      tutorName: widget.booking.tutorName,
      subject: widget.booking.subject,
      scheduledAt: dt,
      durationMinutes: _durationMinutes,
      kpCost: widget.booking.kpCost,
      status: widget.booking.status,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }
}
