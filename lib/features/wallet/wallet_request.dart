class WalletRequest {
  const WalletRequest({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.note,
    required this.createdAt,
    this.requestType = '',
    this.requesterName = '',
    this.requesterEmail = '',
    this.reviewedAt,
  });

  final int id;
  final double amount;
  final String currency;
  final String status;
  final String note;
  final DateTime? createdAt;
  final String requestType;
  final String requesterName;
  final String requesterEmail;
  final DateTime? reviewedAt;

  bool get isPending => status.toLowerCase() == 'pending';

  static List<WalletRequest> listFromResponse(dynamic response) {
    final raw = response is List
        ? response
        : response is Map && response['data'] is List
        ? response['data'] as List
        : const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => WalletRequest.fromResponse(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  factory WalletRequest.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final requester = data['dealer'] is Map
        ? Map<String, dynamic>.from(data['dealer'] as Map)
        : data['reseller'] is Map
        ? Map<String, dynamic>.from(data['reseller'] as Map)
        : const <String, dynamic>{};
    return WalletRequest(
      id: int.tryParse((data['id'] ?? 0).toString()) ?? 0,
      amount:
          double.tryParse(
            data['requested_amount']?.toString() ??
                data['amount']?.toString() ??
                '',
          ) ??
          0,
      currency: data['currency']?.toString() ?? 'USD',
      status: data['status']?.toString() ?? 'pending',
      note: data['note']?.toString() ?? '',
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? ''),
      requestType: data['request_type']?.toString() ?? '',
      requesterName: requester['name']?.toString() ?? '',
      requesterEmail: requester['email']?.toString() ?? '',
      reviewedAt: DateTime.tryParse(
        (data['reviewed_at'] ?? data['processed_at'])?.toString() ?? '',
      ),
    );
  }
}
