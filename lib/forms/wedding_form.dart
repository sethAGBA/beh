import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beh/models/event.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class WeddingForm extends StatefulWidget {
  final DocumentSnapshot? eventDoc;
  const WeddingForm({super.key, this.eventDoc});

  @override
  State<WeddingForm> createState() => _WeddingFormState();
}

class _WeddingFormState extends State<WeddingForm> {
  bool get _isEditing => widget.eventDoc != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.eventDoc;
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      _brideNameController.text = (data['brideName'] ?? '') as String;
      _groomNameController.text = (data['groomName'] ?? '') as String;
      _guestCountController.text = data['guestCount']?.toString() ?? '';
      _budgetController.text = data['budget']?.toString() ?? '';
      _locationController.text = (data['location'] ?? '') as String;
      _notesController.text = (data['notes'] ?? '') as String;
      final ts = data['eventDate'];
      if (ts is Timestamp) {
        final dt = ts.toDate();
        _selectedDate = DateTime(dt.year, dt.month, dt.day);
        _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
    }
  }
  final _formKey = GlobalKey<FormState>();
  final _brideNameController = TextEditingController();
  final _groomNameController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _brideNameController.dispose();
    _groomNameController.dispose();
    _guestCountController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
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
        if (user == null) {
          throw Exception('Utilisateur non connecté');
        }
        if (_selectedDate == null || _selectedTime == null) {
          throw Exception('Date ou heure manquante');
        }

        final eventDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        // Create a more descriptive event name
        final eventName = 'Mariage de ${_brideNameController.text.trim()} et ${_groomNameController.text.trim()}';

        final data = {
          'userId': user.uid,
          'eventType': 'mariage',
          'eventName': eventName,
          'brideName': _brideNameController.text.trim(),
          'groomName': _groomNameController.text.trim(),
          'guestCount': int.tryParse(_guestCountController.text.trim()) ?? 0,
          'eventDate': Timestamp.fromDate(eventDateTime),
          'budget': double.tryParse(_budgetController.text.trim()) ?? 0.0,
          'location': _locationController.text.trim(),
          'notes': _notesController.text.trim(),
        };

        if (_isEditing) {
          await FirebaseFirestore.instance.collection('events').doc(widget.eventDoc!.id).update(data);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Événement de mariage mis à jour avec succès !')),
            );
            context.go('/home');
          }
        } else {
          data['createdAt'] = FieldValue.serverTimestamp();
          final eventRef = await FirebaseFirestore.instance.collection('events').add(data);

          // Create a default checklist
          final checklistBatch = FirebaseFirestore.instance.batch();
          final checklistRef = eventRef.collection('checklist');
          final defaultTasks = [
            'Choisir le lieu de réception',
            'Envoyer les faire-part',
            'Réserver le traiteur',
            'Choisir la décoration',
            'Réserver le photographe',
            'Acheter les alliances',
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
              const SnackBar(content: Text('Événement de mariage créé avec succès !')),
            );
            context.go('/home');
          }
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
            controller: _brideNameController,
            decoration: const InputDecoration(labelText: 'Nom de la mariée'),
            validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _groomNameController,
            decoration: const InputDecoration(labelText: 'Nom du marié'),
            validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _guestCountController,
            decoration: const InputDecoration(labelText: 'Nombre de personnes invitées'),
            keyboardType: TextInputType.number,
            validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'Nombre invalide' : null,
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
                        labelText: _selectedDate == null ? 'Date de l\'événement' : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
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
                        labelText: _selectedTime == null ? 'Heure de début' : 'Heure: ${_selectedTime!.format(context)}',
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
            controller: _budgetController,
            decoration: const InputDecoration(labelText: 'Budget prévu'),
            keyboardType: TextInputType.number,
            validator: (value) => (value == null || value.isEmpty || double.tryParse(value) == null) ? 'Budget invalide' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Lieu souhaité (optionnel)'),
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
