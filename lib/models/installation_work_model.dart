//
// Work types for installation
enum InstallationWorkType {
  structureWork('Structure Work'),
  panels('Panels'),
  inverterWiring('Inverter & Wiring'),
  earthing('Earthing'),
  lightningArrestor('Lightning Arrestor');

  const InstallationWorkType(this.displayName);
  final String displayName;

  static InstallationWorkType fromString(String value) {
    return InstallationWorkType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => InstallationWorkType.structureWork,
    );
  }
}

// Employee view work types
enum WorkType {
  solarPanelInstallation('Solar Panel Installation'),
  electricalWiring('Electrical Wiring'),
  inverterInstallation('Inverter Installation'),
  meterInstallation('Meter Installation'),
  systemTesting('System Testing'),
  finalInspection('Final Inspection'),
  customerTraining('Customer Training'),
  documentationReview('Documentation Review'),
  maintenanceCheckup('Maintenance Checkup'),
  troubleshooting('Troubleshooting');

  const WorkType(this.displayName);
  final String displayName;

  static WorkType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'solar_panel_installation':
      case 'solarpanelinstallation':
        return WorkType.solarPanelInstallation;
      case 'electrical_wiring':
      case 'electricalwiring':
        return WorkType.electricalWiring;
      case 'inverter_installation':
      case 'inverterinstallation':
        return WorkType.inverterInstallation;
      case 'meter_installation':
      case 'meterinstallation':
        return WorkType.meterInstallation;
      case 'system_testing':
      case 'systemtesting':
        return WorkType.systemTesting;
      case 'final_inspection':
      case 'finalinspection':
        return WorkType.finalInspection;
      case 'customer_training':
      case 'customertraining':
        return WorkType.customerTraining;
      case 'documentation_review':
      case 'documentationreview':
        return WorkType.documentationReview;
      case 'maintenance_checkup':
      case 'maintenancecheckup':
        return WorkType.maintenanceCheckup;
      case 'troubleshooting':
        return WorkType.troubleshooting;
      default:
        return WorkType.solarPanelInstallation;
    }
  }

  String get databaseValue {
    switch (this) {
      case WorkType.solarPanelInstallation:
        return 'solar_panel_installation';
      case WorkType.electricalWiring:
        return 'electrical_wiring';
      case WorkType.inverterInstallation:
        return 'inverter_installation';
      case WorkType.meterInstallation:
        return 'meter_installation';
      case WorkType.systemTesting:
        return 'system_testing';
      case WorkType.finalInspection:
        return 'final_inspection';
      case WorkType.customerTraining:
        return 'customer_training';
      case WorkType.documentationReview:
        return 'documentation_review';
      case WorkType.maintenanceCheckup:
        return 'maintenance_checkup';
      case WorkType.troubleshooting:
        return 'troubleshooting';
    }
  }
}

// Work status
enum WorkStatus {
  notStarted('Not Started'),
  inProgress('In Progress'),
  awaitingCompletion('Awaiting Completion'),
  completed('Completed'),
  verified('Verified'),
  acknowledged('Acknowledged'),
  approved('Approved');

  const WorkStatus(this.displayName);
  final String displayName;

  static WorkStatus fromString(String value) {
    return WorkStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => WorkStatus.notStarted,
    );
  }
}

// Individual employee work session
class WorkSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final LocationVerification startLocation;
  final LocationVerification? endLocation;
  final List<LocationVerification> periodicChecks;

  WorkSession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.notes,
    required this.startLocation,
    this.endLocation,
    this.periodicChecks = const [],
  });

  factory WorkSession.fromJson(Map<String, dynamic> json) {
    return WorkSession(
      id: json['id'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      notes: json['notes'],
      startLocation: LocationVerification.fromJson(json['start_location']),
      endLocation: json['end_location'] != null
          ? LocationVerification.fromJson(json['end_location'])
          : null,
      periodicChecks:
          (json['periodic_checks'] as List<dynamic>?)
              ?.map((check) => LocationVerification.fromJson(check))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'notes': notes,
      'start_location': startLocation.toJson(),
      'end_location': endLocation?.toJson(),
      'periodic_checks': periodicChecks.map((check) => check.toJson()).toList(),
    };
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
}

// Employee work log for each work type
class EmployeeWorkLog {
  final String employeeId;
  final String employeeName;
  final List<WorkSession> sessions;
  final String? individualNotes;
  final bool hasCompleted;
  final bool isCurrentlyAtSite;
  final DateTime? lastLocationCheck;
  final List<LocationVerification> locationHistory;

  EmployeeWorkLog({
    required this.employeeId,
    required this.employeeName,
    this.sessions = const [],
    this.individualNotes,
    this.hasCompleted = false,
    this.isCurrentlyAtSite = false,
    this.lastLocationCheck,
    this.locationHistory = const [],
  });

  factory EmployeeWorkLog.fromJson(Map<String, dynamic> json) {
    return EmployeeWorkLog(
      employeeId: json['employee_id'] ?? '',
      employeeName: json['employee_name'] ?? '',
      sessions:
          (json['sessions'] as List<dynamic>?)
              ?.map((session) => WorkSession.fromJson(session))
              .toList() ??
          [],
      individualNotes: json['individual_notes'],
      hasCompleted: json['has_completed'] ?? false,
      isCurrentlyAtSite: json['is_currently_at_site'] ?? false,
      lastLocationCheck: json['last_location_check'] != null
          ? DateTime.parse(json['last_location_check'])
          : null,
      locationHistory:
          (json['location_history'] as List<dynamic>?)
              ?.map((location) => LocationVerification.fromJson(location))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'sessions': sessions.map((session) => session.toJson()).toList(),
      'individual_notes': individualNotes,
      'has_completed': hasCompleted,
      'is_currently_at_site': isCurrentlyAtSite,
      'last_location_check': lastLocationCheck?.toIso8601String(),
      'location_history': locationHistory
          .map((location) => location.toJson())
          .toList(),
    };
  }

  double get totalHours {
    return sessions.fold(
      0.0,
      (total, session) => total + session.duration.inMinutes / 60.0,
    );
  }

  bool get isCurrentlyWorking {
    return sessions.any((session) => session.endTime == null);
  }
}

// Location verification
class LocationVerification {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isWithinSite;
  final double distanceFromSite;
  final String? reason;

  LocationVerification({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isWithinSite,
    required this.distanceFromSite,
    this.reason,
  });

  factory LocationVerification.fromJson(Map<String, dynamic> json) {
    return LocationVerification(
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      accuracy: json['accuracy']?.toDouble() ?? 0.0,
      isWithinSite: json['is_within_site'] ?? false,
      distanceFromSite: json['distance_from_site']?.toDouble() ?? 0.0,
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'is_within_site': isWithinSite,
      'distance_from_site': distanceFromSite,
      'reason': reason,
    };
  }
}

// Material usage for work
class MaterialUsage {
  final String materialId;
  final String materialName;
  final int allocatedQuantity;
  final int usedQuantity;
  final String unit;
  final String? notes;

  MaterialUsage({
    required this.materialId,
    required this.materialName,
    required this.allocatedQuantity,
    required this.usedQuantity,
    required this.unit,
    this.notes,
  });

  factory MaterialUsage.fromJson(Map<String, dynamic> json) {
    return MaterialUsage(
      materialId: json['material_id'] ?? '',
      materialName: json['material_name'] ?? '',
      allocatedQuantity: json['allocated_quantity'] ?? 0,
      usedQuantity: json['used_quantity'] ?? 0,
      unit: json['unit'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'material_name': materialName,
      'allocated_quantity': allocatedQuantity,
      'used_quantity': usedQuantity,
      'unit': unit,
      'notes': notes,
    };
  }

  int get variance => usedQuantity - allocatedQuantity;
  bool get isOverUsed => variance > 0;
  bool get isUnderUsed => variance < 0;
  bool get isExactUsage => variance == 0;
}

// Main installation work item
class InstallationWorkItem {
  final String id;
  final String customerId;
  final InstallationWorkType workType;

  // Location data
  final double siteLatitude;
  final double siteLongitude;
  final String siteAddress;

  // Team structure
  final String leadEmployeeId;
  final String leadEmployeeName;
  final List<String> teamMemberIds;
  final List<String> teamMemberNames;

  // Work status and timing
  final WorkStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Employee logs and material usage
  final Map<String, EmployeeWorkLog> employeeLogs;
  final List<MaterialUsage> materialUsage;

  // Work documentation
  final String? workNotes;
  final List<String> workPhotos;

  // Verification chain
  final String verificationStatus; // pending, verified, rejected
  final String? verifiedBy; // Lead ID
  final DateTime? verifiedAt;
  final String? acknowledgedBy; // Manager ID
  final DateTime? acknowledgedAt;
  final String? approvedBy; // Director ID
  final DateTime? approvedAt;
  final String? verificationNotes;

  InstallationWorkItem({
    required this.id,
    required this.customerId,
    required this.workType,
    required this.siteLatitude,
    required this.siteLongitude,
    required this.siteAddress,
    required this.leadEmployeeId,
    required this.leadEmployeeName,
    this.teamMemberIds = const [],
    this.teamMemberNames = const [],
    this.status = WorkStatus.notStarted,
    this.startTime,
    this.endTime,
    required this.createdAt,
    required this.updatedAt,
    this.employeeLogs = const {},
    this.materialUsage = const [],
    this.workNotes,
    this.workPhotos = const [],
    this.verificationStatus = 'pending',
    this.verifiedBy,
    this.verifiedAt,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.approvedBy,
    this.approvedAt,
    this.verificationNotes,
  });

  factory InstallationWorkItem.fromJson(Map<String, dynamic> json) {
    // Handle missing timestamps
    final now = DateTime.now();
    final createdAtString = json['created_at'] ?? now.toIso8601String();
    final updatedAtString = json['updated_at'] ?? now.toIso8601String();

    return InstallationWorkItem(
      id: json['id']?.toString() ?? json['work_item_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      workType: InstallationWorkType.fromString(
        json['work_type']?.toString() ?? '',
      ),
      siteLatitude: (json['site_latitude'] as num?)?.toDouble() ?? 0.0,
      siteLongitude: (json['site_longitude'] as num?)?.toDouble() ?? 0.0,
      siteAddress:
          json['site_address']?.toString() ??
          json['customer_address']?.toString() ??
          '',
      leadEmployeeId: json['lead_employee_id']?.toString() ?? '',
      leadEmployeeName: json['lead_employee_name']?.toString() ?? '',
      teamMemberIds: List<String>.from(
        json['team_member_ids'] ?? json['assigned_employee_ids'] ?? [],
      ),
      teamMemberNames: List<String>.from(
        json['team_member_names'] ?? json['assigned_employee_names'] ?? [],
      ),
      status: WorkStatus.fromString(json['status']?.toString() ?? ''),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      createdAt: DateTime.parse(createdAtString),
      updatedAt: DateTime.parse(updatedAtString),
      employeeLogs: Map<String, EmployeeWorkLog>.from(
        (json['employee_logs'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, EmployeeWorkLog.fromJson(value)),
            ) ??
            {},
      ),
      materialUsage:
          (json['material_usage'] as List<dynamic>?)
              ?.map((material) => MaterialUsage.fromJson(material))
              .toList() ??
          [],
      workNotes: json['work_notes']?.toString(),
      workPhotos: List<String>.from(json['work_photos'] ?? []),
      verificationStatus: json['verification_status']?.toString() ?? 'pending',
      verifiedBy: json['verified_by']?.toString(),
      verifiedAt: json['verified_date'] != null || json['verified_at'] != null
          ? DateTime.parse(json['verified_date'] ?? json['verified_at'])
          : null,
      acknowledgedBy: json['acknowledged_by']?.toString(),
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'])
          : null,
      approvedBy: json['approved_by']?.toString(),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      verificationNotes: json['verification_notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'work_type': workType.name,
      'site_latitude': siteLatitude,
      'site_longitude': siteLongitude,
      'site_address': siteAddress,
      'lead_employee_id': leadEmployeeId,
      'lead_employee_name': leadEmployeeName,
      'team_member_ids': teamMemberIds,
      'team_member_names': teamMemberNames,
      'status': status.name,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'employee_logs': employeeLogs.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'material_usage': materialUsage
          .map((material) => material.toJson())
          .toList(),
      'work_notes': workNotes,
      'work_photos': workPhotos,
      'verification_status': verificationStatus,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
      'acknowledged_by': acknowledgedBy,
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'verification_notes': verificationNotes,
    };
  }

  // Employee-specific properties for compatibility
  int get progressPercentage {
    switch (status) {
      case WorkStatus.notStarted:
        return 0;
      case WorkStatus.inProgress:
        return employeeLogs.isEmpty ? 25 : 50;
      case WorkStatus.awaitingCompletion:
        return 75;
      case WorkStatus.completed:
      case WorkStatus.verified:
      case WorkStatus.acknowledged:
      case WorkStatus.approved:
        return 100;
    }
  }

  double? get estimatedHours {
    // Estimate based on work type
    switch (workType) {
      case InstallationWorkType.structureWork:
        return 8.0;
      case InstallationWorkType.panels:
        return 6.0;
      case InstallationWorkType.inverterWiring:
        return 4.0;
      case InstallationWorkType.earthing:
        return 2.0;
      case InstallationWorkType.lightningArrestor:
        return 2.0;
    }
  }

  double? get actualHours => totalWorkHours > 0 ? totalWorkHours : null;

  String get installationProjectId =>
      customerId; // Using customerId as project reference

  DateTime? get scheduledDate => startTime;

  String get assignedEmployeeId => leadEmployeeId;
  String? get assignedEmployeeName => leadEmployeeName;

  // Add copyWith method
  InstallationWorkItem copyWith({
    String? id,
    String? customerId,
    InstallationWorkType? workType,
    double? siteLatitude,
    double? siteLongitude,
    String? siteAddress,
    String? leadEmployeeId,
    String? leadEmployeeName,
    List<String>? teamMemberIds,
    List<String>? teamMemberNames,
    WorkStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, EmployeeWorkLog>? employeeLogs,
    List<MaterialUsage>? materialUsage,
    String? workNotes,
    List<String>? workPhotos,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
    String? approvedBy,
    DateTime? approvedAt,
    String? verificationNotes,
  }) {
    return InstallationWorkItem(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      workType: workType ?? this.workType,
      siteLatitude: siteLatitude ?? this.siteLatitude,
      siteLongitude: siteLongitude ?? this.siteLongitude,
      siteAddress: siteAddress ?? this.siteAddress,
      leadEmployeeId: leadEmployeeId ?? this.leadEmployeeId,
      leadEmployeeName: leadEmployeeName ?? this.leadEmployeeName,
      teamMemberIds: teamMemberIds ?? this.teamMemberIds,
      teamMemberNames: teamMemberNames ?? this.teamMemberNames,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      employeeLogs: employeeLogs ?? this.employeeLogs,
      materialUsage: materialUsage ?? this.materialUsage,
      workNotes: workNotes ?? this.workNotes,
      workPhotos: workPhotos ?? this.workPhotos,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      verificationNotes: verificationNotes ?? this.verificationNotes,
    );
  }

  // Helper methods
  List<String> get allAssignedEmployeeIds => [leadEmployeeId, ...teamMemberIds];

  int get totalAssignedEmployees => allAssignedEmployeeIds.length;

  int get employeesAtSite =>
      employeeLogs.values.where((log) => log.isCurrentlyAtSite).length;

  int get employeesWorking =>
      employeeLogs.values.where((log) => log.isCurrentlyWorking).length;

  bool get allEmployeesCompleted =>
      employeeLogs.values.every((log) => log.hasCompleted);

  double get totalWorkHours =>
      employeeLogs.values.fold(0.0, (total, log) => total + log.totalHours);

  bool get hasMaterialVariance =>
      materialUsage.any((material) => material.variance != 0);

  bool get isReadyForVerification =>
      status == WorkStatus.completed &&
      allEmployeesCompleted &&
      materialUsage.isNotEmpty;

  bool get isVerified => status.index >= WorkStatus.verified.index;
  bool get isAcknowledged => status.index >= WorkStatus.acknowledged.index;
  bool get isApproved => status.index >= WorkStatus.approved.index;
}

// Installation project containing all work items for a customer
class InstallationProject {
  final String projectId;
  final String customerId;
  final String customerName;
  final String customerAddress;
  final double siteLatitude;
  final double siteLongitude;
  final DateTime? scheduledStartDate;
  final List<InstallationWorkItem> workItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  InstallationProject({
    required this.projectId,
    required this.customerId,
    required this.customerName,
    required this.customerAddress,
    required this.siteLatitude,
    required this.siteLongitude,
    this.scheduledStartDate,
    this.workItems = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstallationProject.fromJson(Map<String, dynamic> json) {
    print('Creating InstallationProject from JSON: $json');

    // Handle both direct table data and view data
    final now = DateTime.now();
    final createdAtString =
        json['created_at'] ?? json['assigned_date'] ?? now.toIso8601String();
    final updatedAtString =
        json['updated_at'] ?? json['assigned_date'] ?? now.toIso8601String();

    // Safely parse work items
    List<InstallationWorkItem> workItems = [];
    final workItemsData = json['work_items'];
    if (workItemsData != null && workItemsData is List) {
      try {
        workItems = workItemsData
            .map(
              (item) =>
                  InstallationWorkItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } catch (e) {
        print('Error parsing work items: $e');
      }
    }

    try {
      return InstallationProject(
        projectId:
            json['project_id']?.toString() ?? json['id']?.toString() ?? '',
        customerId: json['customer_id']?.toString() ?? '',
        customerName: json['customer_name']?.toString() ?? '',
        customerAddress: json['customer_address']?.toString() ?? '',
        siteLatitude: (json['site_latitude'] as num?)?.toDouble() ?? 0.0,
        siteLongitude: (json['site_longitude'] as num?)?.toDouble() ?? 0.0,
        scheduledStartDate: json['scheduled_start_date'] != null
            ? DateTime.parse(json['scheduled_start_date'])
            : null,
        workItems: workItems,
        createdAt: DateTime.parse(createdAtString),
        updatedAt: DateTime.parse(updatedAtString),
      );
    } catch (e) {
      print('Error creating InstallationProject: $e');
      print('Problematic field values:');
      print(
        '  projectId: ${json['project_id']} (${json['project_id'].runtimeType})',
      );
      print(
        '  customerId: ${json['customer_id']} (${json['customer_id'].runtimeType})',
      );
      print(
        '  customerName: ${json['customer_name']} (${json['customer_name'].runtimeType})',
      );
      print(
        '  customerAddress: ${json['customer_address']} (${json['customer_address'].runtimeType})',
      );
      print('  createdAtString: $createdAtString');
      print('  updatedAtString: $updatedAtString');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'site_latitude': siteLatitude,
      'site_longitude': siteLongitude,
      'scheduled_start_date': scheduledStartDate?.toIso8601String(),
      'work_items': workItems.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  int get totalWorkItems => workItems.length;
  int get completedWorkItems =>
      workItems.where((item) => item.status == WorkStatus.completed).length;
  int get verifiedWorkItems =>
      workItems.where((item) => item.isVerified).length;
  int get approvedWorkItems =>
      workItems.where((item) => item.isApproved).length;

  double get progressPercentage =>
      totalWorkItems > 0 ? (completedWorkItems / totalWorkItems) * 100 : 0.0;

  bool get isProjectCompleted =>
      workItems.isNotEmpty && workItems.every((item) => item.isApproved);

  WorkStatus get overallStatus {
    if (workItems.isEmpty) return WorkStatus.notStarted;
    if (isProjectCompleted) return WorkStatus.approved;
    if (workItems.any((item) => item.status == WorkStatus.inProgress))
      return WorkStatus.inProgress;
    if (workItems.any((item) => item.status == WorkStatus.completed))
      return WorkStatus.completed;
    return WorkStatus.notStarted;
  }
}
