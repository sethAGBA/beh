import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentConfirmationPage extends StatelessWidget {
  final String eventId;
  final String method;
  final double amount;

  const PaymentConfirmationPage({super.key, required this.eventId, required this.method, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmer le Paiement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Récapitulatif', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ListTile(title: Text(method), subtitle: const Text('Méthode choisie')),
            ListTile(title: Text('${amount.toStringAsFixed(0)} FCFA'), subtitle: const Text('Montant')),
            ListTile(title: const Text('#TRANS123456'), subtitle: const Text('Numéro de transaction (simulé)')),
            const Spacer(),
            Text('Veuillez confirmer votre paiement.', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Simulate payment processing
                  context.go(
                    '/my-events/details/$eventId/summary/payment/verify',
                    extra: {
                      'eventId': eventId,
                      'method': method,
                      'amount': amount,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Confirmer le paiement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
