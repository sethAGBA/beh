import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:beh/models/event.dart';
import 'package:beh/models/guest.dart';
import 'package:beh/models/vendor.dart'; // Added import

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late Future<Event> _eventFuture;
  final _guestNameController = TextEditingController();
  final _guestEmailController = TextEditingController();
  final _guestPlusOneController = TextEditingController();
  bool _isAddingGuest = false;

  // Vendor controllers
  final _vendorNameController = TextEditingController();
  final _vendorServiceTypeController = TextEditingController();
  final _vendorContactInfoController = TextEditingController();
  final _vendorPriceController = TextEditingController();
  final _vendorNotesController = TextEditingController();
  bool _isAddingVendor = false;

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

  Future<void> _addGuest() async {
    if (_guestNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le nom de l\'invité.')),
      );
      return;
    }

    setState(() {
      _isAddingGuest = true;
    });

    try {
      final newGuest = Guest(
        id: '', // Firestore will generate this
        eventId: widget.eventId,
        name: _guestNameController.text.trim(),
        email: _guestEmailController.text.trim().isEmpty ? null : _guestEmailController.text.trim(),
        plusOne: int.tryParse(_guestPlusOneController.text.trim()),
      );

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('guests')
          .add(newGuest.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invité ajouté avec succès !')),
        );
        _guestNameController.clear();
        _guestEmailController.clear();
        _guestPlusOneController.clear();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout de l\'invité: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Une erreur inattendue est survenue: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isAddingGuest = false;
          });
        }
      }
    }

  Future<void> _addVendor() async {
    if (_vendorNameController.text.trim().isEmpty || _vendorServiceTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le nom et le type de service du prestataire.')),
      );
      return;
    }

    setState(() {
      _isAddingVendor = true;
    });

    try {
      final newVendor = Vendor(
        id: '', // Firestore will generate this
        eventId: widget.eventId,
        name: _vendorNameController.text.trim(),
        serviceType: _vendorServiceTypeController.text.trim(),
        contactInfo: _vendorContactInfoController.text.trim().isEmpty ? null : _vendorContactInfoController.text.trim(),
        price: double.tryParse(_vendorPriceController.text.trim()),
        notes: _vendorNotesController.text.trim().isEmpty ? null : _vendorNotesController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('vendors')
          .add(newVendor.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prestataire ajouté avec succès !')),
        );
        _vendorNameController.clear();
        _vendorServiceTypeController.clear();
        _vendorContactInfoController.clear();
        _vendorPriceController.clear();
        _vendorNotesController.clear();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout du prestataire: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Une erreur inattendue est survenue: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isAddingVendor = false;
          });
        }
      }
    }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPlusOneController.dispose();
    _vendorNameController.dispose();
    _vendorServiceTypeController.dispose();
    _vendorContactInfoController.dispose();
    _vendorPriceController.dispose();
    _vendorNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Event>(
      future: _eventFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chargement...')) /*backgroundColor: Colors.blue removed*/,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erreur')) /*backgroundColor: Colors.blue removed*/,
            body: Center(child: Text('Erreur: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Introuvable')) /*backgroundColor: Colors.blue removed*/,
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
            /*backgroundColor: Colors.blue removed*/
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
                
                // Guest Management Section
                _buildSectionTitle(theme, 'Gestion des invités'),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _guestNameController,
                  decoration: const InputDecoration(labelText: 'Nom de l\'invité'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _guestEmailController,
                  decoration: const InputDecoration(labelText: 'Email (optionnel)'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _guestPlusOneController,
                  decoration: const InputDecoration(labelText: 'Accompagnants (+1, optionnel)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAddingGuest ? null : _addGuest,
                    child: _isAddingGuest
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Text('Ajouter un invité'),
                  ),
                ),
                const Divider(height: 40),
                _buildSectionTitle(theme, 'Liste des invités'),
                const SizedBox(height: 10),
                _buildGuestList(),

                const Divider(height: 40),

                // Vendor Management Section
                _buildSectionTitle(theme, 'Gestion des prestataires'),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _vendorNameController,
                  decoration: const InputDecoration(labelText: 'Nom du prestataire'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _vendorServiceTypeController,
                  decoration: const InputDecoration(labelText: 'Type de service (ex: Photographe)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _vendorContactInfoController,
                  decoration: const InputDecoration(labelText: 'Contact (optionnel)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _vendorPriceController,
                  decoration: const InputDecoration(labelText: 'Prix (optionnel)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _vendorNotesController,
                  decoration: const InputDecoration(labelText: 'Notes (optionnel)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAddingVendor ? null : _addVendor,
                    child: _isAddingVendor
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Ajouter un prestataire'),
                  ),
                ),
                const Divider(height: 40),
                _buildSectionTitle(theme, 'Liste des prestataires'),
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

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
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
                  },
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
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
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
    