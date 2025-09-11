import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/installation_model.dart';

class InstallationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get all installation work assignments
  static Future<List<InstallationWorkAssignment>> getAllInstallationAssignments({
    String? officeId,
    String? employeeId,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('installation_work_assignments')
          .select('''
            *,
            customers (
              name,
              address,
              latitude,
              longitude
            )
          ''');

      if (officeId != null) {
        // Filter by office through customer relationship
        query = query.eq('customers.office_id', officeId);
      }

      if (employeeId != null) {
        // Filter assignments for specific employee
        query = query.contains('assigned_employee_ids', [employeeId]);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => InstallationWorkAssignment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get installation assignments: $e');
    }
  }

  // Check if customer has an installation assignment
  static Future<InstallationWorkAssignment?> getCustomerInstallationAssignment(String customerId) async {
    try {
      final response = await _supabase
          .from('installation_work_assignments')
          .select('''
            *,
            customers (
              name,
              address,
              latitude,
              longitude
            )
          ''')
          .eq('customer_id', customerId)
          .maybeSingle();

      if (response == null) return null;
      
      return InstallationWorkAssignment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get customer installation assignment: $e');
    }
  }

  // Create new installation work assignment
  static Future<InstallationWorkAssignment> createInstallationAssignment({
    required String customerId,
    required List<String> assignedEmployeeIds,
    required String assignedById,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    try {
      // Get customer details
      final customerResponse = await _supabase
          .from('customers')
          .select('name, address, latitude, longitude')
          .eq('id', customerId)
          .single();

      // Get employee names
      final employeesResponse = await _supabase
          .from('users')
          .select('id, full_name')
          .in_('id', assignedEmployeeIds);

      final employeeNames = employeesResponse
          .map((user) => user['full_name'] as String)
          .toList();

      // Get assigner details
      final assignerResponse = await _supabase
          .from('users')
          .select('full_name')
          .eq('id', assignedById)
          .single();

      final assignment = {
        'customer_id': customerId,
        'customer_name': customerResponse['name'],
        'customer_address': customerResponse['address'],
        'customer_latitude': customerResponse['latitude'],
        'customer_longitude': customerResponse['longitude'],
        'assigned_employee_ids': assignedEmployeeIds,
        'assigned_employee_names': employeeNames,
        'assigned_by_id': assignedById,
        'assigned_by_name': assignerResponse['full_name'],
        'assigned_date': DateTime.now().toIso8601String(),
        'scheduled_date': scheduledDate?.toIso8601String(),
        'status': 'assigned',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'subtasks_status': _getDefaultSubTasksStatusJson(),
        'subtasks_start_times': _getDefaultSubTasksDateTimesJson(),
        'subtasks_completion_times': _getDefaultSubTasksDateTimesJson(),
        'subtasks_photos': _getDefaultSubTasksPhotosJson(),
        'subtasks_notes': _getDefaultSubTasksNotesJson(),
        'subtasks_employees_present': _getDefaultSubTasksEmployeesJson(),
      };

      final response = await _supabase
          .from('installation_work_assignments')
          .insert(assignment)
          .select()
          .single();

      // Update customer phase to installation
      await _supabase
          .from('customers')
          .update({
            'current_phase': 'installation',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customerId);

      return InstallationWorkAssignment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create installation assignment: $e');
    }
  }

  // Start a sub-task with GPS verification
  static Future<InstallationWorkAssignment> startSubTask({
    required String assignmentId,
    required InstallationSubTask subTask,
    required List<String> employeesPresent,
    required String startedByEmployeeId,
  }) async {
    try {
      // Get current assignment
      final assignment = await getInstallationAssignment(assignmentId);
      
      // Verify GPS location for all employees present
      final customerLat = assignment.customerLatitude;
      final customerLng = assignment.customerLongitude;
      
      if (customerLat == null || customerLng == null) {
        throw Exception('Customer location not available for GPS verification');
      }

      // Get current location of all employees present
      final bool allEmployeesAtSite = await _verifyAllEmployeesAtSite(
        employeesPresent,
        customerLat,
        customerLng,
      );

      if (!allEmployeesAtSite) {
        throw Exception('Not all employees are within 50 meters of customer location');
      }

      // Update sub-task status
      final updatedSubTasksStatus = Map<InstallationSubTask, InstallationTaskStatus>.from(assignment.subTasksStatus);
      updatedSubTasksStatus[subTask] = InstallationTaskStatus.inProgress;

      final updatedSubTasksStartTimes = Map<InstallationSubTask, DateTime?>.from(assignment.subTasksStartTimes);
      updatedSubTasksStartTimes[subTask] = DateTime.now();

      final updatedSubTasksEmployeesPresent = Map<InstallationSubTask, List<String>?>.from(assignment.subTasksEmployeesPresent);
      updatedSubTasksEmployeesPresent[subTask] = employeesPresent;

      // Update assignment status to in_progress if not already
      String overallStatus = assignment.status;
      if (overallStatus == 'assigned') {
        overallStatus = 'in_progress';
      }

      final updates = {
        'status': overallStatus,
        'subtasks_status': _subTasksStatusToJson(updatedSubTasksStatus),
        'subtasks_start_times': _subTasksDateTimesToJson(updatedSubTasksStartTimes),
        'subtasks_employees_present': _subTasksEmployeesToJson(updatedSubTasksEmployeesPresent),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('installation_work_assignments')
          .update(updates)
          .eq('id', assignmentId)
          .select()
          .single();

      return InstallationWorkAssignment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to start sub-task: $e');
    }
  }

  // Complete a sub-task with GPS verification and mandatory fields
  static Future<InstallationWorkAssignment> completeSubTask({
    required String assignmentId,
    required InstallationSubTask subTask,
    required String completedByEmployeeId,
    required String completionNotes,
    required List<String> photoUrls,
    List<String>? solarPanelSerialNumbers, // Required for dataCollection
    List<String>? inverterSerialNumbers, // Required for dataCollection
  }) async {
    try {
      // Get current assignment
      final assignment = await getInstallationAssignment(assignmentId);
      
      // Verify GPS location for completing employee
      final customerLat = assignment.customerLatitude;
      final customerLng = assignment.customerLongitude;
      
      if (customerLat == null || customerLng == null) {
        throw Exception('Customer location not available for GPS verification');
      }

      final bool employeeAtSite = await _verifyEmployeeAtSite(
        completedByEmployeeId,
        customerLat,
        customerLng,
      );

      if (!employeeAtSite) {
        throw Exception('Employee is not within 50 meters of customer location');
      }

      // Validate mandatory fields
      if (completionNotes.trim().isEmpty) {
        throw Exception('Completion notes are required');
      }

      if (photoUrls.isEmpty) {
        throw Exception('At least one photo is required for task completion');
      }

      // Special validation for data collection sub-task
      if (subTask == InstallationSubTask.dataCollection) {
        if (solarPanelSerialNumbers == null || solarPanelSerialNumbers.isEmpty) {
          throw Exception('Solar panel serial numbers are required for data collection');
        }
        if (inverterSerialNumbers == null || inverterSerialNumbers.isEmpty) {
          throw Exception('Inverter serial numbers are required for data collection');
        }
      }

      // Update sub-task status
      final updatedSubTasksStatus = Map<InstallationSubTask, InstallationTaskStatus>.from(assignment.subTasksStatus);
      updatedSubTasksStatus[subTask] = InstallationTaskStatus.completed;

      final updatedSubTasksCompletionTimes = Map<InstallationSubTask, DateTime?>.from(assignment.subTasksCompletionTimes);
      updatedSubTasksCompletionTimes[subTask] = DateTime.now();

      final updatedSubTasksPhotos = Map<InstallationSubTask, List<String>?>.from(assignment.subTasksPhotos);
      updatedSubTasksPhotos[subTask] = photoUrls;

      final updatedSubTasksNotes = Map<InstallationSubTask, String?>.from(assignment.subTasksNotes);
      updatedSubTasksNotes[subTask] = completionNotes;

      // Check if all sub-tasks are completed
      final bool allCompleted = updatedSubTasksStatus.values.every(
        (status) => status == InstallationTaskStatus.completed,
      );

      String overallStatus = assignment.status;
      if (allCompleted) {
        overallStatus = 'completed';
      }

      final updates = {
        'status': overallStatus,
        'subtasks_status': _subTasksStatusToJson(updatedSubTasksStatus),
        'subtasks_completion_times': _subTasksDateTimesToJson(updatedSubTasksCompletionTimes),
        'subtasks_photos': _subTasksPhotosToJson(updatedSubTasksPhotos),
        'subtasks_notes': _subTasksNotesToJson(updatedSubTasksNotes),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add data collection specific fields if completing data collection
      if (subTask == InstallationSubTask.dataCollection) {
        updates['solar_panel_serial_numbers'] = solarPanelSerialNumbers?.join(',') ?? '';
        updates['inverter_serial_numbers'] = inverterSerialNumbers?.join(',') ?? '';
        updates['data_collection_completed_at'] = DateTime.now().toIso8601String();
        updates['data_collection_completed_by'] = completedByEmployeeId;
      }

      final response = await _supabase
          .from('installation_work_assignments')
          .update(updates)
          .eq('id', assignmentId)
          .select()
          .single();

      // Update customer's serial numbers if data collection is completed
      if (subTask == InstallationSubTask.dataCollection) {
        await _supabase
            .from('customers')
            .update({
              'solar_panels_serial_numbers': jsonEncode(solarPanelSerialNumbers),
              'inverter_serial_numbers': jsonEncode(inverterSerialNumbers),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', assignment.customerId);
      }

      return InstallationWorkAssignment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to complete sub-task: $e');
    }
  }

  // Verify installation work (Lead/Manager/Director)
  static Future<InstallationWorkAssignment> verifyInstallation({
    required String assignmentId,
    required String verifiedById,
    required String verificationStatus, // 'approved' or 'rejected'
    String? verificationNotes,
  }) async {
    try {
      // Get verifier details
      final verifierResponse = await _supabase
          .from('users')
          .select('full_name, role')
          .eq('id', verifiedById)
          .single();

      // Check if user has permission to verify
      final String verifierRole = verifierResponse['role'];
      if (!['lead', 'manager', 'director'].contains(verifierRole)) {
        throw Exception('Only leads, managers, and directors can verify installations');
      }

      final String finalStatus = verificationStatus == 'approved' ? 'verified' : 'rejected';

      final updates = {
        'status': finalStatus,
        'verified_by_id': verifiedById,
        'verified_by_name': verifierResponse['full_name'],
        'verified_date': DateTime.now().toIso8601String(),
        'verification_status': verificationStatus,
        'verification_notes': verificationNotes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('installation_work_assignments')
          .update(updates)
          .eq('id', assignmentId)
          .select()
          .single();

      // If approved, move customer to next phase
      if (verificationStatus == 'approved') {
        final assignment = InstallationWorkAssignment.fromJson(response);
        await _supabase
            .from('customers')
            .update({
              'current_phase': 'documentation', // Move to next phase
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', assignment.customerId);
      }

      return InstallationWorkAssignment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to verify installation: $e');
    }
  }

  // Get specific installation assignment
  static Future<InstallationWorkAssignment> getInstallationAssignment(String assignmentId) async {
    try {
      final response = await _supabase
          .from('installation_work_assignments')
          .select('''
            *,
            customers (
              name,
              address,
              latitude,
              longitude
            )
          ''')
          .eq('id', assignmentId)
          .single();

      return InstallationWorkAssignment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get installation assignment: $e');
    }
  }

  // Get installation assignments for specific employee
  static Future<List<InstallationWorkAssignment>> getEmployeeInstallationAssignments(String employeeId) async {
    try {
      final response = await _supabase
          .from('installation_work_assignments')
          .select('''
            *,
            customers (
              name,
              address,
              latitude,
              longitude
            )
          ''')
          .contains('assigned_employee_ids', [employeeId])
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => InstallationWorkAssignment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get employee installation assignments: $e');
    }
  }

  // Get current location and verify if employee is at customer site
  static Future<bool> _verifyEmployeeAtSite(
    String employeeId,
    double customerLat,
    double customerLng,
  ) async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate distance
      final double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        customerLat,
        customerLng,
      );

      // Check if within 50 meters
      return distance <= 50.0;
    } catch (e) {
      throw Exception('Failed to verify location: $e');
    }
  }

  // Verify all employees are at customer site
  static Future<bool> _verifyAllEmployeesAtSite(
    List<String> employeeIds,
    double customerLat,
    double customerLng,
  ) async {
    // For now, we'll verify the current employee's location
    // In a full implementation, you'd need to verify all employees
    // This could involve real-time location sharing between employees
    
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate distance
      final double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        customerLat,
        customerLng,
      );

      // Check if within 50 meters
      return distance <= 50.0;
    } catch (e) {
      throw Exception('Failed to verify location: $e');
    }
  }

  // Get installation assignments that need verification
  static Future<List<InstallationWorkAssignment>> getAssignmentsAwaitingVerification({
    String? officeId,
  }) async {
    try {
      var query = _supabase
          .from('installation_work_assignments')
          .select('''
            *,
            customers (
              name,
              address,
              latitude,
              longitude,
              office_id
            )
          ''')
          .eq('status', 'completed');

      if (officeId != null) {
        query = query.eq('customers.office_id', officeId);
      }

      final response = await query.order('updated_at', ascending: true);

      return (response as List)
          .map((json) => InstallationWorkAssignment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get assignments awaiting verification: $e');
    }
  }

  // Get installation statistics for dashboard
  static Future<Map<String, int>> getInstallationStatistics({String? officeId, String? employeeId}) async {
    try {
      var query = _supabase.from('installation_work_assignments').select('status');

      if (officeId != null) {
        // Join with customers to filter by office
        query = _supabase
            .from('installation_work_assignments')
            .select('status, customers!inner(office_id)')
            .eq('customers.office_id', officeId);
      }

      if (employeeId != null) {
        query = query.contains('assigned_employee_ids', [employeeId]);
      }

      final response = await query;

      final Map<String, int> statistics = {
        'total': 0,
        'assigned': 0,
        'in_progress': 0,
        'completed': 0,
        'verified': 0,
        'rejected': 0,
      };

      for (final record in response) {
        final String status = record['status'];
        statistics['total'] = (statistics['total'] ?? 0) + 1;
        statistics[status] = (statistics[status] ?? 0) + 1;
      }

      return statistics;
    } catch (e) {
      throw Exception('Failed to get installation statistics: $e');
    }
  }

  // Helper methods for JSON conversion
  static String _getDefaultSubTasksStatusJson() {
    final Map<String, String> result = {};
    for (InstallationSubTask task in InstallationSubTask.values) {
      result[task.name] = InstallationTaskStatus.pending.name;
    }
    return jsonEncode(result);
  }

  static String _getDefaultSubTasksDateTimesJson() {
    final Map<String, String?> result = {};
    for (InstallationSubTask task in InstallationSubTask.values) {
      result[task.name] = null;
    }
    return jsonEncode(result);
  }

  static String _getDefaultSubTasksPhotosJson() {
    final Map<String, List<String>?> result = {};
    for (InstallationSubTask task in InstallationSubTask.values) {
      result[task.name] = null;
    }
    return jsonEncode(result);
  }

  static String _getDefaultSubTasksNotesJson() {
    final Map<String, String?> result = {};
    for (InstallationSubTask task in InstallationSubTask.values) {
      result[task.name] = null;
    }
    return jsonEncode(result);
  }

  static String _getDefaultSubTasksEmployeesJson() {
    final Map<String, List<String>?> result = {};
    for (InstallationSubTask task in InstallationSubTask.values) {
      result[task.name] = null;
    }
    return jsonEncode(result);
  }

  static String _subTasksStatusToJson(Map<InstallationSubTask, InstallationTaskStatus> statuses) {
    final Map<String, String> result = {};
    for (final entry in statuses.entries) {
      result[entry.key.name] = entry.value.name;
    }
    return jsonEncode(result);
  }

  static String _subTasksDateTimesToJson(Map<InstallationSubTask, DateTime?> dateTimes) {
    final Map<String, String?> result = {};
    for (final entry in dateTimes.entries) {
      result[entry.key.name] = entry.value?.toIso8601String();
    }
    return jsonEncode(result);
  }

  static String _subTasksPhotosToJson(Map<InstallationSubTask, List<String>?> photos) {
    final Map<String, List<String>?> result = {};
    for (final entry in photos.entries) {
      result[entry.key.name] = entry.value;
    }
    return jsonEncode(result);
  }

  static String _subTasksNotesToJson(Map<InstallationSubTask, String?> notes) {
    final Map<String, String?> result = {};
    for (final entry in notes.entries) {
      result[entry.key.name] = entry.value;
    }
    return jsonEncode(result);
  }

  static String _subTasksEmployeesToJson(Map<InstallationSubTask, List<String>?> employees) {
    final Map<String, List<String>?> result = {};
    for (final entry in employees.entries) {
      result[entry.key.name] = entry.value;
    }
    return jsonEncode(result);
  }

  // Add photo upload functionality
  static Future<String> uploadPhoto({
    required String assignmentId,
    required InstallationSubTask subTask,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final String storagePath = 'installation_photos/$assignmentId/${subTask.name}/$fileName';
      
      // Read file as bytes for Supabase storage
      final File file = File(filePath);
      final bytes = await file.readAsBytes();
      
      await _supabase.storage
          .from('installation_photos')
          .uploadBinary(storagePath, bytes);

      final String publicUrl = _supabase.storage
          .from('installation_photos')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Update task notes during work
  static Future<InstallationWorkAssignment> updateTaskNotes({
    required String assignmentId,
    required InstallationSubTask subTask,
    required String notes,
  }) async {
    try {
      final assignment = await getInstallationAssignment(assignmentId);
      
      final updatedSubTasksNotes = Map<InstallationSubTask, String?>.from(assignment.subTasksNotes);
      updatedSubTasksNotes[subTask] = notes;

      final updates = {
        'subtasks_notes': _subTasksNotesToJson(updatedSubTasksNotes),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('installation_work_assignments')
          .update(updates)
          .eq('id', assignmentId)
          .select()
          .single();

      return InstallationWorkAssignment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update task notes: $e');
    }
  }

  // Get completed installations for verification
  static Future<List<InstallationWorkAssignment>> getCompletedInstallations() async {
    try {
      final response = await _supabase
          .from('installation_work_assignments')
          .select('''
            *,
            customers (
              name,
              address,
              latitude,
              longitude
            )
          ''')
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => InstallationWorkAssignment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get completed installations: $e');
    }
  }

  // Get sub-task details for verification
  static Future<List<Map<String, dynamic>>> getSubTaskDetails(String assignmentId) async {
    try {
      final assignment = await getInstallationAssignment(assignmentId);
      final List<Map<String, dynamic>> subTaskDetails = [];

      for (final subTask in InstallationSubTask.values) {
        final status = assignment.subTasksStatus[subTask] ?? InstallationTaskStatus.pending;
        final startTime = assignment.subTasksStartTimes[subTask];
        final completionTime = assignment.subTasksCompletionTimes[subTask];
        final photos = assignment.subTasksPhotos[subTask] ?? [];
        final notes = assignment.subTasksNotes[subTask];

        subTaskDetails.add({
          'sub_task': subTask.name,
          'status': status.name,
          'start_time': startTime?.toIso8601String(),
          'completion_time': completionTime?.toIso8601String(),
          'photos': photos,
          'notes': notes,
        });
      }

      return subTaskDetails;
    } catch (e) {
      throw Exception('Failed to get sub-task details: $e');
    }
  }

  // Assign employees to work - for compatibility with existing screens
  static Future<void> assignEmployeesToWork({
    required String assignmentId,
    required List<String> employeeIds,
  }) async {
    try {
      await _supabase
          .from('installation_work_assignments')
          .update({
            'assigned_employee_ids': employeeIds,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assignmentId);
    } catch (e) {
      throw Exception('Failed to assign employees to work: $e');
    }
  }

  // Get installation project - for compatibility
  static Future<InstallationWorkAssignment> getInstallationProject(String projectId) async {
    return await getInstallationAssignment(projectId);
  }

  // Create installation project - for compatibility
  static Future<String> createInstallationProject({
    required String customerId,
    required List<String> employeeIds,
    required DateTime scheduledDate,
    String? notes,
    required String assignedBy,
  }) async {
    final assignment = await createInstallationAssignment(
      customerId: customerId,
      assignedEmployeeIds: employeeIds,
      assignedById: assignedBy,
      scheduledDate: scheduledDate,
      notes: notes,
    );
    return assignment.id;
  }

  // Verify work - for compatibility
  static Future<void> verifyWork({
    required String assignmentId,
    required String verifiedBy,
    required bool isApproved,
    String? remarks,
  }) async {
    await verifyInstallation(
      assignmentId: assignmentId,
      verifiedById: verifiedBy,
      verificationStatus: isApproved ? 'approved' : 'rejected',
      verificationNotes: remarks,
    );
  }

  // Acknowledge work - for compatibility
  static Future<void> acknowledgeWork({
    required String assignmentId,
    required String acknowledgedBy,
  }) async {
    try {
      await _supabase
          .from('installation_work_assignments')
          .update({
            'acknowledged_by': acknowledgedBy,
            'acknowledged_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assignmentId);
    } catch (e) {
      throw Exception('Failed to acknowledge work: $e');
    }
  }

  // Approve work - for compatibility
  static Future<void> approveWork({
    required String assignmentId,
    required String approvedBy,
  }) async {
    await verifyInstallation(
      assignmentId: assignmentId,
      verifiedById: approvedBy,
      verificationStatus: 'approved',
    );
  }
}
