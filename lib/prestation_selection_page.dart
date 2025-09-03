
import 'package:beh/models/service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          .where('category', isEqualTo: 'décoration')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune prestation de décoration trouvée.'));
        }

        final services = snapshot.data!.docs.map((doc) => Service.fromFirestore(doc)).toList();

        return ListView.builder(
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // You can add an image here later
                    // Image.network(service.imageUrl ?? '', width: 80, height: 80, fit: BoxFit.cover),
                    // const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name, style: Theme.of(context).textTheme.titleLarge),
                          Text('${service.price.toStringAsFixed(0)} FCFA', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                    PrestationCounter(eventId: widget.eventId, service: service),
                  ],
                ),
              ),
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
          const TabBar(
            tabs: [
              Tab(text: 'Cuisine Africaine'),
              Tab(text: 'Cuisine Européenne'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFoodCategoryTab('africaine'),
                _buildFoodCategoryTab('europeenne'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCategoryTab(String cuisineType) {
    final categories = ['entree', 'plat', 'dessert'];

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
          return ExpansionTile(
          title: Text('${category[0].toUpperCase()}${category.substring(1)}s'),
          children: [_buildFoodList(cuisineType, category)],
        );
      },
    );
  }

  Widget _buildFoodList(String cuisineType, String foodCategory) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('category', isEqualTo: 'nourriture_${cuisineType}_$foodCategory')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const ListTile(title: Text('Aucun plat disponible dans cette catégorie.'));
        }

        final services = snapshot.data!.docs.map((doc) => Service.fromFirestore(doc)).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            // For food, we can use the same counter logic
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name, style: Theme.of(context).textTheme.titleLarge),
                          Text('${service.price.toStringAsFixed(0)} FCFA', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                    PrestationCounter(eventId: widget.eventId, service: service),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('selected_prestations')
          .doc(widget.service.id)
          .snapshots(),
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
    setState(() {
      _quantity++;
    });
    _updatePrestation();
  }

  void _decrement() {
    setState(() {
      _quantity--;
    });
    _updatePrestation();
  }

  void _updatePrestation() {
    final docRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('selected_prestations')
        .doc(widget.service.id);

    if (_quantity > 0) {
      docRef.set({
        'name': widget.service.name,
        'quantity': _quantity,
        'price': widget.service.price,
        'totalPrice': widget.service.price * _quantity,
      });
    } else {
      docRef.delete();
    }
  }
}
