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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'événement'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<Event>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Événement introuvable.'));
          }

          final event = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.eventName,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Date: ${event.eventDate.toLocal().toString().split(' ')[0]}'),
                Text('Lieu: ${event.location}'),
                Text('Budget: ${event.budget.toStringAsFixed(2)} FCFA'),
                if (event.description != null && event.description!.isNotEmpty)
                  Text('Description: ${event.description}'),
                const Divider(height: 40),
                const Text(
                  'Gestion des invités',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _guestNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'invité',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _guestEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email de l\'invité (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _guestPlusOneController,
                  decoration: const InputDecoration(
                    labelText: 'Accompagnants (+1, optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _isAddingGuest ? null : _addGuest,
                    child: _isAddingGuest
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text('Ajouter un invité'),
                  ),
                ),
                const Divider(height: 40),
                const Text(
                  'Liste des invités',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
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
                      return const Center(child: Text('Aucun invité ajouté pour cet événement.'));
                    }

                    final guests = snapshot.data!.docs.map((doc) => Guest.fromFirestore(doc)).toList();

                    return ListView.builder(
                      shrinkWrap: true, // Important for nested list views
                      physics: const NeverScrollableScrollPhysics(), // Important for nested list views
                      itemCount: guests.length,
                      itemBuilder: (context, index) {
                        final guest = guests[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          child: ListTile(
                            title: Text(guest.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (guest.email != null && guest.email!.isNotEmpty) Text('Email: ${guest.email}'),
                                Text('Statut RSVP: ${guest.rsvpStatus}'),
                                if (guest.plusOne != null) Text('Accompagnants: ${guest.plusOne}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                // Implement delete guest functionality
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
                ),
                const Divider(height: 40), // New section for Vendors
                const Text(
                  'Gestion des prestataires',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _vendorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du prestataire',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _vendorServiceTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Type de service (ex: Photographe, Traiteur)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _vendorContactInfoController,
                  decoration: const InputDecoration(
                    labelText: 'Contact (email ou téléphone, optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _vendorPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Prix (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _vendorNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _isAddingVendor ? null : _addVendor,
                    child: _isAddingVendor
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text('Ajouter un prestataire'),
                  ),
                ),
                const Divider(height: 40),
                const Text(
                  'Liste des prestataires',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
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
                      return const Center(child: Text('Aucun prestataire ajouté pour cet événement.'));
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Service: ${vendor.serviceType}'),
                                if (vendor.contactInfo != null && vendor.contactInfo!.isNotEmpty)
                                  Text('Contact: ${vendor.contactInfo}'),
                                if (vendor.price != null) Text('Prix: ${vendor.price!.toStringAsFixed(2)} FCFA'),
                                if (vendor.notes != null && vendor.notes!.isNotEmpty)
                                  Text('Notes: ${vendor.notes}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
    