class CartItem {
  final String medicineId;
  final String medicineName;
  final String? medicineImageUrl;
  final String pharmacyId;
  final String pharmacyName;
  final double unitPrice;
  int quantity;

  CartItem({
    required this.medicineId,
    required this.medicineName,
    this.medicineImageUrl,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'medicine_image_url': medicineImageUrl,
      'pharmacy_id': pharmacyId,
      'pharmacy_name': pharmacyName,
      'unit_price': unitPrice,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      medicineId: json['medicine_id'] as String,
      medicineName: json['medicine_name'] as String,
      medicineImageUrl: json['medicine_image_url'] as String?,
      pharmacyId: json['pharmacy_id'] as String,
      pharmacyName: json['pharmacy_name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}
