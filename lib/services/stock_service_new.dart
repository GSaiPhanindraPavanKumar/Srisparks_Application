import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stock_item_model.dart';
import '../models/stock_log_model.dart';

class StockService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all stock items for an office
  Future<List<StockItemModel>> getStockItemsByOffice(int officeId) async {
    final response = await _supabase
        .from('stock_items')
        .select()
        .eq('office_id', officeId)
        .order('name', ascending: true);

    // Explicitly cast to List<Map<String, dynamic>> and then map to StockItemModel
    final List<Map<String, dynamic>> stockItemData =
        List<Map<String, dynamic>>.from(response);
    return stockItemData.map((item) => StockItemModel.fromJson(item)).toList();
  }

  // Create a new stock item
  Future<StockItemModel> createStockItem(StockItemModel item) async {
    final response = await _supabase
        .from('stock_items')
        .insert(item.toJson())
        .select()
        .single();

    return StockItemModel.fromJson(response);
  }

  // Update stock quantity (add or decrease)
  Future<bool> updateStockQuantity({
    required int stockItemId,
    required String action, // 'add' or 'decrease'
    required int quantity,
    String? reason,
    int? workId,
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
          .update({
            'current_stock': newStock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', stockItemId);

      // Log the transaction
      await _supabase.from('stock_log').insert({
        'stock_item_id': stockItemId,
        'action': action,
        'quantity': quantity,
        'previous_stock': previousStock,
        'new_stock': newStock,
        'reason': reason,
        'work_id': workId,
        'office_id': stockItem.officeId,
        'user_id': _supabase.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error updating stock: $e');
      return false;
    }
  }

  // Get stock history/log for an office
  Future<List<StockLogModel>> getStockLog({
    int? officeId,
    int? stockItemId,
  }) async {
    var query = _supabase.from('stock_log').select();

    if (officeId != null) {
      query = query.eq('office_id', officeId);
    }

    if (stockItemId != null) {
      query = query.eq('stock_item_id', stockItemId);
    }

    final response = await query.order('created_at', ascending: false);

    // Explicitly cast to List<Map<String, dynamic>> and then map to StockLogModel
    final List<Map<String, dynamic>> stockLogData =
        List<Map<String, dynamic>>.from(response);
    return stockLogData.map((log) => StockLogModel.fromJson(log)).toList();
  }

  // Update stock item details
  Future<bool> updateStockItem(int id, StockItemModel item) async {
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
  Future<bool> deleteStockItem(int id) async {
    try {
      await _supabase.from('stock_items').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting stock item: $e');
      return false;
    }
  }

  // Get stock item by id
  Future<StockItemModel?> getStockItemById(int id) async {
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
