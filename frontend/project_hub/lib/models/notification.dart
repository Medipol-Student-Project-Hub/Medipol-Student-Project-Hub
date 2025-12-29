class Notification {
  final String id;
  final String notificationType;
  final String title;
  final String message;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.message,
    this.link,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'].toString(),
      notificationType: json['notification_type'] ?? 'general',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      link: json['link'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_type': notificationType,
      'title': title,
      'message': message,
      'link': link,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
