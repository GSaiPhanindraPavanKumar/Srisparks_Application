enum StockMovementType {
  inbound,    // Stock coming in (purchase, transfer in)
  outbound,   // Stock going out (usage, transfer out, damage)
  adjustment, // Manual adjustments
  transfer,   // Between offices
}

class StockMovementModel {
  final String id;
  final String stockItemId;
  final String officeId;
  final StockMovementType movementType;
  final int quantity;
  final int previousQuantity;
  final int newQuantity;
  final String? reason;
  final String? referenceNumber; // Work order, purchase order, etc.
  final String? workId; // If used for specific work
  final String? transferFromOfficeId; // For transfers
  final String? transferToOfficeId; // For transfers
  final String userId; // Who made the movement
  final DateTime movementDate;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  // Populated from joins
  final String? stockItemName;
  final String? userName;
  final String? officeName;

  StockMovementModel({
    required this.id,
    required this.stockItemId,
    required this.officeId,
    required this.movementType,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    this.reason,
    this.referenceNumber,
    this.workId,
    this.transferFromOfficeId,
    this.transferToOfficeId,
    required this.userId,
    required this.movementDate,
    required this.createdAt,
    this.metadata,
    this.stockItemName,
    this.userName,
    this.officeName,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'],
      stockItemId: json['stock_item_id'],
      officeId: json['office_id'],
      movementType: StockMovementType.values.firstWhere(
        (type) => type.name == json['movement_type'],
      ),
      quantity: json['quantity'],
      previousQuantity: json['previous_quantity'],
      newQuantity: json['new_quantity'],
      reason: json['reason'],
      referenceNumber: json['reference_number'],
      workId: json['work_id'],
      transferFromOfficeId: json['transfer_from_office_id'],
      transferToOfficeId: json['transfer_to_office_id'],
      userId: json['user_id'],
      movementDate: DateTime.parse(json['movement_date']),
      createdAt: DateTime.parse(json['created_at']),
      metadata: json['metadata'],
      stockItemName: json['stock_item_name'],
      userName: json['user_name'],
      officeName: json['office_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock_item_id': stockItemId,
      'office_id': officeId,
      'movement_type': movementType.name,
      'quantity': quantity,
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'reason': reason,
      'reference_number': referenceNumber,
      'work_id': workId,
      'transfer_from_office_id': transferFromOfficeId,
      'transfer_to_office_id': transferToOfficeId,
      'user_id': userId,
      'movement_date': movementDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  String get movementTypeDisplayName {
    switch (movementType) {
      case StockMovementType.inbound:
        return 'Stock In';
      case StockMovementType.outbound:
        return 'Stock Out';
      case StockMovementType.adjustment:
        return 'Adjustment';
      case StockMovementType.transfer:
        return 'Transfer';
    }
  }
}
