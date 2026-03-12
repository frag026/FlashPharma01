class Pharmacy {
  final String id;
  final String name;
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String licenseNumber;
  final double rating;
  final int totalRatings;
  final bool isOpen;
  final String openTime;
  final String closeTime;
  final double deliveryRadius; // km
  final double deliveryFee;
  final double distance; // calculated from user location

  Pharmacy({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.licenseNumber,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.isOpen = true,
    this.openTime = '08:00',
    this.closeTime = '22:00',
    this.deliveryRadius = 10.0,
    this.deliveryFee = 30.0,
    this.distance = 0.0,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerName: json['owner_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      licenseNumber: json['license_number'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      isOpen: json['is_open'] as bool? ?? true,
      openTime: json['open_time'] as String? ?? '08:00',
      closeTime: json['close_time'] as String? ?? '22:00',
      deliveryRadius: (json['delivery_radius'] as num?)?.toDouble() ?? 10.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 30.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_name': ownerName,
      'email': email,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'license_number': licenseNumber,
      'rating': rating,
      'total_ratings': totalRatings,
      'is_open': isOpen,
      'open_time': openTime,
      'close_time': closeTime,
      'delivery_radius': deliveryRadius,
      'delivery_fee': deliveryFee,
    };
  }
}
