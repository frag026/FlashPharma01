class SearchResult {
  final String medicineId;
  final String medicineName;
  final String genericName;
  final String manufacturer;
  final String category;
  final String? imageUrl;
  final bool requiresPrescription;
  final List<PharmacyStock> pharmacies;

  SearchResult({
    required this.medicineId,
    required this.medicineName,
    required this.genericName,
    required this.manufacturer,
    required this.category,
    this.imageUrl,
    required this.requiresPrescription,
    required this.pharmacies,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      medicineId: json['medicine_id'] as String? ?? json['objectID'] as String,
      medicineName: json['medicine_name'] as String? ?? json['name'] as String,
      genericName: json['generic_name'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      category: json['category'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      requiresPrescription: json['requires_prescription'] as bool? ?? false,
      pharmacies: (json['pharmacies'] as List<dynamic>?)
              ?.map((e) => PharmacyStock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PharmacyStock {
  final String pharmacyId;
  final String pharmacyName;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final double price;
  final int quantity;
  final bool inStock;
  final double rating;

  PharmacyStock({
    required this.pharmacyId,
    required this.pharmacyName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.price,
    required this.quantity,
    this.inStock = true,
    this.rating = 0.0,
  });

  factory PharmacyStock.fromJson(Map<String, dynamic> json) {
    return PharmacyStock(
      pharmacyId: json['pharmacy_id'] as String,
      pharmacyName: json['pharmacy_name'] as String,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 0,
      inStock: json['in_stock'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
