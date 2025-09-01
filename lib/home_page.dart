import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:beh/models/event.dart';
import 'package:beh/event_creation_form.dart'; // Import the new form

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) {
          setState(() {
            _userName = userDoc['firstName'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur (user data): ${e.toString()}')),
        );
      }
    }
  }

  // MODIFIED: Now accepts an optional Event for editing
  void _showCreateEventModal(BuildContext context, {Event? event}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Modal Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          // MODIFIED: Title changes for editing
                          event == null ? 'Nouvel Événement' : 'Modifier l\'événement',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16.0),
                      // MODIFIED: Pass the event to the form
                      child: EventCreationForm(event: event),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // NEW: Function to handle event deletion
  Future<void> _deleteEvent(BuildContext context, Event event) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Voulez-vous vraiment supprimer l\'événement "${event.eventName}" ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('events').doc(event.id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Événement supprimé avec succès.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: ${e.toString()}')),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('userId', isEqualTo: user?.uid ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _userName == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final events = snapshot.hasData ? snapshot.data!.docs.map((doc) => Event.fromFirestore(doc)).toList() : [];
          final totalBudget = events.fold<double>(0.0, (sum, event) => sum + event.budget);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 120.0,
                backgroundColor: colorScheme.primary,
                iconTheme: IconThemeData(color: colorScheme.onPrimary),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Text(
                    _userName != null ? 'Bonjour, $_userName' : 'Bienvenue',
                    style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                  ),
                  background: Container(
                    color: colorScheme.primary,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {},
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: CircleAvatar(
                        backgroundColor: colorScheme.secondary,
                        child: Text(
                          _userName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Tableau de Bord',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDashboardCard(context, Icons.event_note, 'Événements', events.length.toString()),
                    _buildDashboardCard(context, Icons.attach_money, 'Budget Total', '${totalBudget.toStringAsFixed(0)} FCFA'),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                  child: Text(
                    'Mes Événements',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (events.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Text('Aucun événement pour le moment.', style: theme.textTheme.bodyLarge),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildEventCard(context, events[index]);
                    },
                    childCount: events.length,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        // MODIFIED: Pass null for event to indicate creation
        onPressed: () => _showCreateEventModal(context),
        label: const Text('Nouvel Événement'),
        icon: const Icon(Icons.add),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // MODIFIED: Added PopupMenuButton for edit/delete actions
  Widget _buildEventCard(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: () => context.go('/event-details/${event.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.eventName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showCreateEventModal(context, event: event);
                    } else if (value == 'delete') {
                      _deleteEvent(context, event);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Modifier'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(event.eventDate.toLocal().toString().split(' ')[0], style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(event.location, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${event.budget.toStringAsFixed(0)} FCFA',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
