class AttendanceModel {
  final String? id;
  final String userId;
  final String? officeId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double checkInLatitude;
  final double checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final DateTime attendanceDate;
  final String status; // 'checked_in', 'checked_out'
  final String? summary;
  final String? checkInUpdate; // User update/status during check-in
  final String? checkOutUpdate; // User update/status during check-out
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceModel({
    this.id,
    required this.userId,
    this.officeId,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInLatitude,
    required this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    required this.attendanceDate,
    required this.status,
    this.summary,
    this.checkInUpdate,
    this.checkOutUpdate,
    required this.createdAt,
    this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      userId: json['user_id'],
      officeId: json['office_id'],
      checkInTime: DateTime.parse(json['check_in_time']),
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      checkInLatitude: json['check_in_latitude']?.toDouble() ?? 0.0,
      checkInLongitude: json['check_in_longitude']?.toDouble() ?? 0.0,
      checkOutLatitude: json['check_out_latitude']?.toDouble(),
      checkOutLongitude: json['check_out_longitude']?.toDouble(),
      attendanceDate: DateTime.parse(json['attendance_date']),
      status: json['status'] ?? 'checked_in',
      summary: json['summary'],
      checkInUpdate: json['check_in_update'],
      checkOutUpdate: json['check_out_update'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (officeId != null) 'office_id': officeId,
      'check_in_time': checkInTime.toIso8601String(),
      if (checkOutTime != null)
        'check_out_time': checkOutTime!.toIso8601String(),
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      if (checkOutLatitude != null) 'check_out_latitude': checkOutLatitude,
      if (checkOutLongitude != null) 'check_out_longitude': checkOutLongitude,
      'attendance_date': attendanceDate.toIso8601String().split(
        'T',
      )[0], // Just the date part
      'status': status,
      if (summary != null) 'summary': summary,
      if (checkInUpdate != null) 'check_in_update': checkInUpdate,
      if (checkOutUpdate != null) 'check_out_update': checkOutUpdate,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Calculate duration dynamically from check-in and check-out times
  String get formattedDuration {
    if (checkOutTime == null) return 'Still working';
    final duration = checkOutTime!.difference(checkInTime);
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60);
    return '${hours}h ${minutes}m';
  }

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? officeId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    DateTime? attendanceDate,
    String? status,
    String? summary,
    String? checkInUpdate,
    String? checkOutUpdate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      officeId: officeId ?? this.officeId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      checkInUpdate: checkInUpdate ?? this.checkInUpdate,
      checkOutUpdate: checkOutUpdate ?? this.checkOutUpdate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
