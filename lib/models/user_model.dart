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

enum UserStatus { active, inactive, pending_approval }

extension UserStatusExtension on UserStatus {
  String get name {
    switch (this) {
      case UserStatus.active:
        return 'active';
      case UserStatus.inactive:
        return 'inactive';
      case UserStatus.pending_approval:
        return 'pending_approval';
    }
  }

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.pending_approval:
        return 'Pending Approval';
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
  final String? reportingToId;
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
    this.reportingToId,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  // Helper getters
  String get name => fullName ?? email;
  String get displayName => fullName ?? email;
  String get roleDisplayName => isLead ? 'Lead' : role.displayName;
  String get statusDisplayName => status.displayName;
  bool get isActive => status == UserStatus.active;
  bool get isPending => status == UserStatus.pending_approval;
  bool get isInactive => status == UserStatus.inactive;

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
        orElse: () => UserStatus.pending_approval,
      ),
      isLead: json['is_lead'] ?? false,
      officeId: json['office_id'],
      reportingToId: json['reporting_to_id'],
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
      'reporting_to_id': reportingToId,
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
    String? reportingToId,
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
      reportingToId: reportingToId ?? this.reportingToId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, role: ${role.displayName}, status: ${status.displayName}, isLead: $isLead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
