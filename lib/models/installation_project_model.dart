class InstallationProjectModel {
  final String id;
  final String customerId;
  final String status;
  final String assignedById;
  final DateTime? assignedDate;
  final DateTime? startedDate;
  final DateTime? completedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledStartDate;

  InstallationProjectModel({
    required this.id,
    required this.customerId,
    required this.status,
    required this.assignedById,
    this.assignedDate,
    this.startedDate,
    this.completedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledStartDate,
  });

  factory InstallationProjectModel.fromJson(Map<String, dynamic> json) {
    return InstallationProjectModel(
      id: json['id'],
      customerId: json['customer_id'],
      status: json['status'] ?? 'created',
      assignedById: json['assigned_by_id'],
      assignedDate: json['assigned_date'] != null
          ? DateTime.parse(json['assigned_date'])
          : null,
      startedDate: json['started_date'] != null
          ? DateTime.parse(json['started_date'])
          : null,
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      scheduledStartDate: json['scheduled_start_date'] != null
          ? DateTime.parse(json['scheduled_start_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'status': status,
      'assigned_by_id': assignedById,
      'assigned_date': assignedDate?.toIso8601String(),
      'started_date': startedDate?.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'scheduled_start_date': scheduledStartDate?.toIso8601String(),
    };
  }

  // Helper methods for status checking
  bool get isCreated => status == 'created';
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isVerified => status == 'verified';
  bool get isApproved => status == 'approved';

  String get statusDisplayName {
    switch (status) {
      case 'created':
        return 'Created';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'verified':
        return 'Verified';
      case 'approved':
        return 'Approved';
      default:
        return status.toUpperCase();
    }
  }

  // Duration calculations
  Duration? get assignmentDuration {
    if (assignedDate == null || startedDate == null) return null;
    return startedDate!.difference(assignedDate!);
  }

  Duration? get installationDuration {
    if (startedDate == null || completedDate == null) return null;
    return completedDate!.difference(startedDate!);
  }

  Duration? get totalProjectDuration {
    if (assignedDate == null || completedDate == null) return null;
    return completedDate!.difference(assignedDate!);
  }

  // Progress tracking
  double get progressPercentage {
    switch (status) {
      case 'created':
        return 0.0;
      case 'assigned':
        return 20.0;
      case 'in_progress':
        return 60.0;
      case 'completed':
        return 80.0;
      case 'verified':
        return 90.0;
      case 'approved':
        return 100.0;
      default:
        return 0.0;
    }
  }

  // Create a copy with updated fields
  InstallationProjectModel copyWith({
    String? id,
    String? customerId,
    String? status,
    String? assignedById,
    DateTime? assignedDate,
    DateTime? startedDate,
    DateTime? completedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledStartDate,
  }) {
    return InstallationProjectModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      assignedById: assignedById ?? this.assignedById,
      assignedDate: assignedDate ?? this.assignedDate,
      startedDate: startedDate ?? this.startedDate,
      completedDate: completedDate ?? this.completedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledStartDate: scheduledStartDate ?? this.scheduledStartDate,
    );
  }
}
