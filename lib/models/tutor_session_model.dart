import 'package:cloud_firestore/cloud_firestore.dart';

class TutorSession {
  final String id;
  final String tutorId;
  final String tutorName;
  final String tutorInitials;
  final String tutorAvatarColor;
  final List<String> subjects;
  final double rating;
  final int reviewCount;
  final int kpPerHour;
  final List<String> availability;
  final bool isAvailableNow;

  TutorSession({
    required this.id,
    required this.tutorId,
    required this.tutorName,
    required this.tutorInitials,
    required this.tutorAvatarColor,
    required this.subjects,
    required this.rating,
    required this.reviewCount,
    required this.kpPerHour,
    required this.availability,
    required this.isAvailableNow,
  });

  factory TutorSession.fromMap(String id, Map<String, dynamic> data) {
    return TutorSession(
      id: id,
      tutorId: data['tutorId'] as String? ?? '',
      tutorName: data['tutorName'] as String? ?? 'Tutor',
      tutorInitials: data['tutorInitials'] as String? ?? 'TR',
      tutorAvatarColor: data['tutorAvatarColor'] as String? ?? '#E1F5EE',
      subjects: (data['subjects'] as List<dynamic>? ?? const [])
          .map((subject) => subject.toString())
          .toList(),
      rating: (data['rating'] as num?)?.toDouble() ?? 5,
      reviewCount: data['reviewCount'] as int? ?? 0,
      kpPerHour: data['kpPerHour'] as int? ?? 60,
      availability: (data['availability'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      isAvailableNow: data['isAvailableNow'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tutorId': tutorId,
      'tutorName': tutorName,
      'tutorInitials': tutorInitials,
      'tutorAvatarColor': tutorAvatarColor,
      'subjects': subjects,
      'rating': rating,
      'reviewCount': reviewCount,
      'kpPerHour': kpPerHour,
      'availability': availability,
      'isAvailableNow': isAvailableNow,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
