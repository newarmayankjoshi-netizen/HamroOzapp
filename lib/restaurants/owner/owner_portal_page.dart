import 'package:flutter/material.dart';

import 'owner_edit_page.dart';
import 'owner_models.dart';
import 'owner_preview_page.dart';
import 'owner_repository.dart';

class OwnerPortalPage extends StatefulWidget {
  const OwnerPortalPage({super.key});

  @override
  State<OwnerPortalPage> createState() => _OwnerPortalPageState();
}

class _OwnerPortalPageState extends State<OwnerPortalPage> {
  late Future<List<OwnerRestaurantProfile>> _future;

  @override
  void initState() {
    super.initState();
    _future = OwnerRestaurantRepository.instance.loadMyRestaurants();
  }

  Future<void> _reload() async {
    setState(() {
      _future = OwnerRestaurantRepository.instance.loadMyRestaurants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Owners'),
        actions: [
          IconButton(
            tooltip: 'Add restaurant',
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created = await Navigator.push<OwnerRestaurantProfile?>(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerEditPage(
                    initial: OwnerRestaurantProfile.create(),
                  ),
                ),
              );
              if (created != null) await _reload();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<OwnerRestaurantProfile>>(
        future: _future,
        builder: (context, snapshot) {
          final profiles = snapshot.data ?? const [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                Text(
                  'Business Booster (MVP)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create menus, promotions, story, bookings/ordering links, loyalty, and view local analytics.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                if (profiles.isEmpty) ...[
                  _EmptyState(
                    onAdd: () async {
                      final created = await Navigator.push<OwnerRestaurantProfile?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OwnerEditPage(
                            initial: OwnerRestaurantProfile.create(),
                          ),
                        ),
                      );
                      if (created != null) await _reload();
                    },
                  ),
                ] else ...[
                  ...profiles.map(
                    (p) => _OwnerRestaurantTile(
                      profile: p,
                      onEdit: () async {
                        final saved = await Navigator.push<OwnerRestaurantProfile?>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OwnerEditPage(initial: p),
                          ),
                        );
                        if (saved != null) await _reload();
                      },
                      onPreview: () async {
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OwnerPreviewPage(profile: p),
                          ),
                        );
                        await _reload();
                      },
                      onDelete: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Delete restaurant?'),
                              content: Text('Delete "${p.name.isEmpty ? 'Unnamed restaurant' : p.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                        if (ok == true) {
                            await OwnerRestaurantRepository.instance.deleteById(p.id);
                          await _reload();
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OwnerRestaurantTile extends StatelessWidget {
  final OwnerRestaurantProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  const _OwnerRestaurantTile({
    required this.profile,
    required this.onEdit,
    required this.onPreview,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile.name.isEmpty ? 'Unnamed restaurant' : profile.name;
    final subtitle = profile.address.isEmpty
        ? 'Tap Edit to add address'
        : profile.address;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
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
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'preview':
                        onPreview();
                        return;
                      case 'edit':
                        onEdit();
                        return;
                      case 'delete':
                        onDelete();
                        return;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'preview',
                      child: Text('Preview'),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onPreview,
                    child: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onEdit,
                    child: const Text('Edit'),
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Icon(Icons.storefront, size: 64, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          const Text(
            'No restaurants added yet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your restaurant to create a menu, promotions, and loyalty program.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onAdd,
            child: const Text('Add Restaurant'),
          ),
        ],
      ),
    );
  }
}
