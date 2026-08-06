class MobileNotificationItem {
  const MobileNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.relatedOrderId,
    this.relatedEsimId,
    this.metadata = const {},
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;
  final Object? relatedOrderId;
  final Object? relatedEsimId;
  final Map<String, dynamic> metadata;

  factory MobileNotificationItem.fromJson(Map<String, dynamic> json) {
    return MobileNotificationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
      relatedOrderId: json['related_order_id'],
      relatedEsimId: json['related_esim_id'],
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  MobileNotificationItem copyWith({bool? isRead, DateTime? readAt}) {
    return MobileNotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      relatedOrderId: relatedOrderId,
      relatedEsimId: relatedEsimId,
      metadata: metadata,
    );
  }
}

List<MobileNotificationItem> parseMobileNotifications(dynamic payload) {
  final root = payload is Map ? Map<String, dynamic>.from(payload) : const <String, dynamic>{};
  final data = root['data'];
  final raw = data is List
      ? data
      : data is Map && data['notifications'] is List
          ? data['notifications'] as List
          : root['notifications'] is List
              ? root['notifications'] as List
              : const [];
  return raw
      .whereType<Map>()
      .map((item) => MobileNotificationItem.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}
