import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? description;
  final String? imageUrl;

  Service({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.description,
    this.imageUrl,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? '',
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
    );
  }
}
