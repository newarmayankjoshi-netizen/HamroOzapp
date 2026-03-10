import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyPlacesLauncher {
  static Future<void> openNepaleseGroceries(BuildContext context) async {
    await _launchMapsSearch(context, 'Nepalese grocery store');
  }

  static Future<void> openNepaleseRestaurants(BuildContext context) async {
    await _launchMapsSearch(context, 'Nepalese restaurant');
  }

  static Future<void> openNepalesePhotographers(BuildContext context) async {
    await _launchMapsSearch(context, 'Nepali photographer');
  }

  static Future<void> openNepaleseBarbers(BuildContext context) async {
    await _launchMapsSearch(context, 'Nepali barber');
  }

  static Future<void> openNepaleseJewelleryShops(BuildContext context) async {
    await _launchMapsSearch(context, 'Nepali jewellery shop');
  }

  static Future<void> openNepaleseBeautyParlors(BuildContext context) async {
    await _launchMapsSearch(context, 'Nepali beauty parlour');
  }

  static Future<void> openNepaleseClothingStores(BuildContext context) async {
    await _launchMapsSearch(context, 'Nepali clothing store');
  }

  static Future<void> openNepaleseMigrationAgents(BuildContext context) async {
    await _launchMapsSearch(context, 'Nepalese migration agent');
  }

  static Future<void> openNepaleseFinanceBrokers(BuildContext context) async {
    await _launchMapsSearch(context, 'Nepalese finance broker');
  }

  static Future<void> openBanksAndAtms(BuildContext context) async {
    await _launchMapsSearch(context, 'Bank ATM');
  }

  static Future<void> openNepaleseFunctionCentres(BuildContext context) async {
    await _launchMapsSearch(context, 'Nepalese function centre');
  }

  static Future<void> openHealthcareHospitals(BuildContext context) async {
    await _launchMapsSearch(context, 'Hospital medical centre');
  }

  static Future<void> showNepaleseFinder(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nepalese Finder',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Opens your Maps app and shows nearby places based on your location.',
                ),
                const SizedBox(height: 14),
                _ActionTile(
                  icon: Icons.local_grocery_store_outlined,
                  title: 'Find Nepalese groceries',
                  subtitle: 'Nepali grocery stores near you',
                  onTap: () async {
                    Navigator.pop(context);
                    await openNepaleseGroceries(context);
                  },
                ),
                const SizedBox(height: 6),
                _ActionTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Find Nepalese photographers',
                  subtitle: 'Nepali photographers near you',
                  onTap: () async {
                    Navigator.pop(context);
                    await openNepalesePhotographers(context);
                  },
                ),
                const SizedBox(height: 6),
                _ActionTile(
                  icon: Icons.content_cut_outlined,
                  title: 'Find Nepalese barbers',
                  subtitle: 'Nepali barbers near you',
                  onTap: () async {
                    Navigator.pop(context);
                    await openNepaleseBarbers(context);
                  },
                ),
                const SizedBox(height: 6),
                _ActionTile(
                  icon: Icons.diamond_outlined,
                  title: 'Find Nepalese jewellery shops',
                  subtitle: 'Nepali jewellery shops near you',
                  onTap: () async {
                    Navigator.pop(context);
                    await openNepaleseJewelleryShops(context);
                  },
                ),
                const SizedBox(height: 6),
                _ActionTile(
                  icon: Icons.spa_outlined,
                  title: 'Find Nepalese beauty parlors',
                  subtitle: 'Nepali beauty parlors near you',
                  onTap: () async {
                    Navigator.pop(context);
                    await openNepaleseBeautyParlors(context);
                  },
                ),
                const SizedBox(height: 6),
                _ActionTile(
                  icon: Icons.checkroom_outlined,
                  title: 'Find Nepalese clothing stores',
                  subtitle: 'Nepali clothing stores near you',
                  onTap: () async {
                    Navigator.pop(context);
                    await openNepaleseClothingStores(context);
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _launchMapsSearch(
    BuildContext context,
    String query,
  ) async {
    final pos = await _tryGetPosition(context);

    final uri = _buildMapsUri(query: query, pos: pos);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open Maps app')));
    }
  }

  static Uri _buildMapsUri({required String query, Position? pos}) {
    final q = Uri.encodeComponent(
      pos == null ? query : '$query near ${pos.latitude},${pos.longitude}',
    );

    if (Platform.isIOS) {
      // Apple Maps.
      final params = <String, String>{'q': query};
      if (pos != null) {
        params['ll'] = '${pos.latitude},${pos.longitude}';
      }
      return Uri.https('maps.apple.com', '/', params);
    }

    // Google Maps (web URL that opens the installed app when available).
    return Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
  }

  static Future<Position?> _tryGetPosition(BuildContext context) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is permanently denied. Opening Maps without location.',
              ),
            ),
          );
        }
        return null;
      }

      if (permission == LocationPermission.denied) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF111827)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 18, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ),
    );
  }
}
