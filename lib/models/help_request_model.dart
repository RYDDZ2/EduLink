import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { open, pending, confirmed }

class HelpRequest {
  final String id;
  final String userId;
  final String userName;
  final String userInitials;
  final String userAvatarColor;
  final String title;
  final String description;
  final List<String> tags;
  final int knowledgePoints;
  final RequestStatus status;
  final DateTime createdAt;
  final String? availableTime;
  final String? imageUrl;

  HelpRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userInitials,
    required this.userAvatarColor,
    required this.title,
    required this.description,
    required this.tags,
    required this.knowledgePoints,
    required this.status,
    required this.createdAt,
    this.availableTime,
    this.imageUrl,
  });

  static RequestStatus statusFromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return RequestStatus.pending;
      case 'confirmed':
        return RequestStatus.confirmed;
      default:
        return RequestStatus.open;
    }
  }

  String get statusKey {
    switch (status) {
      case RequestStatus.open:
        return 'open';
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.confirmed:
        return 'confirmed';
    }
  }

  factory HelpRequest.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return HelpRequest(
      id: id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Student',
      userInitials: data['userInitials'] as String? ?? 'ST',
      userAvatarColor: data['userAvatarColor'] as String? ?? '#EEEDFE',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      knowledgePoints: data['knowledgePoints'] as int? ?? 40,
      status: statusFromString(data['status'] as String? ?? 'open'),
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      availableTime: data['availableTime'] as String?,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userInitials': userInitials,
      'userAvatarColor': userAvatarColor,
      'title': title,
      'description': description,
      'tags': tags,
      'knowledgePoints': knowledgePoints,
      'status': statusKey,
      'createdAt': Timestamp.fromDate(createdAt),
      'availableTime': availableTime,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
