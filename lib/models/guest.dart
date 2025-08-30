import 'package:cloud_firestore/cloud_firestore.dart';

class Guest {
  final String id;
  final String eventId;
  final String name;
  final String? email;
  final String rsvpStatus; // e.g., 'Pending', 'Accepted', 'Declined'
  final int? plusOne; // Number of additional guests

  Guest({
    required this.id,
    required this.eventId,
    required this.name,
    this.email,
    this.rsvpStatus = 'Pending',
    this.plusOne,
  });

  factory Guest.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Guest(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'],
      rsvpStatus: data['rsvpStatus'] ?? 'Pending',
      plusOne: data['plusOne'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'name': name,
      'email': email,
      'rsvpStatus': rsvpStatus,
      'plusOne': plusOne,
    };
  }
}
