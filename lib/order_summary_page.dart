import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beh/models/event.dart';
import 'package:go_router/go_router.dart';

class OrderSummaryPage extends StatefulWidget {
  final String eventId;

  const OrderSummaryPage({super.key, required this.eventId});

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _fetchSummaryData();
  }

  Future<Map<String, dynamic>> _fetchSummaryData() async {
    final eventDoc = await FirebaseFirestore.instance.collection('events').doc(widget.eventId).get();
    if (!eventDoc.exists) throw Exception('Event not found');

    final event = Event.fromFirestore(eventDoc);

    DocumentSnapshot? userDoc;
    if (event.userId != null) {
      userDoc = await FirebaseFirestore.instance.collection('users').doc(event.userId).get();
    }

    final prestationsSnapshot = await eventDoc.reference.collection('selected_prestations').get();
    final prestations = prestationsSnapshot.docs.map((doc) => doc.data()).toList();

    return {
      'event': event,
      'user': userDoc?.data(),
      'prestations': prestations,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final appBar = AppBar(
          title: const Text('Récapitulatif Commande'),
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: appBar, body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(appBar: appBar, body: Center(child: Text('Erreur: ${snapshot.error}')));
        }
        if (!snapshot.hasData) {
          return Scaffold(appBar: appBar, body: const Center(child: Text('Aucune donnée trouvée.')));
        }

        final event = snapshot.data!['event'] as Event;
        final userData = snapshot.data!['user'] as Map<String, dynamic>?;
        final prestations = snapshot.data!['prestations'] as List<dynamic>;

        return Scaffold(
          appBar: appBar,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventDetailsSection(context, event),
                const Divider(height: 30),
                _buildClientDetailsSection(context, userData),
                const Divider(height: 30),
                _buildPrestationsSection(context, prestations),
                const Divider(height: 30),
                _buildFinancialsSection(context, prestations),
              ],
            ),
          ),
          bottomNavigationBar: _buildActionButtons(context, prestations),
        );
      },
    );
  }

  Widget _buildEventDetailsSection(BuildContext context, Event event) {
    // Basic event details — keep this minimal and defensive to avoid depending on specific Event fields.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Détails Événement', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        ListTile(title: Text(event.eventName), subtitle: const Text('Nom de l\'événement')),
        ListTile(title: Text(event.eventDate.toLocal().toString().split(' ')[0]), subtitle: const Text('Date')),
        ListTile(title: Text(event.location), subtitle: const Text('Lieu')),
      ],
    );
  }

  Widget _buildClientDetailsSection(BuildContext context, Map<String, dynamic>? userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informations Client', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        ListTile(title: Text(userData?['firstName'] ?? 'N/A'), subtitle: const Text('Prénom')),
        ListTile(title: Text(userData?['fullName'] ?? 'N/A'), subtitle: const Text('Nom')),
        ListTile(title: Text(userData?['email'] ?? 'N/A'), subtitle: const Text('Email')),
      ],
    );
  }

  Widget _buildPrestationsSection(BuildContext context, List<dynamic> prestations) {
    final decorationPrestations = prestations.where((p) => p['category'] == 'décoration').toList();
    final africanFoodPrestations = prestations.where((p) => p['category'].toString().startsWith('nourriture_africaine')).toList();
    final europeanFoodPrestations = prestations.where((p) => p['category'].toString().startsWith('nourriture_europeenne')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prestations Sélectionnées', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (prestations.isEmpty)
          const ListTile(title: Text('Aucune prestation sélectionnée.'))
        else ...[
          if (decorationPrestations.isNotEmpty)
            _buildPrestationCategory(context, 'Décoration', decorationPrestations),
          if (africanFoodPrestations.isNotEmpty)
            _buildPrestationCategory(context, 'Cuisine Africaine', africanFoodPrestations),
          if (europeanFoodPrestations.isNotEmpty)
            _buildPrestationCategory(context, 'Cuisine Européenne', europeanFoodPrestations),
        ],
      ],
    );
  }

  Widget _buildPrestationCategory(BuildContext context, String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ...items.map((p) {
          final data = p as Map<String, dynamic>;
          return ListTile(
            title: Text(data['name'] ?? ''),
            subtitle: Text('Quantité: ${data['quantity']} - ${data['description'] ?? ''}'),
            trailing: Text('${data['totalPrice']} FCFA'),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFinancialsSection(BuildContext context, List<dynamic> prestations) {
    double subTotal = 0;
    for (var p in prestations) {
      subTotal += (p['totalPrice'] as num?)?.toDouble() ?? 0.0;
    }
    // Assuming 18% tax, can be made dynamic later
    final double tax = subTotal * 0.18;
    // Placeholder for discount
    final double discount = 0.0; // For now, no discount
    final double total = subTotal + tax - discount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Détails Financiers', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        ListTile(title: Text('${subTotal.toStringAsFixed(0)} FCFA'), subtitle: const Text('Sous-total')),
        ListTile(title: Text('${tax.toStringAsFixed(0)} FCFA'), subtitle: const Text('TVA (18%)')),
        ListTile(title: Text('${discount.toStringAsFixed(0)} FCFA'), subtitle: const Text('Remises éventuelles')),
        const Divider(),
        ListTile(
          title: Text('${total.toStringAsFixed(0)} FCFA', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: const Text('TOTAL GÉNÉRAL'),
        ),
        const SizedBox(height: 20),
        Text('Récapitulatif visuel (graphique à venir)', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, List<dynamic> prestations) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final total = _calculateTotal(prestations);
                context.go(
                  '/event-details/${widget.eventId}/summary/payment',
                  extra: total,
                );
              },
              child: const Text('Payer maintenant'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Go back to event details
              // Then navigate to prestations page
              // This assumes the current route is /event-details/:eventId/summary
              // and we want to go to /event-details/:eventId/prestations
              // GoRouter.of(context).go('/event-details/${widget.eventId}/prestations');
              // For simplicity, we can just pop twice if the flow is always summary -> prestations
              // Or use context.go if we want to be explicit
              GoRouter.of(context).go('/event-details/${widget.eventId}/prestations');
            },
            child: const Text('Modifier les prestations'),
          ),
          TextButton(onPressed: () {
            // TODO: Implement cancel order logic (e.g., clear selected prestations, navigate home)
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande annulée (logique à implémenter)')));
            context.go('/home');
          }, child: const Text('Annuler commande')),
          TextButton(onPressed: () {
            // TODO: Implement save for later logic (e.g., mark order as draft)
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande sauvegardée pour plus tard (logique à implémenter)')));
          }, child: const Text('Sauvegarder pour plus tard')),
        ],
      ),
    );
  }

  double _calculateTotal(List<dynamic> prestations) {
    double subTotal = 0;
    for (var p in prestations) {
      subTotal += (p['totalPrice'] as num?)?.toDouble() ?? 0.0;
    }
    final double tax = subTotal * 0.18;
    final double discount = 0.0;
    return subTotal + tax - discount;
  }
}
