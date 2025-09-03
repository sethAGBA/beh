import 'package:beh/widgets/checklist_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:beh/models/event.dart';
import 'package:intl/intl.dart'; // For date formatting

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _fetchDetails();
  }

  Future<Map<String, dynamic>> _fetchDetails() async {
    final eventDoc = await FirebaseFirestore.instance.collection('events').doc(widget.eventId).get();
    if (!eventDoc.exists) throw Exception('Event not found');

    final event = Event.fromFirestore(eventDoc);

    final prestationsSnapshot = await eventDoc.reference.collection('selected_prestations').get();
    final prestations = prestationsSnapshot.docs.map((doc) => doc.data()).toList();
    final spentBudget = prestations.fold<double>(0.0, (sum, p) => sum + (p['totalPrice'] ?? 0.0));

    return {
      'event': event,
      'spentBudget': spentBudget,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(title: const Text('Erreur')), body: Center(child: Text('Erreur: ${snapshot.error}')));
        }
        if (!snapshot.hasData) {
          return Scaffold(appBar: AppBar(title: const Text('Introuvable')), body: const Center(child: Text('Événement introuvable.')));
        }

        final event = snapshot.data!['event'] as Event;
        final spentBudget = snapshot.data!['spentBudget'] as double;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                // Only call pop when there's something to pop. Otherwise
                // fall back to the root route so we don't throw "There is nothing to pop".
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            title: Text(event.eventName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_outlined),
                onPressed: () { /* TODO: Implement event editing */ },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _detailsFuture = _fetchDetails();
              });
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCountdownCard(context, event),
                  const SizedBox(height: 20),
                  _buildBudgetCard(context, event, spentBudget),
                  const SizedBox(height: 20),
                  _buildActionsCard(context, event),
                  const SizedBox(height: 20),
                  ChecklistWidget(eventId: widget.eventId),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownCard(BuildContext context, Event event) {
    final daysLeft = event.eventDate.difference(DateTime.now()).inDays;
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_bottom_outlined, color: Colors.white, size: 40),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compte à rebours',
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                Text(
                  daysLeft > 0 ? '$daysLeft jours restants' : 'Événement passé',
                  style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Event event, double spentBudget) {
    final theme = Theme.of(context);
    final budget = event.budget;
    final remainingBudget = budget - spentBudget;
    final progress = budget > 0 ? spentBudget / budget : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suivi du Budget', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBudgetColumn('Utilisé', spentBudget, Colors.orange),
                _buildBudgetColumn('Restant', remainingBudget, Colors.green),
                _buildBudgetColumn('Total', budget, theme.colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetColumn(String title, double amount, Color color) {
    final formattedAmount = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(amount);
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(formattedAmount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildActionsCard(BuildContext context, Event event) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionItem(context, Icons.design_services_outlined, 'Prestations', () {
              context.go('/my-events/details/${event.id}/prestations');
            }),
            _buildActionItem(context, Icons.receipt_long_outlined, 'Récapitulatif', () {
              context.go('/my-events/details/${event.id}/summary');
            }),
            _buildActionItem(context, Icons.support_agent_outlined, 'Support', () {
              // TODO: Implement support action
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
