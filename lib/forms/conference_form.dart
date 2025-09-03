import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ConferenceForm extends StatefulWidget {
  final DocumentSnapshot? eventDoc;

  ConferenceForm({Key? key, this.eventDoc}) : super(key: key);

  @override
  State<ConferenceForm> createState() => _ConferenceFormState();
}

class _ConferenceFormState extends State<ConferenceForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _attendeeCountController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _topicController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  bool get _isEditing => widget.eventDoc != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.eventDoc;
    if (doc != null) {
      final raw = doc.data();
      final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
      _titleController.text = (data['eventName'] ?? '') as String;
      _companyNameController.text = (data['companyName'] ?? '') as String;
      _attendeeCountController.text = data['attendeeCount']?.toString() ?? '';
      _budgetController.text = data['budget']?.toString() ?? '';
      _locationController.text = (data['location'] ?? '') as String;
      _topicController.text = (data['topic'] ?? '') as String;
      _notesController.text = (data['notes'] ?? '') as String;
      final ts = data['eventDate'];
      if (ts is Timestamp) {
        final dt = ts.toDate();
        _selectedDate = DateTime(dt.year, dt.month, dt.day);
        _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyNameController.dispose();
    _attendeeCountController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _topicController.dispose();
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
        if (_isEditing) {
          await _updateEvent();
        } else {
          await _createEvent();
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

  Future<void> _createEvent() async {
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

    final eventName = _titleController.text.trim();

    final eventRef = await FirebaseFirestore.instance.collection('events').add({
      'userId': user.uid,
      'eventType': 'conference',
      'eventName': eventName,
      'companyName': _companyNameController.text.trim(),
      'attendeeCount': int.tryParse(_attendeeCountController.text.trim()) ?? 0,
      'eventDate': Timestamp.fromDate(eventDateTime),
      'budget': double.tryParse(_budgetController.text.trim()) ?? 0.0,
      'location': _locationController.text.trim(),
      'topic': _topicController.text.trim(),
      'notes': _notesController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Create a default checklist for conferences
    final checklistBatch = FirebaseFirestore.instance.batch();
    final checklistRef = eventRef.collection('checklist');
    final defaultTasks = [
      'Finaliser la liste des intervenants',
      'Réserver le matériel audiovisuel',
      'Préparer les badges et documents',
      'Confirmer le traiteur pour les pauses café',
      'Envoyer le programme aux participants',
    ];
    for (var task in defaultTasks) {
      checklistBatch.set(checklistRef.doc(), {
        'title': task,
        'isCompleted': false,
      });
    }
    await checklistBatch.commit();

    if (mounted) {
      // Notify admin
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'type': 'new_event',
        'eventId': eventRef.id,
        'eventType': 'conference',
        'eventName': eventName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('admin_meta').doc('notifications').set({'unreadEvents': FieldValue.increment(1)}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conférence créée avec succès !')),
      );
      context.go('/home');
    }
  }

  Future<void> _updateEvent() async {
    if (_selectedDate == null || _selectedTime == null) throw Exception('Date ou heure manquante');

    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final eventName = _titleController.text.trim();

    await FirebaseFirestore.instance.collection('events').doc(widget.eventDoc!.id).update({
      'eventName': eventName,
      'companyName': _companyNameController.text.trim(),
      'attendeeCount': int.tryParse(_attendeeCountController.text.trim()) ?? 0,
      'eventDate': Timestamp.fromDate(eventDateTime),
      'budget': double.tryParse(_budgetController.text.trim()) ?? 0.0,
      'location': _locationController.text.trim(),
      'topic': _topicController.text.trim(),
      'notes': _notesController.text.trim(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conférence mise à jour avec succès !')),
      );
      context.go('/home');
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
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Titre de la conférence'),
            validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _companyNameController,
            decoration: const InputDecoration(labelText: 'Nom de l\'entreprise/organisation'),
            validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _attendeeCountController,
            decoration: const InputDecoration(labelText: 'Nombre de participants'),
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
            controller: _budgetController,
            decoration: const InputDecoration(labelText: 'Budget'),
            keyboardType: TextInputType.number,
            validator: (value) => (value == null || value.isEmpty || double.tryParse(value) == null) ? 'Budget invalide' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Lieu'),
            validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _topicController,
            decoration: const InputDecoration(labelText: 'Secteur/Thème (optionnel)'),
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
