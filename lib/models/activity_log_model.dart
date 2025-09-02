enum ActivityType {
  user_created,
  user_updated,
  user_approved,
  user_rejected,
  work_assigned,
  work_started,
  work_completed,
  work_verified,
  work_rejected,
  customer_created,
  customer_updated,
  office_created,
  office_updated,
  stock_item_created,
  stock_item_updated,
  stock_movement,
  stock_transfer,
  login,
  logout,
  // Application Phase Activities
  application_submitted,
  application_approved,
  application_rejected,
  application_recommended,
  application_not_recommended,
  site_survey_completed,
  feasibility_updated,
  phase_updated,
}

class ActivityLogModel {
  final String id;
  final String userId;
  final ActivityType activityType;
  final String? description;
  final String? entityId;
  final String? entityType;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  ActivityLogModel({
    required this.id,
    required this.userId,
    required this.activityType,
    this.description,
    this.entityId,
    this.entityType,
    this.oldData,
    this.newData,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
    this.metadata,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'],
      userId: json['user_id'],
      activityType: ActivityType.values.firstWhere(
        (e) => e.name == json['activity_type'],
        orElse: () => ActivityType.user_updated,
      ),
      description: json['description'],
      entityId: json['entity_id'],
      entityType: json['entity_type'],
      oldData: json['old_data'],
      newData: json['new_data'],
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      createdAt: DateTime.parse(json['created_at']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'activity_type': activityType.name,
      'description': description,
      'entity_id': entityId,
      'entity_type': entityType,
      'old_data': oldData,
      'new_data': newData,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  String get activityDisplayName {
    switch (activityType) {
      case ActivityType.user_created:
        return 'User Created';
      case ActivityType.user_updated:
        return 'User Updated';
      case ActivityType.user_approved:
        return 'User Approved';
      case ActivityType.user_rejected:
        return 'User Rejected';
      case ActivityType.work_assigned:
        return 'Work Assigned';
      case ActivityType.work_started:
        return 'Work Started';
      case ActivityType.work_completed:
        return 'Work Completed';
      case ActivityType.work_verified:
        return 'Work Verified';
      case ActivityType.work_rejected:
        return 'Work Rejected';
      case ActivityType.customer_created:
        return 'Customer Created';
      case ActivityType.customer_updated:
        return 'Customer Updated';
      case ActivityType.office_created:
        return 'Office Created';
      case ActivityType.office_updated:
        return 'Office Updated';
      case ActivityType.stock_item_created:
        return 'Stock Item Created';
      case ActivityType.stock_item_updated:
        return 'Stock Item Updated';
      case ActivityType.stock_movement:
        return 'Stock Movement';
      case ActivityType.stock_transfer:
        return 'Stock Transfer';
      case ActivityType.login:
        return 'Login';
      case ActivityType.logout:
        return 'Logout';
      case ActivityType.application_submitted:
        return 'Application Submitted';
      case ActivityType.application_approved:
        return 'Application Approved';
      case ActivityType.application_rejected:
        return 'Application Rejected';
      case ActivityType.application_recommended:
        return 'Application Recommended';
      case ActivityType.application_not_recommended:
        return 'Application Not Recommended';
      case ActivityType.site_survey_completed:
        return 'Site Survey Completed';
      case ActivityType.feasibility_updated:
        return 'Feasibility Updated';
      case ActivityType.phase_updated:
        return 'Phase Updated';
    }
  }
}
