class AttendanceUpdateModel {
  final String? id;
  final String attendanceId;
  final String userId;
  final String updateText;
  final DateTime updateTime;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  AttendanceUpdateModel({
    this.id,
    required this.attendanceId,
    required this.userId,
    required this.updateText,
    required this.updateTime,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  factory AttendanceUpdateModel.fromJson(Map<String, dynamic> json) {
    return AttendanceUpdateModel(
      id: json['id'],
      attendanceId: json['attendance_id'],
      userId: json['user_id'],
      updateText: json['update_text'],
      updateTime: DateTime.parse(json['update_time']),
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'attendance_id': attendanceId,
      'user_id': userId,
      'update_text': updateText,
      'update_time': updateTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AttendanceUpdateModel copyWith({
    String? id,
    String? attendanceId,
    String? userId,
    String? updateText,
    DateTime? updateTime,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return AttendanceUpdateModel(
      id: id ?? this.id,
      attendanceId: attendanceId ?? this.attendanceId,
      userId: userId ?? this.userId,
      updateText: updateText ?? this.updateText,
      updateTime: updateTime ?? this.updateTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
