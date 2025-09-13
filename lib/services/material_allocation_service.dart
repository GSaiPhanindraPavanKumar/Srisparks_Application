import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/material_allocation_model.dart';
import '../models/material_allocation_item_model.dart';

class MaterialAllocationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Create new material allocation
  static Future<MaterialAllocationModel> createAllocation({
    required String customerId,
    required String officeId,
    required String allocatedById,
    DateTime? allocationDate,
    DateTime? deliveryDate,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase
          .from('material_allocations')
          .insert({
            'customer_id': customerId,
            'office_id': officeId,
            'allocated_by_id': allocatedById,
            'allocation_date': allocationDate?.toIso8601String(),
            'delivery_date': deliveryDate?.toIso8601String(),
            'notes': notes,
            'metadata': metadata,
            'status': 'draft',
          })
          .select()
          .single();

      return MaterialAllocationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create material allocation: $e');
    }
  }

  // Add item to material allocation
  static Future<MaterialAllocationItemModel> addAllocationItem({
    required String materialAllocationId,
    required String stockItemId,
    required int requiredQuantity,
    int allocatedQuantity = 0,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('material_allocation_items')
          .insert({
            'material_allocation_id': materialAllocationId,
            'stock_item_id': stockItemId,
            'required_quantity': requiredQuantity,
            'allocated_quantity': allocatedQuantity,
            'notes': notes,
          })
          .select('''
            *,
            stock_items!inner(
              item_name,
              category,
              subcategory,
              item_code,
              unit,
              unit_price
            )
          ''')
          .single();

      // Flatten the response to match our model
      final flattenedResponse = {
        ...response,
        'item_name': response['stock_items']['item_name'],
        'category': response['stock_items']['category'],
        'subcategory': response['stock_items']['subcategory'],
        'item_code': response['stock_items']['item_code'],
        'unit': response['stock_items']['unit'],
        'unit_price': response['stock_items']['unit_price'],
      };
      flattenedResponse.remove('stock_items');

      return MaterialAllocationItemModel.fromJson(flattenedResponse);
    } catch (e) {
      throw Exception('Failed to add allocation item: $e');
    }
  }

  // Update allocation item quantities
  static Future<MaterialAllocationItemModel> updateAllocationItem({
    required String itemId,
    int? requiredQuantity,
    int? allocatedQuantity,
    int? deliveredQuantity,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (requiredQuantity != null)
        updateData['required_quantity'] = requiredQuantity;
      if (allocatedQuantity != null)
        updateData['allocated_quantity'] = allocatedQuantity;
      if (deliveredQuantity != null)
        updateData['delivered_quantity'] = deliveredQuantity;
      if (notes != null) updateData['notes'] = notes;

      final response = await _supabase
          .from('material_allocation_items')
          .update(updateData)
          .eq('id', itemId)
          .select('''
            *,
            stock_items!inner(
              item_name,
              category,
              subcategory,
              item_code,
              unit,
              unit_price
            )
          ''')
          .single();

      // Flatten the response
      final flattenedResponse = {
        ...response,
        'item_name': response['stock_items']['item_name'],
        'category': response['stock_items']['category'],
        'subcategory': response['stock_items']['subcategory'],
        'item_code': response['stock_items']['item_code'],
        'unit': response['stock_items']['unit'],
        'unit_price': response['stock_items']['unit_price'],
      };
      flattenedResponse.remove('stock_items');

      return MaterialAllocationItemModel.fromJson(flattenedResponse);
    } catch (e) {
      throw Exception('Failed to update allocation item: $e');
    }
  }

  // Confirm allocation (changes status and updates stock)
  static Future<MaterialAllocationModel> confirmAllocation(
    String allocationId,
  ) async {
    try {
      final response = await _supabase
          .from('material_allocations')
          .update({
            'status': 'confirmed',
            'allocation_date': DateTime.now().toIso8601String(),
          })
          .eq('id', allocationId)
          .select()
          .single();

      return MaterialAllocationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to confirm allocation: $e');
    }
  }

  // Mark allocation as delivered
  static Future<MaterialAllocationModel> markAsDelivered(
    String allocationId,
  ) async {
    try {
      final response = await _supabase
          .from('material_allocations')
          .update({
            'status': 'delivered',
            'delivery_date': DateTime.now().toIso8601String(),
          })
          .eq('id', allocationId)
          .select()
          .single();

      return MaterialAllocationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to mark allocation as delivered: $e');
    }
  }

  // Get allocation with items
  static Future<MaterialAllocationModel> getAllocation(
    String allocationId,
  ) async {
    try {
      // Get allocation details
      final allocationResponse = await _supabase
          .from('material_allocations')
          .select('''
            *,
            customers!inner(name),
            offices!inner(name),
            employees!inner(name)
          ''')
          .eq('id', allocationId)
          .single();

      // Get allocation items
      final itemsResponse = await _supabase
          .from('material_allocation_items')
          .select('''
            *,
            stock_items!inner(
              item_name,
              category,
              subcategory,
              item_code,
              unit,
              unit_price,
              current_stock
            )
          ''')
          .eq('material_allocation_id', allocationId);

      // Convert items to model
      final items = itemsResponse.map<MaterialAllocationItemModel>((item) {
        final flattenedItem = {
          ...item,
          'item_name': item['stock_items']['item_name'],
          'category': item['stock_items']['category'],
          'subcategory': item['stock_items']['subcategory'],
          'item_code': item['stock_items']['item_code'],
          'unit': item['stock_items']['unit'],
          'unit_price': item['stock_items']['unit_price'],
          'available_stock': item['stock_items']['current_stock'],
        };
        flattenedItem.remove('stock_items');
        return MaterialAllocationItemModel.fromJson(flattenedItem);
      }).toList();

      // Create allocation model
      final allocation = MaterialAllocationModel.fromJson({
        ...allocationResponse,
        'customer_name': allocationResponse['customers']['name'],
        'office_name': allocationResponse['offices']['name'],
        'allocated_by_name': allocationResponse['employees']['name'],
      });

      return allocation.copyWith(items: items);
    } catch (e) {
      throw Exception('Failed to get allocation: $e');
    }
  }

  // Get allocations for a customer
  static Future<List<MaterialAllocationModel>> getAllocationsForCustomer(
    String customerId, {
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase
          .from('material_allocations')
          .select('''
            *,
            customers!inner(name),
            offices!inner(name),
            employees!inner(name)
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;

      return response.map<MaterialAllocationModel>((allocation) {
        return MaterialAllocationModel.fromJson({
          ...allocation,
          'customer_name': allocation['customers']['name'],
          'office_name': allocation['offices']['name'],
          'allocated_by_name': allocation['employees']['name'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get allocations for customer: $e');
    }
  }

  // Get allocations for an office
  static Future<List<MaterialAllocationModel>> getAllocationsForOffice(
    String officeId, {
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase
          .from('material_allocations')
          .select('''
            *,
            customers!inner(name),
            offices!inner(name),
            employees!inner(name)
          ''')
          .eq('office_id', officeId)
          .order('created_at', ascending: false);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }

      if (toDate != null) {
        query = query.lte('created_at', toDate.toIso8601String());
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;

      return response.map<MaterialAllocationModel>((allocation) {
        return MaterialAllocationModel.fromJson({
          ...allocation,
          'customer_name': allocation['customers']['name'],
          'office_name': allocation['offices']['name'],
          'allocated_by_name': allocation['employees']['name'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get allocations for office: $e');
    }
  }

  // Delete allocation (only if status is draft)
  static Future<void> deleteAllocation(String allocationId) async {
    try {
      // First check if allocation can be deleted
      final allocation = await _supabase
          .from('material_allocations')
          .select('status')
          .eq('id', allocationId)
          .single();

      if (allocation['status'] != 'draft') {
        throw Exception('Cannot delete allocation that is not in draft status');
      }

      // Delete allocation items first (cascade should handle this, but being explicit)
      await _supabase
          .from('material_allocation_items')
          .delete()
          .eq('material_allocation_id', allocationId);

      // Delete allocation
      await _supabase
          .from('material_allocations')
          .delete()
          .eq('id', allocationId);
    } catch (e) {
      throw Exception('Failed to delete allocation: $e');
    }
  }

  // Delete allocation item
  static Future<void> deleteAllocationItem(String itemId) async {
    try {
      await _supabase
          .from('material_allocation_items')
          .delete()
          .eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to delete allocation item: $e');
    }
  }

  // Get stock availability for items
  static Future<Map<String, int>> getStockAvailability(
    List<String> stockItemIds,
  ) async {
    try {
      final response = await _supabase
          .from('stock_items')
          .select('id, current_stock')
          .in_('id', stockItemIds);

      final stockMap = <String, int>{};
      for (final item in response) {
        stockMap[item['id']] = item['current_stock'] ?? 0;
      }
      return stockMap;
    } catch (e) {
      throw Exception('Failed to get stock availability: $e');
    }
  }

  // Get allocation summary statistics
  static Future<Map<String, dynamic>> getAllocationStats({
    String? officeId,
    String? customerId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase.from('material_allocation_summary').select('*');

      if (officeId != null) {
        query = query.eq('office_id', officeId);
      }

      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }

      if (fromDate != null) {
        query = query.gte('allocation_date', fromDate.toIso8601String());
      }

      if (toDate != null) {
        query = query.lte('allocation_date', toDate.toIso8601String());
      }

      final response = await query;

      // Calculate aggregate statistics
      int totalAllocations = response.length;
      int totalItems = 0;
      int totalAllocatedQuantity = 0;
      int totalDeliveredQuantity = 0;
      double totalValue = 0.0;

      final statusCounts = <String, int>{};

      for (final allocation in response) {
        totalItems += (allocation['total_items'] ?? 0) as int;
        totalAllocatedQuantity +=
            (allocation['total_allocated_quantity'] ?? 0) as int;
        totalDeliveredQuantity +=
            (allocation['total_delivered_quantity'] ?? 0) as int;
        totalValue += (allocation['total_value'] ?? 0.0) as double;

        final status = allocation['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      return {
        'total_allocations': totalAllocations,
        'total_items': totalItems,
        'total_allocated_quantity': totalAllocatedQuantity,
        'total_delivered_quantity': totalDeliveredQuantity,
        'total_value': totalValue,
        'status_counts': statusCounts,
        'allocation_completion_rate': totalItems > 0
            ? (totalAllocatedQuantity / totalItems) * 100
            : 0.0,
        'delivery_completion_rate': totalAllocatedQuantity > 0
            ? (totalDeliveredQuantity / totalAllocatedQuantity) * 100
            : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get allocation statistics: $e');
    }
  }
}
