class AdminSupportData {
  const AdminSupportData({
    required this.count,
    required this.openCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.closedCount,
    required this.tickets,
  });

  final int count;
  final int openCount;
  final int inProgressCount;
  final int resolvedCount;
  final int closedCount;
  final List<AdminSupportTicket> tickets;

  factory AdminSupportData.fromResponse(dynamic response) {
    if (response is! Map) {
      return const AdminSupportData(
        count: 0,
        openCount: 0,
        inProgressCount: 0,
        resolvedCount: 0,
        closedCount: 0,
        tickets: [],
      );
    }
    final root = Map<String, dynamic>.from(response);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final rawTickets = data['tickets'];
    final tickets = rawTickets is List
        ? rawTickets
            .whereType<Map>()
            .map((item) => AdminSupportTicket.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false)
        : const <AdminSupportTicket>[];

    return AdminSupportData(
      count: _int(data['count'], fallback: tickets.length),
      openCount: _int(data['open_count']),
      inProgressCount: _int(data['in_progress_count']),
      resolvedCount: _int(data['resolved_count']),
      closedCount: _int(data['closed_count']),
      tickets: tickets,
    );
  }
}

class AdminSupportTicket {
  const AdminSupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.clientName,
    required this.clientEmail,
    required this.assignedToName,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
  });

  final int id;
  final String subject;
  final String description;
  final String status;
  final String clientName;
  final String clientEmail;
  final String assignedToName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  factory AdminSupportTicket.fromJson(Map<String, dynamic> json) =>
      AdminSupportTicket(
        id: _int(json['id']),
        subject: (json['subject'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        clientName: (json['client_name'] ?? '').toString(),
        clientEmail: (json['client_email'] ?? '').toString(),
        assignedToName: (json['assigned_to_name'] ?? '').toString(),
        createdAt: _date(json['created_at']),
        updatedAt: _date(json['updated_at']),
        resolvedAt: _date(json['resolved_at']),
      );
}

int _int(dynamic value, {int fallback = 0}) =>
    int.tryParse((value ?? '').toString()) ?? fallback;

DateTime? _date(dynamic value) {
  final text = (value ?? '').toString();
  return text.isEmpty ? null : DateTime.tryParse(text);
}
