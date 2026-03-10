import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/overpass_service.dart';
import 'states_page.dart' as states;
import 'restaurants/owner/owner_models.dart';
import 'restaurants/owner/owner_storage.dart';
export 'services/overpass_service.dart' show Restaurant;

class RestaurantsPage extends StatefulWidget {
  final states.AustralianState? selectedState;
  final Future<RestaurantsScreenData> Function(states.AustralianState? selectedState)? dataLoader;

  const RestaurantsPage({
    super.key,
    this.selectedState,
    this.dataLoader,
  });

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  late Future<RestaurantsScreenData> _dataFuture;
  String _searchQuery = '';
  String _selectedLocation = 'All Locations';
  Timer? _searchDebounce;

  bool get _isStateView => widget.selectedState != null;

  @override
  void initState() {
    super.initState();
    final loader = widget.dataLoader;
    _dataFuture = loader != null ? loader(widget.selectedState) : _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (_searchQuery == value) return;
      setState(() {
        _searchQuery = value;
      });
    });
  }

  Future<RestaurantsScreenData> _loadData() async {
    final overpass = widget.selectedState != null
        ? await OverpassService.fetchRestaurantsByState(widget.selectedState!)
        : await OverpassService.fetchNepalseRestaurants();

    final ownerAdded = widget.selectedState == null
        ? const <OwnerRestaurantProfile>[]
        : await _loadOwnerAddedByState(widget.selectedState!.abbreviation);

    return RestaurantsScreenData(overpassRestaurants: overpass, ownerAdded: ownerAdded);
  }

  static String _extractAuStateAbbr(String input) {
    final match = RegExp(
      r'\b(NSW|VIC|QLD|SA|WA|TAS|ACT|NT)\s+\d{4}$',
      caseSensitive: false,
    ).firstMatch(input.trim());
    return match?.group(1)?.toUpperCase() ?? '';
  }

  static String _ownerLocationFromAddress(String address) {
    final parts = address.split(',');
    if (parts.length >= 2) {
      return parts[1].trim();
    }
    return address.trim();
  }

  Future<List<OwnerRestaurantProfile>> _loadOwnerAddedByState(String abbr) async {
    final profiles = await OwnerRestaurantStorage.loadProfiles();
    final target = abbr.trim().toUpperCase();
    return profiles
        .where((p) => _extractAuStateAbbr(p.address) == target)
        .toList();
  }

  List<String> _getUniqueLocations(List<Restaurant> restaurants) {
    final locations = <String>{'All Locations'};
    for (final restaurant in restaurants) {
      locations.add(restaurant.location);
    }
    return locations.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectedState != null
              ? 'Restaurants in ${widget.selectedState!.abbreviation}'
              : 'Nepalese Restaurants',
        ),
      ),
      body: FutureBuilder<RestaurantsScreenData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading restaurants...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load restaurants',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your internet connection and try again.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            _dataFuture = _loadData();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final data = snapshot.data;
          final restaurants = data?.overpassRestaurants ?? const <Restaurant>[];
          final ownerAdded = data?.ownerAdded ?? const <OwnerRestaurantProfile>[];
          final normalizedQuery = _searchQuery.trim().toLowerCase();
          final filteredOwnerAdded = _getFilteredOwnerAdded(
            ownerAdded,
            normalizedQuery: normalizedQuery,
          );
          final filteredRestaurants = _getFilteredRestaurants(
            restaurants,
            normalizedQuery: normalizedQuery,
          );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by name or address...',
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (widget.selectedState != null && filteredOwnerAdded.isNotEmpty) ...[
                    Text(
                      'Added in App',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...filteredOwnerAdded.map(
                      (p) => _OwnerAddedRestaurantCard(
                        profile: p,
                        location: _ownerLocationFromAddress(p.address),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Location Filter (only on the overall list, not state-specific pages)
                  if (!_isStateView) ...[
                    Text(
                      'Filter by Location',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _getUniqueLocations(restaurants)
                            .map((location) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    label: Text(location),
                                    selected: _selectedLocation == location,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedLocation = location;
                                      });
                                    },
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Results Count
                  Text(
                    'Found ${filteredRestaurants.length} restaurant${filteredRestaurants.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Restaurants List
                  Expanded(
                    child: _buildRestaurantsList(filteredRestaurants, theme),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<OwnerRestaurantProfile> _getFilteredOwnerAdded(
    List<OwnerRestaurantProfile> profiles, {
    required String normalizedQuery,
  }) {
    final stateAbbr = widget.selectedState?.abbreviation.toUpperCase() ?? '';
    return profiles.where((p) {
      final location = _ownerLocationFromAddress(p.address).toUpperCase();
      final matchesState = stateAbbr.isEmpty || location.contains(stateAbbr);
      final matchesSearch = normalizedQuery.isEmpty ||
          p.name.toLowerCase().contains(normalizedQuery) ||
          p.address.toLowerCase().contains(normalizedQuery);
      return matchesState && matchesSearch;
    }).toList();
  }

  List<Restaurant> _getFilteredRestaurants(
    List<Restaurant> restaurants, {
    required String normalizedQuery,
  }) {
    return restaurants.where((restaurant) {
      final matchesSearch = normalizedQuery.isEmpty ||
          restaurant.name.toLowerCase().contains(normalizedQuery) ||
          (restaurant.address ?? '').toLowerCase().contains(normalizedQuery) ||
          restaurant.location.toLowerCase().contains(normalizedQuery);

      final matchesState = !_isStateView ||
          restaurant.location.toUpperCase().contains(
                widget.selectedState!.abbreviation.toUpperCase(),
              );

      final matchesLocation = _isStateView ||
          _selectedLocation == 'All Locations' ||
          restaurant.location.contains(_selectedLocation);

      return matchesSearch && matchesState && matchesLocation;
    }).toList();
  }

  Widget _buildRestaurantsList(
    List<Restaurant> filteredRestaurants,
    ThemeData theme,
  ) {
    if (filteredRestaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 64,
              color: theme.colorScheme.primary.withAlpha(77),
            ),
            const SizedBox(height: 16),
            Text(
              'No restaurants found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = filteredRestaurants[index];
        return RestaurantCard(restaurant: restaurant);
      },
    );
  }
}

class RestaurantsScreenData {
  final List<Restaurant> overpassRestaurants;
  final List<OwnerRestaurantProfile> ownerAdded;

  const RestaurantsScreenData({
    required this.overpassRestaurants,
    required this.ownerAdded,
  });
}

class _OwnerAddedRestaurantCard extends StatelessWidget {
  final OwnerRestaurantProfile profile;
  final String location;

  const _OwnerAddedRestaurantCard({
    required this.profile,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isEmpty ? 'Restaurant' : profile.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (profile.rating > 0)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFE5E7EB), height: 1),
            const SizedBox(height: 12),
            if (profile.address.trim().isNotEmpty) ...[
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: profile.address.trim(),
                theme: theme,
              ),
              const SizedBox(height: 10),
            ],
            if (profile.phone.trim().isNotEmpty) ...[
              _InfoRow(
                icon: Icons.phone_outlined,
                label: profile.phone.trim(),
                theme: theme,
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                if (profile.phone.trim().isNotEmpty)
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () {
                        final uri = Uri(
                          scheme: 'tel',
                          path: profile.phone.trim(),
                        );
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call, size: 18),
                          SizedBox(width: 8),
                          Text('Call'),
                        ],
                      ),
                    ),
                  ),
                if (profile.phone.trim().isNotEmpty) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () {
                      final query = [
                        profile.name,
                        profile.address,
                      ].where((e) => e.trim().isNotEmpty).join(' ');

                      final uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
                      );
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Map'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              color: const Color(0xFFE5E7EB),
              height: 1,
            ),
            const SizedBox(height: 12),
            if (restaurant.address != null) ...[
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: restaurant.address!,
                theme: theme,
              ),
              const SizedBox(height: 10),
            ],
            if (restaurant.phone != null) ...[
              _InfoRow(
                icon: Icons.phone_outlined,
                label: restaurant.phone!,
                theme: theme,
              ),
              const SizedBox(height: 10),
            ],
            if (restaurant.phone != null || restaurant.address != null)
              Row(
                children: [
                  if (restaurant.phone != null)
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () {
                          final uri = Uri(
                            scheme: 'tel',
                            path: restaurant.phone!,
                          );
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call, size: 18),
                            SizedBox(width: 8),
                            Text('Call'),
                          ],
                        ),
                      ),
                    ),
                  if (restaurant.phone != null) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () {
                        final query = [
                          restaurant.name,
                          if (restaurant.address != null) restaurant.address!,
                          restaurant.location,
                        ].where((e) => e.trim().isNotEmpty).join(' ');

                        final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
                        );
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Map'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}
