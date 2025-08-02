import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stock_item_model.dart';
import '../models/stock_log_model.dart';

class StockService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all stock items for an office
  Future<List<StockItemModel>> getStockItemsByOffice(String officeId) async {
    print('Getting stock items for office: $officeId');
    
    final response = await _supabase
        .from('stock_items')
        .select()
        .eq('office_id', officeId)
        .order('name', ascending: true);

    print('Found ${(response as List).length} stock items for office $officeId');
    
    return (response as List)
        .map((item) => StockItemModel.fromJson(item))
        .toList();
  }

  // Create a new stock item
  Future<StockItemModel> createStockItem(StockItemModel item) async {
    print('Creating stock item: ${item.name} for office: ${item.officeId}');
    
    final response = await _supabase
        .from('stock_items')
        .insert(item.toJson())
        .select()
        .single();

    print('Stock item created successfully: ${response['id']}');
    
    final createdItem = StockItemModel.fromJson(response);
    
    // If initial stock is greater than 0, log it as an 'add' action
    if (createdItem.currentStock > 0) {
      print('Logging initial stock: ${createdItem.currentStock} for item ${createdItem.id}');
      
      await _supabase.from('stock_log').insert({
        'stock_item_id': createdItem.id,
        'action_type': 'add',
        'quantity_change': createdItem.currentStock,
        'previous_stock': 0,
        'new_stock': createdItem.currentStock,
        'reason': 'Initial stock creation',
        'office_id': createdItem.officeId,
        'user_id': _supabase.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('Initial stock logged successfully');
    }
    
    return createdItem;
  }

  // Update stock quantity (add or decrease)
  Future<bool> updateStockQuantity({
    required String stockItemId,
    required String action, // 'add' or 'decrease'
    required int quantity,
    String? reason,
    String? workId,
  }) async {
    try {
      // Get current stock item
      final currentItem = await _supabase
          .from('stock_items')
          .select()
          .eq('id', stockItemId)
          .single();

      final stockItem = StockItemModel.fromJson(currentItem);
      final previousStock = stockItem.currentStock;
      
      int newStock;
      if (action == 'add') {
        newStock = previousStock + quantity;
      } else if (action == 'decrease') {
        newStock = previousStock - quantity;
        if (newStock < 0) {
          throw Exception('Cannot decrease stock below zero');
        }
      } else {
        throw Exception('Invalid action. Use "add" or "decrease"');
      }

      // Update stock item
      await _supabase
          .from('stock_items')
          .update({'current_stock': newStock, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', stockItemId);

      print('Stock item updated: $stockItemId from $previousStock to $newStock');

      // Log the transaction
      final logData = {
        'stock_item_id': stockItemId,
        'action_type': action,
        'quantity_change': action == 'add' ? quantity : -quantity,
        'previous_stock': previousStock,
        'new_stock': newStock,
        'reason': reason,
        'work_id': workId,
        'office_id': stockItem.officeId,
        'user_id': _supabase.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      print('Inserting stock log: $logData');
      
      await _supabase.from('stock_log').insert(logData);
      
      print('Stock log inserted successfully');

      return true;
    } catch (e) {
      print('Error updating stock: $e');
      return false;
    }
  }

  // Get stock history/log for an office
  Future<List<StockLogModel>> getStockLog({String? officeId, String? stockItemId}) async {
    print('Getting stock log for officeId: $officeId, stockItemId: $stockItemId');
    
    var query = _supabase.from('stock_log').select();
    
    if (officeId != null) {
      query = query.eq('office_id', officeId);
    }
    
    if (stockItemId != null) {
      query = query.eq('stock_item_id', stockItemId);
    }
    
    final response = await query.order('created_at', ascending: false);

    print('Found ${(response as List).length} stock log entries');
    
    return (response as List)
        .map((log) => StockLogModel.fromJson(log))
        .toList();
  }

  // Update stock item details
  Future<bool> updateStockItem(String id, StockItemModel item) async {
    try {
      await _supabase
          .from('stock_items')
          .update({
            'name': item.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (e) {
      print('Error updating stock item: $e');
      return false;
    }
  }

  // Delete stock item
  Future<bool> deleteStockItem(String id) async {
    try {
      // Get the stock item details before deletion for logging
      final currentItem = await _supabase
          .from('stock_items')
          .select()
          .eq('id', id)
          .single();

      final stockItem = StockItemModel.fromJson(currentItem);
      
      // Log the deletion if there was stock
      if (stockItem.currentStock > 0) {
        print('Logging stock deletion: ${stockItem.currentStock} for item ${stockItem.id}');
        
        await _supabase.from('stock_log').insert({
          'stock_item_id': stockItem.id,
          'action_type': 'delete',
          'quantity_change': -stockItem.currentStock,
          'previous_stock': stockItem.currentStock,
          'new_stock': 0,
          'reason': 'Item deleted',
          'office_id': stockItem.officeId,
          'user_id': _supabase.auth.currentUser?.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      // Delete the stock item
      await _supabase
          .from('stock_items')
          .delete()
          .eq('id', id);
          
      print('Stock item deleted successfully: $id');
      return true;
    } catch (e) {
      print('Error deleting stock item: $e');
      return false;
    }
  }

  // Get stock item by id
  Future<StockItemModel?> getStockItemById(String id) async {
    try {
      final response = await _supabase
          .from('stock_items')
          .select()
          .eq('id', id)
          .single();

      return StockItemModel.fromJson(response);
    } catch (e) {
      print('Error getting stock item: $e');
      return null;
    }
  }
}
