class StockItemModel {
  final String? id;
  final String name;
  final int currentStock;
  final String officeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StockItemModel({
    this.id,
    required this.name,
    required this.currentStock,
    required this.officeId,
    this.createdAt,
    this.updatedAt,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    try {
      return StockItemModel(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        currentStock: (json['current_stock'] as num?)?.toInt() ?? 0,
        officeId: json['office_id']?.toString() ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'].toString())
            : null,
      );
    } catch (e) {
      print('Error parsing StockItemModel from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'current_stock': currentStock,
      'office_id': officeId,
    };

    // Only include id if it's not null (for updates)
    if (id != null) {
      json['id'] = id;
    }

    // Only include timestamps if they're not null
    if (createdAt != null) {
      json['created_at'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      json['updated_at'] = updatedAt!.toIso8601String();
    }

    return json;
  }

  StockItemModel copyWith({
    String? id,
    String? name,
    int? currentStock,
    String? officeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      currentStock: currentStock ?? this.currentStock,
      officeId: officeId ?? this.officeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
