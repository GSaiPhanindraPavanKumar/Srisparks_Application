enum UserRole { director, manager, lead, employee }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.director:
        return 'director';
      case UserRole.manager:
        return 'manager';
      case UserRole.lead:
        return 'lead';
      case UserRole.employee:
        return 'employee';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.director:
        return 'Director';
      case UserRole.manager:
        return 'Manager';
      case UserRole.lead:
        return 'Lead';
      case UserRole.employee:
        return 'Employee';
    }
  }
}

enum UserStatus { active, inactive }

extension UserStatusExtension on UserStatus {
  String get name {
    switch (this) {
      case UserStatus.active:
        return 'active';
      case UserStatus.inactive:
        return 'inactive';
    }
  }

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
    }
  }
}

enum ApprovalStatus { pending, approved, rejected }

extension ApprovalStatusExtension on ApprovalStatus {
  String get name {
    switch (this) {
      case ApprovalStatus.pending:
        return 'pending';
      case ApprovalStatus.approved:
        return 'approved';
      case ApprovalStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Pending';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final UserRole role;
  final UserStatus status;
  final bool isLead;
  final String? officeId;

  // Approval workflow fields
  final String? addedBy;
  final DateTime? addedTime;
  final String? approvedBy;
  final DateTime? approvedTime;
  final ApprovalStatus approvalStatus;

  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    required this.role,
    required this.status,
    this.isLead = false,
    this.officeId,
    this.addedBy,
    this.addedTime,
    this.approvedBy,
    this.approvedTime,
    this.approvalStatus = ApprovalStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  // Helper getters
  String get name => fullName ?? email;
  String get displayName => fullName ?? email;
  String get roleDisplayName => isLead ? 'Lead' : role.displayName;
  String get statusDisplayName => status.displayName;
  String get approvalStatusDisplayName => approvalStatus.displayName;
  bool get isActive => status == UserStatus.active;
  bool get isPending => approvalStatus == ApprovalStatus.pending;
  bool get isApproved => approvalStatus == ApprovalStatus.approved;
  bool get isRejected => approvalStatus == ApprovalStatus.rejected;
  bool get isInactive => status == UserStatus.inactive;
  bool get canLogin =>
      status == UserStatus.active && approvalStatus == ApprovalStatus.approved;

  // JSON serialization
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.employee,
      ),
      status: UserStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => UserStatus.inactive,
      ),
      isLead: json['is_lead'] ?? false,
      officeId: json['office_id'],
      addedBy: json['added_by'],
      addedTime: json['added_time'] != null
          ? DateTime.parse(json['added_time'])
          : null,
      approvedBy: json['approved_by'],
      approvedTime: json['approved_time'] != null
          ? DateTime.parse(json['approved_time'])
          : null,
      approvalStatus: ApprovalStatus.values.firstWhere(
        (a) => a.name == json['approval_status'],
        orElse: () => ApprovalStatus.pending,
      ),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role.name,
      'status': status.name,
      'is_lead': isLead,
      'office_id': officeId,
      'added_by': addedBy,
      'added_time': addedTime?.toIso8601String(),
      'approved_by': approvedBy,
      'approved_time': approvedTime?.toIso8601String(),
      'approval_status': approvalStatus.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    UserStatus? status,
    bool? isLead,
    String? officeId,
    String? addedBy,
    DateTime? addedTime,
    String? approvedBy,
    DateTime? approvedTime,
    ApprovalStatus? approvalStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      status: status ?? this.status,
      isLead: isLead ?? this.isLead,
      officeId: officeId ?? this.officeId,
      addedBy: addedBy ?? this.addedBy,
      addedTime: addedTime ?? this.addedTime,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedTime: approvedTime ?? this.approvedTime,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, role: ${role.displayName}, status: ${status.displayName}, approvalStatus: ${approvalStatus.displayName}, isLead: $isLead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
