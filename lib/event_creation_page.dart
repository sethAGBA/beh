import 'package:beh/forms/funeral_form.dart';
import 'package:beh/forms/conference_form.dart';
import 'package:beh/forms/birthday_form.dart';
import 'package:beh/forms/wedding_form.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventCreationPage extends StatelessWidget {
  final String eventType;

  const EventCreationPage({super.key, required this.eventType});

  Widget _buildForm() {
    switch (eventType) {
      case 'mariage':
        return const WeddingForm();
      case 'anniversaire':
        return const BirthdayForm();
      case 'conference':
        return const ConferenceForm();
      case 'funerailles':
        return const FuneralForm();
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
          onPressed: () => context.go('/services'),
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
