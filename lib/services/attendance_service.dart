import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Check if user has an active check-in for today
  Future<AttendanceModel?> getTodayActiveAttendance() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('attendance')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('status', 'checked_in')
          .gte('check_in_time', startOfDay.toIso8601String())
          .lt('check_in_time', endOfDay.toIso8601String())
          .maybeSingle();

      if (response != null) {
        return AttendanceModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting today\'s active attendance: $e');
      return null;
    }
  }

  // Check if user has checked in today (for any status)
  Future<bool> hasCheckedInToday(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('attendance')
          .select('id')
          .eq('user_id', userId)
          .gte('check_in_time', startOfDay.toIso8601String())
          .lt('check_in_time', endOfDay.toIso8601String())
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking if user has checked in today: $e');
      return false;
    }
  }

  // Get current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Check in
  Future<AttendanceModel> checkIn({String? officeId, String? notes}) async {
    try {
      // Check if already checked in today
      final existingAttendance = await getTodayActiveAttendance();
      if (existingAttendance != null) {
        throw Exception('You are already checked in today');
      }

      // Get current location
      final position = await _getCurrentLocation();

      final now = DateTime.now();
      final attendanceData = {
        'user_id': _supabase.auth.currentUser!.id,
        'office_id': officeId,
        'check_in_time': now.toIso8601String(),
        'check_in_latitude': position.latitude,
        'check_in_longitude': position.longitude,
        'attendance_date': now.toIso8601String().split(
          'T',
        )[0], // Just the date part
        'status': 'checked_in',
        'notes': notes,
        'created_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('attendance')
          .insert(attendanceData)
          .select()
          .single();

      return AttendanceModel.fromJson(response);
    } catch (e) {
      print('Error checking in: $e');
      rethrow;
    }
  }

  // Check out
  Future<AttendanceModel> checkOut({String? notes}) async {
    try {
      // Get today's active attendance
      final activeAttendance = await getTodayActiveAttendance();
      if (activeAttendance == null) {
        throw Exception('No active check-in found for today');
      }

      // Get current location
      final position = await _getCurrentLocation();

      final now = DateTime.now();

      final updateData = {
        'check_out_time': now.toIso8601String(),
        'check_out_latitude': position.latitude,
        'check_out_longitude': position.longitude,
        'status': 'checked_out',
        'notes': notes ?? activeAttendance.notes,
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('attendance')
          .update(updateData)
          .eq('id', activeAttendance.id!)
          .select()
          .single();

      return AttendanceModel.fromJson(response);
    } catch (e) {
      print('Error checking out: $e');
      rethrow;
    }
  }

  // Get attendance history for current user
  Future<List<AttendanceModel>> getAttendanceHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    try {
      // Build query step by step
      var query = _supabase
          .from('attendance')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id);

      // Apply date filters and ordering as a single chain
      final response =
          await (startDate != null && endDate != null
                  ? query
                        .gte('check_in_time', startDate.toIso8601String())
                        .lte('check_in_time', endDate.toIso8601String())
                        .order('check_in_time', ascending: false)
                        .limit(limit)
                  : startDate != null
                  ? query
                        .gte('check_in_time', startDate.toIso8601String())
                        .order('check_in_time', ascending: false)
                        .limit(limit)
                  : endDate != null
                  ? query
                        .lte('check_in_time', endDate.toIso8601String())
                        .order('check_in_time', ascending: false)
                        .limit(limit)
                  : query.order('check_in_time', ascending: false).limit(limit))
              as List<dynamic>;

      return response
          .map<AttendanceModel>(
            (attendance) =>
                AttendanceModel.fromJson(attendance as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting attendance history: $e');
      return [];
    }
  }

  // Get attendance for specific date
  Future<AttendanceModel?> getAttendanceForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('attendance')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .gte('check_in_time', startOfDay.toIso8601String())
          .lt('check_in_time', endOfDay.toIso8601String())
          .maybeSingle();

      if (response != null) {
        return AttendanceModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting attendance for date: $e');
      return null;
    }
  }

  // Get weekly attendance summary
  Future<Map<String, dynamic>> getWeeklyAttendanceSummary() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final attendances = await getAttendanceHistory(
        startDate: startOfWeek,
        endDate: endOfWeek,
      );

      int totalDays = attendances.length;
      Duration totalHours = Duration.zero;
      int onTimeCount = 0;

      for (final attendance in attendances) {
        // Calculate hours dynamically from check-in and check-out times
        if (attendance.checkOutTime != null) {
          final duration = attendance.checkOutTime!.difference(
            attendance.checkInTime,
          );
          totalHours += duration;
        }

        // Consider on-time if checked in before 9 AM (you can adjust this)
        if (attendance.checkInTime.hour < 9) {
          onTimeCount++;
        }
      }

      return {
        'totalDays': totalDays,
        'totalHours': totalHours,
        'onTimeCount': onTimeCount,
        'averageHours': totalDays > 0
            ? Duration(
                milliseconds: (totalHours.inMilliseconds / totalDays).round(),
              )
            : Duration.zero,
      };
    } catch (e) {
      print('Error getting weekly summary: $e');
      return {
        'totalDays': 0,
        'totalHours': Duration.zero,
        'onTimeCount': 0,
        'averageHours': Duration.zero,
      };
    }
  }

  // Get attendance records for office (Director functionality)
  Future<List<AttendanceModel>> getOfficeAttendanceRecords({
    String? officeId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int limit = 100,
  }) async {
    try {
      var query = _supabase.from('attendance').select('*');

      // Filter by office if provided
      if (officeId != null) {
        query = query.eq('office_id', officeId);
      }

      // Filter by user if provided
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      // Filter by status if provided
      if (status != null) {
        query = query.eq('status', status);
      }

      // Apply date range filters and ordering as a single chain
      final response =
          await (startDate != null && endDate != null
                  ? query
                        .gte('check_in_time', startDate.toIso8601String())
                        .lte('check_in_time', endDate.toIso8601String())
                        .order('check_in_time', ascending: false)
                        .limit(limit)
                  : startDate != null
                  ? query
                        .gte('check_in_time', startDate.toIso8601String())
                        .order('check_in_time', ascending: false)
                        .limit(limit)
                  : endDate != null
                  ? query
                        .lte('check_in_time', endDate.toIso8601String())
                        .order('check_in_time', ascending: false)
                        .limit(limit)
                  : query.order('check_in_time', ascending: false).limit(limit))
              as List<dynamic>;

      return response
          .map<AttendanceModel>(
            (attendance) =>
                AttendanceModel.fromJson(attendance as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting office attendance records: $e');
      return [];
    }
  }

  // Get attendance statistics for office
  Future<Map<String, dynamic>> getOfficeAttendanceStatistics({
    String? officeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final records = await getOfficeAttendanceRecords(
        officeId: officeId,
        startDate: startDate,
        endDate: endDate,
        limit: 1000, // Higher limit for statistics
      );

      final totalRecords = records.length;
      final completedRecords = records
          .where((r) => r.status == 'checked_out')
          .length;
      final activeRecords = totalRecords - completedRecords;

      Duration totalDuration = Duration.zero;
      int onTimeCount = 0;

      for (final record in records) {
        if (record.checkOutTime != null) {
          totalDuration += record.checkOutTime!.difference(record.checkInTime);
        }

        // Consider on-time if checked in before 9 AM
        if (record.checkInTime.hour < 9) {
          onTimeCount++;
        }
      }

      final avgDuration = completedRecords > 0
          ? Duration(
              milliseconds: (totalDuration.inMilliseconds / completedRecords)
                  .round(),
            )
          : Duration.zero;

      return {
        'totalRecords': totalRecords,
        'completedRecords': completedRecords,
        'activeRecords': activeRecords,
        'totalDuration': totalDuration,
        'averageDuration': avgDuration,
        'onTimeCount': onTimeCount,
        'onTimePercentage': totalRecords > 0
            ? (onTimeCount / totalRecords * 100).round()
            : 0,
      };
    } catch (e) {
      print('Error getting office attendance statistics: $e');
      return {
        'totalRecords': 0,
        'completedRecords': 0,
        'activeRecords': 0,
        'totalDuration': Duration.zero,
        'averageDuration': Duration.zero,
        'onTimeCount': 0,
        'onTimePercentage': 0,
      };
    }
  }

  // Get attendance records with user details (for leads/managers)
  Future<List<Map<String, dynamic>>> getAttendanceWithUserDetails({
    String? officeId,
    DateTime? date,
    String? status,
  }) async {
    try {
      // First, get attendance records
      var query = _supabase.from('attendance').select('*');

      // Filter by office if provided
      if (officeId != null) {
        query = query.eq('office_id', officeId);
      }

      // Filter by date if provided
      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        query = query
            .gte('check_in_time', startOfDay.toIso8601String())
            .lt('check_in_time', endOfDay.toIso8601String());
      } else {
        // Default to today
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        query = query
            .gte('check_in_time', startOfDay.toIso8601String())
            .lt('check_in_time', endOfDay.toIso8601String());
      }

      // Filter by status if provided
      if (status != null) {
        query = query.eq('status', status);
      }

      final attendanceRecords = await query.order(
        'check_in_time',
        ascending: false,
      );

      // If no records, return empty list
      if (attendanceRecords.isEmpty) {
        return [];
      }

      // Get unique user IDs
      final userIds = (attendanceRecords as List<dynamic>)
          .map((record) => record['user_id'] as String)
          .toSet()
          .toList();

      // Fetch user details
      final usersResponse = await _supabase
          .from('users')
          .select('id, full_name, email, role, is_lead')
          .in_('id', userIds);

      // Create a map of user details for quick lookup
      final userMap = <String, Map<String, dynamic>>{};
      for (var user in usersResponse as List<dynamic>) {
        userMap[user['id'] as String] = user as Map<String, dynamic>;
      }

      // Combine attendance with user details
      final result = <Map<String, dynamic>>[];
      for (var attendance in attendanceRecords) {
        final attendanceMap = attendance as Map<String, dynamic>;
        final userId = attendanceMap['user_id'] as String;
        final userDetails = userMap[userId];

        if (userDetails != null) {
          // Create a combined record
          final combined = Map<String, dynamic>.from(attendanceMap);
          combined['users'] = userDetails;
          result.add(combined);
        }
      }

      return result;
    } catch (e) {
      print('Error getting attendance with user details: $e');
      return [];
    }
  }

  // Get today's team attendance (for leads)
  Future<List<Map<String, dynamic>>> getTodayTeamAttendance(
    String officeId,
  ) async {
    try {
      return await getAttendanceWithUserDetails(
        officeId: officeId,
        date: DateTime.now(),
      );
    } catch (e) {
      print('Error getting today\'s team attendance: $e');
      return [];
    }
  }

  // Get attendance summary by user (for reporting)
  Future<Map<String, dynamic>> getUserAttendanceSummary({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final records = await getOfficeAttendanceRecords(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      final totalDays = records.length;
      final completedDays = records
          .where((r) => r.status == 'checked_out')
          .length;
      final presentDays = records.where((r) => r.checkInTime.hour < 9).length;

      Duration totalHours = Duration.zero;
      for (final record in records.where((r) => r.checkOutTime != null)) {
        totalHours += record.checkOutTime!.difference(record.checkInTime);
      }

      return {
        'totalDays': totalDays,
        'completedDays': completedDays,
        'presentDays': presentDays,
        'totalHours': totalHours,
        'averageHours': completedDays > 0
            ? Duration(
                milliseconds: (totalHours.inMilliseconds / completedDays)
                    .round(),
              )
            : Duration.zero,
        'attendanceRate': totalDays > 0
            ? (completedDays / totalDays * 100).round()
            : 0,
      };
    } catch (e) {
      print('Error getting user attendance summary: $e');
      return {
        'totalDays': 0,
        'completedDays': 0,
        'presentDays': 0,
        'totalHours': Duration.zero,
        'averageHours': Duration.zero,
        'attendanceRate': 0,
      };
    }
  }
}
