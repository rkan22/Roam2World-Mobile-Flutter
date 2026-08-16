class NotificationRule {
  const NotificationRule({
    required this.id,
    required this.name,
    required this.description,
    required this.threshold,
    required this.unit,
    required this.enabled,
    required this.channels,
    required this.severity,
  });

  final String id;
  final String name;
  final String description;
  final double threshold;
  final String unit;
  final bool enabled;
  final List<String> channels;
  final String severity;

  NotificationRule copyWith({
    double? threshold,
    bool? enabled,
    List<String>? channels,
    String? severity,
  }) => NotificationRule(
    id: id,
    name: name,
    description: description,
    threshold: threshold ?? this.threshold,
    unit: unit,
    enabled: enabled ?? this.enabled,
    channels: channels ?? this.channels,
    severity: severity ?? this.severity,
  );

  factory NotificationRule.fromJson(Map<String, dynamic> json) {
    return NotificationRule(
      id: (json['id'] ?? json['key'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? 'Notification rule').toString(),
      description: (json['description'] ?? json['detail'] ?? '').toString(),
      threshold: double.tryParse((json['threshold'] ?? 0).toString()) ?? 0,
      unit: (json['unit'] ?? '').toString(),
      enabled: json['enabled'] != false,
      channels: json['channels'] is List
          ? (json['channels'] as List).map((item) => item.toString()).toList()
          : const ['in_app'],
      severity: (json['severity'] ?? 'normal').toString().toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'threshold': threshold,
    'unit': unit,
    'enabled': enabled,
    'channels': channels,
    'severity': severity,
  };
}
