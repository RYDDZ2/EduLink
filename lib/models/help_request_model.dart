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
  });
}
