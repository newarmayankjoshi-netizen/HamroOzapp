import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import 'add_item_page.dart';
import 'marketplace_page.dart';
import 'message_thread_page.dart';
import 'auth_page.dart';
import 'profile_page.dart';
import 'services/security_service.dart';
import 'services/bookmark_service.dart';
import 'bookmarks_page.dart';

enum ItemScamLikelihood { high, medium, low, unknown }

extension ItemScamLikelihoodLabel on ItemScamLikelihood {
  String get label {
    switch (this) {
      case ItemScamLikelihood.high:
        return 'High risk';
      case ItemScamLikelihood.medium:
        return 'Medium risk';
      case ItemScamLikelihood.low:
        return 'Low risk';
      case ItemScamLikelihood.unknown:
        return 'Unknown';
    }
  }
}

class ItemSafetyAnalysis {
  final ItemScamLikelihood likelihood;
  final List<String> prohibitedTerms;
  final List<String> suspiciousPhrases;

  const ItemSafetyAnalysis({
    required this.likelihood,
    required this.prohibitedTerms,
    required this.suspiciousPhrases,
  });
}

class ItemDetailPage extends StatefulWidget {
  final MarketplaceItem item;

  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final SecurityService securityService = SecurityService();

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

  static const List<String> _suspiciousPhrases = [
    'verification code',
    'otp',
    'urgent',
    'kindly',
    'click link',
    'telegram',
    'whatsapp',
  ];

  late MarketplaceItem _item;
  Future<ItemSafetyAnalysis>? _safetyAnalysisFuture;
  bool _isBookmarked = false;

  static bool _isRemoteUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  Future<void> _reloadItem() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('marketplace_items')
          .doc(_item.id)
          .get();

      if (!doc.exists) return;
      final data = doc.data();
      if (data == null || !mounted) return;

      final posted = data['postedDate'] is Timestamp
          ? (data['postedDate'] as Timestamp).toDate()
          : _item.postedDate;
      final priceValue = data['price'];
      final price = priceValue is num ? priceValue.toDouble() : _item.price;
      final imagesDynamic = data['images'];
      final images = imagesDynamic is List
          ? imagesDynamic.whereType<String>().toList()
          : _item.images;
      final viewCountValue = data['viewCount'];
      final viewCount = viewCountValue is num
          ? viewCountValue.toInt()
          : _item.viewCount;
      final isClosedValue = data['isClosed'];
      final isClosed = isClosedValue is bool ? isClosedValue : _item.isClosed;
      final closedReason = data['closedReason'] is String
          ? (data['closedReason'] as String)
          : _item.closedReason;
      final closedAtValue = data['closedAt'];
      final closedAt = closedAtValue is Timestamp
          ? closedAtValue.toDate()
          : _item.closedAt;

      setState(() {
        _item = _item.copyWith(
          title: (data['title'] ?? _item.title) as String,
          description: (data['description'] ?? _item.description) as String,
          price: price,
          category: (data['category'] ?? _item.category) as String,
          condition: (data['condition'] ?? _item.condition) as String,
          location: (data['location'] ?? _item.location) as String,
          postedDate: posted,
          images: images,
          viewCount: viewCount,
          isClosed: isClosed,
          closedReason: closedReason,
          closedAt: closedAt,
        );
      });
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<void> _setClosed(bool isClosed, {String reason = ''}) async {
    if (!isClosed) {
      await FirebaseFirestore.instance
          .collection('marketplace_items')
          .doc(_item.id)
          .update({
            'isClosed': false,
            'closedReason': FieldValue.delete(),
            'closedAt': FieldValue.delete(),
            'reopenedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      setState(() {
        _item = _item.copyWith(
          isClosed: false,
          closedReason: null,
          closedAt: null,
        );
      });
      return;
    }

    await FirebaseFirestore.instance
        .collection('marketplace_items')
        .doc(_item.id)
        .update({
          'isClosed': true,
          'closedReason': reason,
          'closedAt': FieldValue.serverTimestamp(),
        });

    if (!mounted) return;
    setState(() {
      _item = _item.copyWith(
        isClosed: true,
        closedReason: reason,
        closedAt: DateTime.now(),
      );
    });
  }

  Future<void> _deleteListing() async {
    for (final imageUrl in _item.images) {
      if (imageUrl.startsWith('http')) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (_) {
          // Ignore failures.
        }
      }
    }
    await FirebaseFirestore.instance
        .collection('marketplace_items')
        .doc(_item.id)
        .delete();
  }

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _safetyAnalysisFuture = _analyzeItem();
    Future.microtask(() async {
      final uid = AuthState.currentUserId;
      if (uid != null) {
        final b = await BookmarkService.isBookmarked(uid, 'marketplace_items', _item.id);
        if (!mounted) return;
        setState(() => _isBookmarked = b);
      }
    });
  }

  Future<ItemSafetyAnalysis> _analyzeItem() async {
    final combined =
        '${_item.title}\n${_item.description}\n${_item.category}\n${_item.condition}\n${_item.location}';
    final prohibited = securityService.findProhibitedTerms(combined);

    final lower = combined.toLowerCase();
    final suspicious =
        _suspiciousPhrases
            .where((p) => lower.contains(p))
            .toSet()
            .toList(growable: false)
          ..sort();

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

    // Extra signal: unusually low price for certain categories.
    if (likelihood != ItemScamLikelihood.high) {
      final category = _item.category.toLowerCase();
      final isHighValueCategory =
          category.contains('electronics') || category.contains('vehicles');
      if (isHighValueCategory && _item.price > 0 && _item.price < 50) {
        likelihood = ItemScamLikelihood.medium;
      }
    }

    return ItemSafetyAnalysis(
      likelihood: likelihood,
      prohibitedTerms: prohibited,
      suspiciousPhrases: suspicious,
    );
  }

  void _openAiSafetyDetails(ItemSafetyAnalysis analysis) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ItemSafetyCheckDetailPage(item: _item, analysis: analysis),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewerUserId = AuthState.currentUserId;
    final isMyItem = viewerUserId != null && _item.sellerId == viewerUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            tooltip: _isBookmarked ? 'Remove bookmark' : 'Bookmark',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final user = FirebaseAuth.instance.currentUser;
              developer.log('BookmarkDebug: currentUser uid=${user?.uid} email=${user?.email}', name: 'BookmarkDebug');
              developer.log('BookmarkDebug: projectId=${Firebase.app().options.projectId}', name: 'BookmarkDebug');
              if (user == null) {
                if (!mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('Please sign in to bookmark items.')));
                return;
              }
              final uid = user.uid;
              final previous = _isBookmarked;
              setState(() => _isBookmarked = !previous);
              try {
                final ok = await BookmarkService.toggleBookmark(uid, 'marketplace_items', _item.id, title: _item.title);
                if (!mounted) return;
                if (!ok) {
                  setState(() => _isBookmarked = previous);
                  messenger.showSnackBar(const SnackBar(content: Text('Bookmark failed')));
                }
              } catch (e) {
                if (!mounted) return;
                setState(() => _isBookmarked = previous);
                messenger.showSnackBar(SnackBar(content: Text('Bookmark failed: $e')));
              }
            },
          ),
          if (isMyItem)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddItemPage(initialItem: _item),
                  ),
                ).then((_) {
                  _reloadItem();
                });
              },
            ),
          if (isMyItem)
            IconButton(
              icon: Icon(
                _item.isClosed ? Icons.visibility : Icons.visibility_off,
              ),
              tooltip: _item.isClosed ? 'Reopen listing' : 'Close listing',
              onPressed: () {
                if (_item.isClosed) {
                  _setClosed(false).then((_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Listing reopened')),
                    );
                  });
                  return;
                }

                _promptCloseReason(context).then((reason) {
                  if (reason == null) return;
                  _setClosed(true, reason: reason).then((_) {
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
              },
            ),
          if (isMyItem)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(context),
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'view_bookmarks') {
                if (!context.mounted) return;
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksPage()));
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'view_bookmarks', child: Text('View Bookmarks')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery
            Container(
              height: 300,
              color: theme.colorScheme.primaryContainer,
              child: _item.images.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 100,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    )
                  : PageView.builder(
                      itemCount: _item.images.length,
                      itemBuilder: (context, index) {
                        final value = _item.images[index];
                        if (_isRemoteUrl(value)) {
                          return Image.network(
                            value,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: theme.colorScheme.primary.withValues(alpha: 
                                    0.5,
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        return Image.file(
                          File(value),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: theme.colorScheme.primary.withValues(alpha: 
                                  0.5,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Text(
                    '\$${_item.price.toStringAsFixed(0)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    _item.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.category_outlined,
                            label: 'Category',
                            value: _item.category,
                          ),
                          const Divider(height: 24),
                          _DetailRow(
                            icon: Icons.verified_outlined,
                            label: 'Condition',
                            value: _item.condition,
                          ),
                          const Divider(height: 24),
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: _item.location,
                          ),
                          const Divider(height: 24),
                          _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Posted',
                            value: _item.timeAgo,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _item.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  InkWell(
                    onTap: () async {
                      final analysis =
                          await (_safetyAnalysisFuture ?? _analyzeItem());
                      if (!context.mounted) return;
                      _openAiSafetyDetails(analysis);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FutureBuilder<ItemSafetyAnalysis>(
                          future: _safetyAnalysisFuture,
                          builder: (context, snapshot) {
                            final analysis = snapshot.data;
                            ItemScamLikelihood likelihood =
                                ItemScamLikelihood.unknown;
                            String subtitle = 'Tap to view details';
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              subtitle = 'Checking listing… (tap for details)';
                            } else if (snapshot.hasError) {
                              subtitle =
                                  'Could not run AI check (tap for safety tips)';
                            } else if (analysis != null) {
                              likelihood = analysis.likelihood;
                              subtitle = 'Tap to view red flags and advice';
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

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.shield_outlined, color: badgeFg),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Safety Check',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: badgeFg.withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Text(
                                          'AI Safety Check: ${likelihood.label}',
                                          style: TextStyle(
                                            color: badgeFg,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        subtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: const Color(0xFF374151),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: badgeFg),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Seller Info Card
                  if (!isMyItem) ...[
                    Text(
                      'Seller Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfilePage(
                                profileUserId: _item.sellerId,
                                displayNameOverride: _item.sellerName,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _item.sellerName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'View profile',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF6B7280),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMyItem
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => _contactSeller(context, 'message'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Message'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _contactSeller(context, 'call'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call, size: 20),
                            SizedBox(width: 8),
                            Text('Call Seller'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _contactSeller(BuildContext context, String method) {
    if (method == 'call') {
      _makeCall(context);
    } else if (method == 'message') {
      _openMessaging(context);
    }
  }

  Future<void> _makeCall(BuildContext context) async {
    if (_item.sellerPhone == null || _item.sellerPhone!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seller phone number not available'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final phoneNumber = _item.sellerPhone!.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone call'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openMessaging(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MessageThreadPage(item: _item)),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text(
          'Are you sure you want to delete this listing? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteListing().then((_) {
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listing deleted')),
                );
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class ItemSafetyCheckDetailPage extends StatelessWidget {
  final MarketplaceItem item;
  final ItemSafetyAnalysis analysis;

  const ItemSafetyCheckDetailPage({
    super.key,
    required this.item,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Future<void> openScamwatchReport() async {
      final Uri url = Uri.parse('https://www.scamwatch.gov.au/report-a-scam');
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Scamwatch website')),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Scamwatch website')),
          );
        }
      }
    }

    Color headerBg;
    Color headerFg;
    switch (analysis.likelihood) {
      case ItemScamLikelihood.high:
        headerBg = const Color(0xFFFEE2E2);
        headerFg = const Color(0xFF991B1B);
        break;
      case ItemScamLikelihood.medium:
        headerBg = const Color(0xFFFFF3CD);
        headerFg = const Color(0xFF92400E);
        break;
      case ItemScamLikelihood.low:
        headerBg = const Color(0xFFDCFCE7);
        headerFg = const Color(0xFF166534);
        break;
      case ItemScamLikelihood.unknown:
        headerBg = const Color(0xFFE5E7EB);
        headerFg = const Color(0xFF374151);
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI Safety Check')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: headerBg,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: headerFg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            analysis.likelihood.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: headerFg,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This check looks for common scam signals in the item title/description. Always verify in person when possible.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: headerFg,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Listing',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Signals found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (analysis.prohibitedTerms.isEmpty &&
                        analysis.suspiciousPhrases.isEmpty)
                      Text(
                        'No common scam phrases detected.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    if (analysis.prohibitedTerms.isNotEmpty) ...[
                      Text(
                        'High-risk terms',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: analysis.prohibitedTerms
                            .map(
                              (t) => Chip(
                                label: Text(t),
                                backgroundColor: const Color(0xFFFEE2E2),
                                side: const BorderSide(
                                  color: Color(0xFFFCA5A5),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (analysis.suspiciousPhrases.isNotEmpty) ...[
                      Text(
                        'Suspicious phrases',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: analysis.suspiciousPhrases
                            .map((t) => Chip(label: Text(t)))
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Safety tips',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Bullet('Meet in a public place and inspect the item.'),
                    _Bullet('Avoid gift cards, crypto, or wire transfers.'),
                    _Bullet('Never share OTP/verification codes.'),
                    _Bullet('If pressured to pay a deposit, be cautious.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFFF3F4F6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.report_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'If you suspect a scam, report it to Scamwatch (ACCC).',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: openScamwatchReport,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Scamwatch'),
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

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
