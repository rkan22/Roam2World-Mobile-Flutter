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

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String status;
  final double amount;
  final String currency;
  final String description;
  final DateTime? createdAt;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      type: json['transaction_type']?.toString() ?? 'transaction',
      status: json['status']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  bool get isCredit {
    final normalized = type.toLowerCase();
    return normalized.contains('allocation') ||
        normalized.contains('topup') ||
        normalized.contains('credit') ||
        normalized.contains('refund');
  }
}
