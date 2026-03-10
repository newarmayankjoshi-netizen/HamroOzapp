import 'package:flutter/material.dart';
import 'restaurants_page.dart';

class AustralianState {
  final String name;
  final String abbreviation;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final IconData icon;

  AustralianState({
    required this.name,
    required this.abbreviation,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    required this.icon,
  });

  /// Bounding box format: [south, west, north, east]
  List<double> get bbox => [minLat, minLon, maxLat, maxLon];
}

class StatesPage extends StatelessWidget {
  final List<AustralianState> australianStates = [
    AustralianState(
      name: 'New South Wales',
      abbreviation: 'NSW',
      minLat: -37.5,
      maxLat: -28.0,
      minLon: 140.6,
      maxLon: 154.0,
      icon: Icons.location_city,
    ),
    AustralianState(
      name: 'Victoria',
      abbreviation: 'VIC',
      minLat: -39.2,
      maxLat: -34.0,
      minLon: 141.0,
      maxLon: 150.0,
      icon: Icons.location_city,
    ),
    AustralianState(
      name: 'Queensland',
      abbreviation: 'QLD',
      minLat: -29.2,
      maxLat: -10.0,
      minLon: 138.0,
      maxLon: 154.0,
      icon: Icons.location_city,
    ),
    AustralianState(
      name: 'Western Australia',
      abbreviation: 'WA',
      minLat: -35.1,
      maxLat: -13.5,
      minLon: 113.1,
      maxLon: 129.0,
      icon: Icons.location_city,
    ),
    AustralianState(
      name: 'South Australia',
      abbreviation: 'SA',
      minLat: -38.0,
      maxLat: -26.0,
      minLon: 129.0,
      maxLon: 141.0,
      icon: Icons.location_city,
    ),
    AustralianState(
      name: 'Tasmania',
      abbreviation: 'TAS',
      minLat: -44.0,
      maxLat: -40.6,
      minLon: 144.0,
      maxLon: 148.4,
      icon: Icons.location_city,
    ),
    AustralianState(
      name: 'Australian Capital Territory',
      abbreviation: 'ACT',
      minLat: -35.8,
      maxLat: -35.1,
      minLon: 148.7,
      maxLon: 149.4,
      icon: Icons.location_city,
    ),
    AustralianState(
      name: 'Northern Territory',
      abbreviation: 'NT',
      minLat: -26.0,
      maxLat: -10.5,
      minLon: 129.0,
      maxLon: 138.0,
      icon: Icons.location_city,
    ),
  ];

  StatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a State'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Find Nepalese Restaurants by State",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF111827),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  itemCount: australianStates.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    return StateCard(
                      state: australianStates[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantsPage(
                              selectedState: australianStates[index],
                            ),
                          ),
                        );
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

class StateCard extends StatelessWidget {
  final AustralianState state;
  final VoidCallback onTap;

  const StateCard({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  state.icon,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                state.abbreviation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
