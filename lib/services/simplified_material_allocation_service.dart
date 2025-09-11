import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';
import '../models/stock_item_model.dart';

class SimplifiedMaterialAllocationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Save as draft (planned) - Available to Lead, Manager, Director
  static Future<CustomerModel> saveAsDraft({
    required String customerId,
    required Map<String, dynamic> allocationPlan,
    required String plannedById,
    String? notes,
  }) async {
    try {
      final planJson = jsonEncode(allocationPlan);
      final now = DateTime.now();

      final response = await _supabase
          .from('customers')
          .update({
            'material_allocation_plan': planJson,
            'material_allocation_status': 'planned',
            'material_allocated_by_id':
                plannedById, // Used for permission checking
            'material_planned_by_id': plannedById,
            'material_planned_date': now.toIso8601String(),
            'material_allocation_notes': notes,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', customerId)
          .select()
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save material allocation draft: $e');
    }
  }

  // Proceed with allocation (allocated) - Available to Manager, Director only
  static Future<CustomerModel> proceedWithAllocation({
    required String customerId,
    required String allocatedById,
    Map<String, dynamic>? updatedAllocationPlan,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final updateData = <String, dynamic>{
        'material_allocation_status': 'allocated',
        'material_allocated_by_id': allocatedById,
        'material_allocation_date': now
            .toIso8601String(), // Add allocation date
        'updated_at': now.toIso8601String(),
      };

      // If allocation plan is updated
      if (updatedAllocationPlan != null) {
        updateData['material_allocation_plan'] = jsonEncode(
          updatedAllocationPlan,
        );
      }

      if (notes != null) {
        updateData['material_allocation_notes'] = notes;
      }

      final response = await _supabase
          .from('customers')
          .update(updateData)
          .eq('id', customerId)
          .select()
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to proceed with allocation: $e');
    }
  }

  // Confirm allocation (confirmed) - Director only, triggers stock deduction
  static Future<CustomerModel> confirmAllocation({
    required String customerId,
    required String confirmedById,
  }) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('customers')
          .update({
            'material_allocation_status': 'confirmed',
            'material_allocated_by_id':
                confirmedById, // Keep this to track who confirmed
            'material_confirmed_by_id': confirmedById,
            'material_confirmed_date': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', customerId)
          .select()
          .single();

      // Stock deduction happens automatically via database trigger
      return CustomerModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to confirm allocation: $e');
    }
  }

  // Check if user can edit allocation based on role and current status
  static bool canEditAllocation(String userRole, String currentStatus) {
    switch (userRole.toLowerCase()) {
      case 'lead':
        return ['pending', 'planned'].contains(currentStatus);
      case 'manager':
        return ['pending', 'planned', 'allocated'].contains(currentStatus);
      case 'director':
        return currentStatus != 'confirmed';
      default:
        return false;
    }
  }

  // Check if user can proceed with allocation
  static bool canProceedAllocation(String userRole, String currentStatus) {
    return ['manager', 'director'].contains(userRole.toLowerCase()) &&
        ['planned'].contains(currentStatus);
  }

  // Check if user can confirm allocation
  static bool canConfirmAllocation(String userRole, String currentStatus) {
    return userRole.toLowerCase() == 'director' && currentStatus == 'allocated';
  }

  // Check if allocation is visible to employees
  static bool isVisibleToEmployees(String currentStatus) {
    return currentStatus == 'confirmed';
  }

  // Get customers with material allocation filtered by role permissions
  static Future<List<CustomerModel>> getCustomersWithMaterialAllocation({
    String? officeId,
    String? status,
    String? userRole,
    int limit = 50,
  }) async {
    try {
      final List<Map<String, dynamic>> response = await _supabase
          .from('customers')
          .select()
          .not('material_allocation_status', 'is', null);

      var customers = response
          .map((json) => CustomerModel.fromJson(json))
          .toList();

      // Apply filters in Dart
      if (officeId != null) {
        customers = customers.where((c) => c.officeId == officeId).toList();
      }

      if (status != null) {
        customers = customers
            .where((c) => c.materialAllocationStatus == status)
            .toList();
      }

      // Apply role-based filtering
      if (userRole != null) {
        switch (userRole.toLowerCase()) {
          case 'employee':
            customers = customers
                .where((c) => c.materialAllocationStatus == 'confirmed')
                .toList();
            break;
          case 'lead':
            customers = customers
                .where(
                  (c) => [
                    'pending',
                    'planned',
                  ].contains(c.materialAllocationStatus),
                )
                .toList();
            break;
          case 'manager':
            customers = customers
                .where(
                  (c) => [
                    'pending',
                    'planned',
                    'allocated',
                  ].contains(c.materialAllocationStatus),
                )
                .toList();
            break;
          case 'director':
            // Directors can see all statuses
            break;
        }
      }

      // Sort and limit
      customers.sort((a, b) {
        final aDate = a.materialPlannedDate?.toString() ?? '';
        final bDate = b.materialPlannedDate?.toString() ?? '';
        return bDate.compareTo(aDate);
      });
      if (customers.length > limit) {
        customers = customers.take(limit).toList();
      }

      return customers;
    } catch (e) {
      throw Exception('Failed to get customers with material allocation: $e');
    }
  }

  // Validate allocation plan items against current stock
  static Future<Map<String, dynamic>> validateAllocationPlan({
    required Map<String, dynamic> allocationPlan,
  }) async {
    try {
      final List<Map<String, dynamic>> validationResults = [];
      final items = allocationPlan['items'] as List<dynamic>;

      for (final item in items) {
        final itemId = item['item_id'] as String;
        final allocatedQty = item['allocated_quantity'] as int;

        // Get current stock
        final stockResponse = await _supabase
            .from('stock_items')
            .select('item_name, stock_quantity, unit')
            .eq('id', itemId)
            .single();

        final currentStock = stockResponse['stock_quantity'] as int;
        final shortage = allocatedQty - currentStock;

        validationResults.add({
          'item_id': itemId,
          'item_name': stockResponse['item_name'],
          'unit': stockResponse['unit'],
          'allocated_quantity': allocatedQty,
          'current_stock': currentStock,
          'shortage': shortage > 0 ? shortage : 0,
          'has_shortage': shortage > 0,
        });
      }

      final totalShortages = validationResults
          .where((item) => item['has_shortage'])
          .length;

      return {
        'is_valid': totalShortages == 0,
        'total_items': validationResults.length,
        'items_with_shortage': totalShortages,
        'validation_results': validationResults,
      };
    } catch (e) {
      throw Exception('Failed to validate allocation plan: $e');
    }
  }

  // Get all stock items for allocation planning
  static Future<List<StockItemModel>> getAllStockItems() async {
    try {
      final response = await _supabase
          .from('stock_items')
          .select()
          .order('item_name');

      return response.map((json) => StockItemModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get stock items: $e');
    }
  }

  // Get material allocation history for a customer
  static Future<List<Map<String, dynamic>>> getAllocationHistory({
    required String customerId,
  }) async {
    try {
      final response = await _supabase
          .from('customers')
          .select('material_allocation_history')
          .eq('id', customerId)
          .single();

      final history = response['material_allocation_history'] as List<dynamic>?;
      return history?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception('Failed to get allocation history: $e');
    }
  }
}
