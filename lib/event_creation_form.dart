
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beh/models/event.dart';

class EventCreationForm extends StatefulWidget {
  final Event? event;

  const EventCreationForm({super.key, this.event});

  @override
  State<EventCreationForm> createState() => _EventCreationFormState();
}

class _EventCreationFormState extends State<EventCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  late final bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.event != null;
    if (_isEditing) {
      final event = widget.event!;
      _eventNameController.text = event.eventName;
      _locationController.text = event.location;
      _budgetController.text = event.budget.toString();
      _descriptionController.text = event.description ?? '';
      _selectedDate = event.eventDate;
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_isEditing) {
          await _updateEvent();
        } else {
          await _createEvent();
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

  Future<void> _createEvent() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Utilisateur ou date manquant.')),
      );
      return;
    }

    final newEvent = Event(
      id: '', // Firestore generates this
      userId: user.uid,
      eventName: _eventNameController.text.trim(),
      eventDate: _selectedDate!,
      location: _locationController.text.trim(),
      budget: double.tryParse(_budgetController.text.trim()) ?? 0.0,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    await FirebaseFirestore.instance.collection('events').add(newEvent.toFirestore());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Événement créé avec succès !')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateEvent() async {
    final eventData = {
      'eventName': _eventNameController.text.trim(),
      'eventDate': _selectedDate!,
      'location': _locationController.text.trim(),
      'budget': double.tryParse(_budgetController.text.trim()) ?? 0.0,
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    };

    await FirebaseFirestore.instance.collection('events').doc(widget.event!.id).update(eventData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Événement mis à jour avec succès !')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _eventNameController,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'événement',
              prefixIcon: Icon(Icons.edit_note),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom d\'événement';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: _selectedDate == null
                      ? 'Sélectionner la date'
                      : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (_selectedDate == null) {
                    return 'Veuillez sélectionner une date';
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Lieu',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un lieu';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _budgetController,
            decoration: const InputDecoration(
              labelText: 'Budget estimé',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un budget';
              }
              if (double.tryParse(value) == null) {
                return 'Veuillez entrer un nombre valide';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
              prefixIcon: Icon(Icons.description_outlined),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text(_isEditing ? 'Enregistrer les modifications' : 'Créer l\'événement'),
            ),
          ),
        ],
      ),
    );
  }
}
