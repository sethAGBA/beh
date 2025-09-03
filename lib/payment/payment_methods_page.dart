import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentMethodsPage extends StatefulWidget {
  final String eventId;
  final double totalAmount;

  const PaymentMethodsPage({super.key, required this.eventId, required this.totalAmount});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  String? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Méthodes de Paiement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montant à payer: ${widget.totalAmount.toStringAsFixed(0)} FCFA',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text('Choisissez votre méthode:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _buildPaymentMethodCard(
              value: 't-money',
              title: 'T-Money',
              description: 'Paiement sécurisé mobile',
              fee: 2500,
              icon: Icons.phone_android,
            ),
            const SizedBox(height: 10),
            _buildPaymentMethodCard(
              value: 'flooz',
              title: 'Flooz',
              description: 'Portefeuille électronique',
              fee: 3000,
              icon: Icons.account_balance_wallet,
            ),
            const Spacer(),
            Text('🔒 Paiement 100% sécurisé', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMethod != null
                    ? () {
                        // Navigate to confirmation page
                        context.go(
                          '/my-events/details/${widget.eventId}/summary/payment/confirm',
                          extra: {
                            'method': _selectedMethod,
                            'amount': widget.totalAmount,
                          },
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Confirmer le Paiement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String value,
    required String title,
    required String description,
    required double fee,
    required IconData icon,
  }) {
    return Card(
      elevation: _selectedMethod == value ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: _selectedMethod,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMethod = newValue;
                  });
                },
              ),
              Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                    Text('Frais: ${fee.toStringAsFixed(0)} FCFA', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
