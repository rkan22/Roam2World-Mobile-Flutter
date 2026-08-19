class AdminPartnerList {
  const AdminPartnerList({required this.total, required this.active, required this.items});
  final int total;
  final int active;
  final List<AdminPartnerItem> items;

  factory AdminPartnerList.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final rawData = root['data'];
    final data = rawData is Map ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};
    final rawItems = data['items'] ?? data['results'] ?? root['results'] ?? rawData;
    final parsed = rawItems is List
        ? rawItems.whereType<Map>().map((item) => AdminPartnerItem.fromJson(Map<String, dynamic>.from(item))).toList(growable: false)
        : const <AdminPartnerItem>[];
    return AdminPartnerList(
      total: int.tryParse((data['total'] ?? root['count'] ?? parsed.length).toString()) ?? parsed.length,
      active: parsed.where((item) => item.isActive).length,
      items: parsed,
    );
  }
}

class AdminPartnerItem {
  const AdminPartnerItem({required this.id, required this.companyName, required this.email, required this.resellerName, required this.isActive, required this.walletBalance, required this.customerCount, required this.orderCount, required this.lastActivity, required this.createdAt, required this.isSuspended});
  final int id;
  final String companyName;
  final String email;
  final String resellerName;
  final bool isActive;
  final bool isSuspended;
  final double walletBalance;
  final int customerCount;
  final int orderCount;
  final DateTime? lastActivity;
  final DateTime? createdAt;

  factory AdminPartnerItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : const <String, dynamic>{};
    final firstName = (user['first_name'] ?? json['first_name'] ?? '').toString().trim();
    final lastName = (user['last_name'] ?? json['last_name'] ?? '').toString().trim();
    final fullName = [firstName, lastName].where((value) => value.isNotEmpty).join(' ').trim();
    final email = (user['email'] ?? json['email'] ?? '').toString().trim();
    final company = (json['company_name'] ?? '').toString().trim();
    final suspended = _bool(json['is_suspended']);
    final active = (json['is_active'] == null || _bool(json['is_active'])) && !_bool(user['is_active'], defaultValue: true) == false && !suspended;
    return AdminPartnerItem(
      id: _int(json['id']),
      companyName: company.isNotEmpty ? company : (fullName.isNotEmpty ? fullName : email),
      email: email,
      resellerName: (json['reseller_name'] ?? '').toString().trim(),
      isActive: active,
      isSuspended: suspended,
      walletBalance: _double(json['current_balance'] ?? json['current_credit'] ?? json['available_balance'] ?? json['available_credit']),
      customerCount: _int(json['total_clients']),
      orderCount: _int(json['total_orders']),
      lastActivity: DateTime.tryParse((user['last_login'] ?? json['last_login'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  static bool _bool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    return value == true || value.toString().toLowerCase() == 'true';
  }
  static int _int(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
  static double _double(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
}

class AdminResellerDetail {
  const AdminResellerDetail({required this.id, required this.email, required this.firstName, required this.lastName, required this.phoneCountryCode, required this.phoneNumber, required this.status, required this.creditLimit, required this.currentCredit, required this.maxClients, required this.maxSims, required this.lastLogin, required this.createdAt});
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneCountryCode;
  final String phoneNumber;
  final String status;
  final double creditLimit;
  final double currentCredit;
  final int maxClients;
  final int maxSims;
  final DateTime? lastLogin;
  final DateTime? createdAt;

  factory AdminResellerDetail.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final raw = root['data'] is Map ? Map<String, dynamic>.from(root['data'] as Map) : root;
    final user = raw['user'] is Map ? Map<String, dynamic>.from(raw['user'] as Map) : const <String, dynamic>{};
    return AdminResellerDetail(id: _int(raw['id']), email: _str(user['email'] ?? raw['email']), firstName: _str(user['first_name'] ?? raw['firstName'] ?? raw['first_name']), lastName: _str(user['last_name'] ?? raw['lastName'] ?? raw['last_name']), phoneCountryCode: _str(user['country_code'] ?? raw['phone_country_code'] ?? raw['country_code']), phoneNumber: _str(user['phone_number'] ?? raw['phone_number'] ?? raw['phone']), status: _str(raw['status'] ?? (_bool(raw['is_suspended']) ? 'Suspended' : 'Active')), creditLimit: _double(raw['creditLimit'] ?? raw['credit_limit']), currentCredit: _double(raw['currentCredit'] ?? raw['current_credit']), maxClients: _int(raw['maxClients'] ?? raw['max_clients']), maxSims: _int(raw['simLimit'] ?? raw['max_sims']), lastLogin: DateTime.tryParse(_str(user['last_login'] ?? raw['lastLogin'] ?? raw['last_login'])), createdAt: DateTime.tryParse(_str(raw['createdAt'] ?? raw['created_at'])));
  }
  static String _str(dynamic v) => v?.toString() ?? '';
  static int _int(dynamic v) => int.tryParse(_str(v)) ?? 0;
  static double _double(dynamic v) => double.tryParse(_str(v)) ?? 0;
  static bool _bool(dynamic v) => v == true || v?.toString().toLowerCase() == 'true';
}

class AdminDealerDetail {
  const AdminDealerDetail({required this.id, required this.email, required this.firstName, required this.lastName, required this.resellerName, required this.isActive, required this.isSuspended, required this.suspensionReason, required this.currentBalance, required this.totalAllocated, required this.totalSpent, required this.totalClients, required this.totalOrders, required this.lastLogin});
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String resellerName;
  final bool isActive;
  final bool isSuspended;
  final String suspensionReason;
  final double currentBalance;
  final double totalAllocated;
  final double totalSpent;
  final int totalClients;
  final int totalOrders;
  final DateTime? lastLogin;

  factory AdminDealerDetail.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    dynamic raw = root['data'];
    if (raw is Map && raw['dealer'] is Map) raw = raw['dealer'];
    if (raw is! Map) raw = root;
    final json = Map<String, dynamic>.from(raw as Map);
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
