import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:beh/models/event.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Événements', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'À VENIR'),
            Tab(text: 'PASSÉS'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: SizedBox(
              width: 260,
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                decoration: InputDecoration(
                  hintText: 'Rechercher un événement...',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.03),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onPrimary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : Icon(Icons.search, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            [_buildEventsList(isUpcoming: true), _buildEventsList(isUpcoming: false)],
      ),
    );
  }

  Widget _buildEventsList({required bool isUpcoming}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Veuillez vous connecter.'));
    }

    final now = DateTime.now();
    Query query = FirebaseFirestore.instance
        .collection('events')
        .where('userId', isEqualTo: user.uid);

    if (_searchQuery.isNotEmpty) {
      // Firestore does not support full-text search directly.
      // This performs a prefix search. For more advanced search, consider Algolia or similar.
      query = query
          .orderBy('eventName')
          .startAt([_searchQuery])
          .endAt(['${_searchQuery}\uf8ff']);
    }

    if (isUpcoming) {
      query = query.where('eventDate', isGreaterThanOrEqualTo: now).orderBy('eventDate', descending: false);
    } else {
      query = query.where('eventDate', isLessThan: now).orderBy('eventDate', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUpcoming ? Icons.event_note_outlined : Icons.event_busy_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
                const SizedBox(height: 20),
                Text(
                  isUpcoming ? 'Aucun événement à venir.' : 'Aucun événement passé.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  isUpcoming
                      ? 'Créez votre premier événement dès maintenant !\nAllez à l\'onglet Services pour commencer.'
                      : 'Vos événements passés apparaîtront ici.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (isUpcoming)
                  ElevatedButton.icon(
                    onPressed: () => context.go('/services'),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer un événement'),
                  ),
              ],
            ),
          );
        }

        final events = snapshot.data!.docs.map((doc) => Event.fromFirestore(doc)).toList();

        return RefreshIndicator(
          onRefresh: () async {
            // Stream updates automatically; force a small rebuild for UX.
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: events.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(context, event);
            },
          ),
        );
      },
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormatted = DateFormat.yMMMMd('fr_FR').format(event.eventDate.toLocal());
    final daysLeft = event.eventDate.difference(DateTime.now()).inDays;
    final budgetFormatted = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(event.budget);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => context.go('/my-events/details/${event.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: colorScheme.primary.withOpacity(0.12),
          child: Icon(Icons.event, color: colorScheme.primary, size: 28),
        ),
        title: Text(event.eventName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 6),
                // Prevent overflow by allowing the date text to shrink with an ellipsis.
                Expanded(
                  child: Text(
                    dateFormatted,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                if (daysLeft >= 0)
                  Chip(label: Text('$daysLeft jours'), backgroundColor: Colors.green.shade50, visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text(event.location, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Budget: $budgetFormatted', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () => context.go('/my-events/details/${event.id}'),
        ),
      ),
    );
  }
}
