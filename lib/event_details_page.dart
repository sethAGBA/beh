import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:beh/models/event.dart';
import 'package:beh/models/guest.dart';
import 'package:beh/models/vendor.dart';
import 'package:beh/guest_form.dart';
import 'package:beh/vendor_form.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late Future<Event> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = _fetchEventDetails();
  }

  Future<Event> _fetchEventDetails() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('events').doc(widget.eventId).get();
    if (!doc.exists) {
      throw Exception('Event not found');
    }
    return Event.fromFirestore(doc);
  }

  void _showGuestModal(BuildContext context, {Guest? guest}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  guest == null ? 'Ajouter un invité' : 'Modifier l\'invité',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                GuestForm(guest: guest, eventId: widget.eventId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVendorModal(BuildContext context, {Vendor? vendor}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vendor == null ? 'Ajouter un prestataire' : 'Modifier le prestataire',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                VendorForm(vendor: vendor, eventId: widget.eventId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteGuest(Guest guest) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer l\'invité "${guest.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('guests')
          .doc(guest.id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invité supprimé.')),
        );
      }
    }
  }

  Future<void> _deleteVendor(Vendor vendor) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le prestataire "${vendor.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('vendors')
          .doc(vendor.id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prestataire supprimé.')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Event>(
      future: _eventFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chargement...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: Center(child: Text('Erreur: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Introuvable')),
            body: const Center(child: Text('Événement introuvable.')),
          );
        }

        final event = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            title: Text(event.eventName, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () => context.go('/profile'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.eventName,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(theme, Icons.calendar_today_outlined, event.eventDate.toLocal().toString().split(' ')[0]),
                const SizedBox(height: 8),
                _buildDetailRow(theme, Icons.location_on_outlined, event.location),
                const SizedBox(height: 8),
                _buildDetailRow(theme, Icons.attach_money_outlined, '${event.budget.toStringAsFixed(0)} FCFA'),
                if (event.description != null && event.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(event.description!, style: theme.textTheme.bodyLarge),
                  ),
                const Divider(height: 40),
                
                _buildSectionHeader(theme, 'Invités', () => _showGuestModal(context)),
                const SizedBox(height: 10),
                _buildGuestList(),

                const Divider(height: 40),

                _buildSectionHeader(theme, 'Prestataires', () => _showVendorModal(context)),
                const SizedBox(height: 10),
                _buildVendorList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, VoidCallback onAddPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
          onPressed: onAddPressed,
        ),
      ],
    );
  }

  Widget _buildGuestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('guests')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Aucun invité ajouté.')));
        }

        final guests = snapshot.data!.docs.map((doc) => Guest.fromFirestore(doc)).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: guests.length,
          itemBuilder: (context, index) {
            final guest = guests[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10.0),
              child: ListTile(
                title: Text(guest.name),
                subtitle: (guest.email != null && guest.email!.isNotEmpty)
                    ? Text(guest.email!)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                      onPressed: () => _showGuestModal(context, guest: guest),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteGuest(guest),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVendorList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('vendors')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Aucun prestataire ajouté.')));
        }

        final vendors = snapshot.data!.docs.map((doc) => Vendor.fromFirestore(doc)).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10.0),
              child: ListTile(
                title: Text(vendor.name),
                subtitle: Text(vendor.serviceType),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                      onPressed: () => _showVendorModal(context, vendor: vendor),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteVendor(vendor),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}