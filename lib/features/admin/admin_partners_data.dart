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
    final parsed = rawItems is List ? rawItems.whereType<Map>().map((item) => AdminPartnerItem.fromJson(Map<String, dynamic>.from(item))).toList(growable: false) : const <AdminPartnerItem>[];
    return AdminPartnerList(total: int.tryParse((data['total'] ?? root['count'] ?? parsed.length).toString()) ?? parsed.length, active: parsed.where((item) => item.isActive).length, items: parsed);
  }
}

class AdminPartnerItem {
  const AdminPartnerItem({required this.id, required this.companyName, required this.email, required this.isActive, required this.walletBalance, required this.customerCount, required this.orderCount, required this.lastActivity, required this.createdAt});
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
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : const <String, dynamic>{};
    final firstName = (user['first_name'] ?? '').toString().trim();
    final lastName = (user['last_name'] ?? '').toString().trim();
    final fullName = [firstName, lastName].where((value) => value.isNotEmpty).join(' ').trim();
    final email = (user['email'] ?? json['email'] ?? '').toString().trim();
    final company = (json['company_name'] ?? '').toString().trim();
    final suspended = json['is_suspended'] == true || json['is_suspended']?.toString().toLowerCase() == 'true';
    final userActive = user['is_active'] ?? json['is_active'];
    final active = userActive == null || userActive == true || userActive.toString().toLowerCase() == 'true';
    return AdminPartnerItem(id: int.tryParse((json['id'] ?? 0).toString()) ?? 0, companyName: company.isNotEmpty ? company : (fullName.isNotEmpty ? fullName : email), email: email, isActive: active && !suspended, walletBalance: _number(json['current_credit'] ?? json['available_credit']), customerCount: int.tryParse((json['total_clients'] ?? 0).toString()) ?? 0, orderCount: int.tryParse((json['total_orders'] ?? 0).toString()) ?? 0, lastActivity: DateTime.tryParse((user['last_login'] ?? json['last_login'] ?? '').toString()), createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()));
  }
  static double _number(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
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
    return AdminResellerDetail(id: _int(raw['id']), email: _str(raw['email']), firstName: _str(raw['firstName'] ?? raw['first_name']), lastName: _str(raw['lastName'] ?? raw['last_name']), phoneCountryCode: _str(raw['phone_country_code'] ?? raw['country_code']), phoneNumber: _str(raw['phone_number'] ?? raw['phone']), status: _str(raw['status']), creditLimit: _double(raw['creditLimit'] ?? raw['credit_limit']), currentCredit: _double(raw['currentCredit'] ?? raw['current_credit']), maxClients: _int(raw['maxClients'] ?? raw['max_clients']), maxSims: _int(raw['simLimit'] ?? raw['max_sims']), lastLogin: DateTime.tryParse(_str(raw['lastLogin'] ?? raw['last_login'])), createdAt: DateTime.tryParse(_str(raw['createdAt'] ?? raw['created_at'])));
  }
  static String _str(dynamic v) => v?.toString() ?? '';
  static int _int(dynamic v) => int.tryParse(_str(v)) ?? 0;
  static double _double(dynamic v) => double.tryParse(_str(v)) ?? 0;
}
