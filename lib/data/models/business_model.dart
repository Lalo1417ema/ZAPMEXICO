class BusinessModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final String phone;
  final double rating;
  final String imageUrl;

  BusinessModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.phone,
    required this.rating,
    required this.imageUrl,
  });

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      description: map['description'],
      address: map['address'],
      phone: map['phone'],
      rating: (map['rating'] as num).toDouble(),
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'address': address,
      'phone': phone,
      'rating': rating,
      'imageUrl': imageUrl,
    };
  }
}