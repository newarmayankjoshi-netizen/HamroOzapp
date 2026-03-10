import 'package:flutter/material.dart';

import 'services/nearby_places_launcher.dart';

class ServicesPage extends StatelessWidget {
  static const List<({String title, IconData icon, String description})>
  services = [
    (
      title: 'Nepalese Restaurant finder',
      icon: Icons.restaurant,
      description: 'Open Maps to find Nepalese restaurants near you',
    ),
    (
      title: 'Nepalese Groceries finder',
      icon: Icons.map_outlined,
      description: 'Open Maps to find Nepalese groceries near you',
    ),
    (
      title: 'Nepalese Photographers',
      icon: Icons.camera_alt_outlined,
      description: 'Open Maps to find Nepalese photographers near you',
    ),
    (
      title: 'Nepalese Barbers',
      icon: Icons.content_cut_outlined,
      description: 'Open Maps to find Nepalese barbers near you',
    ),
    (
      title: 'Nepalese Jewellery Shops',
      icon: Icons.diamond_outlined,
      description: 'Open Maps to find Nepalese jewellery shops near you',
    ),
    (
      title: 'Nepalese Beauty Parlors',
      icon: Icons.spa_outlined,
      description: 'Open Maps to find Nepalese beauty parlors near you',
    ),
    (
      title: 'Nepalese Clothings',
      icon: Icons.checkroom_outlined,
      description: 'Open Maps to find Nepalese clothing stores near you',
    ),
    (
      title: 'Nepalese Migration Agents',
      icon: Icons.badge_outlined,
      description: 'Open Maps to find Nepali migration agents near you',
    ),
    (
      title: 'Nepalese Finance Brokers',
      icon: Icons.account_balance_wallet_outlined,
      description: 'Open Maps to find Nepali finance brokers near you',
    ),
    (
      title: 'Bank and ATM',
      icon: Icons.account_balance_outlined,
      description: 'Open Maps to find banks and ATMs near you',
    ),
    (
      title: 'Nepalese function Centers',
      icon: Icons.celebration_outlined,
      description: 'Open Maps to find Nepalese function centres near you',
    ),
    (
      title: 'Healthcare',
      icon: Icons.local_hospital,
      description: 'Healthcare services and providers',
    ),
  ];

  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Available Services",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF111827),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: services.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return ServiceCard(
                      title: services[index].title,
                      icon: services[index].icon,
                      description: services[index].description,
                      onTap: () {
                        if (services[index].title ==
                            'Nepalese Restaurant finder') {
                          NearbyPlacesLauncher.openNepaleseRestaurants(context);
                        } else if (services[index].title ==
                            'Nepalese Groceries finder') {
                          NearbyPlacesLauncher.openNepaleseGroceries(context);
                        } else if (services[index].title ==
                            'Nepalese Photographers') {
                          NearbyPlacesLauncher.openNepalesePhotographers(
                            context,
                          );
                        } else if (services[index].title ==
                            'Nepalese Barbers') {
                          NearbyPlacesLauncher.openNepaleseBarbers(context);
                        } else if (services[index].title ==
                            'Nepalese Jewellery Shops') {
                          NearbyPlacesLauncher.openNepaleseJewelleryShops(
                            context,
                          );
                        } else if (services[index].title ==
                            'Nepalese Beauty Parlors') {
                          NearbyPlacesLauncher.openNepaleseBeautyParlors(
                            context,
                          );
                        } else if (services[index].title ==
                            'Nepalese Clothings') {
                          NearbyPlacesLauncher.openNepaleseClothingStores(
                            context,
                          );
                        } else if (services[index].title ==
                            'Nepalese Migration Agents') {
                          NearbyPlacesLauncher.openNepaleseMigrationAgents(
                            context,
                          );
                        } else if (services[index].title ==
                            'Nepalese Finance Brokers') {
                          NearbyPlacesLauncher.openNepaleseFinanceBrokers(
                            context,
                          );
                        } else if (services[index].title == 'Bank and ATM') {
                          NearbyPlacesLauncher.openBanksAndAtms(context);
                        } else if (services[index].title ==
                            'Nepalese function Centers') {
                          NearbyPlacesLauncher.openNepaleseFunctionCentres(
                            context,
                          );
                        } else if (services[index].title == 'Healthcare') {
                          NearbyPlacesLauncher.openHealthcareHospitals(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${services[index].title} coming soon...',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primaryContainer,
          ),
          child: Icon(icon, size: 24, color: theme.colorScheme.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}
