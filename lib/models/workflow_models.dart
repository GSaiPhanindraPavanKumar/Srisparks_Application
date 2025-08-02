enum CustomerStatus {
  application,
  loanApproval,
  installationAssigned,
  material,
  installation,
  documentation,
  meter,
  inverterTurnOn,
  completed,
}

enum WorkLocation { office, customerSite, external }

enum ComplaintType { technical, maintenance, warranty, billing, other }

enum ServiceType { freeService, paidService, warranty }

class CustomerStatusModel {
  final String id;
  final String customerId;
  final CustomerStatus status;
  final DateTime statusDate;
  final String? assignedUserId;
  final String? assignedUserName;
  final String? notes;
  final List<String>? documents;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerStatusModel({
    required this.id,
    required this.customerId,
    required this.status,
    required this.statusDate,
    this.assignedUserId,
    this.assignedUserName,
    this.notes,
    this.documents,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerStatusModel.fromJson(Map<String, dynamic> json) {
    return CustomerStatusModel(
      id: json['id'],
      customerId: json['customer_id'],
      status: CustomerStatus.values.firstWhere((e) => e.name == json['status']),
      statusDate: DateTime.parse(json['status_date']),
      assignedUserId: json['assigned_user_id'],
      assignedUserName: json['assigned_user_name'],
      notes: json['notes'],
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : null,
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'status': status.name,
      'status_date': statusDate.toIso8601String(),
      'assigned_user_id': assignedUserId,
      'assigned_user_name': assignedUserName,
      'notes': notes,
      'documents': documents,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplayName {
    switch (status) {
      case CustomerStatus.application:
        return 'Application';
      case CustomerStatus.loanApproval:
        return 'Loan/Amount Approval';
      case CustomerStatus.installationAssigned:
        return 'Installation Assigned';
      case CustomerStatus.material:
        return 'Material';
      case CustomerStatus.installation:
        return 'Installation';
      case CustomerStatus.documentation:
        return 'Documentation';
      case CustomerStatus.meter:
        return 'Meter';
      case CustomerStatus.inverterTurnOn:
        return 'Inverter Turn On';
      case CustomerStatus.completed:
        return 'Completed';
    }
  }
}

class WorkAssignmentModel {
  final String id;
  final String workId;
  final String customerId;
  final String customerName;
  final CustomerStatus workStage;
  final List<String> assignedUserIds;
  final List<String> assignedUserNames;
  final WorkLocation location;
  final String? customerAddress;
  final String? locationNotes;
  final DateTime? scheduledDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<ComponentUsage> componentsUsed;
  final String? notes;
  final List<String>? attachments;
  final bool isCompleted;
  final String officeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkAssignmentModel({
    required this.id,
    required this.workId,
    required this.customerId,
    required this.customerName,
    required this.workStage,
    required this.assignedUserIds,
    required this.assignedUserNames,
    required this.location,
    this.customerAddress,
    this.locationNotes,
    this.scheduledDate,
    this.startedAt,
    this.completedAt,
    required this.componentsUsed,
    this.notes,
    this.attachments,
    required this.isCompleted,
    required this.officeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkAssignmentModel.fromJson(Map<String, dynamic> json) {
    return WorkAssignmentModel(
      id: json['id'],
      workId: json['work_id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      workStage: CustomerStatus.values.firstWhere(
        (e) => e.name == json['work_stage'],
      ),
      assignedUserIds: List<String>.from(json['assigned_user_ids']),
      assignedUserNames: List<String>.from(json['assigned_user_names']),
      location: WorkLocation.values.firstWhere(
        (e) => e.name == json['location'],
      ),
      customerAddress: json['customer_address'],
      locationNotes: json['location_notes'],
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      componentsUsed: (json['components_used'] as List)
          .map((e) => ComponentUsage.fromJson(e))
          .toList(),
      notes: json['notes'],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      isCompleted: json['is_completed'],
      officeId: json['office_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get locationDisplayName {
    switch (location) {
      case WorkLocation.office:
        return 'Office';
      case WorkLocation.customerSite:
        return 'Customer Site';
      case WorkLocation.external:
        return 'External Location';
    }
  }
}

class ComponentUsage {
  final String componentId;
  final String componentName;
  final int quantity;
  final String unit;
  final String? notes;

  ComponentUsage({
    required this.componentId,
    required this.componentName,
    required this.quantity,
    required this.unit,
    this.notes,
  });

  factory ComponentUsage.fromJson(Map<String, dynamic> json) {
    return ComponentUsage(
      componentId: json['component_id'],
      componentName: json['component_name'],
      quantity: json['quantity'],
      unit: json['unit'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'component_id': componentId,
      'component_name': componentName,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
    };
  }
}

class InventoryComponentModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String unit;
  final int currentStock;
  final int minimumStock;
  final double unitPrice;
  final String? supplier;
  final String? supplierContact;
  final String officeId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryComponentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.minimumStock,
    required this.unitPrice,
    this.supplier,
    this.supplierContact,
    required this.officeId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryComponentModel.fromJson(Map<String, dynamic> json) {
    return InventoryComponentModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      unit: json['unit'],
      currentStock: json['current_stock'],
      minimumStock: json['minimum_stock'],
      unitPrice: json['unit_price'].toDouble(),
      supplier: json['supplier'],
      supplierContact: json['supplier_contact'],
      officeId: json['office_id'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isLowStock => currentStock <= minimumStock;
}

class CustomerComplaintModel {
  final String id;
  final String customerId;
  final String customerName;
  final ComplaintType type;
  final String title;
  final String description;
  final ServiceType serviceType;
  final bool isUnderWarranty;
  final DateTime installationDate;
  final String priority;
  final String status;
  final List<String> assignedUserIds;
  final List<String> assignedUserNames;
  final DateTime? scheduledDate;
  final DateTime? resolvedAt;
  final String? resolution;
  final List<ComponentUsage>? componentsUsed;
  final double? serviceCost;
  final List<String>? attachments;
  final String officeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerComplaintModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.type,
    required this.title,
    required this.description,
    required this.serviceType,
    required this.isUnderWarranty,
    required this.installationDate,
    required this.priority,
    required this.status,
    required this.assignedUserIds,
    required this.assignedUserNames,
    this.scheduledDate,
    this.resolvedAt,
    this.resolution,
    this.componentsUsed,
    this.serviceCost,
    this.attachments,
    required this.officeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerComplaintModel.fromJson(Map<String, dynamic> json) {
    return CustomerComplaintModel(
      id: json['id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      type: ComplaintType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'],
      description: json['description'],
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == json['service_type'],
      ),
      isUnderWarranty: json['is_under_warranty'],
      installationDate: DateTime.parse(json['installation_date']),
      priority: json['priority'],
      status: json['status'],
      assignedUserIds: List<String>.from(json['assigned_user_ids']),
      assignedUserNames: List<String>.from(json['assigned_user_names']),
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      resolution: json['resolution'],
      componentsUsed: json['components_used'] != null
          ? (json['components_used'] as List)
                .map((e) => ComponentUsage.fromJson(e))
                .toList()
          : null,
      serviceCost: json['service_cost']?.toDouble(),
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      officeId: json['office_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get typeDisplayName {
    switch (type) {
      case ComplaintType.technical:
        return 'Technical Issue';
      case ComplaintType.maintenance:
        return 'Maintenance';
      case ComplaintType.warranty:
        return 'Warranty Claim';
      case ComplaintType.billing:
        return 'Billing Issue';
      case ComplaintType.other:
        return 'Other';
    }
  }

  String get serviceTypeDisplayName {
    switch (serviceType) {
      case ServiceType.freeService:
        return 'Free Service';
      case ServiceType.paidService:
        return 'Paid Service';
      case ServiceType.warranty:
        return 'Warranty Service';
    }
  }
}
