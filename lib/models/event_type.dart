import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For IconData

class EventType {
  final String id;
  final String title;
  final String description;
  final String priceRange;
  final IconData icon;
  final String? imageUrl;
  final String eventTypeKey; // e.g., 'mariage', 'anniversaire'

  EventType({
    required this.id,
    required this.title,
    required this.description,
    required this.priceRange,
    required this.icon,
    this.imageUrl,
    required this.eventTypeKey,
  });

  factory EventType.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventType(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      priceRange: data['price_range'] ?? '',
      icon: IconData(data['icon_code'] as int, fontFamily: data['icon_font_family'] ?? 'MaterialIcons'),
      imageUrl: data['image_url'] as String?,
      eventTypeKey: data['event_type_key'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price_range': priceRange,
      'icon_code': icon.codePoint,
      'icon_font_family': icon.fontFamily,
      'image_url': imageUrl,
      'event_type_key': eventTypeKey,
    };
  }
}
