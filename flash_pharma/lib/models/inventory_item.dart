import 'medicine.dart';

class InventoryItem {
  final String id;
  final String pharmacyId;
  final Medicine medicine;
  final double price;
  final int quantity;
  final String batchNumber;
  final DateTime expiryDate;
  final bool inStock;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.pharmacyId,
    required this.medicine,
    required this.price,
    required this.quantity,
    required this.batchNumber,
    required this.expiryDate,
    this.inStock = true,
    required this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      medicine: Medicine.fromJson(json['medicine'] as Map<String, dynamic>),
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      batchNumber: json['batch_number'] as String? ?? '',
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      inStock: json['in_stock'] as bool? ?? true,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'medicine': medicine.toJson(),
      'price': price,
      'quantity': quantity,
      'batch_number': batchNumber,
      'expiry_date': expiryDate.toIso8601String(),
      'in_stock': inStock,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InventoryItem copyWith({
    double? price,
    int? quantity,
    String? batchNumber,
    DateTime? expiryDate,
    bool? inStock,
  }) {
    return InventoryItem(
      id: id,
      pharmacyId: pharmacyId,
      medicine: medicine,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      inStock: inStock ?? this.inStock,
      updatedAt: DateTime.now(),
    );
  }
}
