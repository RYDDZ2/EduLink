enum BookingStatus { pending, confirmed, completed, cancelled }

class Booking {
  final String id;
  final String tutorName;
  final String subject;
  final DateTime scheduledAt;
  final int durationMinutes;
  final int kpCost;
  BookingStatus status;
  final String? notes;

  Booking({
    required this.id,
    required this.tutorName,
    required this.subject,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.kpCost,
    required this.status,
    this.notes,
  });
}
