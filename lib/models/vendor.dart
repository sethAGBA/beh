import 'package:cloud_firestore/cloud_firestore.dart';

class Vendor {
  final String id;
  final String eventId;
  final String name;
  final String serviceType; // e.g., 'Photographer', 'Caterer', 'Venue'
  final String? contactInfo; // e.g., email, phone number
  final double? price;
  final String? notes;

  Vendor({
    required this.id,
    required this.eventId,
    required this.name,
    required this.serviceType,
    this.contactInfo,
    this.price,
    this.notes,
  });

  factory Vendor.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Vendor(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      name: data['name'] ?? '',
      serviceType: data['serviceType'] ?? '',
      contactInfo: data['contactInfo'],
      price: (data['price'] ?? 0.0).toDouble(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'name': name,
      'serviceType': serviceType,
      'contactInfo': contactInfo,
      'price': price,
      'notes': notes,
    };
  }
}
