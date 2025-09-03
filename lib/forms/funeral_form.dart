import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class FuneralForm extends StatefulWidget {
  const FuneralForm({super.key});

  @override
  State<FuneralForm> createState() => _FuneralFormState();
}

class _FuneralFormState extends State<FuneralForm> {
  final _formKey = GlobalKey<FormState>();
  final _deceasedNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _deceasedNameController.dispose();
    _locationController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Utilisateur non connecté');
        if (_selectedDate == null || _selectedTime == null) throw Exception('Date ou heure manquante');

        final eventDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        final eventName = 'Funérailles de ${_deceasedNameController.text.trim()}';

        final eventRef = await FirebaseFirestore.instance.collection('events').add({
          'userId': user.uid,
          'eventType': 'funerailles',
          'eventName': eventName,
          'deceasedName': _deceasedNameController.text.trim(),
          'eventDate': Timestamp.fromDate(eventDateTime),
          'location': _locationController.text.trim(),
          'contactName': _contactNameController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'budget': double.tryParse(_budgetController.text.trim()) ?? 0.0,
          'notes': _notesController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create a default checklist for funerals
        final checklistBatch = FirebaseFirestore.instance.batch();
        final checklistRef = eventRef.collection('checklist');
        final defaultTasks = [
          'Contacter les pompes funèbres',
          'Prévenir la famille et les proches',
          'Rédiger l\'avis de décès',
          'Organiser la cérémonie',
          'Choisir les fleurs',
        ];
        for (var task in defaultTasks) {
          checklistBatch.set(checklistRef.doc(), {
            'title': task,
            'isCompleted': false,
          });
        }
        await checklistBatch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cérémonie funéraire créée avec succès.')),
          );
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString()}')),
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
        children: [
          TextFormField(
            controller: _deceasedNameController,
            decoration: const InputDecoration(labelText: 'Nom du défunt'),
            validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: _selectedDate == null ? 'Date de la cérémonie' : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                      ),
                      validator: (value) => _selectedDate == null ? 'Date requise' : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: _selectedTime == null ? 'Heure' : 'Heure: ${_selectedTime!.format(context)}',
                      ),
                      validator: (value) => _selectedTime == null ? 'Heure requise' : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Lieu de la cérémonie'),
            validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactNameController,
            decoration: const InputDecoration(labelText: 'Personne de contact'),
            validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactPhoneController,
            decoration: const InputDecoration(labelText: 'Numéro de téléphone du contact'),
            keyboardType: TextInputType.phone,
            validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _budgetController,
            decoration: const InputDecoration(labelText: 'Budget'),
            keyboardType: TextInputType.number,
            validator: (value) => (value == null || value.isEmpty || double.tryParse(value) == null) ? 'Budget invalide' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes spéciales (optionnel)'),
            maxLines: 3,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)) : const Text('Enregistrer la réservation'),
            ),
          ),
        ],
      ),
    );
  }
}
