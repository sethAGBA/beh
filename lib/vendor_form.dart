
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beh/models/vendor.dart';

class VendorForm extends StatefulWidget {
  final Vendor? vendor;
  final String eventId;

  const VendorForm({super.key, this.vendor, required this.eventId});

  @override
  State<VendorForm> createState() => _VendorFormState();
}

class _VendorFormState extends State<VendorForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.vendor != null;
    if (_isEditing) {
      final vendor = widget.vendor!;
      _nameController.text = vendor.name;
      _serviceTypeController.text = vendor.serviceType;
      _contactInfoController.text = vendor.contactInfo ?? '';
      _priceController.text = vendor.price?.toString() ?? '';
      _notesController.text = vendor.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serviceTypeController.dispose();
    _contactInfoController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final vendorData = {
        'eventId': widget.eventId,
        'name': _nameController.text.trim(),
        'serviceType': _serviceTypeController.text.trim(),
        'contactInfo': _contactInfoController.text.trim().isEmpty ? null : _contactInfoController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      };

      try {
        if (_isEditing) {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .collection('vendors')
              .doc(widget.vendor!.id)
              .update(vendorData);
        } else {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .collection('vendors')
              .add(vendorData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Prestataire ${_isEditing ? 'mis à jour' : 'ajouté'} avec succès !')),
          );
          Navigator.of(context).pop();
        }
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.message}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nom du prestataire'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _serviceTypeController,
            decoration: const InputDecoration(labelText: 'Type de service'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un type de service';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactInfoController,
            decoration: const InputDecoration(labelText: 'Contact (optionnel)'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Prix (optionnel)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optionnel)'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                  : Text(_isEditing ? 'Enregistrer' : 'Ajouter'),
            ),
          ),
        ],
      ),
    );
  }
}
