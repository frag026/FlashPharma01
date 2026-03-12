import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _pharmacyId;
  String? _pharmacyName;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  String? get pharmacyId => _pharmacyId;
  String? get pharmacyName => _pharmacyName;

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee => _items.isEmpty ? 0.0 : 30.0;
  double get total => subtotal + deliveryFee;

  void addItem(CartItem item) {
    // If adding from a different pharmacy, clear cart first
    if (_pharmacyId != null && _pharmacyId != item.pharmacyId) {
      _items.clear();
    }

    _pharmacyId = item.pharmacyId;
    _pharmacyName = item.pharmacyName;

    final existingIndex = _items.indexWhere(
      (i) => i.medicineId == item.medicineId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String medicineId) {
    _items.removeWhere((item) => item.medicineId == medicineId);
    if (_items.isEmpty) {
      _pharmacyId = null;
      _pharmacyName = null;
    }
    notifyListeners();
  }

  void updateQuantity(String medicineId, int quantity) {
    final index = _items.indexWhere((i) => i.medicineId == medicineId);
    if (index >= 0) {
      if (quantity <= 0) {
        removeItem(medicineId);
      } else {
        _items[index].quantity = quantity;
        notifyListeners();
      }
    }
  }

  void clear() {
    _items.clear();
    _pharmacyId = null;
    _pharmacyName = null;
    notifyListeners();
  }

  List<Map<String, dynamic>> toOrderItems() {
    return _items
        .map((item) => {
              'medicine_id': item.medicineId,
              'medicine_name': item.medicineName,
              'medicine_image_url': item.medicineImageUrl,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
            })
        .toList();
  }
}
