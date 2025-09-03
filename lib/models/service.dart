import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;

  // New fields
  final String? mainCategory;
  final String? decoType;
  final String? foodCuisine;
  final String? foodCourse;


  Service({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.mainCategory,
    this.decoType,
    this.foodCuisine,
    this.foodCourse,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      mainCategory: data['main_category'] as String?,
      decoType: data['deco_type'] as String?,
      foodCuisine: data['food_cuisine'] as String?,
      foodCourse: data['food_course'] as String?,
    );
  }
}
