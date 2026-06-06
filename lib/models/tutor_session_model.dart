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
  final int kp;
  final List<int> timeAvailabilityMinutes; // [startMinutes, endMinutes]
  final List<String> daysAvailability; // days string(s)

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
    required this.kp,
    required this.timeAvailabilityMinutes,
    required this.daysAvailability,
    required this.isAvailableNow,
  });


  static int _parseFallbackTimeToMinutes(List<dynamic>? availability, {required int index}) {
    // Fallback for legacy format: availability[index] like "15.00-20.00" or "15.00–20.00".
    if (availability == null || availability.isEmpty) return 0;
    if (index < 0 || index >= availability.length) return 0;
    final raw = availability[index].toString();

    // If the value already looks like minutes
    final asInt = int.tryParse(raw);
    if (asInt != null) return asInt;

    // Try parse hh.mm or hh:mm
    final timeMatch = RegExp(r'(\d{1,2})[:\.](\d{2})').firstMatch(raw);
    if (timeMatch == null) return 0;
    final h = int.parse(timeMatch.group(1)!);
    final m = int.parse(timeMatch.group(2)!);
    return h * 60 + m;
  }

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
      // support both old 'kpPerHour' and new 'kp' field
      kp: (data['kp'] ?? data['kpPerHour']) as int? ?? 60,

      // New typed availability
      timeAvailabilityMinutes: [
        (data['startTimeMinutes'] as int?) ??
            _parseFallbackTimeToMinutes(data['availability'] as List<dynamic>?, index: 0),
        (data['endTimeMinutes'] as int?) ??
            _parseFallbackTimeToMinutes(data['availability'] as List<dynamic>?, index: 1),
      ],
      daysAvailability: (data['daysAvailability'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (data['days'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const <String>[],

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
      'kp': kp,
      'daysAvailability': daysAvailability,

      'startTimeMinutes': timeAvailabilityMinutes.isNotEmpty
          ? timeAvailabilityMinutes[0]
          : 0,
      'endTimeMinutes': timeAvailabilityMinutes.length > 1
          ? timeAvailabilityMinutes[1]
          : 0,
      'isAvailableNow': isAvailableNow,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
