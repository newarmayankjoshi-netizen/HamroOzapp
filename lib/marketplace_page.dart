import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'add_item_page.dart';
import 'item_detail_page.dart';
import 'auth_page.dart';
import 'services/security_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/verification_service.dart';

class MarketplaceItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final String location;
  final String sellerId;
  final String sellerName;
  final String? sellerPhone;
  final DateTime postedDate;
  final List<String> images;
  final int viewCount;
  final bool isClosed;
  final String? closedReason;
  final DateTime? closedAt;

  MarketplaceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.location,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    required this.postedDate,
    this.images = const [],
    this.viewCount = 0,
    this.isClosed = false,
    this.closedReason,
    this.closedAt,
  });

  MarketplaceItem copyWith({
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    String? location,
    String? sellerPhone,
    DateTime? postedDate,
    List<String>? images,
    int? viewCount,
    bool? isClosed,
    String? closedReason,
    DateTime? closedAt,
  }) {
    return MarketplaceItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      postedDate: postedDate ?? this.postedDate,
      images: images ?? this.images,
      viewCount: viewCount ?? this.viewCount,
      isClosed: isClosed ?? this.isClosed,
      closedReason: closedReason ?? this.closedReason,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(postedDate);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class MarketplacePage extends StatefulWidget {
  final String? filterSellerId;
  final String? titleOverride;
  final bool activeOnly;

  const MarketplacePage({
    super.key, 
    this.filterSellerId, 
    this.titleOverride,
    this.activeOnly = false,
  });

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  bool _firebaseInitDone = false;

  String _searchQuery = '';
  String _selectedCategory = 'All Categories';
  String _selectedCondition = 'All Conditions';
  String _selectedLocation = 'All Locations';
  double _maxPrice = 10000;
  bool _showMyItems = false;

  final List<String> _categories = [
    'All Categories',
    'Electronics',
    'Furniture',
    'Vehicles',
    'Clothing',
    'Books',
    'Sports',
    'Home & Garden',
    'Toys & Games',
    'Other',
  ];

  final List<String> _conditions = [
    'All Conditions',
    'New',
    'Like New',
    'Good',
    'Fair',
    'For Parts',
  ];

  final List<String> _locations = [
    'All Locations',
    'Sydney',
    'Melbourne',
    'Brisbane',
    'Perth',
    'Adelaide',
    'Canberra',
  ];

  String? get _realUserId => AuthState.currentUserId;

  String get _currentUserId => _realUserId ?? '';

  CollectionReference<Map<String, dynamic>> get _itemsCollection =>
      FirebaseFirestore.instance.collection('marketplace_items');

  List<MarketplaceItem> _itemsSnapshotCache = const [];

  Future<void> _incrementViewCount(String itemId) async {
    try {
      await _itemsCollection.doc(itemId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (_) {
      // Best-effort only.
    }
  }

  static String _closedReasonLabel(String? reason) {
    switch (reason) {
      case 'sold_in_app':
        return 'Sold from this app';
      case 'sold_other_app':
        return 'Sold from other app';
      case 'other':
        return 'Other';
      default:
        return '';
    }
  }

  Future<String?> _promptCloseReason(BuildContext context) async {
    String selected = 'sold_in_app';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Close Listing'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Closing will hide your item from the marketplace. Select a reason (helps us improve the app):',
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: selected,
                    onChanged: (v) => setLocalState(() => selected = v ?? selected),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'sold_in_app',
                          title: const Text('Sold from this app'),
                        ),
                        RadioListTile<String>(
                          value: 'sold_other_app',
                          title: const Text('Sold from other app'),
                        ),
                        RadioListTile<String>(
                          value: 'other',
                          title: const Text('Other / no longer available'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, selected),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _setClosed(
    String itemId,
    bool isClosed, {
    String reason = '',
  }) async {
    if (!isClosed) {
      await _itemsCollection.doc(itemId).update({
        'isClosed': false,
        'closedReason': FieldValue.delete(),
        'closedAt': FieldValue.delete(),
        'reopenedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _itemsCollection.doc(itemId).update({
      'isClosed': true,
      'closedReason': reason,
      'closedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteItem(MarketplaceItem item) async {
    // Try to delete images first (best-effort), then delete the Firestore doc.
    for (final imageUrl in item.images) {
      if (imageUrl.startsWith('http')) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (_) {
          // Ignore failures (missing permissions/file, non-Firebase URL, etc).
        }
      }
    }
    await _itemsCollection.doc(item.id).delete();
  }

  @override
  void initState() {
    super.initState();
    FirebaseBootstrap.tryInit().then((_) {
      if (!mounted) return;
      setState(() {
        _firebaseInitDone = true;
      });
    });
  }

  Widget _firebaseUnavailableBody(ThemeData theme) {
    final initError = FirebaseBootstrap.lastError;
    final errorText = initError == null
        ? ''
        : '\n\nDetails: ${_prettyFirestoreError(initError)}';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 56,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Buy & Sell isn\'t available on this macOS build yet',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This page uses Firebase (Firestore/Storage). On macOS, it will stay blank until Firebase is configured for the macOS bundle ID.'
                '$errorText\n\nFix: run "flutterfire configure --platforms=macos" and add the generated GoogleService-Info.plist to macos/Runner.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await FirebaseBootstrap.tryInit(force: true);
                  if (!mounted) return;
                  setState(() {
                    _firebaseInitDone = true;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Firebase'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _prettyFirestoreError(Object? error) {
    if (error == null) return 'Unknown error';
    if (error is FirebaseException) {
      final message = (error.message ?? '').trim();
      return message.isEmpty ? error.code : '${error.code}: $message';
    }
    return error.toString();
  }

  Query<Map<String, dynamic>> _itemsQuery() {
    Query<Map<String, dynamic>> query = _itemsCollection;
    final filterSellerId = widget.filterSellerId;
    if (filterSellerId != null && filterSellerId.isNotEmpty) {
      // Avoid composite index requirement for (sellerId == X) + orderBy(postedDate).
      // We'll sort client-side for user-scoped views.
      return query.where('sellerId', isEqualTo: filterSellerId);
    } else if (_showMyItems) {
      return query.where('sellerId', isEqualTo: _currentUserId);
    }
    return query.orderBy('postedDate', descending: true);
  }

  static DateTime _timestampToDate(dynamic value, DateTime fallback) {
    if (value is Timestamp) return value.toDate();
    return fallback;
  }

  static DateTime? _timestampToNullableDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    return fallback;
  }

  MarketplaceItem _itemFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final now = DateTime.now();
    final postedDate = _timestampToDate(data['postedDate'], now);
    final priceValue = data['price'];
    final price = priceValue is num ? priceValue.toDouble() : 0.0;
    final imagesDynamic = data['images'];
    final images = imagesDynamic is List
        ? imagesDynamic.whereType<String>().toList()
        : <String>[];

    return MarketplaceItem(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      price: price,
      category: (data['category'] ?? 'Other') as String,
      condition: (data['condition'] ?? 'Good') as String,
      location: (data['location'] ?? 'Sydney') as String,
      sellerId: (data['sellerId'] ?? '') as String,
      sellerName: (data['sellerName'] ?? 'Guest User') as String,
      sellerPhone: data['sellerPhone'] as String?,
      postedDate: postedDate,
      images: images,
      viewCount: _asInt(data['viewCount']),
      isClosed: _asBool(data['isClosed']),
      closedReason: data['closedReason'] is String
          ? (data['closedReason'] as String)
          : null,
      closedAt: _timestampToNullableDate(data['closedAt']),
    );
  }

  List<MarketplaceItem> get _filteredItems {
    return _itemsSnapshotCache.where((item) {
      // My Items filter
      if (_showMyItems && item.sellerId != _currentUserId) return false;

      // Show open items only
      if (item.isClosed) return false;

      // Search filter
      final matchesSearch =
          _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());

      // Category filter
      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          item.category == _selectedCategory;

      // Condition filter
      final matchesCondition =
          _selectedCondition == 'All Conditions' ||
          item.condition == _selectedCondition;

      // Location filter
      final matchesLocation =
          _selectedLocation == 'All Locations' ||
          item.location == _selectedLocation;

      // Price filter
      final matchesPrice = item.price <= _maxPrice;

      return matchesSearch &&
          matchesCategory &&
          matchesCondition &&
          matchesLocation &&
          matchesPrice;
    }).toList()..sort((a, b) => b.postedDate.compareTo(a.postedDate));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUserFiltered =
        widget.filterSellerId != null && widget.filterSellerId!.isNotEmpty;
    final appBarTitle =
        widget.titleOverride ?? (_showMyItems ? 'My Listings' : 'Buy & Sell');

    if (!_firebaseInitDone) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_firebaseReady) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: _firebaseUnavailableBody(theme),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: isUserFiltered
            ? null
            : [
                IconButton(
                  icon: Icon(_showMyItems ? Icons.storefront : Icons.person),
                  onPressed: () {
                    setState(() {
                      _showMyItems = !_showMyItems;
                    });
                  },
                  tooltip: _showMyItems ? 'View All Items' : 'View My Listings',
                ),
              ],
      ),
      floatingActionButton: isUserFiltered
          ? null
          : FutureBuilder<bool>(
              future: VerificationService.canPost(AuthState.currentUserId ?? 'guest'),
              builder: (ctx, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final allowed = snap.data == true;
                if (!allowed) {
                  return FloatingActionButton.extended(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only verified contributors can list items.')));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Sell Item'),
                  );
                }
                return FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddItemPage()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Sell Item'),
                );
              },
            ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _itemsQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load items. ${_prettyFirestoreError(snapshot.error)}',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? const [];
          _itemsSnapshotCache = docs.map(_itemFromDoc).toList()
            ..sort((a, b) => b.postedDate.compareTo(a.postedDate));
          final filteredItems = _filteredItems;

          return SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () => _showFiltersBottomSheet(context),
                      ),
                    ),
                  ),
                ),

                // Active Filters Chips
                if (_selectedCategory != 'All Categories' ||
                    _selectedCondition != 'All Conditions' ||
                    _selectedLocation != 'All Locations' ||
                    _maxPrice < 10000)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedCategory != 'All Categories')
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(_selectedCategory),
                                onDeleted: () {
                                  setState(() {
                                    _selectedCategory = 'All Categories';
                                  });
                                },
                              ),
                            ),
                          if (_selectedCondition != 'All Conditions')
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(_selectedCondition),
                                onDeleted: () {
                                  setState(() {
                                    _selectedCondition = 'All Conditions';
                                  });
                                },
                              ),
                            ),
                          if (_selectedLocation != 'All Locations')
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(_selectedLocation),
                                onDeleted: () {
                                  setState(() {
                                    _selectedLocation = 'All Locations';
                                  });
                                },
                              ),
                            ),
                          if (_maxPrice < 10000)
                            Chip(
                              label: Text('Under \$${_maxPrice.toInt()}'),
                              onDeleted: () {
                                setState(() {
                                  _maxPrice = 10000;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Results Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredItems.length} item${filteredItems.length == 1 ? '' : 's'} found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Items Grid
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showMyItems
                                    ? Icons.inventory_2_outlined
                                    : Icons.shopping_bag_outlined,
                                size: 64,
                                color: theme.colorScheme.primary.withValues(alpha: 
                                  0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _showMyItems
                                    ? 'No items listed yet'
                                    : 'No items found',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _showMyItems
                                    ? 'Tap the button below to sell your first item'
                                    : 'Try adjusting your filters',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                // single column layout to stack cards vertically
                                crossAxisCount: 1,
                                childAspectRatio: 3.0,
                                // Make marketplace cards taller for more details
                                mainAxisExtent: 220,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return ItemCard(
                              item: item,
                              currentUserId: _currentUserId,
                              onTap: () {
                                final isOwner = _currentUserId == item.sellerId;
                                if (!isOwner) {
                                  _incrementViewCount(item.id);
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ItemDetailPage(item: item),
                                  ),
                                );
                              },
                              onEdit:
                                  filteredItems[index].sellerId ==
                                      _currentUserId
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddItemPage(
                                            initialItem: filteredItems[index],
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              onToggleClosed:
                                  filteredItems[index].sellerId ==
                                      _currentUserId
                                  ? () {
                                      final itemToToggle = filteredItems[index];
                                      if (itemToToggle.isClosed) {
                                        _setClosed(
                                          itemToToggle.id,
                                          false,
                                        ).then((_) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Listing reopened'),
                                            ),
                                          );
                                        });
                                      } else {
                                        _promptCloseReason(context).then((reason) {
                                          if (reason == null) return;
                                          _setClosed(
                                            itemToToggle.id,
                                            true,
                                            reason: reason,
                                          ).then((_) {
                                            if (!context.mounted) return;
                                            final label = _closedReasonLabel(reason);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  label.isEmpty
                                                      ? 'Listing closed'
                                                      : 'Listing closed ($label)',
                                                ),
                                              ),
                                            );
                                          });
                                        });
                                      }
                                    }
                                  : null,
                              onDelete:
                                  filteredItems[index].sellerId ==
                                      _currentUserId
                                  ? () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Item'),
                                          content: Text(
                                            'Are you sure you want to delete "${filteredItems[index].title}"?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final itemToDelete = filteredItems[index];
                                                Navigator.pop(context);
                                                final current = AuthState.currentUserId ?? 'guest';
                                                final allowed = await VerificationService.canPost(current);
                                                if (!allowed) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only verified contributors may delete items.'), backgroundColor: Colors.red));
                                                  return;
                                                }
                                                _deleteItem(itemToDelete).then((_,) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Item deleted',
                                                      ),
                                                    ),
                                                  );
                                                });
                                              },
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'All Categories';
                          _selectedCondition = 'All Conditions';
                          _selectedLocation = 'All Locations';
                          _maxPrice = 10000;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Condition Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCondition,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  items: _conditions.map((condition) {
                    return DropdownMenuItem(
                      value: condition,
                      child: Text(condition),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() {
                      setState(() {
                        _selectedCondition = value!;
                      });
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Location Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedLocation,
                  decoration: const InputDecoration(labelText: 'Location'),
                  items: _locations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() {
                      setState(() {
                        _selectedLocation = value!;
                      });
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Price Slider
                Text(
                  'Max Price: \$${_maxPrice.toInt()}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  value: _maxPrice,
                  min: 0,
                  max: 10000,
                  divisions: 100,
                  label: '\$${_maxPrice.toInt()}',
                  onChanged: (value) {
                    setModalState(() {
                      setState(() {
                        _maxPrice = value;
                      });
                    });
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Filters'),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final MarketplaceItem item;
  final VoidCallback onTap;
  final String currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleClosed;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.currentUserId,
    this.onEdit,
    this.onDelete,
    this.onToggleClosed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = currentUserId == item.sellerId;

    const suspiciousPhrases = [
      'deposit',
      'pay now',
      'pay upfront',
      'upfront',
      'shipping only',
      'delivery only',
      'no inspection',
      'no viewing',
      'verify code',
      'verification code',
      'otp',
      'urgent',
      'kindly',
      'click link',
      'telegram',
      'whatsapp',
    ];

    final combined =
        '${item.title}\n${item.description}\n${item.category}\n${item.condition}\n${item.location}';
    final prohibited = securityService.findProhibitedTerms(combined);
    final lower = combined.toLowerCase();
    final suspicious =
        suspiciousPhrases
            .where((p) => lower.contains(p))
            .toSet()
            .toList(growable: false);

    ItemScamLikelihood likelihood = ItemScamLikelihood.low;
    if (combined.trim().isEmpty) {
      likelihood = ItemScamLikelihood.unknown;
    } else if (prohibited.isNotEmpty) {
      likelihood = ItemScamLikelihood.high;
    } else if (suspicious.length >= 2) {
      likelihood = ItemScamLikelihood.medium;
    } else if (suspicious.isNotEmpty) {
      likelihood = ItemScamLikelihood.medium;
    }

    if (likelihood != ItemScamLikelihood.high) {
      final category = item.category.toLowerCase();
      final isHighValueCategory =
          category.contains('electronics') || category.contains('vehicles');
      if (isHighValueCategory && item.price > 0 && item.price < 50) {
        likelihood = ItemScamLikelihood.medium;
      }
    }

    Color badgeBg;
    Color badgeFg;
    switch (likelihood) {
      case ItemScamLikelihood.high:
        badgeBg = const Color(0xFFFEE2E2);
        badgeFg = const Color(0xFF991B1B);
        break;
      case ItemScamLikelihood.medium:
        badgeBg = const Color(0xFFFFF3CD);
        badgeFg = const Color(0xFF92400E);
        break;
      case ItemScamLikelihood.low:
        badgeBg = const Color(0xFFDCFCE7);
        badgeFg = const Color(0xFF166534);
        break;
      case ItemScamLikelihood.unknown:
        badgeBg = const Color(0xFFE5E7EB);
        badgeFg = const Color(0xFF374151);
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder or actual image
            Container(
              height: 96,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.images.isNotEmpty)
                    Image.file(
                      File(item.images[0]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        );
                      },
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  if (item.isClosed)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'CLOSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: badgeFg.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'AI: ${likelihood.label}',
                          style: TextStyle(
                            color: badgeFg,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Price
                    Text(
                      '\$${item.price.toStringAsFixed(0)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item.location,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                size: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${item.viewCount} views',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.timeAgo,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 9,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOwner)
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                  onPressed: onEdit,
                                  icon: const Icon(Icons.edit),
                                  color: theme.colorScheme.primary,
                                  tooltip: 'Edit',
                                  padding: EdgeInsets.zero,
                                  iconSize: 14,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 1),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                  onPressed: onToggleClosed,
                                  icon: Icon(
                                    item.isClosed
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  color: item.isClosed
                                      ? Colors.green
                                      : Colors.orange,
                                  tooltip: item.isClosed ? 'Reopen' : 'Close',
                                  padding: EdgeInsets.zero,
                                  iconSize: 14,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 1),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                  onPressed: onDelete,
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  tooltip: 'Delete',
                                  padding: EdgeInsets.zero,
                                  iconSize: 14,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
