
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beh/models/guest.dart';

class GuestForm extends StatefulWidget {
  final Guest? guest;
  final String eventId;

  const GuestForm({super.key, this.guest, required this.eventId});

  @override
  State<GuestForm> createState() => _GuestFormState();
}

class _GuestFormState extends State<GuestForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _plusOneController = TextEditingController();
  bool _isLoading = false;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.guest != null;
    if (_isEditing) {
      final guest = widget.guest!;
      _nameController.text = guest.name;
      _emailController.text = guest.email ?? '';
      _plusOneController.text = guest.plusOne?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _plusOneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final guestData = {
        'eventId': widget.eventId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'plusOne': int.tryParse(_plusOneController.text.trim()),
        // We don't update rsvpStatus here, as it's a separate action
      };

      try {
        if (_isEditing) {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .collection('guests')
              .doc(widget.guest!.id)
              .update(guestData);
        } else {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .collection('guests')
              .add(guestData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invité ${_isEditing ? 'mis à jour' : 'ajouté'} avec succès !')),
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
            decoration: const InputDecoration(labelText: 'Nom de l\'invité'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email (optionnel)'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _plusOneController,
            decoration: const InputDecoration(labelText: 'Accompagnants (+1, optionnel)'),
            keyboardType: TextInputType.number,
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
