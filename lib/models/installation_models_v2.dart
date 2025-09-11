import 'package:geolocator/geolocator.dart';

/// Enhanced Installation Project Model - Complete Redesign
class InstallationProjectV2 {
  final String id;
  final String customerId;
  final String projectCode;
  
  // Customer Information
  final String customerName;
  final String customerAddress;
  final String? customerPhone;
  final String? customerEmail;
  
  // Site Information
  final double siteLatitude;
  final double siteLongitude;
  final String? siteAddress;
  final String? siteAccessInstructions;
  final double geofenceRadius;
  
  // Project Details
  final double systemCapacityKw;
  final int estimatedDurationDays;
  final int? actualDurationDays;
  final double? projectValue;
  
  // Status and Timeline
  final ProjectStatus status;
  final ProjectPriority priority;
  final DateTime? scheduledStartDate;
  final DateTime? actualStartDate;
  final DateTime? estimatedCompletionDate;
  final DateTime? actualCompletionDate;
  
  // Progress Tracking
  final double overallProgressPercentage;
  final int totalPhases;
  final int completedPhases;
  final int totalCheckpoints;
  final int passedCheckpoints;
  
  // Team Assignment
  final String? projectManagerId;
  final String? siteSupervisorId;
  final String? assignedOfficeId;
  
  // Quality and Safety
  final double qualityScore;
  final int safetyIncidents;
  final double? customerSatisfactionScore;
  
  // Documentation
  final String? projectNotes;
  final List<String> specialRequirements;
  final List<ProjectAttachment> attachments;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  InstallationProjectV2({
    required this.id,
    required this.customerId,
    required this.projectCode,
    required this.customerName,
    required this.customerAddress,
    this.customerPhone,
    this.customerEmail,
    required this.siteLatitude,
    required this.siteLongitude,
    this.siteAddress,
    this.siteAccessInstructions,
    this.geofenceRadius = 100.0,
    required this.systemCapacityKw,
    this.estimatedDurationDays = 7,
    this.actualDurationDays,
    this.projectValue,
    this.status = ProjectStatus.planning,
    this.priority = ProjectPriority.medium,
    this.scheduledStartDate,
    this.actualStartDate,
    this.estimatedCompletionDate,
    this.actualCompletionDate,
    this.overallProgressPercentage = 0.0,
    this.totalPhases = 0,
    this.completedPhases = 0,
    this.totalCheckpoints = 0,
    this.passedCheckpoints = 0,
    this.projectManagerId,
    this.siteSupervisorId,
    this.assignedOfficeId,
    this.qualityScore = 0.0,
    this.safetyIncidents = 0,
    this.customerSatisfactionScore,
    this.projectNotes,
    this.specialRequirements = const [],
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory InstallationProjectV2.fromJson(Map<String, dynamic> json) {
    return InstallationProjectV2(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      projectCode: json['project_code'] as String,
      customerName: json['customer_name'] as String,
      customerAddress: json['customer_address'] as String,
      customerPhone: json['customer_phone'] as String?,
      customerEmail: json['customer_email'] as String?,
      siteLatitude: (json['site_latitude'] as num).toDouble(),
      siteLongitude: (json['site_longitude'] as num).toDouble(),
      siteAddress: json['site_address'] as String?,
      siteAccessInstructions: json['site_access_instructions'] as String?,
      geofenceRadius: (json['geofence_radius'] as num?)?.toDouble() ?? 100.0,
      systemCapacityKw: (json['system_capacity_kw'] as num).toDouble(),
      estimatedDurationDays: json['estimated_duration_days'] as int? ?? 7,
      actualDurationDays: json['actual_duration_days'] as int?,
      projectValue: (json['project_value'] as num?)?.toDouble(),
      status: ProjectStatus.fromString(json['status'] as String? ?? 'planning'),
      priority: ProjectPriority.fromString(json['priority'] as String? ?? 'medium'),
      scheduledStartDate: json['scheduled_start_date'] != null 
          ? DateTime.parse(json['scheduled_start_date'] as String) 
          : null,
      actualStartDate: json['actual_start_date'] != null 
          ? DateTime.parse(json['actual_start_date'] as String) 
          : null,
      estimatedCompletionDate: json['estimated_completion_date'] != null 
          ? DateTime.parse(json['estimated_completion_date'] as String) 
          : null,
      actualCompletionDate: json['actual_completion_date'] != null 
          ? DateTime.parse(json['actual_completion_date'] as String) 
          : null,
      overallProgressPercentage: (json['overall_progress_percentage'] as num?)?.toDouble() ?? 0.0,
      totalPhases: json['total_phases'] as int? ?? 0,
      completedPhases: json['completed_phases'] as int? ?? 0,
      totalCheckpoints: json['total_checkpoints'] as int? ?? 0,
      passedCheckpoints: json['passed_checkpoints'] as int? ?? 0,
      projectManagerId: json['project_manager_id'] as String?,
      siteSupervisorId: json['site_supervisor_id'] as String?,
      assignedOfficeId: json['assigned_office_id'] as String?,
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0.0,
      safetyIncidents: json['safety_incidents'] as int? ?? 0,
      customerSatisfactionScore: (json['customer_satisfaction_score'] as num?)?.toDouble(),
      projectNotes: json['project_notes'] as String?,
      specialRequirements: _parseStringList(json['special_requirements']),
      attachments: _parseAttachments(json['attachments']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'project_code': projectCode,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'site_latitude': siteLatitude,
      'site_longitude': siteLongitude,
      'site_address': siteAddress,
      'site_access_instructions': siteAccessInstructions,
      'geofence_radius': geofenceRadius,
      'system_capacity_kw': systemCapacityKw,
      'estimated_duration_days': estimatedDurationDays,
      'actual_duration_days': actualDurationDays,
      'project_value': projectValue,
      'status': status.value,
      'priority': priority.value,
      'scheduled_start_date': scheduledStartDate?.toIso8601String().split('T')[0],
      'actual_start_date': actualStartDate?.toIso8601String().split('T')[0],
      'estimated_completion_date': estimatedCompletionDate?.toIso8601String().split('T')[0],
      'actual_completion_date': actualCompletionDate?.toIso8601String().split('T')[0],
      'overall_progress_percentage': overallProgressPercentage,
      'total_phases': totalPhases,
      'completed_phases': completedPhases,
      'total_checkpoints': totalCheckpoints,
      'passed_checkpoints': passedCheckpoints,
      'project_manager_id': projectManagerId,
      'site_supervisor_id': siteSupervisorId,
      'assigned_office_id': assignedOfficeId,
      'quality_score': qualityScore,
      'safety_incidents': safetyIncidents,
      'customer_satisfaction_score': customerSatisfactionScore,
      'project_notes': projectNotes,
      'special_requirements': specialRequirements,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  // Calculate distance from current location to site
  double calculateDistanceToSite(Position currentPosition) {
    return Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      siteLatitude,
      siteLongitude,
    );
  }

  // Check if current location is within geofence
  bool isWithinGeofence(Position currentPosition) {
    final distance = calculateDistanceToSite(currentPosition);
    return distance <= geofenceRadius;
  }

  // Calculate overall progress based on phases and checkpoints
  double calculateOverallProgress(List<InstallationWorkPhase> phases) {
    if (phases.isEmpty) return 0.0;
    
    final totalProgress = phases.fold<double>(
      0.0, 
      (sum, phase) => sum + phase.progressPercentage
    );
    
    return totalProgress / phases.length;
  }

  static List<String> _parseStringList(dynamic json) {
    if (json == null) return [];
    if (json is List) return json.cast<String>();
    return [];
  }

  static List<ProjectAttachment> _parseAttachments(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return json.map((item) => ProjectAttachment.fromJson(item)).toList();
    }
    return [];
  }

  InstallationProjectV2 copyWith({
    String? id,
    String? customerId,
    String? projectCode,
    String? customerName,
    String? customerAddress,
    String? customerPhone,
    String? customerEmail,
    double? siteLatitude,
    double? siteLongitude,
    String? siteAddress,
    String? siteAccessInstructions,
    double? geofenceRadius,
    double? systemCapacityKw,
    int? estimatedDurationDays,
    int? actualDurationDays,
    double? projectValue,
    ProjectStatus? status,
    ProjectPriority? priority,
    DateTime? scheduledStartDate,
    DateTime? actualStartDate,
    DateTime? estimatedCompletionDate,
    DateTime? actualCompletionDate,
    double? overallProgressPercentage,
    int? totalPhases,
    int? completedPhases,
    int? totalCheckpoints,
    int? passedCheckpoints,
    String? projectManagerId,
    String? siteSupervisorId,
    String? assignedOfficeId,
    double? qualityScore,
    int? safetyIncidents,
    double? customerSatisfactionScore,
    String? projectNotes,
    List<String>? specialRequirements,
    List<ProjectAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return InstallationProjectV2(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      projectCode: projectCode ?? this.projectCode,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      siteLatitude: siteLatitude ?? this.siteLatitude,
      siteLongitude: siteLongitude ?? this.siteLongitude,
      siteAddress: siteAddress ?? this.siteAddress,
      siteAccessInstructions: siteAccessInstructions ?? this.siteAccessInstructions,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      systemCapacityKw: systemCapacityKw ?? this.systemCapacityKw,
      estimatedDurationDays: estimatedDurationDays ?? this.estimatedDurationDays,
      actualDurationDays: actualDurationDays ?? this.actualDurationDays,
      projectValue: projectValue ?? this.projectValue,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      scheduledStartDate: scheduledStartDate ?? this.scheduledStartDate,
      actualStartDate: actualStartDate ?? this.actualStartDate,
      estimatedCompletionDate: estimatedCompletionDate ?? this.estimatedCompletionDate,
      actualCompletionDate: actualCompletionDate ?? this.actualCompletionDate,
      overallProgressPercentage: overallProgressPercentage ?? this.overallProgressPercentage,
      totalPhases: totalPhases ?? this.totalPhases,
      completedPhases: completedPhases ?? this.completedPhases,
      totalCheckpoints: totalCheckpoints ?? this.totalCheckpoints,
      passedCheckpoints: passedCheckpoints ?? this.passedCheckpoints,
      projectManagerId: projectManagerId ?? this.projectManagerId,
      siteSupervisorId: siteSupervisorId ?? this.siteSupervisorId,
      assignedOfficeId: assignedOfficeId ?? this.assignedOfficeId,
      qualityScore: qualityScore ?? this.qualityScore,
      safetyIncidents: safetyIncidents ?? this.safetyIncidents,
      customerSatisfactionScore: customerSatisfactionScore ?? this.customerSatisfactionScore,
      projectNotes: projectNotes ?? this.projectNotes,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

/// Enhanced Work Phase Model
class InstallationWorkPhase {
  final String id;
  final String projectId;
  final String phaseCode;
  final String phaseName;
  final String? phaseDescription;
  final int phaseOrder;
  final List<String> prerequisitePhases;
  final PhaseStatus status;
  final double progressPercentage;
  
  // Timeline
  final DateTime? estimatedStartDate;
  final DateTime? actualStartDate;
  final double? estimatedDurationHours;
  final double actualDurationHours;
  final DateTime? estimatedCompletionDate;
  final DateTime? actualCompletionDate;
  
  // Team Assignment
  final String? leadTechnicianId;
  final List<TeamMember> assignedTeamMembers;
  final List<String> requiredSkills;
  
  // Location and Safety
  final String? workLocationDescription;
  final List<String> safetyRequirements;
  final List<String> requiredEquipment;
  
  // Quality Control
  final List<QualityCheckpoint> qualityCheckpoints;
  final List<String> passedCheckpoints;
  final double? qualityScore;
  
  // Materials and Resources
  final List<MaterialRequirement> requiredMaterials;
  final List<MaterialAllocation> allocatedMaterials;
  final List<MaterialUsage> usedMaterials;
  
  // Documentation
  final String? workInstructions;
  final String? completionNotes;
  final List<PhasePhoto> phasePhotos;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  InstallationWorkPhase({
    required this.id,
    required this.projectId,
    required this.phaseCode,
    required this.phaseName,
    this.phaseDescription,
    required this.phaseOrder,
    this.prerequisitePhases = const [],
    this.status = PhaseStatus.notStarted,
    this.progressPercentage = 0.0,
    this.estimatedStartDate,
    this.actualStartDate,
    this.estimatedDurationHours,
    this.actualDurationHours = 0.0,
    this.estimatedCompletionDate,
    this.actualCompletionDate,
    this.leadTechnicianId,
    this.assignedTeamMembers = const [],
    this.requiredSkills = const [],
    this.workLocationDescription,
    this.safetyRequirements = const [],
    this.requiredEquipment = const [],
    this.qualityCheckpoints = const [],
    this.passedCheckpoints = const [],
    this.qualityScore,
    this.requiredMaterials = const [],
    this.allocatedMaterials = const [],
    this.usedMaterials = const [],
    this.workInstructions,
    this.completionNotes,
    this.phasePhotos = const [],
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory InstallationWorkPhase.fromJson(Map<String, dynamic> json) {
    return InstallationWorkPhase(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      phaseCode: json['phase_code'] as String,
      phaseName: json['phase_name'] as String,
      phaseDescription: json['phase_description'] as String?,
      phaseOrder: json['phase_order'] as int,
      prerequisitePhases: _parseStringList(json['prerequisite_phases']),
      status: PhaseStatus.fromString(json['status'] as String? ?? 'not_started'),
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      estimatedStartDate: json['estimated_start_date'] != null 
          ? DateTime.parse(json['estimated_start_date'] as String) 
          : null,
      actualStartDate: json['actual_start_date'] != null 
          ? DateTime.parse(json['actual_start_date'] as String) 
          : null,
      estimatedDurationHours: (json['estimated_duration_hours'] as num?)?.toDouble(),
      actualDurationHours: (json['actual_duration_hours'] as num?)?.toDouble() ?? 0.0,
      estimatedCompletionDate: json['estimated_completion_date'] != null 
          ? DateTime.parse(json['estimated_completion_date'] as String) 
          : null,
      actualCompletionDate: json['actual_completion_date'] != null 
          ? DateTime.parse(json['actual_completion_date'] as String) 
          : null,
      leadTechnicianId: json['lead_technician_id'] as String?,
      assignedTeamMembers: _parseTeamMembers(json['assigned_team_members']),
      requiredSkills: _parseStringList(json['required_skills']),
      workLocationDescription: json['work_location_description'] as String?,
      safetyRequirements: _parseStringList(json['safety_requirements']),
      requiredEquipment: _parseStringList(json['required_equipment']),
      qualityCheckpoints: _parseQualityCheckpoints(json['quality_checkpoints']),
      passedCheckpoints: _parseStringList(json['passed_checkpoints']),
      qualityScore: (json['quality_score'] as num?)?.toDouble(),
      requiredMaterials: _parseMaterialRequirements(json['required_materials']),
      allocatedMaterials: _parseMaterialAllocations(json['allocated_materials']),
      usedMaterials: _parseMaterialUsage(json['used_materials']),
      workInstructions: json['work_instructions'] as String?,
      completionNotes: json['completion_notes'] as String?,
      phasePhotos: _parsePhasePhotos(json['phase_photos']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'phase_code': phaseCode,
      'phase_name': phaseName,
      'phase_description': phaseDescription,
      'phase_order': phaseOrder,
      'prerequisite_phases': prerequisitePhases,
      'status': status.value,
      'progress_percentage': progressPercentage,
      'estimated_start_date': estimatedStartDate?.toIso8601String().split('T')[0],
      'actual_start_date': actualStartDate?.toIso8601String().split('T')[0],
      'estimated_duration_hours': estimatedDurationHours,
      'actual_duration_hours': actualDurationHours,
      'estimated_completion_date': estimatedCompletionDate?.toIso8601String().split('T')[0],
      'actual_completion_date': actualCompletionDate?.toIso8601String().split('T')[0],
      'lead_technician_id': leadTechnicianId,
      'assigned_team_members': assignedTeamMembers.map((tm) => tm.toJson()).toList(),
      'required_skills': requiredSkills,
      'work_location_description': workLocationDescription,
      'safety_requirements': safetyRequirements,
      'required_equipment': requiredEquipment,
      'quality_checkpoints': qualityCheckpoints.map((qc) => qc.toJson()).toList(),
      'passed_checkpoints': passedCheckpoints,
      'quality_score': qualityScore,
      'required_materials': requiredMaterials.map((mr) => mr.toJson()).toList(),
      'allocated_materials': allocatedMaterials.map((ma) => ma.toJson()).toList(),
      'used_materials': usedMaterials.map((mu) => mu.toJson()).toList(),
      'work_instructions': workInstructions,
      'completion_notes': completionNotes,
      'phase_photos': phasePhotos.map((pp) => pp.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  // Helper methods for parsing complex JSON structures
  static List<String> _parseStringList(dynamic json) {
    if (json == null) return [];
    if (json is List) return json.cast<String>();
    return [];
  }

  static List<TeamMember> _parseTeamMembers(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return json.map((item) => TeamMember.fromJson(item)).toList();
    }
    return [];
  }

  static List<QualityCheckpoint> _parseQualityCheckpoints(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return json.map((item) => QualityCheckpoint.fromJson(item)).toList();
    }
    return [];
  }

  static List<MaterialRequirement> _parseMaterialRequirements(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return json.map((item) => MaterialRequirement.fromJson(item)).toList();
    }
    return [];
  }

  static List<MaterialAllocation> _parseMaterialAllocations(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return json.map((item) => MaterialAllocation.fromJson(item)).toList();
    }
    return [];
  }

  static List<MaterialUsage> _parseMaterialUsage(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return json.map((item) => MaterialUsage.fromJson(item)).toList();
    }
    return [];
  }

  static List<PhasePhoto> _parsePhasePhotos(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return json.map((item) => PhasePhoto.fromJson(item)).toList();
    }
    return [];
  }

  // Check if phase can be started based on prerequisites
  bool canStart(List<InstallationWorkPhase> allPhases) {
    if (prerequisitePhases.isEmpty) return true;
    
    for (final prereq in prerequisitePhases) {
      final prereqPhase = allPhases.firstWhere(
        (phase) => phase.phaseCode == prereq,
        orElse: () => throw Exception('Prerequisite phase $prereq not found'),
      );
      
      if (prereqPhase.status != PhaseStatus.completed) {
        return false;
      }
    }
    
    return true;
  }

  // Calculate estimated completion date based on start date and duration
  DateTime? calculateEstimatedCompletion() {
    if (estimatedStartDate == null || estimatedDurationHours == null) {
      return null;
    }
    
    // Assuming 8 hours work per day
    final days = (estimatedDurationHours! / 8).ceil();
    return estimatedStartDate!.add(Duration(days: days));
  }
}

/// Enhanced Installation Team Model
class InstallationTeam {
  final String id;
  final String projectId;
  final String teamName;
  final TeamType teamType;
  final String teamLeadId;
  final List<TeamMember> teamMembers;
  final List<TeamMember> backupMembers;
  final Map<String, double> skillMatrix;
  final List<String> certifications;
  final List<String> equipmentAssigned;
  final List<String> assignedPhases;
  final double currentWorkload;
  final TeamAvailabilityStatus availabilityStatus;
  final int completedPhases;
  final double averageQualityScore;
  final double onTimeCompletionRate;
  final Location? lastKnownLocation;
  final Map<String, dynamic> communicationPreferences;
  final DateTime createdAt;
  final String? createdBy;

  InstallationTeam({
    required this.id,
    required this.projectId,
    required this.teamName,
    this.teamType = TeamType.general,
    required this.teamLeadId,
    this.teamMembers = const [],
    this.backupMembers = const [],
    this.skillMatrix = const {},
    this.certifications = const [],
    this.equipmentAssigned = const [],
    this.assignedPhases = const [],
    this.currentWorkload = 0.0,
    this.availabilityStatus = TeamAvailabilityStatus.available,
    this.completedPhases = 0,
    this.averageQualityScore = 0.0,
    this.onTimeCompletionRate = 0.0,
    this.lastKnownLocation,
    this.communicationPreferences = const {},
    required this.createdAt,
    this.createdBy,
  });

  factory InstallationTeam.fromJson(Map<String, dynamic> json) {
    return InstallationTeam(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      teamName: json['team_name'] as String,
      teamType: TeamType.fromString(json['team_type'] as String? ?? 'general'),
      teamLeadId: json['team_lead_id'] as String,
      teamMembers: _parseTeamMembers(json['team_members']),
      backupMembers: _parseTeamMembers(json['backup_members']),
      skillMatrix: _parseSkillMatrix(json['skill_matrix']),
      certifications: _parseStringList(json['certifications']),
      equipmentAssigned: _parseStringList(json['equipment_assigned']),
      assignedPhases: _parseStringList(json['assigned_phases']),
      currentWorkload: (json['current_workload'] as num?)?.toDouble() ?? 0.0,
      availabilityStatus: TeamAvailabilityStatus.fromString(
        json['availability_status'] as String? ?? 'available'
      ),
      completedPhases: json['completed_phases'] as int? ?? 0,
      averageQualityScore: (json['average_quality_score'] as num?)?.toDouble() ?? 0.0,
      onTimeCompletionRate: (json['on_time_completion_rate'] as num?)?.toDouble() ?? 0.0,
      lastKnownLocation: json['last_known_location'] != null 
          ? Location.fromJson(json['last_known_location']) 
          : null,
      communicationPreferences: json['communication_preferences'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'team_name': teamName,
      'team_type': teamType.value,
      'team_lead_id': teamLeadId,
      'team_members': teamMembers.map((tm) => tm.toJson()).toList(),
      'backup_members': backupMembers.map((bm) => bm.toJson()).toList(),
      'skill_matrix': skillMatrix,
      'certifications': certifications,
      'equipment_assigned': equipmentAssigned,
      'assigned_phases': assignedPhases,
      'current_workload': currentWorkload,
      'availability_status': availabilityStatus.value,
      'completed_phases': completedPhases,
      'average_quality_score': averageQualityScore,
      'on_time_completion_rate': onTimeCompletionRate,
      'last_known_location': lastKnownLocation?.toJson(),
      'communication_preferences': communicationPreferences,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  static List<TeamMember> _parseTeamMembers(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return json.map((item) => TeamMember.fromJson(item)).toList();
    }
    return [];
  }

  static Map<String, double> _parseSkillMatrix(dynamic json) {
    if (json == null) return {};
    if (json is Map) {
      return json.map((key, value) => MapEntry(
        key.toString(), 
        (value as num).toDouble()
      ));
    }
    return {};
  }

  static List<String> _parseStringList(dynamic json) {
    if (json == null) return [];
    if (json is List) return json.cast<String>();
    return [];
  }
}

// Supporting classes and enums continue in next part...
