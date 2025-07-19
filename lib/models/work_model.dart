enum WorkStatus { pending, in_progress, completed, verified, rejected }

enum WorkPriority { low, medium, high, urgent }

class WorkModel {
  final String id;
  final String title;
  final String? description;
  final String customerId;
  final String assignedToId;
  final String assignedById;
  final WorkStatus status;
  final WorkPriority priority;
  final DateTime? dueDate;
  final DateTime? startDate;
  final DateTime? completedDate;
  final DateTime? verifiedDate;
  final String? verifiedById;
  final String? rejectionReason;
  final double? estimatedHours;
  final double? actualHours;
  final String officeId;
  final double? startLocationLatitude;
  final double? startLocationLongitude;
  final double? completeLocationLatitude;
  final double? completeLocationLongitude;
  final String? completionResponse;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  WorkModel({
    required this.id,
    required this.title,
    this.description,
    required this.customerId,
    required this.assignedToId,
    required this.assignedById,
    required this.status,
    required this.priority,
    this.dueDate,
    this.startDate,
    this.completedDate,
    this.verifiedDate,
    this.verifiedById,
    this.rejectionReason,
    this.estimatedHours,
    this.actualHours,
    required this.officeId,
    this.startLocationLatitude,
    this.startLocationLongitude,
    this.completeLocationLatitude,
    this.completeLocationLongitude,
    this.completionResponse,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory WorkModel.fromJson(Map<String, dynamic> json) {
    return WorkModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      customerId: json['customer_id'],
      assignedToId: json['assigned_to_id'],
      assignedById: json['assigned_by_id'],
      status: WorkStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WorkStatus.pending,
      ),
      priority: WorkPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => WorkPriority.medium,
      ),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'])
          : null,
      verifiedDate: json['verified_date'] != null
          ? DateTime.parse(json['verified_date'])
          : null,
      verifiedById: json['verified_by_id'],
      rejectionReason: json['rejection_reason'],
      estimatedHours: json['estimated_hours']?.toDouble(),
      actualHours: json['actual_hours']?.toDouble(),
      officeId: json['office_id'],
      startLocationLatitude: json['start_location_latitude']?.toDouble(),
      startLocationLongitude: json['start_location_longitude']?.toDouble(),
      completeLocationLatitude: json['complete_location_latitude']?.toDouble(),
      completeLocationLongitude: json['complete_location_longitude']?.toDouble(),
      completionResponse: json['completion_response'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'customer_id': customerId,
      'assigned_to_id': assignedToId,
      'assigned_by_id': assignedById,
      'status': status.name,
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'verified_date': verifiedDate?.toIso8601String(),
      'verified_by_id': verifiedById,
      'rejection_reason': rejectionReason,
      'estimated_hours': estimatedHours,
      'actual_hours': actualHours,
      'office_id': officeId,
      'start_location_latitude': startLocationLatitude,
      'start_location_longitude': startLocationLongitude,
      'complete_location_latitude': completeLocationLatitude,
      'complete_location_longitude': completeLocationLongitude,
      'completion_response': completionResponse,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case WorkStatus.pending:
        return 'Pending';
      case WorkStatus.in_progress:
        return 'In Progress';
      case WorkStatus.completed:
        return 'Completed';
      case WorkStatus.verified:
        return 'Verified';
      case WorkStatus.rejected:
        return 'Rejected';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case WorkPriority.low:
        return 'Low';
      case WorkPriority.medium:
        return 'Medium';
      case WorkPriority.high:
        return 'High';
      case WorkPriority.urgent:
        return 'Urgent';
    }
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) &&
        status != WorkStatus.completed &&
        status != WorkStatus.verified;
  }

  bool get canStart {
    return status == WorkStatus.pending;
  }

  bool get canComplete {
    return status == WorkStatus.in_progress;
  }

  bool get canVerify {
    return status == WorkStatus.completed;
  }

  bool get canReject {
    return status == WorkStatus.completed || status == WorkStatus.in_progress;
  }

  // Helper getter for assigned to name (would typically be fetched from a relationship)
  String? get assignedToName =>
      null; // This should be populated via a join query
}
