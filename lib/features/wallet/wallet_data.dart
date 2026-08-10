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
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get canRequestTopUp => isDealer || role.toLowerCase() == 'reseller';

  WalletData copyWith({List<WalletTransaction>? transactions}) {
    return WalletData(
      role: role,
      currency: currency,
      availableAmount: availableAmount,
      currentAmount: currentAmount,
      secondaryAmount: secondaryAmount,
      secondaryLabel: secondaryLabel,
      transactions: transactions ?? this.transactions,
    );
  }

  factory WalletData.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final role = data['role']?.toString() ?? '';
    final isDealer = role.toLowerCase() == 'dealer';
    double money(dynamic value) =>
        double.tryParse(value?.toString() ?? '') ?? 0;
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
        isDealer
            ? data['total_spent']
            : role.toLowerCase() == 'admin'
            ? data['pending_wallet_requests']
            : data['credit_limit'],
      ),
      secondaryLabel: isDealer
          ? 'Total spent'
          : role.toLowerCase() == 'admin'
          ? 'Pending requests'
          : 'Credit limit',
      transactions: rawTransactions
          .whereType<Map>()
          .map(
            (item) =>
                WalletTransaction.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class WalletTransactionPage {
  const WalletTransactionPage({
    required this.transactions,
    required this.balance,
    required this.currency,
  });

  final List<WalletTransaction> transactions;
  final double balance;
  final String currency;

  factory WalletTransactionPage.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final rawTransactions = root['transactions'] is List
        ? root['transactions'] as List
        : root['data'] is List
        ? root['data'] as List
        : const [];
    return WalletTransactionPage(
      transactions: rawTransactions
          .whereType<Map>()
          .map(
            (item) =>
                WalletTransaction.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      balance: double.tryParse(root['balance']?.toString() ?? '') ?? 0,
      currency: root['currency']?.toString() ?? 'USD',
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
    this.balanceBefore,
    this.balanceAfter,
  });

  final String id;
  final String type;
  final String status;
  final double amount;
  final String currency;
  final String description;
  final DateTime? createdAt;
  final double? balanceBefore;
  final double? balanceAfter;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: (json['id'] ?? '').toString(),
      type: json['transaction_type']?.toString() ?? 'transaction',
      status: json['status']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      balanceBefore: _optionalMoney(json['balance_before']),
      balanceAfter: _optionalMoney(json['balance_after']),
    );
  }

  bool get isCredit {
    final normalized = type.toLowerCase();
    if (balanceBefore != null &&
        balanceAfter != null &&
        balanceBefore != balanceAfter) {
      return balanceAfter! > balanceBefore!;
    }
    if (normalized == 'adjustment') return amount >= 0;
    return normalized.contains('allocation') ||
        normalized.contains('topup') ||
        normalized.contains('credit') ||
        normalized.contains('refund') ||
        normalized.contains('bonus');
  }

  double get displayAmount => amount.abs();

  static double? _optionalMoney(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return double.tryParse(value.toString());
  }
}
