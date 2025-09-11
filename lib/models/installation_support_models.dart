// Supporting classes and enums for Installation Models V2

/// Project Status Enum
enum ProjectStatus {
  planning('planning'),
  scheduled('scheduled'),
  inProgress('in_progress'),
  qualityCheck('quality_check'),
  customerReview('customer_review'),
  completed('completed'),
  onHold('on_hold'),
  cancelled('cancelled');

  const ProjectStatus(this.value);
  final String value;

  static ProjectStatus fromString(String value) {
    return ProjectStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProjectStatus.planning,
    );
  }

  String get displayName {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.scheduled:
        return 'Scheduled';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.qualityCheck:
        return 'Quality Check';
      case ProjectStatus.customerReview:
        return 'Customer Review';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive {
    return this == ProjectStatus.inProgress || 
           this == ProjectStatus.scheduled ||
           this == ProjectStatus.qualityCheck;
  }

  bool get isCompleted {
    return this == ProjectStatus.completed;
  }
}

/// Project Priority Enum
enum ProjectPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  const ProjectPriority(this.value);
  final String value;

  static ProjectPriority fromString(String value) {
    return ProjectPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => ProjectPriority.medium,
    );
  }

  String get displayName {
    switch (this) {
      case ProjectPriority.low:
        return 'Low';
      case ProjectPriority.medium:
        return 'Medium';
      case ProjectPriority.high:
        return 'High';
      case ProjectPriority.urgent:
        return 'Urgent';
    }
  }

  int get sortOrder {
    switch (this) {
      case ProjectPriority.urgent:
        return 4;
      case ProjectPriority.high:
        return 3;
      case ProjectPriority.medium:
        return 2;
      case ProjectPriority.low:
        return 1;
    }
  }
}

/// Phase Status Enum
enum PhaseStatus {
  notStarted('not_started'),
  planned('planned'),
  inProgress('in_progress'),
  qualityCheck('quality_check'),
  reworkRequired('rework_required'),
  completed('completed'),
  onHold('on_hold'),
  cancelled('cancelled');

  const PhaseStatus(this.value);
  final String value;

  static PhaseStatus fromString(String value) {
    return PhaseStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PhaseStatus.notStarted,
    );
  }

  String get displayName {
    switch (this) {
      case PhaseStatus.notStarted:
        return 'Not Started';
      case PhaseStatus.planned:
        return 'Planned';
      case PhaseStatus.inProgress:
        return 'In Progress';
      case PhaseStatus.qualityCheck:
        return 'Quality Check';
      case PhaseStatus.reworkRequired:
        return 'Rework Required';
      case PhaseStatus.completed:
        return 'Completed';
      case PhaseStatus.onHold:
        return 'On Hold';
      case PhaseStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get canStart {
    return this == PhaseStatus.notStarted || this == PhaseStatus.planned;
  }

  bool get isActive {
    return this == PhaseStatus.inProgress || this == PhaseStatus.qualityCheck;
  }

  bool get isCompleted {
    return this == PhaseStatus.completed;
  }
}

/// Team Type Enum
enum TeamType {
  general('general'),
  specialized('specialized'),
  emergency('emergency'),
  qualityControl('quality_control');

  const TeamType(this.value);
  final String value;

  static TeamType fromString(String value) {
    return TeamType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TeamType.general,
    );
  }

  String get displayName {
    switch (this) {
      case TeamType.general:
        return 'General';
      case TeamType.specialized:
        return 'Specialized';
      case TeamType.emergency:
        return 'Emergency';
      case TeamType.qualityControl:
        return 'Quality Control';
    }
  }
}

/// Team Availability Status Enum
enum TeamAvailabilityStatus {
  available('available'),
  busy('busy'),
  break('break'),
  offline('offline'),
  emergency('emergency');

  const TeamAvailabilityStatus(this.value);
  final String value;

  static TeamAvailabilityStatus fromString(String value) {
    return TeamAvailabilityStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TeamAvailabilityStatus.available,
    );
  }

  String get displayName {
    switch (this) {
      case TeamAvailabilityStatus.available:
        return 'Available';
      case TeamAvailabilityStatus.busy:
        return 'Busy';
      case TeamAvailabilityStatus.break:
        return 'On Break';
      case TeamAvailabilityStatus.offline:
        return 'Offline';
      case TeamAvailabilityStatus.emergency:
        return 'Emergency';
    }
  }

  bool get isAvailable {
    return this == TeamAvailabilityStatus.available;
  }
}

/// Checkpoint Type Enum
enum CheckpointType {
  quality('quality'),
  safety('safety'),
  milestone('milestone'),
  customerApproval('customer_approval'),
  regulatory('regulatory');

  const CheckpointType(this.value);
  final String value;

  static CheckpointType fromString(String value) {
    return CheckpointType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CheckpointType.quality,
    );
  }

  String get displayName {
    switch (this) {
      case CheckpointType.quality:
        return 'Quality';
      case CheckpointType.safety:
        return 'Safety';
      case CheckpointType.milestone:
        return 'Milestone';
      case CheckpointType.customerApproval:
        return 'Customer Approval';
      case CheckpointType.regulatory:
        return 'Regulatory';
    }
  }
}

/// Checkpoint Status Enum
enum CheckpointStatus {
  pending('pending'),
  inReview('in_review'),
  passed('passed'),
  failed('failed'),
  waived('waived');

  const CheckpointStatus(this.value);
  final String value;

  static CheckpointStatus fromString(String value) {
    return CheckpointStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CheckpointStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case CheckpointStatus.pending:
        return 'Pending';
      case CheckpointStatus.inReview:
        return 'In Review';
      case CheckpointStatus.passed:
        return 'Passed';
      case CheckpointStatus.failed:
        return 'Failed';
      case CheckpointStatus.waived:
        return 'Waived';
    }
  }

  bool get isPassed {
    return this == CheckpointStatus.passed || this == CheckpointStatus.waived;
  }
}

/// Resource Type Enum
enum ResourceType {
  material('material'),
  equipment('equipment'),
  tool('tool'),
  vehicle('vehicle'),
  consumable('consumable');

  const ResourceType(this.value);
  final String value;

  static ResourceType fromString(String value) {
    return ResourceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ResourceType.material,
    );
  }

  String get displayName {
    switch (this) {
      case ResourceType.material:
        return 'Material';
      case ResourceType.equipment:
        return 'Equipment';
      case ResourceType.tool:
        return 'Tool';
      case ResourceType.vehicle:
        return 'Vehicle';
      case ResourceType.consumable:
        return 'Consumable';
    }
  }
}

/// Resource Status Enum
enum ResourceStatus {
  required('required'),
  ordered('ordered'),
  allocated('allocated'),
  delivered('delivered'),
  inUse('in_use'),
  returned('returned'),
  consumed('consumed');

  const ResourceStatus(this.value);
  final String value;

  static ResourceStatus fromString(String value) {
    return ResourceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ResourceStatus.required,
    );
  }

  String get displayName {
    switch (this) {
      case ResourceStatus.required:
        return 'Required';
      case ResourceStatus.ordered:
        return 'Ordered';
      case ResourceStatus.allocated:
        return 'Allocated';
      case ResourceStatus.delivered:
        return 'Delivered';
      case ResourceStatus.inUse:
        return 'In Use';
      case ResourceStatus.returned:
        return 'Returned';
      case ResourceStatus.consumed:
        return 'Consumed';
    }
  }
}

/// Activity Type Enum
enum ActivityType {
  projectStarted('project_started'),
  projectCompleted('project_completed'),
  phaseStarted('phase_started'),
  phaseCompleted('phase_completed'),
  checkpointPassed('checkpoint_passed'),
  checkpointFailed('checkpoint_failed'),
  teamAssigned('team_assigned'),
  teamReassigned('team_reassigned'),
  materialDelivered('material_delivered'),
  materialUsed('material_used'),
  issueReported('issue_reported'),
  issueResolved('issue_resolved'),
  customerCommunication('customer_communication'),
  safetyIncident('safety_incident'),
  qualityReview('quality_review'),
  locationCheck('location_check'),
  breakStarted('break_started'),
  breakEnded('break_ended'),
  shiftStarted('shift_started'),
  shiftEnded('shift_ended');

  const ActivityType(this.value);
  final String value;

  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ActivityType.locationCheck,
    );
  }

  String get displayName {
    switch (this) {
      case ActivityType.projectStarted:
        return 'Project Started';
      case ActivityType.projectCompleted:
        return 'Project Completed';
      case ActivityType.phaseStarted:
        return 'Phase Started';
      case ActivityType.phaseCompleted:
        return 'Phase Completed';
      case ActivityType.checkpointPassed:
        return 'Checkpoint Passed';
      case ActivityType.checkpointFailed:
        return 'Checkpoint Failed';
      case ActivityType.teamAssigned:
        return 'Team Assigned';
      case ActivityType.teamReassigned:
        return 'Team Reassigned';
      case ActivityType.materialDelivered:
        return 'Material Delivered';
      case ActivityType.materialUsed:
        return 'Material Used';
      case ActivityType.issueReported:
        return 'Issue Reported';
      case ActivityType.issueResolved:
        return 'Issue Resolved';
      case ActivityType.customerCommunication:
        return 'Customer Communication';
      case ActivityType.safetyIncident:
        return 'Safety Incident';
      case ActivityType.qualityReview:
        return 'Quality Review';
      case ActivityType.locationCheck:
        return 'Location Check';
      case ActivityType.breakStarted:
        return 'Break Started';
      case ActivityType.breakEnded:
        return 'Break Ended';
      case ActivityType.shiftStarted:
        return 'Shift Started';
      case ActivityType.shiftEnded:
        return 'Shift Ended';
    }
  }

  bool get isMilestone {
    return this == ActivityType.projectStarted ||
           this == ActivityType.projectCompleted ||
           this == ActivityType.phaseStarted ||
           this == ActivityType.phaseCompleted;
  }
}

/// Supporting Data Classes

/// Project Attachment
class ProjectAttachment {
  final String id;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String? description;
  final DateTime uploadedAt;
  final String uploadedBy;

  ProjectAttachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    this.description,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory ProjectAttachment.fromJson(Map<String, dynamic> json) {
    return ProjectAttachment(
      id: json['id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      description: json['description'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      uploadedBy: json['uploaded_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'description': description,
      'uploaded_at': uploadedAt.toIso8601String(),
      'uploaded_by': uploadedBy,
    };
  }
}

/// Team Member
class TeamMember {
  final String userId;
  final String name;
  final String role;
  final List<String> skills;
  final double proficiencyLevel;
  final bool isLead;
  final String? contactNumber;
  final String? email;

  TeamMember({
    required this.userId,
    required this.name,
    required this.role,
    this.skills = const [],
    this.proficiencyLevel = 0.0,
    this.isLead = false,
    this.contactNumber,
    this.email,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      skills: (json['skills'] as List?)?.cast<String>() ?? [],
      proficiencyLevel: (json['proficiency_level'] as num?)?.toDouble() ?? 0.0,
      isLead: json['is_lead'] as bool? ?? false,
      contactNumber: json['contact_number'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'role': role,
      'skills': skills,
      'proficiency_level': proficiencyLevel,
      'is_lead': isLead,
      'contact_number': contactNumber,
      'email': email,
    };
  }
}

/// Quality Checkpoint
class QualityCheckpoint {
  final String checkpointCode;
  final String checkpointName;
  final String? description;
  final CheckpointType type;
  final bool isMandatory;
  final bool requiresPhoto;
  final bool requiresSignature;
  final bool requiresMeasurement;
  final List<String> acceptanceCriteria;
  final CheckpointStatus status;
  final double? resultScore;
  final String? resultNotes;
  final List<String> failureReasons;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  QualityCheckpoint({
    required this.checkpointCode,
    required this.checkpointName,
    this.description,
    this.type = CheckpointType.quality,
    this.isMandatory = true,
    this.requiresPhoto = false,
    this.requiresSignature = false,
    this.requiresMeasurement = false,
    this.acceptanceCriteria = const [],
    this.status = CheckpointStatus.pending,
    this.resultScore,
    this.resultNotes,
    this.failureReasons = const [],
    this.verifiedBy,
    this.verifiedAt,
  });

  factory QualityCheckpoint.fromJson(Map<String, dynamic> json) {
    return QualityCheckpoint(
      checkpointCode: json['checkpoint_code'] as String,
      checkpointName: json['checkpoint_name'] as String,
      description: json['description'] as String?,
      type: CheckpointType.fromString(json['type'] as String? ?? 'quality'),
      isMandatory: json['is_mandatory'] as bool? ?? true,
      requiresPhoto: json['requires_photo'] as bool? ?? false,
      requiresSignature: json['requires_signature'] as bool? ?? false,
      requiresMeasurement: json['requires_measurement'] as bool? ?? false,
      acceptanceCriteria: (json['acceptance_criteria'] as List?)?.cast<String>() ?? [],
      status: CheckpointStatus.fromString(json['status'] as String? ?? 'pending'),
      resultScore: (json['result_score'] as num?)?.toDouble(),
      resultNotes: json['result_notes'] as String?,
      failureReasons: (json['failure_reasons'] as List?)?.cast<String>() ?? [],
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkpoint_code': checkpointCode,
      'checkpoint_name': checkpointName,
      'description': description,
      'type': type.value,
      'is_mandatory': isMandatory,
      'requires_photo': requiresPhoto,
      'requires_signature': requiresSignature,
      'requires_measurement': requiresMeasurement,
      'acceptance_criteria': acceptanceCriteria,
      'status': status.value,
      'result_score': resultScore,
      'result_notes': resultNotes,
      'failure_reasons': failureReasons,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}

/// Material Requirement
class MaterialRequirement {
  final String materialCode;
  final String materialName;
  final double requiredQuantity;
  final String unit;
  final double? unitCost;
  final String? supplier;
  final String? specifications;

  MaterialRequirement({
    required this.materialCode,
    required this.materialName,
    required this.requiredQuantity,
    required this.unit,
    this.unitCost,
    this.supplier,
    this.specifications,
  });

  factory MaterialRequirement.fromJson(Map<String, dynamic> json) {
    return MaterialRequirement(
      materialCode: json['material_code'] as String,
      materialName: json['material_name'] as String,
      requiredQuantity: (json['required_quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      unitCost: (json['unit_cost'] as num?)?.toDouble(),
      supplier: json['supplier'] as String?,
      specifications: json['specifications'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_code': materialCode,
      'material_name': materialName,
      'required_quantity': requiredQuantity,
      'unit': unit,
      'unit_cost': unitCost,
      'supplier': supplier,
      'specifications': specifications,
    };
  }
}

/// Material Allocation
class MaterialAllocation {
  final String materialCode;
  final double allocatedQuantity;
  final DateTime allocationDate;
  final String allocatedBy;
  final String? batchNumber;
  final String? storageLocation;

  MaterialAllocation({
    required this.materialCode,
    required this.allocatedQuantity,
    required this.allocationDate,
    required this.allocatedBy,
    this.batchNumber,
    this.storageLocation,
  });

  factory MaterialAllocation.fromJson(Map<String, dynamic> json) {
    return MaterialAllocation(
      materialCode: json['material_code'] as String,
      allocatedQuantity: (json['allocated_quantity'] as num).toDouble(),
      allocationDate: DateTime.parse(json['allocation_date'] as String),
      allocatedBy: json['allocated_by'] as String,
      batchNumber: json['batch_number'] as String?,
      storageLocation: json['storage_location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_code': materialCode,
      'allocated_quantity': allocatedQuantity,
      'allocation_date': allocationDate.toIso8601String(),
      'allocated_by': allocatedBy,
      'batch_number': batchNumber,
      'storage_location': storageLocation,
    };
  }
}

/// Material Usage
class MaterialUsage {
  final String materialCode;
  final double usedQuantity;
  final DateTime usageDate;
  final String usedBy;
  final String? usageNotes;
  final String? wasteQuantity;

  MaterialUsage({
    required this.materialCode,
    required this.usedQuantity,
    required this.usageDate,
    required this.usedBy,
    this.usageNotes,
    this.wasteQuantity,
  });

  factory MaterialUsage.fromJson(Map<String, dynamic> json) {
    return MaterialUsage(
      materialCode: json['material_code'] as String,
      usedQuantity: (json['used_quantity'] as num).toDouble(),
      usageDate: DateTime.parse(json['usage_date'] as String),
      usedBy: json['used_by'] as String,
      usageNotes: json['usage_notes'] as String?,
      wasteQuantity: json['waste_quantity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_code': materialCode,
      'used_quantity': usedQuantity,
      'usage_date': usageDate.toIso8601String(),
      'used_by': usedBy,
      'usage_notes': usageNotes,
      'waste_quantity': wasteQuantity,
    };
  }
}

/// Phase Photo
class PhasePhoto {
  final String id;
  final String photoUrl;
  final String? caption;
  final String? tags;
  final DateTime capturedAt;
  final String capturedBy;
  final double? latitude;
  final double? longitude;

  PhasePhoto({
    required this.id,
    required this.photoUrl,
    this.caption,
    this.tags,
    required this.capturedAt,
    required this.capturedBy,
    this.latitude,
    this.longitude,
  });

  factory PhasePhoto.fromJson(Map<String, dynamic> json) {
    return PhasePhoto(
      id: json['id'] as String,
      photoUrl: json['photo_url'] as String,
      caption: json['caption'] as String?,
      tags: json['tags'] as String?,
      capturedAt: DateTime.parse(json['captured_at'] as String),
      capturedBy: json['captured_by'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photo_url': photoUrl,
      'caption': caption,
      'tags': tags,
      'captured_at': capturedAt.toIso8601String(),
      'captured_by': capturedBy,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// Location
class Location {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime? timestamp;
  final double? accuracy;

  Location({
    required this.latitude,
    required this.longitude,
    this.address,
    this.timestamp,
    this.accuracy,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String) 
          : null,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp?.toIso8601String(),
      'accuracy': accuracy,
    };
  }
}

/// Installation Activity Model
class InstallationActivity {
  final String id;
  final String projectId;
  final String? phaseId;
  final String? teamId;
  final ActivityType activityType;
  final String activityTitle;
  final String? activityDescription;
  final String performedBy;
  final String? affectedUserId;
  final Location? activityLocation;
  final DateTime timestamp;
  final int? durationMinutes;
  final Map<String, dynamic> activityContext;
  final List<String> attachments;
  final List<String> tags;
  final String activityStatus;
  final bool isMilestone;
  final String visibility;

  InstallationActivity({
    required this.id,
    required this.projectId,
    this.phaseId,
    this.teamId,
    required this.activityType,
    required this.activityTitle,
    this.activityDescription,
    required this.performedBy,
    this.affectedUserId,
    this.activityLocation,
    required this.timestamp,
    this.durationMinutes,
    this.activityContext = const {},
    this.attachments = const [],
    this.tags = const [],
    this.activityStatus = 'completed',
    this.isMilestone = false,
    this.visibility = 'team',
  });

  factory InstallationActivity.fromJson(Map<String, dynamic> json) {
    return InstallationActivity(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      phaseId: json['phase_id'] as String?,
      teamId: json['team_id'] as String?,
      activityType: ActivityType.fromString(json['activity_type'] as String),
      activityTitle: json['activity_title'] as String,
      activityDescription: json['activity_description'] as String?,
      performedBy: json['performed_by'] as String,
      affectedUserId: json['affected_user_id'] as String?,
      activityLocation: json['activity_location'] != null 
          ? Location.fromJson(json['activity_location']) 
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      durationMinutes: json['duration_minutes'] as int?,
      activityContext: json['activity_context'] as Map<String, dynamic>? ?? {},
      attachments: (json['attachments'] as List?)?.cast<String>() ?? [],
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      activityStatus: json['activity_status'] as String? ?? 'completed',
      isMilestone: json['is_milestone'] as bool? ?? false,
      visibility: json['visibility'] as String? ?? 'team',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'phase_id': phaseId,
      'team_id': teamId,
      'activity_type': activityType.value,
      'activity_title': activityTitle,
      'activity_description': activityDescription,
      'performed_by': performedBy,
      'affected_user_id': affectedUserId,
      'activity_location': activityLocation?.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'duration_minutes': durationMinutes,
      'activity_context': activityContext,
      'attachments': attachments,
      'tags': tags,
      'activity_status': activityStatus,
      'is_milestone': isMilestone,
      'visibility': visibility,
    };
  }
}

/// Installation Verification Status Enum
enum InstallationVerificationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  underReview('under_review');

  const InstallationVerificationStatus(this.value);
  final String value;

  static InstallationVerificationStatus fromString(String value) {
    return InstallationVerificationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InstallationVerificationStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case InstallationVerificationStatus.pending:
        return 'Pending';
      case InstallationVerificationStatus.approved:
        return 'Approved';
      case InstallationVerificationStatus.rejected:
        return 'Rejected';
      case InstallationVerificationStatus.underReview:
        return 'Under Review';
    }
  }
}
