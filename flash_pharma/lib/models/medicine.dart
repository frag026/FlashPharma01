class Medicine {
  final String id;
  final String name;
  final String genericName;
  final String manufacturer;
  final String category;
  final String description;
  final String dosageForm;
  final String strength;
  final String? imageUrl;
  final bool requiresPrescription;
  final List<String> tags;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.manufacturer,
    required this.category,
    required this.description,
    required this.dosageForm,
    required this.strength,
    this.imageUrl,
    required this.requiresPrescription,
    this.tags = const [],
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      genericName: json['generic_name'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dosageForm: json['dosage_form'] as String? ?? '',
      strength: json['strength'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      requiresPrescription: json['requires_prescription'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'generic_name': genericName,
      'manufacturer': manufacturer,
      'category': category,
      'description': description,
      'dosage_form': dosageForm,
      'strength': strength,
      'image_url': imageUrl,
      'requires_prescription': requiresPrescription,
      'tags': tags,
    };
  }
}
