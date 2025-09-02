class MaterialAllocationModel {
  final String? id;
  final String customerId;
  final String officeId;
  final String allocatedById;
  final String status; // 'draft', 'confirmed', 'delivered', 'cancelled'
  final DateTime? allocationDate;
  final DateTime? deliveryDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  // Related data
  final String? customerName;
  final String? officeName;
  final String? allocatedByName;
  final List<MaterialAllocationItemModel>? items;

  MaterialAllocationModel({
    this.id,
    required this.customerId,
    required this.officeId,
    required this.allocatedById,
    this.status = 'draft',
    this.allocationDate,
    this.deliveryDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.metadata,
    this.customerName,
    this.officeName,
    this.allocatedByName,
    this.items,
  });

  factory MaterialAllocationModel.fromJson(Map<String, dynamic> json) {
    return MaterialAllocationModel(
      id: json['id'],
      customerId: json['customer_id'],
      officeId: json['office_id'],
      allocatedById: json['allocated_by_id'],
      status: json['status'] ?? 'draft',
      allocationDate: json['allocation_date'] != null
          ? DateTime.parse(json['allocation_date'])
          : null,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'])
          : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      metadata: json['metadata'],
      customerName: json['customer_name'],
      officeName: json['office_name'],
      allocatedByName: json['allocated_by_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'office_id': officeId,
      'allocated_by_id': allocatedById,
      'status': status,
      'allocation_date': allocationDate?.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  MaterialAllocationModel copyWith({
    String? id,
    String? customerId,
    String? officeId,
    String? allocatedById,
    String? status,
    DateTime? allocationDate,
    DateTime? deliveryDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? customerName,
    String? officeName,
    String? allocatedByName,
    List<MaterialAllocationItemModel>? items,
  }) {
    return MaterialAllocationModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      officeId: officeId ?? this.officeId,
      allocatedById: allocatedById ?? this.allocatedById,
      status: status ?? this.status,
      allocationDate: allocationDate ?? this.allocationDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      customerName: customerName ?? this.customerName,
      officeName: officeName ?? this.officeName,
      allocatedByName: allocatedByName ?? this.allocatedByName,
      items: items ?? this.items,
    );
  }

  // Helper getters
  String get statusDisplayName {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'confirmed':
        return 'Confirmed';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  bool get isEditable => status == 'draft';
  bool get isConfirmed => status == 'confirmed';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  // Calculate totals from items
  int get totalRequiredItems {
    if (items == null) return 0;
    return items!.fold(0, (sum, item) => sum + item.requiredQuantity);
  }

  int get totalAllocatedItems {
    if (items == null) return 0;
    return items!.fold(0, (sum, item) => sum + item.allocatedQuantity);
  }

  int get totalDeliveredItems {
    if (items == null) return 0;
    return items!.fold(0, (sum, item) => sum + (item.deliveredQuantity ?? 0));
  }

  double get allocationCompletionPercentage {
    if (totalRequiredItems == 0) return 0.0;
    return (totalAllocatedItems / totalRequiredItems) * 100;
  }

  double get deliveryCompletionPercentage {
    if (totalAllocatedItems == 0) return 0.0;
    return (totalDeliveredItems / totalAllocatedItems) * 100;
  }
}
