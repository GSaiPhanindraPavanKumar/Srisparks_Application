import 'dart:convert';

class CustomerModel {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final int? kw;
  final bool isActive;
  final String officeId;
  final String addedById;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  // Project Phase Tracking
  final String currentPhase;

  // Application Phase Fields
  final DateTime applicationDate;
  final Map<String, dynamic>? applicationDetails;
  final String applicationStatus;
  final String? applicationApprovedById;
  final DateTime? applicationApprovalDate;
  final String? applicationNotes;

  // Manager Recommendation Fields
  final String? managerRecommendation; // 'approve' or 'reject'
  final String? managerRecommendedById;
  final DateTime? managerRecommendationDate;
  final String? managerRecommendationComment;

  final bool siteSurveyCompleted;
  final DateTime? siteSurveyDate;
  final String? siteSurveyTechnicianId;
  final Map<String, dynamic>? siteSurveyPhotos;
  final int? estimatedKw;
  final double? estimatedCost;
  final String feasibilityStatus;

  // Equipment Serial Numbers (populated in later phases)
  final String? solarPanelsSerialNumbers;
  final String? inverterSerialNumbers;
  final String? electricMeterServiceNumber;

  // Amount Phase Fields (only accessible after application approval)
  final int? amountKw; // Final confirmed kW capacity
  final double? amountTotal; // Total project amount in Rs
  final String?
  amountPaymentsData; // JSON string containing payment history with multiple payments
  final String amountPaymentStatus; // 'pending', 'partial', 'completed'
  final String?
  amountClearedById; // Director/Manager who cleared the amount phase
  final DateTime? amountClearedDate; // Date when amount phase was cleared
  final String? amountNotes; // Additional notes about payment/amount

  // Legacy fields - kept for backward compatibility
  final double?
  amountPaid; // Amount actually paid in Rs (calculated from amountPaymentsData)
  final DateTime? amountPaidDate; // Date when payment was made
  final String? amountUtrNumber; // UTR/transaction reference number

  // Material Allocation Fields
  final String?
  materialAllocationPlan; // JSON string containing allocation plan
  final String
  materialAllocationStatus; // 'pending', 'planned', 'allocated', 'delivered', 'completed'
  final DateTime? materialAllocationDate; // Date when materials were allocated
  final String? materialAllocatedById; // User who allocated the materials
  final DateTime? materialDeliveryDate; // Date when materials were delivered
  final String?
  materialAllocationNotes; // Additional notes about material allocation

  // Enhanced Audit Trail Fields
  final String? materialPlannedById; // User who planned the materials
  final DateTime? materialPlannedDate; // Date when materials were planned
  final String? materialConfirmedById; // User who confirmed the allocation
  final DateTime? materialConfirmedDate; // Date when allocation was confirmed
  final String? materialDeliveredById; // User who delivered the materials
  final DateTime? materialDeliveredDate; // Date when materials were delivered
  final String?
  materialAllocationHistory; // JSON string containing allocation history

  CustomerModel({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.kw,
    required this.isActive,
    required this.officeId,
    required this.addedById,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
    this.metadata,

    // Project Phase Tracking
    this.currentPhase = 'application',

    // Application Phase Fields
    required this.applicationDate,
    this.applicationDetails,
    this.applicationStatus = 'pending',
    this.applicationApprovedById,
    this.applicationApprovalDate,
    this.applicationNotes,

    // Manager Recommendation Fields
    this.managerRecommendation,
    this.managerRecommendedById,
    this.managerRecommendationDate,
    this.managerRecommendationComment,

    this.siteSurveyCompleted = false,
    this.siteSurveyDate,
    this.siteSurveyTechnicianId,
    this.siteSurveyPhotos,
    this.estimatedKw,
    this.estimatedCost,
    this.feasibilityStatus = 'pending',

    // Equipment Serial Numbers
    this.solarPanelsSerialNumbers,
    this.inverterSerialNumbers,
    this.electricMeterServiceNumber,

    // Amount Phase Fields
    this.amountKw,
    this.amountTotal,
    this.amountPaymentsData,
    this.amountPaymentStatus = 'pending',
    this.amountClearedById,
    this.amountClearedDate,
    this.amountNotes,

    // Legacy fields
    this.amountPaid,
    this.amountPaidDate,
    this.amountUtrNumber,

    // Material Allocation Fields
    this.materialAllocationPlan,
    this.materialAllocationStatus = 'pending',
    this.materialAllocationDate,
    this.materialAllocatedById,
    this.materialDeliveryDate,
    this.materialAllocationNotes,

    // Enhanced Audit Trail Fields
    this.materialPlannedById,
    this.materialPlannedDate,
    this.materialConfirmedById,
    this.materialConfirmedDate,
    this.materialDeliveredById,
    this.materialDeliveredDate,
    this.materialAllocationHistory,
  });

  // Helper method to safely parse JSON fields from various formats
  static String? _parseJsonField(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map || value is List) {
      // Convert Map/List to JSON string
      try {
        return jsonEncode(value);
      } catch (e) {
        return null;
      }
    }
    return value.toString();
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      country: json['country'],
      kw: json['kw'],
      isActive: json['is_active'] ?? true,
      officeId: json['office_id'],
      addedById: json['added_by_id'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      metadata: json['metadata'],

      // Project Phase Tracking
      currentPhase: json['current_phase'] ?? 'application',

      // Application Phase Fields
      applicationDate: DateTime.parse(
        json['application_date'] ?? DateTime.now().toIso8601String(),
      ),
      applicationDetails: json['application_details'],
      applicationStatus: json['application_status'] ?? 'pending',
      applicationApprovedById: json['application_approved_by_id'],
      applicationApprovalDate: json['application_approval_date'] != null
          ? DateTime.parse(json['application_approval_date'])
          : null,
      applicationNotes: json['application_notes'],

      // Manager Recommendation Fields
      managerRecommendation: json['manager_recommendation'],
      managerRecommendedById: json['manager_recommended_by_id'],
      managerRecommendationDate: json['manager_recommendation_date'] != null
          ? DateTime.parse(json['manager_recommendation_date'])
          : null,
      managerRecommendationComment: json['manager_recommendation_comment'],

      siteSurveyCompleted: json['site_survey_completed'] ?? false,
      siteSurveyDate: json['site_survey_date'] != null
          ? DateTime.parse(json['site_survey_date'])
          : null,
      siteSurveyTechnicianId: json['site_survey_technician_id'],
      siteSurveyPhotos: json['site_survey_photos'],
      estimatedKw: json['estimated_kw'],
      estimatedCost: json['estimated_cost']?.toDouble(),
      feasibilityStatus: json['feasibility_status'] ?? 'pending',

      // Equipment Serial Numbers
      solarPanelsSerialNumbers: json['solar_panels_serial_numbers'],
      inverterSerialNumbers: json['inverter_serial_numbers'],
      electricMeterServiceNumber: json['electric_meter_service_number'],

      // Amount Phase Fields
      amountKw: json['amount_kw'],
      amountTotal: json['amount_total']?.toDouble(),
      amountPaymentsData: json['amount_payments_data'],
      amountPaymentStatus: json['amount_payment_status'] ?? 'pending',
      amountClearedById: json['amount_cleared_by_id'],
      amountClearedDate: json['amount_cleared_date'] != null
          ? DateTime.parse(json['amount_cleared_date'])
          : null,
      amountNotes: json['amount_notes'],

      // Legacy fields - calculated from amountPaymentsData
      amountPaid: json['amount_paid']?.toDouble(),
      amountPaidDate: json['amount_paid_date'] != null
          ? DateTime.parse(json['amount_paid_date'])
          : null,
      amountUtrNumber: json['amount_utr_number'],

      // Material Allocation Fields
      materialAllocationPlan: _parseJsonField(json['material_allocation_plan']),
      materialAllocationStatus: json['material_allocation_status'] ?? 'pending',
      materialAllocationDate: json['material_allocation_date'] != null
          ? DateTime.parse(json['material_allocation_date'])
          : null,
      materialAllocatedById: json['material_allocated_by_id'],
      materialDeliveryDate: json['material_delivery_date'] != null
          ? DateTime.parse(json['material_delivery_date'])
          : null,
      materialAllocationNotes: json['material_allocation_notes'],

      // Enhanced Audit Trail Fields
      materialPlannedById: json['material_planned_by_id'],
      materialPlannedDate: json['material_planned_date'] != null
          ? DateTime.parse(json['material_planned_date'])
          : null,
      materialConfirmedById: json['material_confirmed_by_id'],
      materialConfirmedDate: json['material_confirmed_date'] != null
          ? DateTime.parse(json['material_confirmed_date'])
          : null,
      materialDeliveredById: json['material_delivered_by_id'],
      materialDeliveredDate: json['material_delivered_date'] != null
          ? DateTime.parse(json['material_delivered_date'])
          : null,
      materialAllocationHistory: _parseJsonField(
        json['material_allocation_history'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'kw': kw,
      'is_active': isActive,
      'office_id': officeId,
      'added_by_id': addedById,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,

      // Project Phase Tracking
      'current_phase': currentPhase,

      // Application Phase Fields
      'application_date': applicationDate.toIso8601String(),
      'application_details': applicationDetails,
      'application_status': applicationStatus,
      'application_approved_by_id': applicationApprovedById,
      'application_approval_date': applicationApprovalDate?.toIso8601String(),
      'application_notes': applicationNotes,

      // Manager Recommendation Fields
      'manager_recommendation': managerRecommendation,
      'manager_recommended_by_id': managerRecommendedById,
      'manager_recommendation_date': managerRecommendationDate
          ?.toIso8601String(),
      'manager_recommendation_comment': managerRecommendationComment,

      'site_survey_completed': siteSurveyCompleted,
      'site_survey_date': siteSurveyDate?.toIso8601String(),
      'site_survey_technician_id': siteSurveyTechnicianId,
      'site_survey_photos': siteSurveyPhotos,
      'estimated_kw': estimatedKw,
      'estimated_cost': estimatedCost,
      'feasibility_status': feasibilityStatus,

      // Equipment Serial Numbers
      'solar_panels_serial_numbers': solarPanelsSerialNumbers,
      'inverter_serial_numbers': inverterSerialNumbers,
      'electric_meter_service_number': electricMeterServiceNumber,

      // Amount Phase Fields
      'amount_kw': amountKw,
      'amount_total': amountTotal,
      'amount_paid': amountPaid,
      'amount_paid_date': amountPaidDate?.toIso8601String(),
      'amount_utr_number': amountUtrNumber,
      'amount_payment_status': amountPaymentStatus,
      'amount_cleared_by_id': amountClearedById,
      'amount_cleared_date': amountClearedDate?.toIso8601String(),
      'amount_notes': amountNotes,

      // Material Allocation Fields
      'material_allocation_plan': materialAllocationPlan,
      'material_allocation_status': materialAllocationStatus,
      'material_allocation_date': materialAllocationDate?.toIso8601String(),
      'material_allocated_by_id': materialAllocatedById,
      'material_delivery_date': materialDeliveryDate?.toIso8601String(),
      'material_allocation_notes': materialAllocationNotes,

      // Enhanced Audit Trail Fields
      'material_planned_by_id': materialPlannedById,
      'material_planned_date': materialPlannedDate?.toIso8601String(),
      'material_confirmed_by_id': materialConfirmedById,
      'material_confirmed_date': materialConfirmedDate?.toIso8601String(),
      'material_delivered_by_id': materialDeliveredById,
      'material_delivered_date': materialDeliveredDate?.toIso8601String(),
      'material_allocation_history': materialAllocationHistory,
    };
  }

  String get fullAddress {
    final parts = [
      address,
      city,
      state,
      zipCode,
      country,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(', ');
  }

  String get displayName {
    return name;
  }

  // Application Phase Helper Methods
  String get currentPhaseDisplayName {
    switch (currentPhase) {
      case 'application':
        return 'Application';
      case 'amount':
        return 'Payment';
      case 'material_allocation':
        return 'Material Allocation';
      case 'material_delivery':
        return 'Material Delivery';
      case 'installation':
        return 'Installation';
      case 'documentation':
        return 'Documentation';
      case 'meter_connection':
        return 'Meter Connection';
      case 'inverter_turnon':
        return 'Inverter Turn-on';
      case 'completed':
        return 'Completed';
      case 'service_phase':
        return 'Service Phase';
      default:
        return currentPhase.replaceAll('_', ' ').toTitleCase();
    }
  }

  String get applicationStatusDisplayName {
    switch (applicationStatus) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return applicationStatus.toTitleCase();
    }
  }

  String get feasibilityStatusDisplayName {
    switch (feasibilityStatus) {
      case 'pending':
        return 'Under Review';
      case 'feasible':
        return 'Feasible';
      case 'not_feasible':
        return 'Not Feasible';
      default:
        return feasibilityStatus.toTitleCase();
    }
  }

  String get amountPaymentStatusDisplayName {
    switch (amountPaymentStatus) {
      case 'pending':
        return 'Payment Pending';
      case 'partial':
        return 'Partially Paid';
      case 'completed':
        return 'Fully Paid';
      default:
        return amountPaymentStatus.toTitleCase();
    }
  }

  // Check if application is approved and ready for amount phase
  bool get isReadyForAmountPhase {
    return applicationStatus == 'approved' && currentPhase == 'application';
  }

  // Check if amount phase is accessible (application must be approved)
  bool get canAccessAmountPhase {
    return applicationStatus == 'approved';
  }

  bool get isAmountPhaseCompleted {
    return amountClearedById != null && amountClearedDate != null;
  }

  // Check if customer can proceed to next phase (amount cleared or payment pending but allowed)
  bool get canProceedFromAmountPhase {
    return isAmountPhaseCompleted || amountPaymentStatus == 'pending';
  }

  // Material Allocation Helper Methods
  String get materialAllocationStatusDisplayName {
    switch (materialAllocationStatus) {
      case 'pending':
        return 'Pending Planning';
      case 'planned':
        return 'Plan Created';
      case 'allocated':
        return 'Materials Allocated';
      case 'delivered':
        return 'Materials Delivered';
      case 'completed':
        return 'Allocation Complete';
      default:
        return materialAllocationStatus.replaceAll('_', ' ').toTitleCase();
    }
  }

  bool get hasMaterialAllocationPlan {
    return materialAllocationPlan != null && materialAllocationPlan!.isNotEmpty;
  }

  bool get isMaterialAllocated {
    return materialAllocationStatus == 'allocated' ||
        materialAllocationStatus == 'delivered' ||
        materialAllocationStatus == 'completed';
  }

  bool get isMaterialDelivered {
    return materialAllocationStatus == 'delivered' ||
        materialAllocationStatus == 'completed';
  }

  bool get canAllocateMaterials {
    return currentPhase == 'material_allocation' &&
        materialAllocationStatus == 'planned';
  }

  bool get canDeliverMaterials {
    return materialAllocationStatus == 'allocated';
  }

  // Parse material allocation plan JSON
  Map<String, dynamic>? get materialAllocationPlanData {
    if (materialAllocationPlan == null || materialAllocationPlan!.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(materialAllocationPlan!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Get material allocation items list
  List<Map<String, dynamic>> get materialAllocationItems {
    final planData = materialAllocationPlanData;
    if (planData == null || planData['items'] == null) {
      return [];
    }
    try {
      return List<Map<String, dynamic>>.from(planData['items']);
    } catch (e) {
      return [];
    }
  }

  // Calculate total required items
  int get totalRequiredMaterials {
    return materialAllocationItems.fold(0, (sum, item) {
      return sum + (item['required_quantity'] as int? ?? 0);
    });
  }

  // Calculate total allocated items
  int get totalAllocatedMaterials {
    return materialAllocationItems.fold(0, (sum, item) {
      return sum + (item['allocated_quantity'] as int? ?? 0);
    });
  }

  // Calculate allocation completion percentage
  double get materialAllocationCompletionPercentage {
    if (totalRequiredMaterials == 0) return 0.0;
    return (totalAllocatedMaterials / totalRequiredMaterials) * 100;
  }

  bool get isMaterialAllocationComplete {
    return totalRequiredMaterials > 0 &&
        totalAllocatedMaterials >= totalRequiredMaterials;
  }

  // Helper methods for multiple payments management
  List<Map<String, dynamic>> get paymentHistory {
    if (amountPaymentsData == null || amountPaymentsData!.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(amountPaymentsData!);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  double get totalAmountPaid {
    return paymentHistory.fold(0.0, (sum, payment) {
      return sum + (payment['amount']?.toDouble() ?? 0.0);
    });
  }

  double get pendingAmount {
    final total = amountTotal ?? 0.0;
    final paid = totalAmountPaid;
    return total - paid;
  }

  bool get isPaymentComplete {
    return pendingAmount <= 0;
  }

  String get calculatedPaymentStatus {
    final paid = totalAmountPaid;
    final total = amountTotal ?? 0.0;

    if (total == 0) return 'pending';
    if (paid >= total) return 'completed';
    if (paid > 0) return 'partial';
    return 'pending';
  }

  bool get isApplicationPending => applicationStatus == 'pending';
  bool get isApplicationApproved => applicationStatus == 'approved';
  bool get isApplicationRejected => applicationStatus == 'rejected';

  bool get isFeasibilityPending => feasibilityStatus == 'pending';
  bool get isFeasible => feasibilityStatus == 'feasible';
  bool get isNotFeasible => feasibilityStatus == 'not_feasible';

  String get projectSummary {
    final kw = estimatedKw ?? this.kw;
    final cost = estimatedCost;

    if (kw != null && cost != null) {
      return '${kw}kW System - ₹${cost.toStringAsFixed(0)}';
    } else if (kw != null) {
      return '${kw}kW Solar System';
    } else if (cost != null) {
      return 'Project Value: ₹${cost.toStringAsFixed(0)}';
    } else {
      return 'Solar Installation Project';
    }
  }
}

extension StringExtension on String {
  String toTitleCase() {
    return split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : word,
        )
        .join(' ');
  }
}
