import 'package:flutter/material.dart';
import 'package:beh/models/service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceDetailModal extends StatelessWidget {
  final Service service;
  final bool isAdminView;

  const ServiceDetailModal({super.key, required this.service, this.isAdminView = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AlertDialog(
      title: Text(service.name, style: textTheme.headlineSmall),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service.imageUrl != null && service.imageUrl!.isNotEmpty)
              Image.network(service.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text('Prix: ${service.price.toStringAsFixed(0)} FCFA', style: textTheme.titleMedium),
            if (service.description != null && service.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Description: ${service.description}', style: textTheme.bodyMedium),
              ),
            const SizedBox(height: 16),
            Text('Catégorie principale: ${service.mainCategory ?? 'N/A'}', style: textTheme.bodyMedium),
            if (service.mainCategory == 'Décoration')
              Text('Type de décoration: ${service.decoType ?? 'N/A'}', style: textTheme.bodyMedium),
            if (service.mainCategory == 'Nourriture') ...[
              Text('Cuisine: ${service.foodCuisine ?? 'N/A'}', style: textTheme.bodyMedium),
              Text('Type de plat: ${service.foodCourse ?? 'N/A'}', style: textTheme.bodyMedium),
            ],
            if (isAdminView) ...[
              const SizedBox(height: 16),
              Text('Disponible: ${(service.available ?? false) ? 'Oui' : 'Non'}', style: textTheme.bodyMedium),
              if (service.createdAt != null) // Assuming createdAt is a Timestamp or DateTime
                Text('Créé le: ${DateFormat('dd/MM/yyyy HH:mm').format(service.createdAt is Timestamp ? service.createdAt.toDate() : service.createdAt)}', style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
