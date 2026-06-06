import 'package:cloud_firestore/cloud_firestore.dart';

class HelpOffer {
  final String id;
  final String requestId;
  final String requestTitle;
  final String studentId;
  final String studentName;
  final String tutorId;
  final String tutorName;
  final String tutorInitials;
  final String tutorAvatarColor;
  final String message;
  final String status;
  final DateTime createdAt;
  final int kpOffered;

  const HelpOffer({
    required this.id,
    required this.requestId,
    required this.requestTitle,
    required this.studentId,
    required this.studentName,
    required this.tutorId,
    required this.tutorName,
    required this.tutorInitials,
    required this.tutorAvatarColor,
    required this.message,
    required this.status,
    required this.createdAt,
    this.kpOffered = 40,
  });

  bool get isPending => status == 'pending';

  factory HelpOffer.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return HelpOffer(
      id: id,
      requestId: data['requestId'] as String? ?? '',
      requestTitle: data['requestTitle'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? 'Student',
      tutorId: data['tutorId'] as String? ?? '',
      tutorName: data['tutorName'] as String? ?? 'Tutor',
      tutorInitials: data['tutorInitials'] as String? ?? 'TR',
      tutorAvatarColor: data['tutorAvatarColor'] as String? ?? '#E1F5EE',
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      kpOffered: data['kpOffered'] as int? ?? 40,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'requestTitle': requestTitle,
      'studentId': studentId,
      'studentName': studentName,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'tutorInitials': tutorInitials,
      'tutorAvatarColor': tutorAvatarColor,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class SessionBookingRequest {
  final String id;
  final String tutorSessionId;
  final String tutorId;
  final String tutorName;
  final String studentId;
  final String studentName;
  final String studentInitials;
  final String subject;
  final DateTime scheduledAt;
  final int durationMinutes;
  final int kpCost;
  final int tutorKp;
  final String notes;
  final String status;
  final DateTime createdAt;

  const SessionBookingRequest({
    required this.id,
    required this.tutorSessionId,
    required this.tutorId,
    required this.tutorName,
    required this.studentId,
    required this.studentName,
    required this.studentInitials,
    required this.subject,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.kpCost,
    required this.tutorKp,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  factory SessionBookingRequest.fromMap(String id, Map<String, dynamic> data) {
    final scheduled = data['scheduledAt'];
    final created = data['createdAt'];
    return SessionBookingRequest(
      id: id,
      tutorSessionId: data['tutorSessionId'] as String? ?? '',
      tutorId: data['tutorId'] as String? ?? '',
      tutorName: data['tutorName'] as String? ?? 'Tutor',
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? 'Student',
      studentInitials: data['studentInitials'] as String? ?? 'ST',
      subject: data['subject'] as String? ?? '',
      scheduledAt: scheduled is Timestamp ? scheduled.toDate() : DateTime.now(),
      durationMinutes: data['durationMinutes'] as int? ?? 60,
      kpCost: data['kpCost'] as int? ?? 0,
      tutorKp: data['tutorKp'] as int? ?? data['kpCost'] as int? ?? 0,
      notes: data['notes'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tutorSessionId': tutorSessionId,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'studentId': studentId,
      'studentName': studentName,
      'studentInitials': studentInitials,
      'subject': subject,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'durationMinutes': durationMinutes,
      'kpCost': kpCost,
      'tutorKp': tutorKp,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class TutoringSession {
  final String id;
  final String studentId;
  final String studentName;
  final String studentInitials;
  final String tutorId;
  final String tutorName;
  final String tutorInitials;
  final String title;
  final String subject;
  final String sourceType;
  final String sourceId;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;

  const TutoringSession({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentInitials,
    required this.tutorId,
    required this.tutorName,
    required this.tutorInitials,
    required this.title,
    required this.subject,
    required this.sourceType,
    required this.sourceId,
    required this.status,
    required this.startedAt,
    this.endedAt,
  });

  bool get isActive => status == 'active';

  String otherName(String currentUserId) {
    return currentUserId == studentId ? tutorName : studentName;
  }

  String otherInitials(String currentUserId) {
    return currentUserId == studentId ? tutorInitials : studentInitials;
  }

  factory TutoringSession.fromMap(String id, Map<String, dynamic> data) {
    final started = data['startedAt'];
    final ended = data['endedAt'];
    return TutoringSession(
      id: id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? 'Student',
      studentInitials: data['studentInitials'] as String? ?? 'ST',
      tutorId: data['tutorId'] as String? ?? '',
      tutorName: data['tutorName'] as String? ?? 'Tutor',
      tutorInitials: data['tutorInitials'] as String? ?? 'TR',
      title: data['title'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      sourceType: data['sourceType'] as String? ?? '',
      sourceId: data['sourceId'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      startedAt: started is Timestamp ? started.toDate() : DateTime.now(),
      endedAt: ended is Timestamp ? ended.toDate() : null,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return ChatMessage(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }
}
