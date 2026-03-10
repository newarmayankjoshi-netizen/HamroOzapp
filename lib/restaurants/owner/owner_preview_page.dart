import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'owner_analytics_page.dart';
import 'owner_models.dart';
import 'owner_repository.dart';

class OwnerPreviewPage extends StatefulWidget {
  final OwnerRestaurantProfile profile;

  const OwnerPreviewPage({
    super.key,
    required this.profile,
  });

  @override
  State<OwnerPreviewPage> createState() => _OwnerPreviewPageState();
}

class _OwnerPreviewPageState extends State<OwnerPreviewPage> {
  late OwnerRestaurantProfile _profile;
  int _stamps = 0;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    OwnerRestaurantRepository.instance.incrementProfileView(_profile.id);
    _loadStamps();
  }

  Future<void> _loadStamps() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stamps = prefs.getInt(_stampsKey) ?? 0;
    });
  }

  String get _stampsKey => 'restaurant_loyalty_stamps_${_profile.id}';

  Future<void> _setStamps(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stampsKey, value);
    if (!mounted) return;
    setState(() {
      _stamps = value;
    });
  }

  Future<void> _launchExternal(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPhone(String raw) async {
    final p = raw.trim();
    if (p.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: p);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _profile.name.isEmpty ? 'Restaurant' : _profile.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'Analytics',
            icon: const Icon(Icons.query_stats),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerAnalyticsPage(profile: _profile),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _HeaderCard(
              profile: _profile,
              onCall: _profile.phone.isEmpty ? null : () => _callPhone(_profile.phone),
              onWebsite:
                  _profile.website.isEmpty ? null : () => _launchExternal(_profile.website),
              onReviews:
                  _profile.reviewsUrl.isEmpty ? null : () => _launchExternal(_profile.reviewsUrl),
            ),
            const SizedBox(height: 14),
            if (_profile.promotions.isNotEmpty) ...[
              Text(
                'Specials / Events',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ..._profile.promotions.map(
                (p) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (p.details.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            p.details,
                            style: const TextStyle(color: Color(0xFF374151)),
                          ),
                        ],
                        if (p.validUntil.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Valid until: ${p.validUntil}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_profile.story.trim().isNotEmpty) ...[
              Text(
                'Story',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _profile.story,
                    style: const TextStyle(color: Color(0xFF374151)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_profile.reviewHighlights.trim().isNotEmpty) ...[
              Text(
                'Reviews & Ratings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _profile.reviewHighlights,
                    style: const TextStyle(color: Color(0xFF374151)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              'Menu',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (_profile.menu.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No menu items added yet.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              )
            else
              ..._profile.menu.map(
                (m) => Card(
                  child: ListTile(
                    onTap: () async {
                      await OwnerRestaurantRepository.instance.incrementMenuItemView(
                        _profile.id,
                        m.id,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viewed: ${m.name}'),
                          duration: const Duration(milliseconds: 900),
                        ),
                      );
                    },
                    leading: _MenuImage(photoUrl: m.photoUrl),
                    title: Text(
                      m.name.isEmpty ? 'Menu item' : m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'AUD ${m.price.toStringAsFixed(2)}${m.isDailySpecial ? ' • Daily special' : ''}${m.available ? '' : ' • Sold out'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Text(
              'Bookings / Ordering',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _profile.bookingUrl.isEmpty
                        ? null
                        : () async {
                            await OwnerRestaurantRepository.instance
                                .incrementBookingClick(_profile.id);
                            await _launchExternal(_profile.bookingUrl);
                          },
                    child: const Text('Book a table'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _profile.orderUrl.isEmpty
                        ? null
                        : () async {
                            await OwnerRestaurantRepository.instance
                                .incrementOrderClick(_profile.id);
                            await _launchExternal(_profile.orderUrl);
                          },
                    child: const Text('Order online'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Loyalty (demo)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _LoyaltyCard(
              stampsNeeded: max(1, _profile.loyalty.stampsNeeded),
              reward: _profile.loyalty.reward,
              message: _profile.loyalty.comebackMessage,
              stamps: _stamps,
              onAddStamp: () {
                final next = min(_profile.loyalty.stampsNeeded, _stamps + 1);
                _setStamps(next);
              },
              onReset: () => _setStamps(0),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final OwnerRestaurantProfile profile;
  final VoidCallback? onCall;
  final VoidCallback? onWebsite;
  final VoidCallback? onReviews;

  const _HeaderCard({
    required this.profile,
    required this.onCall,
    required this.onWebsite,
    required this.onReviews,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.name.isEmpty ? 'Restaurant' : profile.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF111827),
              ),
            ),
            if (profile.address.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                profile.address,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _RatingPill(rating: profile.rating),
                const SizedBox(width: 8),
                if (onReviews != null)
                  TextButton.icon(
                    onPressed: onReviews,
                    icon: const Icon(Icons.reviews_outlined),
                    label: const Text('Reviews'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onCall,
                    child: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onWebsite,
                    child: const Text('Website'),
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

class _RatingPill extends StatelessWidget {
  final double rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = rating <= 0 ? null : rating;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            r == null ? 'No rating yet' : r.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuImage extends StatelessWidget {
  final String photoUrl;

  const _MenuImage({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl.trim().isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_outlined, color: Color(0xFF6B7280)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        photoUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          return Container(
            width: 44,
            height: 44,
            color: const Color(0xFFE5E7EB),
            child: const Icon(Icons.broken_image_outlined),
          );
        },
      ),
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  final int stampsNeeded;
  final String reward;
  final String message;
  final int stamps;
  final VoidCallback onAddStamp;
  final VoidCallback onReset;

  const _LoyaltyCard({
    required this.stampsNeeded,
    required this.reward,
    required this.message,
    required this.stamps,
    required this.onAddStamp,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final done = stamps >= stampsNeeded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reward.isEmpty ? 'Loyalty reward' : reward,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stamps: $stamps / $stampsNeeded',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                stampsNeeded,
                (i) {
                  final filled = i < stamps;
                  return Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: filled ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: done ? null : onAddStamp,
                    child: const Text('Add stamp'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: stamps == 0 ? null : onReset,
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
            if (message.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(color: Color(0xFF374151)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
