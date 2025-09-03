import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String eventId;

  const PaymentSuccessPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Réussi'),
        automaticallyImplyLeading: false, // Prevent going back from success page
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 100,
              ),
              const SizedBox(height: 20),
              Text(
                'FÉLICITATIONS !',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Votre réservation a été confirmée avec succès',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.confirmation_number),
                title: const Text('Confirmation N°: #MRG2024001'), // Simulated
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Reçu envoyé à votre email'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Rappel programmé pour le 20 Décembre 2024'), // Simulated
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'), // Navigate back to home
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Retour Accueil'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/my-events/details/$eventId'), // Navigate to event details
                child: const Text('Voir Détails'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
