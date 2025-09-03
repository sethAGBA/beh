import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentFailurePage extends StatelessWidget {
  final String eventId;

  const PaymentFailurePage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Échoué'),
        automaticallyImplyLeading: false, // Prevent going back from failure page
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cancel_outlined,
                color: Theme.of(context).colorScheme.error,
                size: 100,
              ),
              const SizedBox(height: 20),
              Text(
                'Paiement échoué',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Nous sommes désolés, votre paiement n\'a pas pu être traité',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Raison: Fonds insuffisants (simulé)'),
              ),
              const SizedBox(height: 20),
              Text('Suggestions:', style: Theme.of(context).textTheme.titleSmall),
              ListTile(leading: const Icon(Icons.check), title: const Text('Vérifiez votre solde')),
              ListTile(leading: const Icon(Icons.check), title: const Text('Réessayez dans quelques minutes')),
              ListTile(leading: const Icon(Icons.check), title: const Text('Contactez votre opérateur')),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/event-details/${eventId}/summary/payment'); // Go back to payment methods
                  },
                  child: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // TODO: Implement contact support
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fonctionnalité de support à implémenter')));
                },
                child: const Text('Contact Support'),
              ),
              TextButton(
                onPressed: () {
                  context.go('/home'); // Go back to home
                },
                child: const Text('Retour Accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}