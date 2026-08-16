class ProviderRetryQueueData {
  const ProviderRetryQueueData({
    required this.items,
    required this.total,
    required this.summary,
  });

  final List<ProviderRetryItem> items;
  final int total;
  final ProviderRetrySummary summary;

  factory ProviderRetryQueueData.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final rawItems = root['data'];
    return ProviderRetryQueueData(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => ProviderRetryItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
      total:
          int.tryParse((root['total'] ?? root['count'] ?? 0).toString()) ?? 0,
      summary: ProviderRetrySummary.fromJson(
        root['summary'] is Map
            ? Map<String, dynamic>.from(root['summary'] as Map)
            : const <String, dynamic>{},
      ),
    );
  }
}

class ProviderRetrySummary {
  const ProviderRetrySummary({
    required this.pending,
    required this.retrying,
    required this.failed,
    required this.resolved,
    required this.cancelled,
    required this.dueNow,
  });

  final int pending;
  final int retrying;
  final int failed;
  final int resolved;
  final int cancelled;
  final int dueNow;

  factory ProviderRetrySummary.fromJson(Map<String, dynamic> json) =>
      ProviderRetrySummary(
        pending: _int(json['pending']),
        retrying: _int(json['retrying']),
        failed: _int(json['failed']),
        resolved: _int(json['resolved']),
        cancelled: _int(json['cancelled']),
        dueNow: _int(json['due_now']),
      );
}

class ProviderRetryItem {
  const ProviderRetryItem({
    required this.id,
    required this.orderNumber,
    required this.provider,
    required this.category,
    required this.status,
    required this.reason,
    required this.attemptCount,
    required this.maxAttempts,
    required this.canRetry,
    required this.lastError,
    required this.nextRetryAt,
    required this.createdAt,
  });

  final int id;
  final String orderNumber;
  final String provider;
  final String category;
  final String status;
  final String reason;
  final int attemptCount;
  final int maxAttempts;
  final bool canRetry;
  final String lastError;
  final DateTime? nextRetryAt;
  final DateTime? createdAt;

  factory ProviderRetryItem.fromJson(Map<String, dynamic> json) =>
      ProviderRetryItem(
        id: _int(json['id']),
        orderNumber: (json['order_number'] ?? json['order_id'] ?? '')
            .toString(),
        provider: (json['provider'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        reason: (json['reason'] ?? '').toString(),
        attemptCount: _int(json['attempt_count']),
        maxAttempts: _int(json['max_attempts']),
        canRetry: json['can_retry'] == true,
        lastError: (json['last_error'] ?? '').toString(),
        nextRetryAt: _date(json['next_retry_at']),
        createdAt: _date(json['created_at']),
      );
}

int _int(dynamic value) => int.tryParse((value ?? 0).toString()) ?? 0;
DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());
