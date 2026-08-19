class AdminPartnerList {
  const AdminPartnerList({
    required this.total,
    required this.active,
    required this.items,
  });

  final int total;
  final int active;
  final List<AdminPartnerItem> items;

  factory AdminPartnerList.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final rawData = root['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    final rawItems = data['items'] ?? data['results'] ?? root['results'] ?? rawData;
    final parsed = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => AdminPartnerItem.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
        : const <AdminPartnerItem>[];

    return AdminPartnerList(
      total: int.tryParse((data['total'] ?? root['count'] ?? parsed.length).toString()) ?? parsed.length,
      active: parsed.where((item) => item.isActive).length,
      items: parsed,
    );
  }
}

class AdminPartnerItem {
  const AdminPartnerItem({
    required this.id,
    required this.companyName,
    required this.email,
    required this.isActive,
    required this.walletBalance,
    required this.customerCount,
    required this.orderCount,
    required this.lastActivity,
    required this.createdAt,
  });

  final int id;
  final String companyName;
  final String email;
  final bool isActive;
  final double walletBalance;
  final int customerCount;
  final int orderCount;
  final DateTime? lastActivity;
  final DateTime? createdAt;

  factory AdminPartnerItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : const <String, dynamic>{};
    final firstName = (user['first_name'] ?? '').toString().trim();
    final lastName = (user['last_name'] ?? '').toString().trim();
    final fullName = [firstName, lastName].where((value) => value.isNotEmpty).join(' ').trim();
    final email = (user['email'] ?? json['email'] ?? '').toString().trim();
    final company = (json['company_name'] ?? '').toString().trim();
    final suspended = json['is_suspended'] == true || json['is_suspended']?.toString().toLowerCase() == 'true';
    final userActive = user['is_active'] ?? json['is_active'];
    final active = userActive == null || userActive == true || userActive.toString().toLowerCase() == 'true';

    return AdminPartnerItem(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      companyName: company.isNotEmpty ? company : (fullName.isNotEmpty ? fullName : email),
      email: email,
      isActive: active && !suspended,
      walletBalance: _number(json['current_credit'] ?? json['available_credit']),
      customerCount: int.tryParse((json['total_clients'] ?? 0).toString()) ?? 0,
      orderCount: int.tryParse((json['total_orders'] ?? 0).toString()) ?? 0,
      lastActivity: DateTime.tryParse((user['last_login'] ?? json['last_login'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  static double _number(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
}
