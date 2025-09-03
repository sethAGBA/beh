import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beh/models/event.dart';
import 'package:beh/forms/funeral_form.dart';
import 'package:beh/forms/conference_form.dart';
import 'package:beh/forms/birthday_form.dart';
import 'package:beh/forms/wedding_form.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventCreationPage extends StatelessWidget {
  final String eventType;
  final DocumentSnapshot? eventDoc;

  const EventCreationPage({super.key, required this.eventType, this.eventDoc});

  Widget _buildForm() {
    switch (eventType) {
      case 'mariage':
        return WeddingForm(eventDoc: eventDoc);
      case 'anniversaire':
        return BirthdayForm(eventDoc: eventDoc);
      case 'conference':
        return ConferenceForm(eventDoc: eventDoc);
      case 'funerailles':
        return FuneralForm(eventDoc: eventDoc);
      default:
        return const Center(
          child: Text('Formulaire non disponible pour ce type d\'événement.'),
        );
    } 
  }

  String _getTitle() {
    switch (eventType) {
      case 'mariage':
        return 'Réservation Mariage';
      case 'anniversaire':
        return 'Réservation Anniversaire';
      case 'conference':
        return 'Réservation Conférence';
      case 'funerailles':
        return 'Organisation Funérailles';
      default:
        return 'Créer un événement';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Prefer popping navigation stack to return to previous screen when available
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              // Fallback: go to services
              context.go('/services');
            }
          },
        ),
        title: Text(_getTitle()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildForm(),
      ),
    );
  }
}
