
import 'package:beh/models/service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

class PrestationSelectionPage extends StatefulWidget {
  final String eventId;

  const PrestationSelectionPage({super.key, required this.eventId});

  @override
  State<PrestationSelectionPage> createState() => _PrestationSelectionPageState();
}

class _PrestationSelectionPageState extends State<PrestationSelectionPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélection des Prestations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Décoration'),
            Tab(text: 'Nourriture'),
          ],
          labelColor: Theme.of(context).colorScheme.surface,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDecorationTab(),
          _buildNourritureTab(),
        ],
      ),
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .collection('selected_prestations')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          double totalPrice = 0;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalPrice += data['totalPrice'] ?? 0;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${totalPrice.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prestations enregistrées.')),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

Widget _buildDecorationTab() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('services')
        .where('main_category', isEqualTo: 'Décoration')
        .where('available', isEqualTo: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Erreur: ${snapshot.error}'));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.palette, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aucune prestation de décoration trouvée.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }

      final services = snapshot.data!.docs.map((doc) => Service.fromFirestore(doc)).toList();
      final groupedServices = groupBy(services, (Service service) => service.decoType ?? 'Autre');

      final sortedKeys = groupedServices.keys.toList()..sort();

      return ListView.builder(
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final decoType = sortedKeys[index];
          final typeServices = groupedServices[decoType]!;
          return ExpansionTile(
            title: Text(decoType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            initiallyExpanded: true,
            children: typeServices.map((service) => _buildServiceListItem(service)).toList(),
          );
        },
      );
    },
  );
}

  Widget _buildNourritureTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
 TabBar(
 labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Cuisine Africaine'),
              Tab(text: 'Cuisine Européenne'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFoodCuisineTab('Africaine'),
                _buildFoodCuisineTab('Européenne'),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildFoodCuisineTab(String cuisineType) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('services')
        .where('main_category', isEqualTo: 'Nourriture')
        .where('food_cuisine', isEqualTo: cuisineType)
        .where('available', isEqualTo: true)
        .snapshots(),
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
              Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aucune prestation de cuisine $cuisineType trouvée.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }

      final services = snapshot.data!.docs.map((doc) => Service.fromFirestore(doc)).toList();
      final groupedServices = groupBy(services, (Service service) => service.foodCourse ?? 'Autre');

      final sortedKeys = groupedServices.keys.toList()
        ..sort((a, b) {
          const order = ['Entrée', 'Plat', 'Dessert', 'Autre'];
          return order.indexOf(a).compareTo(order.indexOf(b));
        });

      return ListView.builder(
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final course = sortedKeys[index];
          final courseServices = groupedServices[course]!;
          return ExpansionTile(
            title: Text(course, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            initiallyExpanded: true,
            children: courseServices.map((service) => _buildServiceListItem(service)).toList(),
          );
        },
      );
    },
  );
}

  Widget _buildServiceListItem(Service service) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // You can add an image here later
            // if (service.imageUrl != null && service.imageUrl!.isNotEmpty)
            //   Image.network(service.imageUrl!, width: 80, height: 80, fit: BoxFit.cover),
            // const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: Theme.of(context).textTheme.titleLarge),
                  if (service.description != null && service.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(service.description!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 4),
                  Text('${service.price.toStringAsFixed(0)} FCFA', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            PrestationCounter(eventId: widget.eventId, service: service),
          ],
        ),
      ),
    );
  }
}

class PrestationCounter extends StatefulWidget {
  final String eventId;
  final Service service;

  const PrestationCounter({super.key, required this.eventId, required this.service});

  @override
  State<PrestationCounter> createState() => _PrestationCounterState();
}

class _PrestationCounterState extends State<PrestationCounter> {
  int _quantity = 0;

  DocumentReference get _docRef => FirebaseFirestore.instance
      .collection('events')
      .doc(widget.eventId)
      .collection('selected_prestations')
      .doc(widget.service.id);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          _quantity = data['quantity'] ?? 0;
        } else {
          _quantity = 0;
        }

        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _quantity > 0 ? _decrement : null,
            ),
            Text('$_quantity', style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _increment,
            ),
          ],
        );
      },
    );
  }

  void _increment() {
    _updatePrestation(_quantity + 1);
  }

  void _decrement() {
    if (_quantity > 0) {
      _updatePrestation(_quantity - 1);
    }
  }

  void _updatePrestation(int newQuantity) {
    if (newQuantity > 0) {
      _docRef.set({
        'name': widget.service.name,
        'quantity': newQuantity,
        'price': widget.service.price,
        'totalPrice': widget.service.price * newQuantity,
        // Also save the service details for easy summary later
        'main_category': widget.service.mainCategory,
        'deco_type': widget.service.decoType,
        'food_cuisine': widget.service.foodCuisine,
        'food_course': widget.service.foodCourse,
      }, SetOptions(merge: true));
    } else {
      _docRef.delete();
    }
    // No need for setState, StreamBuilder will rebuild
  }
}
