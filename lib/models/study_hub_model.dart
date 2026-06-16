import 'package:cloud_firestore/cloud_firestore.dart';

enum StudyHubStatus { active, archived }

class StudyHub {
  final String id;
  final String creatorId;
  final String creatorName;
  final String creatorInitials;
  final String creatorAvatarColor;
  final String title;
  final String description;
  final List<String> tags;
  final int members;
  final int activeThreads;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StudyHubStatus status;

  StudyHub({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.creatorInitials,
    required this.creatorAvatarColor,
    required this.title,
    required this.description,
    required this.tags,
    required this.members,
    required this.activeThreads,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  static StudyHubStatus statusFromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'archived':
        return StudyHubStatus.archived;
      default:
        return StudyHubStatus.active;
    }
  }

  String get statusKey {
    switch (status) {
      case StudyHubStatus.active:
        return 'active';
      case StudyHubStatus.archived:
        return 'archived';
    }
  }

  factory StudyHub.fromMap(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];

    return StudyHub(
      id: id,
      creatorId: data['creatorId'] as String? ?? '',
      creatorName: data['creatorName'] as String? ?? 'Creator',
      creatorInitials: data['creatorInitials'] as String? ?? 'CR',
      creatorAvatarColor: data['creatorAvatarColor'] as String? ?? '#E1F5EE',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      members: data['members'] as int? ?? 0,
      activeThreads: data['activeThreads'] as int? ?? 0,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now(),
      status: statusFromString(data['status'] as String? ?? 'active'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorInitials': creatorInitials,
      'creatorAvatarColor': creatorAvatarColor,
      'title': title,
      'description': description,
      'tags': tags,
      'members': members,
      'activeThreads': activeThreads,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': statusKey,
    };
  }

  StudyHub copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? creatorInitials,
    String? creatorAvatarColor,
    String? title,
    String? description,
    List<String>? tags,
    int? members,
    int? activeThreads,
    DateTime? createdAt,
    DateTime? updatedAt,
    StudyHubStatus? status,
  }) {
    return StudyHub(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorInitials: creatorInitials ?? this.creatorInitials,
      creatorAvatarColor: creatorAvatarColor ?? this.creatorAvatarColor,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      members: members ?? this.members,
      activeThreads: activeThreads ?? this.activeThreads,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}

class StudyHubThread {
  final String id;
  final String hubId;
  final String title;
  final String authorId;
  final String authorName;
  final String authorInitials;
  final String authorAvatarColor;
  final List<String> tags;
  final int replies;
  final DateTime createdAt;

  StudyHubThread({
    required this.id,
    required this.hubId,
    required this.title,
    required this.authorId,
    required this.authorName,
    required this.authorInitials,
    required this.authorAvatarColor,
    required this.tags,
    required this.replies,
    required this.createdAt,
  });

  factory StudyHubThread.fromMap(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return StudyHubThread(
      id: id,
      hubId: data['hubId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Author',
      authorInitials: data['authorInitials'] as String? ?? 'AU',
      authorAvatarColor: data['authorAvatarColor'] as String? ?? '#E1F5EE',
      tags: (data['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      replies: data['replies'] as int? ?? 0,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hubId': hubId,
      'title': title,
      'authorId': authorId,
      'authorName': authorName,
      'authorInitials': authorInitials,
      'authorAvatarColor': authorAvatarColor,
      'tags': tags,
      'replies': replies,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class StudyHubReply {
  final String id;
  final String threadId;
  final String content;
  final String authorId;
  final String authorName;
  final String authorInitials;
  final String authorAvatarColor;
  final DateTime createdAt;

  StudyHubReply({
    required this.id,
    required this.threadId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorInitials,
    required this.authorAvatarColor,
    required this.createdAt,
  });

  factory StudyHubReply.fromMap(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return StudyHubReply(
      id: id,
      threadId: data['threadId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Author',
      authorInitials: data['authorInitials'] as String? ?? 'AU',
      authorAvatarColor: data['authorAvatarColor'] as String? ?? '#E1F5EE',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'threadId': threadId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorInitials': authorInitials,
      'authorAvatarColor': authorAvatarColor,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
