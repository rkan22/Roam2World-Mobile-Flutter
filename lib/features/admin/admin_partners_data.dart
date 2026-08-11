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
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final rawItems = data['items'];
    return AdminPartnerList(
      total: int.tryParse((data['total'] ?? 0).toString()) ?? 0,
      active: int.tryParse((data['active'] ?? 0).toString()) ?? 0,
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => AdminPartnerItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

class AdminPartnerItem {
  const AdminPartnerItem({
    required this.id,
    required this.companyName,
    required this.isActive,
    required this.createdAt,
    required this.markupPercentage,
  });

  final int id;
  final String companyName;
  final bool isActive;
  final DateTime? createdAt;
  final double markupPercentage;

  factory AdminPartnerItem.fromJson(Map<String, dynamic> json) {
    final rawActive = json['is_active'];
    return AdminPartnerItem(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      companyName: (json['company_name'] ?? '').toString(),
      isActive:
          rawActive == true || rawActive?.toString().toLowerCase() == 'true',
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      markupPercentage:
          double.tryParse((json['markup_percentage'] ?? 0).toString()) ?? 0,
    );
  }
}
