import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workflow_models.dart';

class WorkflowService {
  final SupabaseClient supabase = Supabase.instance.client;
  // Customer Status Management
  Future<List<CustomerStatusModel>> getCustomerStatusHistory(
    String customerId,
  ) async {
    try {
      final response = await supabase
          .from('customer_status_history')
          .select('''
            *,
            users!customer_status_history_assigned_user_id_fkey(full_name)
          ''')
          .eq('customer_id', customerId)
          .order('status_date', ascending: true);

      return response.map((json) {
        json['assigned_user_name'] = json['users']?['full_name'];
        return CustomerStatusModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get customer status history: $e');
    }
  }

  Future<CustomerStatusModel?> getCurrentCustomerStatus(
    String customerId,
  ) async {
    try {
      final response = await supabase
          .from('customer_status_history')
          .select('''
            *,
            users!customer_status_history_assigned_user_id_fkey(full_name)
          ''')
          .eq('customer_id', customerId)
          .order('status_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      response['assigned_user_name'] = response['users']?['full_name'];
      return CustomerStatusModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get current customer status: $e');
    }
  }

  Future<void> updateCustomerStatus({
    required String customerId,
    required CustomerStatus status,
    String? assignedUserId,
    String? notes,
    List<String>? documents,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await supabase.from('customer_status_history').insert({
        'customer_id': customerId,
        'status': status.name,
        'status_date': DateTime.now().toIso8601String(),
        'assigned_user_id': assignedUserId,
        'notes': notes,
        'documents': documents,
        'metadata': metadata,
      });
    } catch (e) {
      throw Exception('Failed to update customer status: $e');
    }
  }

  // Work Assignment Management
  Future<List<WorkAssignmentModel>> getWorkAssignments({
    String? officeId,
    CustomerStatus? stage,
    String? assignedUserId,
    bool? isCompleted,
  }) async {
    try {
      var query = supabase.from('work_assignments').select('''
            *,
            customers!work_assignments_customer_id_fkey(name, address)
          ''');

      if (officeId != null) {
        query = query.eq('office_id', officeId);
      }
      if (stage != null) {
        query = query.eq('work_stage', stage.name);
      }
      if (assignedUserId != null) {
        query = query.contains('assigned_user_ids', [assignedUserId]);
      }
      if (isCompleted != null) {
        query = query.eq('is_completed', isCompleted);
      }

      final response = await query.order('created_at', ascending: false);

      return response.map((json) {
        json['customer_name'] = json['customers']?['name'];
        json['customer_address'] = json['customers']?['address'];
        return WorkAssignmentModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get work assignments: $e');
    }
  }

  Future<WorkAssignmentModel> createWorkAssignment({
    required String customerId,
    required CustomerStatus workStage,
    required List<String> assignedUserIds,
    required WorkLocation location,
    String? locationNotes,
    DateTime? scheduledDate,
    String? notes,
    required String officeId,
  }) async {
    try {
      // Get user names for the assigned users
      final usersResponse = await supabase
          .from('users')
          .select('id, full_name')
          .in_('id', assignedUserIds);

      final assignedUserNames = usersResponse
          .map((user) => user['full_name'] as String)
          .toList();

      final response = await supabase
          .from('work_assignments')
          .insert({
            'customer_id': customerId,
            'work_stage': workStage.name,
            'assigned_user_ids': assignedUserIds,
            'assigned_user_names': assignedUserNames,
            'location': location.name,
            'location_notes': locationNotes,
            'scheduled_date': scheduledDate?.toIso8601String(),
            'notes': notes,
            'office_id': officeId,
            'components_used': <Map<String, dynamic>>[],
            'is_completed': false,
          })
          .select('''
            *,
            customers!work_assignments_customer_id_fkey(name, address)
          ''')
          .single();

      response['customer_name'] = response['customers']?['name'];
      response['customer_address'] = response['customers']?['address'];
      return WorkAssignmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create work assignment: $e');
    }
  }

  Future<void> addEmployeeToAssignment({
    required String assignmentId,
    required String userId,
    required String userName,
  }) async {
    try {
      // Get current assignment
      final current = await supabase
          .from('work_assignments')
          .select('assigned_user_ids, assigned_user_names')
          .eq('id', assignmentId)
          .single();

      final currentUserIds = List<String>.from(current['assigned_user_ids']);
      final currentUserNames = List<String>.from(
        current['assigned_user_names'],
      );

      if (!currentUserIds.contains(userId)) {
        currentUserIds.add(userId);
        currentUserNames.add(userName);

        await supabase
            .from('work_assignments')
            .update({
              'assigned_user_ids': currentUserIds,
              'assigned_user_names': currentUserNames,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', assignmentId);
      }
    } catch (e) {
      throw Exception('Failed to add employee to assignment: $e');
    }
  }

  Future<void> updateWorkProgress({
    required String assignmentId,
    DateTime? startedAt,
    DateTime? completedAt,
    List<ComponentUsage>? componentsUsed,
    String? notes,
    List<String>? attachments,
    bool? isCompleted,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (startedAt != null)
        updateData['started_at'] = startedAt.toIso8601String();
      if (completedAt != null)
        updateData['completed_at'] = completedAt.toIso8601String();
      if (componentsUsed != null) {
        updateData['components_used'] = componentsUsed
            .map((c) => c.toJson())
            .toList();
      }
      if (notes != null) updateData['notes'] = notes;
      if (attachments != null) updateData['attachments'] = attachments;
      if (isCompleted != null) updateData['is_completed'] = isCompleted;

      await supabase
          .from('work_assignments')
          .update(updateData)
          .eq('id', assignmentId);
    } catch (e) {
      throw Exception('Failed to update work progress: $e');
    }
  }

  // Inventory Management
  Future<List<InventoryComponentModel>> getInventoryComponents({
    String? officeId,
    String? category,
    bool? lowStockOnly,
  }) async {
    try {
      var query = supabase.from('inventory_components').select('*');

      if (officeId != null) {
        query = query.eq('office_id', officeId);
      }
      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query
          .eq('is_active', true)
          .order('name', ascending: true);

      var components = response
          .map((json) => InventoryComponentModel.fromJson(json))
          .toList();

      if (lowStockOnly == true) {
        components = components.where((c) => c.isLowStock).toList();
      }

      return components;
    } catch (e) {
      throw Exception('Failed to get inventory components: $e');
    }
  }

  Future<void> updateInventoryStock({
    required String componentId,
    required int quantityUsed,
    required String workAssignmentId,
  }) async {
    try {
      // Get current stock
      final component = await supabase
          .from('inventory_components')
          .select('current_stock')
          .eq('id', componentId)
          .single();

      final currentStock = component['current_stock'] as int;
      final newStock = currentStock - quantityUsed;

      if (newStock < 0) {
        throw Exception('Insufficient stock available');
      }

      // Update stock
      await supabase
          .from('inventory_components')
          .update({
            'current_stock': newStock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', componentId);

      // Log stock usage
      await supabase.from('stock_usage_log').insert({
        'component_id': componentId,
        'work_assignment_id': workAssignmentId,
        'quantity_used': quantityUsed,
        'stock_before': currentStock,
        'stock_after': newStock,
      });
    } catch (e) {
      throw Exception('Failed to update inventory stock: $e');
    }
  }

  // Complaint Management
  Future<List<CustomerComplaintModel>> getCustomerComplaints({
    String? officeId,
    String? customerId,
    String? assignedUserId,
    ComplaintType? type,
    ServiceType? serviceType,
    String? status,
  }) async {
    try {
      var query = supabase.from('customer_complaints').select('''
            *,
            customers!customer_complaints_customer_id_fkey(name)
          ''');

      if (officeId != null) {
        query = query.eq('office_id', officeId);
      }
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      if (assignedUserId != null) {
        query = query.contains('assigned_user_ids', [assignedUserId]);
      }
      if (type != null) {
        query = query.eq('type', type.name);
      }
      if (serviceType != null) {
        query = query.eq('service_type', serviceType.name);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return response.map((json) {
        json['customer_name'] = json['customers']?['name'];
        return CustomerComplaintModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get customer complaints: $e');
    }
  }

  Future<CustomerComplaintModel> createComplaint({
    required String customerId,
    required ComplaintType type,
    required String title,
    required String description,
    required List<String> assignedUserIds,
    String? priority = 'medium',
    required String officeId,
  }) async {
    try {
      // Get customer installation date to determine warranty eligibility
      final customerStatus = await getCurrentCustomerStatus(customerId);
      final isCompleted = customerStatus?.status == CustomerStatus.completed;

      DateTime? installationDate;
      bool isUnderWarranty = false;
      ServiceType serviceType = ServiceType.paidService;

      if (isCompleted && customerStatus != null) {
        installationDate = customerStatus.statusDate;
        final daysSinceInstallation = DateTime.now()
            .difference(installationDate)
            .inDays;
        isUnderWarranty =
            daysSinceInstallation <= (5 * 365); // 5 years warranty

        if (isUnderWarranty) {
          serviceType = ServiceType.freeService;
        }
      }

      // Get user names
      final usersResponse = await supabase
          .from('users')
          .select('id, full_name')
          .in_('id', assignedUserIds);

      final assignedUserNames = usersResponse
          .map((user) => user['full_name'] as String)
          .toList();

      final response = await supabase
          .from('customer_complaints')
          .insert({
            'customer_id': customerId,
            'type': type.name,
            'title': title,
            'description': description,
            'service_type': serviceType.name,
            'is_under_warranty': isUnderWarranty,
            'installation_date': installationDate?.toIso8601String(),
            'priority': priority,
            'status': 'open',
            'assigned_user_ids': assignedUserIds,
            'assigned_user_names': assignedUserNames,
            'office_id': officeId,
          })
          .select('''
            *,
            customers!customer_complaints_customer_id_fkey(name)
          ''')
          .single();

      response['customer_name'] = response['customers']?['name'];
      return CustomerComplaintModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create complaint: $e');
    }
  }

  Future<void> resolveComplaint({
    required String complaintId,
    required String resolution,
    List<ComponentUsage>? componentsUsed,
    double? serviceCost,
  }) async {
    try {
      await supabase
          .from('customer_complaints')
          .update({
            'status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
            'resolution': resolution,
            'components_used': componentsUsed?.map((c) => c.toJson()).toList(),
            'service_cost': serviceCost,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', complaintId);
    } catch (e) {
      throw Exception('Failed to resolve complaint: $e');
    }
  }

  // Analytics and Reports
  Future<Map<String, dynamic>> getWorkflowAnalytics(String officeId) async {
    try {
      // Get customer status distribution
      final statusDistribution = await supabase.rpc(
        'get_customer_status_distribution',
        params: {'office_id': officeId},
      );

      // Get work assignment metrics
      final workMetrics = await supabase.rpc(
        'get_work_assignment_metrics',
        params: {'office_id': officeId},
      );

      // Get complaint metrics
      final complaintMetrics = await supabase.rpc(
        'get_complaint_metrics',
        params: {'office_id': officeId},
      );

      // Get inventory status
      final inventoryStatus = await supabase.rpc(
        'get_inventory_status',
        params: {'office_id': officeId},
      );

      return {
        'status_distribution': statusDistribution,
        'work_metrics': workMetrics,
        'complaint_metrics': complaintMetrics,
        'inventory_status': inventoryStatus,
      };
    } catch (e) {
      throw Exception('Failed to get workflow analytics: $e');
    }
  }
}
