import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentVerificationPage extends StatefulWidget {
  final String eventId;
  final String method;
  final double amount;

  const PaymentVerificationPage({super.key, required this.eventId, required this.method, required this.amount});

  @override
  State<PaymentVerificationPage> createState() => _PaymentVerificationPageState();
}

class _PaymentVerificationPageState extends State<PaymentVerificationPage> {
  @override
  void initState() {
    super.initState();
    _simulatePaymentProcess();
  }

  Future<void> _logTransaction(String status, {String? failureReason}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Or handle error

    await FirebaseFirestore.instance.collection('transactions').add({
      'userId': user.uid,
      'eventId': widget.eventId,
      'amount': widget.amount,
      'paymentMethod': widget.method,
      'status': status,
      'failureReason': failureReason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _simulatePaymentProcess() async {
    print('Starting payment simulation...');
    try {
      // Simulate a delay for payment processing
      await Future.delayed(const Duration(seconds: 4));

      // Randomly decide success or failure for demonstration
      final bool success = DateTime.now().second % 2 != 0; // 50% chance of success

      if (mounted) {
        if (success) {
          await _logTransaction('success');
          context.go('/my-events/details/${widget.eventId}/summary/payment/success');
        } else {
          await _logTransaction('failure', failureReason: 'Fonds insuffisants (simulé)');
          context.go('/my-events/details/${widget.eventId}/summary/payment/failure');
        }
      }
    } catch (e) {
      print('Error in payment simulation: $e');
      if (mounted) {
        await _logTransaction('failure', failureReason: e.toString());
        context.go('/my-events/details/${widget.eventId}/summary/payment/failure');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification du Paiement'),
        automaticallyImplyLeading: false, // Prevent going back during verification
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Traitement en cours...', 
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Vérification de vos fonds...\nVeuillez ne pas quitter cette page.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
