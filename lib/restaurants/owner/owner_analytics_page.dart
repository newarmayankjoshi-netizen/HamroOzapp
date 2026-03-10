import 'package:flutter/material.dart';

import 'owner_models.dart';
import 'owner_repository.dart';

class OwnerAnalyticsPage extends StatelessWidget {
  final OwnerRestaurantProfile profile;

  const OwnerAnalyticsPage({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SafeArea(
        child: FutureBuilder<_AnalyticsSnapshot>(
          future: _load(profile),
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (data == null) {
              return const Center(child: Text('No analytics yet.'));
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                Text(
                  profile.name.isEmpty ? 'Restaurant' : profile.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                _MetricCard(
                  title: 'Profile views',
                  value: data.profileViews.toString(),
                  subtitle: 'How many times users opened this page on this device.',
                ),
                const SizedBox(height: 12),
                Text(
                  'Most viewed dishes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (data.topDishes.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No dish views yet. Tap menu items in Preview to generate analytics.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                  )
                else
                  ...data.topDishes.map(
                    (d) => Card(
                      child: ListTile(
                        title: Text(d.name.isEmpty ? 'Menu item' : d.name),
                        trailing: Text(
                          d.views.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        subtitle: const Text('Views'),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Coming next (when we add a backend): peak times, user demographics, conversions (views → bookings → orders).',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Future<_AnalyticsSnapshot> _load(OwnerRestaurantProfile profile) async {
    final views = await OwnerRestaurantRepository.instance.getProfileViews(profile.id);

    final dishStats = <_DishStat>[];
    for (final m in profile.menu) {
      final v = await OwnerRestaurantRepository.instance.getMenuItemViews(profile.id, m.id);
      dishStats.add(_DishStat(name: m.name, views: v));
    }

    dishStats.sort((a, b) => b.views.compareTo(a.views));
    final top = dishStats.where((d) => d.views > 0).take(10).toList();

    return _AnalyticsSnapshot(profileViews: views, topDishes: top);
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSnapshot {
  final int profileViews;
  final List<_DishStat> topDishes;

  const _AnalyticsSnapshot({
    required this.profileViews,
    required this.topDishes,
  });
}

class _DishStat {
  final String name;
  final int views;

  const _DishStat({
    required this.name,
    required this.views,
  });
}
