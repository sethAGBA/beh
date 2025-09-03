
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCatalogPage extends StatelessWidget {
  const ServiceCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Hardcoded service data based on GEMINI.md
    final services = [
      {
        'title': 'MARIAGES',
        'description': 'Organisation complète',
        'price': 'À partir de 500,000 FCFA',
        'icon': Icons.favorite_border,
        'image': 'assets/images/wedding.jpg', // Placeholder path
        'eventType': 'mariage',
      },
      {
        'title': 'ANNIVERSAIRES',
        'description': 'Fêtes personnalisées',
        'price': 'À partir de 150,000 FCFA',
        'icon': Icons.cake_outlined,
        'image': 'assets/images/birthday.jpg', // Placeholder path
        'eventType': 'anniversaire',
      },
      {
        'title': 'CONFÉRENCES',
        'description': 'Événements professionnels',
        'price': 'Sur devis',
        'icon': Icons.business_center_outlined,
        'image': 'assets/images/conference.jpg', // Placeholder path
        'eventType': 'conference',
      },
      {
        'title': 'CÉRÉMONIES FUNÉRAIRES',
        'description': 'Hommages et organisation',
        'price': 'Sur devis',
        'icon': Icons.church_outlined,
        'image': 'assets/images/funeral.jpg', // Placeholder path
        'eventType': 'funerailles',
      },
    ];

    // Listen to base prices in config to show updated prices when the admin sets them.
    final basePricesRef = FirebaseFirestore.instance.collection('config').doc('base_prices');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Services'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: basePricesRef.snapshots(),
        builder: (context, snap) {
          final baseData = (snap.data?.data() as Map<String, dynamic>?) ?? {};
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final eventType = service['eventType'] as String;
              final baseVal = baseData[eventType];
              final originalPrice = service['price'] as String;
              final prefixMatch = RegExp(r'^\D*').firstMatch(originalPrice);
              final prefix = prefixMatch?.group(0) ?? '';
              final priceText = (baseVal is num) ? '$prefix${baseVal.toDouble().toStringAsFixed(0)} FCFA' : originalPrice;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Placeholder for an image
                    Container(
                      height: 150,
                      color: colorScheme.secondary.withAlpha(51),
                      child: Center(
                        child: Icon(
                          service['icon'] as IconData,
                          size: 50,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['title'] as String,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            service['description'] as String,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            priceText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/create-event/${service['eventType'] as String}');
                          },
                          child: const Text('Réserver maintenant'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
