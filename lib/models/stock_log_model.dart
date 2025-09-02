class StockLogModel {
  final String? id;
  final String stockItemId;
  final String action; // 'add' or 'decrease'
  final int quantity;
  final int previousStock;
  final int newStock;
  final String? reason;
  final String? workId; // Optional: link to work if related
  final String officeId;
  final String userId;
  final DateTime? createdAt;

  StockLogModel({
    this.id,
    required this.stockItemId,
    required this.action,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.reason,
    this.workId,
    required this.officeId,
    required this.userId,
    this.createdAt,
  });

  factory StockLogModel.fromJson(Map<String, dynamic> json) {
    final quantityChange = json['quantity_change'] ?? json['quantity'] ?? 0;
    return StockLogModel(
      id: json['id'],
      stockItemId: json['stock_item_id'],
      action: json['action_type'] ?? json['action'],
      quantity: quantityChange is int
          ? quantityChange.abs()
          : int.tryParse(quantityChange.toString())?.abs() ?? 0,
      previousStock: json['previous_stock'],
      newStock: json['new_stock'],
      reason: json['reason'],
      workId: json['work_id'],
      officeId: json['office_id'],
      userId: json['user_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock_item_id': stockItemId,
      'action_type': action,
      'quantity_change': action == 'add' ? quantity : -quantity,
      'previous_stock': previousStock,
      'new_stock': newStock,
      'reason': reason,
      'work_id': workId,
      'office_id': officeId,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  StockLogModel copyWith({
    String? id,
    String? stockItemId,
    String? action,
    int? quantity,
    int? previousStock,
    int? newStock,
    String? reason,
    String? workId,
    String? officeId,
    String? userId,
    DateTime? createdAt,
  }) {
    return StockLogModel(
      id: id ?? this.id,
      stockItemId: stockItemId ?? this.stockItemId,
      action: action ?? this.action,
      quantity: quantity ?? this.quantity,
      previousStock: previousStock ?? this.previousStock,
      newStock: newStock ?? this.newStock,
      reason: reason ?? this.reason,
      workId: workId ?? this.workId,
      officeId: officeId ?? this.officeId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
