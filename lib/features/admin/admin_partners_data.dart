  final int totalClients;
  final int totalOrders;
  final DateTime? lastLogin;

  factory AdminDealerDetail.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    dynamic raw = root['data'];
    if (raw is Map && raw['dealer'] is Map) raw = raw['dealer'];
    if (raw is! Map) raw = root;
    final json = Map<String, dynamic>.from(raw);
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : const <String, dynamic>{};
    final first = (user['first_name'] ?? json['first_name'] ?? '').toString().trim();
    final last = (user['last_name'] ?? json['last_name'] ?? '').toString().trim();
    return AdminDealerDetail(
      id: _int(json['id']),
      email: (user['email'] ?? json['email'] ?? '').toString(),
      firstName: first,
      lastName: last,
      resellerName: (json['reseller_name'] ?? '').toString(),
      isActive: _bool(json['is_active']) && !_bool(json['is_suspended']),
      isSuspended: _bool(json['is_suspended']),
      suspensionReason: (json['suspension_reason'] ?? '').toString(),
      currentBalance: _double(json['current_balance'] ?? json['available_balance']),
      totalAllocated: _double(json['total_allocated']),
      totalSpent: _double(json['total_spent']),
      totalClients: _int(json['total_clients']),
      totalOrders: _int(json['total_orders']),
      lastLogin: DateTime.tryParse((user['last_login'] ?? '').toString()),
    );
  }
  static bool _bool(dynamic v) => v == true || v?.toString().toLowerCase() == 'true';
  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  static double _double(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
}
