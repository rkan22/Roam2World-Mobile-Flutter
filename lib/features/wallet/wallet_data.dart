class WalletData {
  const WalletData({
    required this.role,
    required this.currency,
    required this.availableAmount,
    required this.currentAmount,
    required this.secondaryAmount,
    required this.secondaryLabel,
    required this.transactions,
  });

  final String role;
  final String currency;
  final double availableAmount;
  final double currentAmount;
  final double secondaryAmount;
  final String secondaryLabel;
  final List<WalletTransaction> transactions;

  bool get isDealer => role.toLowerCase() == 'dealer';

  WalletData copyWith({List<WalletTransaction>? transactions}) => WalletData(
        role: role,
        currency: currency,
        availableAmount: availableAmount,
        currentAmount: currentAmount,
        secondaryAmount: secondaryAmount,
        secondaryLabel: secondaryLabel,
        transactions: transactions ?? this.transactions,
      );

  double get totalCredits => transactions
      .where((item) => item.normalizedType == 'credit')
      .fold(0, (sum, item) => sum + item.absoluteAmount);

  double get totalDebits => transactions
      .where((item) => item.normalizedType == 'debit')
      .fold(0, (sum, item) => sum + item.absoluteAmount);

  double get totalRefunds => transactions
      .where((item) => item.normalizedType == 'refund')
      .fold(0, (sum, item) => sum + item.absoluteAmount);

  int get failedCount => transactions
      .where((item) => item.status.toLowerCase() == 'failed')
      .length;

  double get netMovement => totalCredits + totalRefunds - totalDebits;

  factory WalletData.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final role = data['role']?.toString() ?? '';
    final isDealer = role.toLowerCase() == 'dealer';
    double money(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
    final rawTransactions = data['recent_transactions'] is List
        ? data['recent_transactions'] as List
        : const [];

    return WalletData(
      role: role,
      currency: data['currency']?.toString() ?? 'USD',
      availableAmount: money(
        isDealer ? data['available_balance'] : data['available_credit'],
      ),
      currentAmount: money(
        isDealer ? data['current_balance'] : data['current_credit'],
      ),
      secondaryAmount: money(
        isDealer ? data['total_spent'] : data['credit_limit'],
      ),
      secondaryLabel: isDealer ? 'Total spent' : 'Credit limit',
      transactions: rawTransactions
          .whereType<Map>()
          .map((item) => WalletTransaction.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }
}

class WalletTransactionCatalog {
  const WalletTransactionCatalog({required this.transactions, required this.count});

  final List<WalletTransaction> transactions;
  final int count;

  factory WalletTransactionCatalog.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final raw = data['transactions'] ?? data['results'] ?? root['transactions'] ?? const [];
    final rows = raw is List
        ? raw
            .whereType<Map>()
            .map((item) => WalletTransaction.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <WalletTransaction>[];
    return WalletTransactionCatalog(
      transactions: rows,
      count: int.tryParse((data['count'] ?? root['count'] ?? rows.length).toString()) ?? rows.length,
    );
  }
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.description,
    required this.createdAt,
    required this.reference,
    required this.provider,
    required this.orderNumber,
    required this.packageName,
    required this.salePrice,
    required this.costPrice,
  });

  final int id;
  final String type;
  final String status;
  final double amount;
  final String currency;
  final String description;
  final DateTime? createdAt;
  final String reference;
  final String provider;
  final String orderNumber;
  final String packageName;
  final double? salePrice;
  final double? costPrice;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final order = json['order'] is Map
        ? Map<String, dynamic>.from(json['order'] as Map)
        : const <String, dynamic>{};

    double? optionalMoney(Iterable<dynamic> values) {
      for (final value in values) {
        if (value == null || value.toString().trim().isEmpty) continue;
        final parsed = double.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
      return null;
    }

    return WalletTransaction(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      type: (json['transaction_type'] ?? json['type'] ?? 'transaction').toString(),
      status: json['status']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      reference: (json['reference_id'] ?? json['reference'] ?? '').toString(),
      provider: (json['provider'] ?? order['provider'] ?? '').toString(),
      orderNumber: (order['order_number'] ?? json['order_number'] ?? '').toString(),
      packageName: (order['product_name'] ?? order['package_name'] ?? json['product_name'] ?? json['package_name'] ?? '').toString(),
      salePrice: optionalMoney([
        order['sale_price'],
        order['final_price'],
        order['total_price'],
        order['amount'],
        json['sale_price'],
      ]),
      costPrice: optionalMoney([
        order['cost_price'],
        order['provider_cost'],
        order['base_price'],
        json['cost_price'],
        json['provider_cost'],
      ]),
    );
  }

  String get normalizedType {
    final normalized = type.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalized.contains('refund') ||
        normalized.contains('reversal') ||
        normalized.contains('return')) {
      return 'refund';
    }
    if (normalized.contains('credit') ||
        normalized.contains('topup') ||
        normalized.contains('allocation') ||
        normalized.contains('deposit') ||
        normalized.contains('fund')) {
      return 'credit';
    }
    if (normalized.contains('debit') ||
        normalized.contains('purchase') ||
        normalized.contains('order') ||
        normalized.contains('charge') ||
        normalized.contains('deduct')) {
      return 'debit';
    }
    return normalized;
  }

  double get absoluteAmount => amount.abs();
  bool get isCredit => normalizedType == 'credit' || normalizedType == 'refund';
  bool get isDebit => normalizedType == 'debit';
  bool get isRefund => normalizedType == 'refund';
  bool get hasProfitability => salePrice != null && costPrice != null && salePrice! > 0;
  double? get grossMargin => hasProfitability ? salePrice! - costPrice! : null;
  double? get grossMarginRate => hasProfitability ? ((salePrice! - costPrice!) / salePrice!) * 100 : null;
}
