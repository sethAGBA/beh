import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String userId;
  final String eventName;
  final DateTime eventDate;
  final String location;
  final double budget;
  final String? description;

  Event({
    required this.id,
    required this.userId,
    required this.eventName,
    required this.eventDate,
    required this.location,
    required this.budget,
    this.description,
  });

  // Factory constructor to create an Event from a Firestore DocumentSnapshot
  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      userId: data['userId'] ?? '',
      eventName: data['eventName'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      budget: (data['budget'] ?? 0.0).toDouble(),
      description: data['description'],
    );
  }

  // Method to convert an Event object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'eventName': eventName,
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location,
      'budget': budget,
      'description': description,
    };
  }
}
