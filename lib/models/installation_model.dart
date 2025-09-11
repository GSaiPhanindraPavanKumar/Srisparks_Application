import 'dart:convert';
import 'dart:math' as math;

// Installation Sub-task Types
enum InstallationSubTask {
  structure,
  panels,
  wiringInverter,
  earthing,
  lightningArrestor,
  dataCollection,
}

// Installation Status for each sub-task
enum InstallationTaskStatus {
  pending,
  assigned,
  inProgress,
  completed,
  verified,
  rejected,
}

// Installation Work Assignment Model
class InstallationWorkAssignment {
  final String id;
  final String customerId;
  final String customerName;
  final String customerAddress;
  final double? customerLatitude;
  final double? customerLongitude;
  final List<String> assignedEmployeeIds;
  final List<String> assignedEmployeeNames;
  final String assignedById; // Director/Manager/Lead who assigned
  final String assignedByName;
  final DateTime assignedDate;
  final DateTime? scheduledDate;
  final String status; // 'assigned', 'in_progress', 'completed', 'verified'
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Sub-tasks status tracking
  final Map<InstallationSubTask, InstallationTaskStatus> subTasksStatus;
  final Map<InstallationSubTask, DateTime?> subTasksStartTimes;
  final Map<InstallationSubTask, DateTime?> subTasksCompletionTimes;
  final Map<InstallationSubTask, List<String>?> subTasksPhotos;
  final Map<InstallationSubTask, String?> subTasksNotes;
  final Map<InstallationSubTask, List<String>?> subTasksEmployeesPresent;

  // Data Collection specific fields
  final List<String>? solarPanelSerialNumbers;
  final List<String>? inverterSerialNumbers;
  final DateTime? dataCollectionCompletedAt;
  final String? dataCollectionCompletedBy;

  // Verification fields
  final String? verifiedById;
  final String? verifiedByName;
  final DateTime? verifiedDate;
  final String? verificationStatus; // 'approved', 'rejected'
  final String? verificationNotes;

  InstallationWorkAssignment({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerAddress,
    this.customerLatitude,
    this.customerLongitude,
    required this.assignedEmployeeIds,
    required this.assignedEmployeeNames,
    required this.assignedById,
    required this.assignedByName,
    required this.assignedDate,
    this.scheduledDate,
    this.status = 'assigned',
    this.notes,
    required this.createdAt,
    this.updatedAt,
    Map<InstallationSubTask, InstallationTaskStatus>? subTasksStatus,
    Map<InstallationSubTask, DateTime?>? subTasksStartTimes,
    Map<InstallationSubTask, DateTime?>? subTasksCompletionTimes,
    Map<InstallationSubTask, List<String>?>? subTasksPhotos,
    Map<InstallationSubTask, String?>? subTasksNotes,
    Map<InstallationSubTask, List<String>?>? subTasksEmployeesPresent,
    this.solarPanelSerialNumbers,
    this.inverterSerialNumbers,
    this.dataCollectionCompletedAt,
    this.dataCollectionCompletedBy,
    this.verifiedById,
    this.verifiedByName,
    this.verifiedDate,
    this.verificationStatus,
    this.verificationNotes,
  }) : subTasksStatus = subTasksStatus ?? _getDefaultSubTasksStatus(),
       subTasksStartTimes = subTasksStartTimes ?? _getDefaultSubTasksDateTimes(),
       subTasksCompletionTimes = subTasksCompletionTimes ?? _getDefaultSubTasksDateTimes(),
       subTasksPhotos = subTasksPhotos ?? _getDefaultSubTasksPhotos(),
       subTasksNotes = subTasksNotes ?? _getDefaultSubTasksNotes(),
       subTasksEmployeesPresent = subTasksEmployeesPresent ?? _getDefaultSubTasksEmployees();

  // Helper methods to create default maps
  static Map<InstallationSubTask, InstallationTaskStatus> _getDefaultSubTasksStatus() {
    return {
      for (InstallationSubTask task in InstallationSubTask.values)
        task: InstallationTaskStatus.pending,
    };
  }

  static Map<InstallationSubTask, DateTime?> _getDefaultSubTasksDateTimes() {
    return {
      for (InstallationSubTask task in InstallationSubTask.values)
        task: null,
    };
  }

  static Map<InstallationSubTask, List<String>?> _getDefaultSubTasksPhotos() {
    return {
      for (InstallationSubTask task in InstallationSubTask.values)
        task: null,
    };
  }

  static Map<InstallationSubTask, String?> _getDefaultSubTasksNotes() {
    return {
      for (InstallationSubTask task in InstallationSubTask.values)
        task: null,
    };
  }

  static Map<InstallationSubTask, List<String>?> _getDefaultSubTasksEmployees() {
    return {
      for (InstallationSubTask task in InstallationSubTask.values)
        task: null,
    };
  }

  factory InstallationWorkAssignment.fromJson(Map<String, dynamic> json) {
    return InstallationWorkAssignment(
      id: json['id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'] ?? json['customers']?['name'] ?? 'Unknown',
      customerAddress: json['customer_address'] ?? json['customers']?['address'] ?? 'No address',
      customerLatitude: json['customer_latitude']?.toDouble() ?? json['customers']?['latitude']?.toDouble(),
      customerLongitude: json['customer_longitude']?.toDouble() ?? json['customers']?['longitude']?.toDouble(),
      assignedEmployeeIds: List<String>.from(json['assigned_employee_ids'] ?? []),
      assignedEmployeeNames: List<String>.from(json['assigned_employee_names'] ?? []),
      assignedById: json['assigned_by_id'],
      assignedByName: json['assigned_by_name'] ?? 'Unknown',
      assignedDate: DateTime.parse(json['assigned_date']),
      scheduledDate: json['scheduled_date'] != null ? DateTime.parse(json['scheduled_date']) : null,
      status: json['status'] ?? 'assigned',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      subTasksStatus: _parseSubTasksStatus(json['subtasks_status']),
      subTasksStartTimes: _parseSubTasksDateTimes(json['subtasks_start_times']),
      subTasksCompletionTimes: _parseSubTasksDateTimes(json['subtasks_completion_times']),
      subTasksPhotos: _parseSubTasksPhotos(json['subtasks_photos']),
      subTasksNotes: _parseSubTasksNotes(json['subtasks_notes']),
      subTasksEmployeesPresent: _parseSubTasksEmployees(json['subtasks_employees_present']),
      solarPanelSerialNumbers: json['solar_panel_serial_numbers'] != null 
          ? List<String>.from(json['solar_panel_serial_numbers'])
          : null,
      inverterSerialNumbers: json['inverter_serial_numbers'] != null
          ? List<String>.from(json['inverter_serial_numbers'])
          : null,
      dataCollectionCompletedAt: json['data_collection_completed_at'] != null
          ? DateTime.parse(json['data_collection_completed_at'])
          : null,
      dataCollectionCompletedBy: json['data_collection_completed_by'],
      verifiedById: json['verified_by_id'],
      verifiedByName: json['verified_by_name'],
      verifiedDate: json['verified_date'] != null ? DateTime.parse(json['verified_date']) : null,
      verificationStatus: json['verification_status'],
      verificationNotes: json['verification_notes'],
    );
  }

  // Parse sub-tasks status from JSON
  static Map<InstallationSubTask, InstallationTaskStatus> _parseSubTasksStatus(dynamic json) {
    if (json == null) return _getDefaultSubTasksStatus();
    
    try {
      final Map<String, dynamic> data = json is String ? jsonDecode(json) : json;
      final Map<InstallationSubTask, InstallationTaskStatus> result = {};
      
      for (InstallationSubTask task in InstallationSubTask.values) {
        final String key = task.name;
        final String? statusStr = data[key];
        result[task] = _parseTaskStatus(statusStr);
      }
      return result;
    } catch (e) {
      return _getDefaultSubTasksStatus();
    }
  }

  // Parse sub-tasks date times from JSON
  static Map<InstallationSubTask, DateTime?> _parseSubTasksDateTimes(dynamic json) {
    if (json == null) return _getDefaultSubTasksDateTimes();
    
    try {
      final Map<String, dynamic> data = json is String ? jsonDecode(json) : json;
      final Map<InstallationSubTask, DateTime?> result = {};
      
      for (InstallationSubTask task in InstallationSubTask.values) {
        final String key = task.name;
        final String? dateStr = data[key];
        result[task] = dateStr != null ? DateTime.parse(dateStr) : null;
      }
      return result;
    } catch (e) {
      return _getDefaultSubTasksDateTimes();
    }
  }

  // Parse sub-tasks photos from JSON
  static Map<InstallationSubTask, List<String>?> _parseSubTasksPhotos(dynamic json) {
    if (json == null) return _getDefaultSubTasksPhotos();
    
    try {
      final Map<String, dynamic> data = json is String ? jsonDecode(json) : json;
      final Map<InstallationSubTask, List<String>?> result = {};
      
      for (InstallationSubTask task in InstallationSubTask.values) {
        final String key = task.name;
        final List<dynamic>? photos = data[key];
        result[task] = photos?.map((e) => e.toString()).toList();
      }
      return result;
    } catch (e) {
      return _getDefaultSubTasksPhotos();
    }
  }

  // Parse sub-tasks notes from JSON
  static Map<InstallationSubTask, String?> _parseSubTasksNotes(dynamic json) {
    if (json == null) return _getDefaultSubTasksNotes();
    
    try {
      final Map<String, dynamic> data = json is String ? jsonDecode(json) : json;
      final Map<InstallationSubTask, String?> result = {};
      
      for (InstallationSubTask task in InstallationSubTask.values) {
        final String key = task.name;
        result[task] = data[key];
      }
      return result;
    } catch (e) {
      return _getDefaultSubTasksNotes();
    }
  }

  // Parse sub-tasks employees present from JSON
  static Map<InstallationSubTask, List<String>?> _parseSubTasksEmployees(dynamic json) {
    if (json == null) return _getDefaultSubTasksEmployees();
    
    try {
      final Map<String, dynamic> data = json is String ? jsonDecode(json) : json;
      final Map<InstallationSubTask, List<String>?> result = {};
      
      for (InstallationSubTask task in InstallationSubTask.values) {
        final String key = task.name;
        final List<dynamic>? employees = data[key];
        result[task] = employees?.map((e) => e.toString()).toList();
      }
      return result;
    } catch (e) {
      return _getDefaultSubTasksEmployees();
    }
  }

  // Parse individual task status
  static InstallationTaskStatus _parseTaskStatus(String? statusStr) {
    switch (statusStr) {
      case 'pending':
        return InstallationTaskStatus.pending;
      case 'assigned':
        return InstallationTaskStatus.assigned;
      case 'in_progress':
        return InstallationTaskStatus.inProgress;
      case 'completed':
        return InstallationTaskStatus.completed;
      case 'verified':
        return InstallationTaskStatus.verified;
      case 'rejected':
        return InstallationTaskStatus.rejected;
      default:
        return InstallationTaskStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'customer_latitude': customerLatitude,
      'customer_longitude': customerLongitude,
      'assigned_employee_ids': assignedEmployeeIds,
      'assigned_employee_names': assignedEmployeeNames,
      'assigned_by_id': assignedById,
      'assigned_by_name': assignedByName,
      'assigned_date': assignedDate.toIso8601String(),
      'scheduled_date': scheduledDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'subtasks_status': _subTasksStatusToJson(),
      'subtasks_start_times': _subTasksDateTimesToJson(subTasksStartTimes),
      'subtasks_completion_times': _subTasksDateTimesToJson(subTasksCompletionTimes),
      'subtasks_photos': _subTasksPhotosToJson(),
      'subtasks_notes': _subTasksNotesToJson(),
      'subtasks_employees_present': _subTasksEmployeesToJson(),
      'solar_panel_serial_numbers': solarPanelSerialNumbers,
      'inverter_serial_numbers': inverterSerialNumbers,
      'data_collection_completed_at': dataCollectionCompletedAt?.toIso8601String(),
      'data_collection_completed_by': dataCollectionCompletedBy,
      'verified_by_id': verifiedById,
      'verified_by_name': verifiedByName,
      'verified_date': verifiedDate?.toIso8601String(),
      'verification_status': verificationStatus,
      'verification_notes': verificationNotes,
    };
  }

  // Convert sub-tasks status to JSON
  String _subTasksStatusToJson() {
    final Map<String, String> result = {};
    for (final entry in subTasksStatus.entries) {
      result[entry.key.name] = entry.value.name;
    }
    return jsonEncode(result);
  }

  // Convert sub-tasks date times to JSON
  String _subTasksDateTimesToJson(Map<InstallationSubTask, DateTime?> dateTimes) {
    final Map<String, String?> result = {};
    for (final entry in dateTimes.entries) {
      result[entry.key.name] = entry.value?.toIso8601String();
    }
    return jsonEncode(result);
  }

  // Convert sub-tasks photos to JSON
  String _subTasksPhotosToJson() {
    final Map<String, List<String>?> result = {};
    for (final entry in subTasksPhotos.entries) {
      result[entry.key.name] = entry.value;
    }
    return jsonEncode(result);
  }

  // Convert sub-tasks notes to JSON
  String _subTasksNotesToJson() {
    final Map<String, String?> result = {};
    for (final entry in subTasksNotes.entries) {
      result[entry.key.name] = entry.value;
    }
    return jsonEncode(result);
  }

  // Convert sub-tasks employees to JSON
  String _subTasksEmployeesToJson() {
    final Map<String, List<String>?> result = {};
    for (final entry in subTasksEmployeesPresent.entries) {
      result[entry.key.name] = entry.value;
    }
    return jsonEncode(result);
  }

  // Helper getters
  String get statusDisplayName {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'verified':
        return 'Verified';
      default:
        return status.toUpperCase();
    }
  }

  bool get isCompleted => status == 'completed' || status == 'verified';
  bool get isInProgress => status == 'in_progress';
  bool get isVerified => status == 'verified';

  // Check if all sub-tasks are completed
  bool get areAllSubTasksCompleted {
    return subTasksStatus.values.every(
      (status) => status == InstallationTaskStatus.completed || status == InstallationTaskStatus.verified,
    );
  }

  // Check if data collection is completed
  bool get isDataCollectionCompleted {
    return subTasksStatus[InstallationSubTask.dataCollection] == InstallationTaskStatus.completed &&
           solarPanelSerialNumbers != null && solarPanelSerialNumbers!.isNotEmpty &&
           inverterSerialNumbers != null && inverterSerialNumbers!.isNotEmpty;
  }

  // Get completion percentage
  double get completionPercentage {
    final completedTasks = subTasksStatus.values
        .where((status) => status == InstallationTaskStatus.completed || status == InstallationTaskStatus.verified)
        .length;
    return (completedTasks / InstallationSubTask.values.length) * 100;
  }

  // Get sub-task display name
  static String getSubTaskDisplayName(InstallationSubTask task) {
    switch (task) {
      case InstallationSubTask.structure:
        return 'Structure Installation';
      case InstallationSubTask.panels:
        return 'Solar Panels Installation';
      case InstallationSubTask.wiringInverter:
        return 'Wiring & Inverter Setup';
      case InstallationSubTask.earthing:
        return 'Earthing Installation';
      case InstallationSubTask.lightningArrestor:
        return 'Lightning Arrestor';
      case InstallationSubTask.dataCollection:
        return 'Data Collection';
    }
  }

  // Copy with method for updates
  InstallationWorkAssignment copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerAddress,
    double? customerLatitude,
    double? customerLongitude,
    List<String>? assignedEmployeeIds,
    List<String>? assignedEmployeeNames,
    String? assignedById,
    String? assignedByName,
    DateTime? assignedDate,
    DateTime? scheduledDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<InstallationSubTask, InstallationTaskStatus>? subTasksStatus,
    Map<InstallationSubTask, DateTime?>? subTasksStartTimes,
    Map<InstallationSubTask, DateTime?>? subTasksCompletionTimes,
    Map<InstallationSubTask, List<String>?>? subTasksPhotos,
    Map<InstallationSubTask, String?>? subTasksNotes,
    Map<InstallationSubTask, List<String>?>? subTasksEmployeesPresent,
    List<String>? solarPanelSerialNumbers,
    List<String>? inverterSerialNumbers,
    DateTime? dataCollectionCompletedAt,
    String? dataCollectionCompletedBy,
    String? verifiedById,
    String? verifiedByName,
    DateTime? verifiedDate,
    String? verificationStatus,
    String? verificationNotes,
  }) {
    return InstallationWorkAssignment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerLatitude: customerLatitude ?? this.customerLatitude,
      customerLongitude: customerLongitude ?? this.customerLongitude,
      assignedEmployeeIds: assignedEmployeeIds ?? this.assignedEmployeeIds,
      assignedEmployeeNames: assignedEmployeeNames ?? this.assignedEmployeeNames,
      assignedById: assignedById ?? this.assignedById,
      assignedByName: assignedByName ?? this.assignedByName,
      assignedDate: assignedDate ?? this.assignedDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subTasksStatus: subTasksStatus ?? this.subTasksStatus,
      subTasksStartTimes: subTasksStartTimes ?? this.subTasksStartTimes,
      subTasksCompletionTimes: subTasksCompletionTimes ?? this.subTasksCompletionTimes,
      subTasksPhotos: subTasksPhotos ?? this.subTasksPhotos,
      subTasksNotes: subTasksNotes ?? this.subTasksNotes,
      subTasksEmployeesPresent: subTasksEmployeesPresent ?? this.subTasksEmployeesPresent,
      solarPanelSerialNumbers: solarPanelSerialNumbers ?? this.solarPanelSerialNumbers,
      inverterSerialNumbers: inverterSerialNumbers ?? this.inverterSerialNumbers,
      dataCollectionCompletedAt: dataCollectionCompletedAt ?? this.dataCollectionCompletedAt,
      dataCollectionCompletedBy: dataCollectionCompletedBy ?? this.dataCollectionCompletedBy,
      verifiedById: verifiedById ?? this.verifiedById,
      verifiedByName: verifiedByName ?? this.verifiedByName,
      verifiedDate: verifiedDate ?? this.verifiedDate,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationNotes: verificationNotes ?? this.verificationNotes,
    );
  }
}

// GPS Location Model for verification
class GPSLocationModel {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String employeeId;
  final String employeeName;

  GPSLocationModel({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.employeeId,
    required this.employeeName,
  });

  factory GPSLocationModel.fromJson(Map<String, dynamic> json) {
    return GPSLocationModel(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      accuracy: json['accuracy'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      employeeId: json['employee_id'],
      employeeName: json['employee_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'employee_id': employeeId,
      'employee_name': employeeName,
    };
  }

  // Calculate distance from customer location in meters
  double distanceFromCustomer(double customerLat, double customerLng) {
    // Haversine formula for calculating distance between two GPS coordinates
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _degreesToRadians(customerLat - latitude);
    final double dLng = _degreesToRadians(customerLng - longitude);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(latitude)) * math.cos(_degreesToRadians(customerLat)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Check if location is within 50m of customer
  bool isWithin50MetersOfCustomer(double customerLat, double customerLng) {
    return distanceFromCustomer(customerLat, customerLng) <= 50.0;
  }
}
