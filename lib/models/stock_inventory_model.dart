import 'package:flutter/material.dart';

class StockInventoryModel {
  final String id;
  final String stockItemId;
  final String officeId;
  final int currentQuantity;
  final int reservedQuantity; // Reserved for pending work
  final int availableQuantity; // current - reserved
  final double totalValue; // current quantity * cost price
  final DateTime lastMovementDate;
  final DateTime updatedAt;

  // Populated from joins
  final String? stockItemName;
  final String? stockItemSku;
  final String? stockItemUnit;
  final double? stockItemCostPrice;
  final int? stockItemMinLevel;
  final int? stockItemMaxLevel;
  final String? officeName;

  StockInventoryModel({
    required this.id,
    required this.stockItemId,
    required this.officeId,
    required this.currentQuantity,
    required this.reservedQuantity,
    required this.availableQuantity,
    required this.totalValue,
    required this.lastMovementDate,
    required this.updatedAt,
    this.stockItemName,
    this.stockItemSku,
    this.stockItemUnit,
    this.stockItemCostPrice,
    this.stockItemMinLevel,
    this.stockItemMaxLevel,
    this.officeName,
  });

  factory StockInventoryModel.fromJson(Map<String, dynamic> json) {
    return StockInventoryModel(
      id: json['id'],
      stockItemId: json['stock_item_id'],
      officeId: json['office_id'],
      currentQuantity: json['current_quantity'],
      reservedQuantity: json['reserved_quantity'],
      availableQuantity: json['available_quantity'],
      totalValue: (json['total_value'] as num).toDouble(),
      lastMovementDate: DateTime.parse(json['last_movement_date']),
      updatedAt: DateTime.parse(json['updated_at']),
      stockItemName: json['stock_item_name'],
      stockItemSku: json['stock_item_sku'],
      stockItemUnit: json['stock_item_unit'],
      stockItemCostPrice: json['stock_item_cost_price']?.toDouble(),
      stockItemMinLevel: json['stock_item_min_level'],
      stockItemMaxLevel: json['stock_item_max_level'],
      officeName: json['office_name'],
    );
  }

  bool get isLowStock {
    if (stockItemMinLevel == null) return false;
    return currentQuantity <= stockItemMinLevel!;
  }

  bool get isOverStock {
    if (stockItemMaxLevel == null) return false;
    return currentQuantity >= stockItemMaxLevel!;
  }

  bool get isOutOfStock {
    return currentQuantity <= 0;
  }

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    if (isOverStock) return 'Overstock';
    return 'Normal';
  }

  Color get statusColor {
    if (isOutOfStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    if (isOverStock) return Colors.blue;
    return Colors.green;
  }
}
