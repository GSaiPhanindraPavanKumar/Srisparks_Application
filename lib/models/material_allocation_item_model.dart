class MaterialAllocationItemModel {
  final String? id;
  final String materialAllocationId;
  final String stockItemId;
  final int requiredQuantity;
  final int allocatedQuantity;
  final int? deliveredQuantity;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Related data from stock_items
  final String? itemName;
  final String? category;
  final String? subcategory;
  final String? itemCode;
  final String? unit;
  final int? availableStock;
  final double? unitPrice;

  MaterialAllocationItemModel({
    this.id,
    required this.materialAllocationId,
    required this.stockItemId,
    required this.requiredQuantity,
    this.allocatedQuantity = 0,
    this.deliveredQuantity,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.itemName,
    this.category,
    this.subcategory,
    this.itemCode,
    this.unit,
    this.availableStock,
    this.unitPrice,
  });

  factory MaterialAllocationItemModel.fromJson(Map<String, dynamic> json) {
    return MaterialAllocationItemModel(
      id: json['id'],
      materialAllocationId: json['material_allocation_id'],
      stockItemId: json['stock_item_id'],
      requiredQuantity: json['required_quantity']?.toInt() ?? 0,
      allocatedQuantity: json['allocated_quantity']?.toInt() ?? 0,
      deliveredQuantity: json['delivered_quantity']?.toInt(),
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      itemName: json['item_name'],
      category: json['category'],
      subcategory: json['subcategory'],
      itemCode: json['item_code'],
      unit: json['unit'],
      availableStock: json['available_stock']?.toInt(),
      unitPrice: json['unit_price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'material_allocation_id': materialAllocationId,
      'stock_item_id': stockItemId,
      'required_quantity': requiredQuantity,
      'allocated_quantity': allocatedQuantity,
      'delivered_quantity': deliveredQuantity,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  MaterialAllocationItemModel copyWith({
    String? id,
    String? materialAllocationId,
    String? stockItemId,
    int? requiredQuantity,
    int? allocatedQuantity,
    int? deliveredQuantity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? itemName,
    String? category,
    String? subcategory,
    String? itemCode,
    String? unit,
    int? availableStock,
    double? unitPrice,
  }) {
    return MaterialAllocationItemModel(
      id: id ?? this.id,
      materialAllocationId: materialAllocationId ?? this.materialAllocationId,
      stockItemId: stockItemId ?? this.stockItemId,
      requiredQuantity: requiredQuantity ?? this.requiredQuantity,
      allocatedQuantity: allocatedQuantity ?? this.allocatedQuantity,
      deliveredQuantity: deliveredQuantity ?? this.deliveredQuantity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      itemCode: itemCode ?? this.itemCode,
      unit: unit ?? this.unit,
      availableStock: availableStock ?? this.availableStock,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  // Helper getters
  int get pendingQuantity => requiredQuantity - allocatedQuantity;
  int get pendingDelivery => allocatedQuantity - (deliveredQuantity ?? 0);
  
  bool get isFullyAllocated => allocatedQuantity >= requiredQuantity;
  bool get isFullyDelivered => (deliveredQuantity ?? 0) >= allocatedQuantity;
  bool get hasStock => (availableStock ?? 0) > 0;
  bool get canAllocateMore => !isFullyAllocated && hasStock;
  
  double get allocationPercentage {
    if (requiredQuantity == 0) return 0.0;
    return (allocatedQuantity / requiredQuantity) * 100;
  }
  
  double get deliveryPercentage {
    if (allocatedQuantity == 0) return 0.0;
    return ((deliveredQuantity ?? 0) / allocatedQuantity) * 100;
  }

  String get allocationStatus {
    if (allocatedQuantity == 0) return 'Not Allocated';
    if (isFullyAllocated) return 'Fully Allocated';
    return 'Partially Allocated';
  }

  String get deliveryStatus {
    if (deliveredQuantity == null || deliveredQuantity == 0) return 'Not Delivered';
    if (isFullyDelivered) return 'Fully Delivered';
    return 'Partially Delivered';
  }

  // Calculate total value
  double get totalRequiredValue => (unitPrice ?? 0) * requiredQuantity;
  double get totalAllocatedValue => (unitPrice ?? 0) * allocatedQuantity;
  double get totalDeliveredValue => (unitPrice ?? 0) * (deliveredQuantity ?? 0);

  // Stock validation
  bool get hasEnoughStock => (availableStock ?? 0) >= requiredQuantity;
  int get shortfallQuantity => 
      hasEnoughStock ? 0 : requiredQuantity - (availableStock ?? 0);

  // Display helpers
  String get stockStatusDisplay {
    if (availableStock == null) return 'Unknown';
    if (availableStock! >= requiredQuantity) return 'Sufficient';
    if (availableStock! > 0) return 'Insufficient';
    return 'Out of Stock';
  }

  String get displayName => itemName ?? itemCode ?? 'Unknown Item';
  String get categoryDisplay => 
      subcategory != null ? '$category > $subcategory' : (category ?? 'Uncategorized');
}
