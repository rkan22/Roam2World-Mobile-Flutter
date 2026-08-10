class WalletRequest {
  const WalletRequest({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final double amount;
  final String currency;
  final String status;
  final String note;
  final DateTime? createdAt;

  factory WalletRequest.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    return WalletRequest(
      id: int.tryParse((data['id'] ?? 0).toString()) ?? 0,
      amount: double.tryParse(
            data['requested_amount']?.toString() ??
                data['amount']?.toString() ??
                '',
          ) ??
          0,
      currency: data['currency']?.toString() ?? 'USD',
      status: data['status']?.toString() ?? 'pending',
      note: (data['dealer_notes'] ?? data['note'] ?? '').toString(),
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? ''),
    );
  }
}
