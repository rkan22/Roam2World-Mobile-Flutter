class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      message: '${json['message'] ?? json['body'] ?? ''}',
      isRead: json['is_read'] == true || json['read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse('${json['created_at']}')
          : null,
    );
  }
}
