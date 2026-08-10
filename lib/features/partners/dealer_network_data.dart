class DealerNetworkData {
  const DealerNetworkData({
    required this.dealers,
    required this.pendingRequests,
  });

  final List<DealerSummary> dealers;
  final List<DealerFundingRequest> pendingRequests;
}

class DealerSummary {
  const DealerSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.currentBalance,
    required this.totalAllocated,
    required this.totalSpent,
    required this.totalSales,
    required this.totalClients,
    required this.totalOrders,
    required this.currency,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final double currentBalance;
  final double totalAllocated;
  final double totalSpent;
  final double totalSales;
  final int totalClients;
  final int totalOrders;
  final String currency;

  bool get isActive => status != 'suspended' && status != 'inactive';

  factory DealerSummary.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : const <String, dynamic>{};
    final firstName = (user['first_name'] ?? json['first_name'] ?? '').toString().trim();
    final lastName = (user['last_name'] ?? json['last_name'] ?? '').toString().trim();
    final fullName = [firstName, lastName].where((part) => part.isNotEmpty).join(' ');
    final explicitStatus = (json['status'] ?? '').toString().toLowerCase();
    final active = json['is_active'] != false;

    double money(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
    int count(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

    return DealerSummary(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      name: fullName.isNotEmpty
          ? fullName
          : (json['company_name'] ?? json['business_name'] ?? json['name'] ?? user['email'] ?? json['email'] ?? 'Dealer').toString(),
      email: (user['email'] ?? json['email'] ?? '').toString(),
      phone: '${user['country_code'] ?? json['country_code'] ?? ''}${user['phone_number'] ?? json['phone_number'] ?? ''}'.trim(),
      status: explicitStatus.isNotEmpty
          ? explicitStatus
          : (active ? 'active' : 'inactive'),
      currentBalance: money(json['current_balance'] ?? json['wallet_balance'] ?? json['available_balance']),
      totalAllocated: money(json['total_allocated']),
      totalSpent: money(json['total_spent']),
      totalSales: money(json['total_sales'] ?? json['revenue'] ?? json['total_revenue'] ?? json['sales']),
      totalClients: count(json['total_clients'] ?? json['clients_count'] ?? json['client_count']),
      totalOrders: count(json['total_orders'] ?? json['orders_count'] ?? json['order_count']),
      currency: (json['currency'] ?? 'USD').toString(),
    );
  }
}

class DealerFundingRequest {
  const DealerFundingRequest({
    required this.id,
    required this.dealerId,
    required this.dealerName,
    required this.dealerEmail,
    required this.amount,
    required this.currency,
    required this.note,
    required this.status,
  });

  final int id;
  final int dealerId;
  final String dealerName;
  final String dealerEmail;
  final double amount;
  final String currency;
  final String note;
  final String status;

  factory DealerFundingRequest.fromJson(Map<String, dynamic> json) {
    final dealer = json['dealer'] is Map
        ? Map<String, dynamic>.from(json['dealer'] as Map)
        : const <String, dynamic>{};
    return DealerFundingRequest(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      dealerId: int.tryParse((json['dealer_id'] ?? dealer['id'] ?? 0).toString()) ?? 0,
      dealerName: (json['dealer_name'] ?? dealer['name'] ?? 'Dealer').toString(),
      dealerEmail: (json['dealer_email'] ?? dealer['email'] ?? '').toString(),
      amount: double.tryParse((json['requested_amount'] ?? json['amount'] ?? 0).toString()) ?? 0,
      currency: (json['currency'] ?? 'USD').toString(),
      note: (json['dealer_notes'] ?? json['note'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
    );
  }
}

class DealerWalletTransfer {
  const DealerWalletTransfer({
    required this.dealerName,
    required this.amount,
    required this.type,
    required this.status,
    required this.reference,
    required this.note,
    required this.createdAt,
  });

  final String dealerName;
  final double amount;
  final String type;
  final String status;
  final String reference;
  final String note;
  final DateTime? createdAt;

  bool get isCredit => type == 'credit';

  factory DealerWalletTransfer.fromJson(Map<String, dynamic> json) {
    final rawType = (json['transaction_type'] ?? json['type'] ?? json['direction'] ?? '').toString().toLowerCase();
    final amount = double.tryParse((json['amount'] ?? json['transfer_amount'] ?? 0).toString()) ?? 0;
    final debit = amount < 0 || rawType.contains('debit') || rawType.contains('deduct') || rawType.contains('refund_to_reseller');
    return DealerWalletTransfer(
      dealerName: (json['dealer_name'] ?? json['user_name'] ?? json['email'] ?? 'Dealer').toString(),
      amount: amount.abs(),
      type: debit ? 'debit' : 'credit',
      status: (json['status'] ?? 'posted').toString(),
      reference: (json['reference'] ?? json['id'] ?? '').toString(),
      note: (json['note'] ?? json['notes'] ?? json['description'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? json['created'] ?? json['date'] ?? '').toString()),
    );
  }
}
