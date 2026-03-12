class Order {
  final String id;
  final String patientId;
  final String patientName;
  final String pharmacyId;
  final String pharmacyName;
  final String? deliveryAgentId;
  final String? deliveryAgentName;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double totalAmount;
  final String status;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String? prescriptionUrl;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.pharmacyId,
    required this.pharmacyName,
    this.deliveryAgentId,
    this.deliveryAgentName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0.0,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.prescriptionUrl,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      patientName: json['patient_name'] as String? ?? '',
      pharmacyId: json['pharmacy_id'] as String,
      pharmacyName: json['pharmacy_name'] as String? ?? '',
      deliveryAgentId: json['delivery_agent_id'] as String?,
      deliveryAgentName: json['delivery_agent_name'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      deliveryAddress: json['delivery_address'] as String,
      deliveryLatitude: (json['delivery_latitude'] as num).toDouble(),
      deliveryLongitude: (json['delivery_longitude'] as num).toDouble(),
      prescriptionUrl: json['prescription_url'] as String?,
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentId: json['payment_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'pharmacy_id': pharmacyId,
      'pharmacy_name': pharmacyName,
      'delivery_agent_id': deliveryAgentId,
      'delivery_agent_name': deliveryAgentName,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount': discount,
      'total_amount': totalAmount,
      'status': status,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'prescription_url': prescriptionUrl,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payment_id': paymentId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  bool get isActive =>
      status != 'delivered' && status != 'cancelled';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class OrderItem {
  final String medicineId;
  final String medicineName;
  final String? medicineImageUrl;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.medicineId,
    required this.medicineName,
    this.medicineImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      medicineId: json['medicine_id'] as String,
      medicineName: json['medicine_name'] as String,
      medicineImageUrl: json['medicine_image_url'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'medicine_image_url': medicineImageUrl,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}
