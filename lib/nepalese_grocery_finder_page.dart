import 'package:flutter/material.dart';

import 'services/nearby_places_launcher.dart';

class NepaleseGroceryFinderPage extends StatelessWidget {
  const NepaleseGroceryFinderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nepalese Grocery Finder')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Nepalese groceries near you',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will open your Maps app and search for nearby Nepalese/Nepali grocery stores.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  NearbyPlacesLauncher.openNepaleseGroceries(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open in Maps'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => NearbyPlacesLauncher.showNepaleseFinder(context),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('More Nepalese nearby searches'),
            ),
            const SizedBox(height: 16),
            Text(
              'Tip: If results are limited, try searching “Nepali grocery”, “South Asian grocery”, or a suburb name in Maps.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
