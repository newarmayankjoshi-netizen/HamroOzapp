import 'package:flutter/material.dart';

import '../../auth_page.dart';
import 'owner_models.dart';
import 'owner_repository.dart';

class OwnerEditPage extends StatefulWidget {
  final OwnerRestaurantProfile initial;

  const OwnerEditPage({
    super.key,
    required this.initial,
  });

  @override
  State<OwnerEditPage> createState() => _OwnerEditPageState();
}

class _OwnerEditPageState extends State<OwnerEditPage> {
  late OwnerRestaurantProfile _profile;

  static const _auAddressExample = 'Shop 3/12 Example St, Harris Park NSW 2150';

  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _website;
  late final TextEditingController _story;
  late final TextEditingController _rating;
  late final TextEditingController _reviewsUrl;
  late final TextEditingController _reviewHighlights;
  late final TextEditingController _bookingUrl;
  late final TextEditingController _orderUrl;

  @override
  void initState() {
    super.initState();
    _profile = widget.initial;

    _name = TextEditingController(text: _profile.name);
    _address = TextEditingController(text: _profile.address);
    _phone = TextEditingController(text: _profile.phone);
    _website = TextEditingController(text: _profile.website);
    _story = TextEditingController(text: _profile.story);
    _rating = TextEditingController(
      text: _profile.rating == 0 ? '' : _profile.rating.toString(),
    );
    _reviewsUrl = TextEditingController(text: _profile.reviewsUrl);
    _reviewHighlights = TextEditingController(text: _profile.reviewHighlights);
    _bookingUrl = TextEditingController(text: _profile.bookingUrl);
    _orderUrl = TextEditingController(text: _profile.orderUrl);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _website.dispose();
    _story.dispose();
    _rating.dispose();
    _reviewsUrl.dispose();
    _reviewHighlights.dispose();
    _bookingUrl.dispose();
    _orderUrl.dispose();
    super.dispose();
  }

  double _parseRating(String raw) {
    final v = double.tryParse(raw.trim());
    if (v == null) return 0;
    if (v < 0) return 0;
    if (v > 5) return 5;
    return v;
  }

  String _normalizeSpaces(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _looksLikeAustralianAddress(String input) {
    final s = _normalizeSpaces(input);
    if (s.isEmpty) return false;
    if (!s.contains(',')) return false;

    // Expect trailing "STATE 4-digit postcode", e.g. "NSW 2150"
    final trailing = RegExp(
      r'\b(NSW|VIC|QLD|SA|WA|TAS|ACT|NT)\s+(\d{4})$'
      ,
      caseSensitive: false,
    );
    return trailing.hasMatch(s);
  }

  String _formatAustralianAddress(String input) {
    final s = _normalizeSpaces(input);
    final trailing = RegExp(
      r'\b(NSW|VIC|QLD|SA|WA|TAS|ACT|NT)\s+(\d{4})$'
      ,
      caseSensitive: false,
    );
    return s.replaceAllMapped(trailing, (m) {
      return '${m.group(1)!.toUpperCase()} ${m.group(2)}';
    });
  }

  Future<void> _save() async {
    final rawAddress = _address.text;
    if (!_looksLikeAustralianAddress(rawAddress)) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Use Australian address format'),
            content: const Text(
              'Please enter the address like this:\n\n'
              '$_auAddressExample\n\n'
              'Format: Street address, Suburb STATE 4-digit postcode',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final ownerId = (AuthState.currentUserEmail ?? '').trim().isNotEmpty
        ? AuthState.currentUserEmail!.trim().toLowerCase()
        : (AuthState.currentUserId ?? '');
    final updated = _profile.copyWith(
      ownerUserId: _profile.ownerUserId.isNotEmpty ? _profile.ownerUserId : ownerId,
      name: _name.text.trim(),
      address: _formatAustralianAddress(rawAddress),
      phone: _phone.text.trim(),
      website: _website.text.trim(),
      story: _story.text.trim(),
      rating: _parseRating(_rating.text),
      reviewsUrl: _reviewsUrl.text.trim(),
      reviewHighlights: _reviewHighlights.text.trim(),
      bookingUrl: _bookingUrl.text.trim(),
      orderUrl: _orderUrl.text.trim(),
    );

    await OwnerRestaurantRepository.instance.upsert(updated);

    if (!mounted) return;
    Navigator.pop(context, updated);
  }

  Future<void> _addOrEditMenuItem({OwnerMenuItem? existing}) async {
    final result = await showDialog<OwnerMenuItem?>(
      context: context,
      builder: (context) => _MenuItemDialog(existing: existing),
    );

    if (!mounted) return;
    if (result == null) return;

    setState(() {
      final menu = _profile.menu.toList();
      final idx = menu.indexWhere((m) => m.id == result.id);
      if (idx >= 0) {
        menu[idx] = result;
      } else {
        menu.add(result);
      }
      _profile = _profile.copyWith(menu: menu);
    });
  }

  Future<void> _deleteMenuItem(String id) async {
    setState(() {
      _profile = _profile.copyWith(
        menu: _profile.menu.where((m) => m.id != id).toList(),
      );
    });
  }

  Future<void> _addOrEditPromotion({OwnerPromotion? existing}) async {
    final result = await showDialog<OwnerPromotion?>(
      context: context,
      builder: (context) => _PromotionDialog(existing: existing),
    );

    if (!mounted) return;
    if (result == null) return;

    setState(() {
      final promos = _profile.promotions.toList();
      final idx = promos.indexWhere((p) => p.id == result.id);
      if (idx >= 0) {
        promos[idx] = result;
      } else {
        promos.add(result);
      }
      _profile = _profile.copyWith(promotions: promos);
    });
  }

  Future<void> _deletePromotion(String id) async {
    setState(() {
      _profile = _profile.copyWith(
        promotions: _profile.promotions.where((p) => p.id != id).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Restaurant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Text(
              'Mini-marketing platform',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Restaurant name',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Address (Australia format)',
                hintText: _auAddressExample,
                helperText: 'Street address, Suburb STATE Postcode (e.g. NSW 2150)',
              ),
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                hintText: '+61...',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _website,
              decoration: const InputDecoration(
                labelText: 'Website (optional)',
                hintText: 'https://',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _rating,
              decoration: const InputDecoration(
                labelText: 'Rating (optional)',
                hintText: '0-5',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reviewsUrl,
              decoration: const InputDecoration(
                labelText: 'Reviews link (optional)',
                hintText: 'Google Maps / Facebook reviews URL',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reviewHighlights,
              decoration: const InputDecoration(
                labelText: 'Review highlights (optional)',
                hintText: 'Paste a few short quotes (one per line)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _story,
              decoration: const InputDecoration(
                labelText: 'Story / Chef intro (optional)',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Menu',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addOrEditMenuItem(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_profile.menu.isEmpty)
              const Text(
                'No items yet. Add your menu items with photos, price, and availability.',
                style: TextStyle(color: Color(0xFF6B7280)),
              )
            else
              ..._profile.menu.map(
                (m) => Card(
                  child: ListTile(
                    title: Text(m.name.isEmpty ? 'Unnamed item' : m.name),
                    subtitle: Text(
                      'AUD ${m.price.toStringAsFixed(2)} • ${m.available ? 'Available' : 'Sold out'}${m.isDailySpecial ? ' • Daily special' : ''}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          _addOrEditMenuItem(existing: m);
                        } else if (v == 'delete') {
                          _deleteMenuItem(m.id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Promotions / Events',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addOrEditPromotion(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_profile.promotions.isEmpty)
              const Text(
                'No promotions yet. Add specials, events, or deals to boost visibility.',
                style: TextStyle(color: Color(0xFF6B7280)),
              )
            else
              ..._profile.promotions.map(
                (p) => Card(
                  child: ListTile(
                    title: Text(p.title.isEmpty ? 'Untitled promotion' : p.title),
                    subtitle: Text(
                      [p.details, if (p.validUntil.isNotEmpty) 'Valid until: ${p.validUntil}']
                          .where((e) => e.trim().isNotEmpty)
                          .join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          _addOrEditPromotion(existing: p);
                        } else if (v == 'delete') {
                          _deletePromotion(p.id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              'Bookings / Ordering',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bookingUrl,
              decoration: const InputDecoration(
                labelText: 'Booking link (optional)',
                hintText: 'https://… (Table reservations)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _orderUrl,
              decoration: const InputDecoration(
                labelText: 'Order link (optional)',
                hintText: 'Uber Eats / DoorDash / pickup URL',
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Loyalty & retention',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _LoyaltyEditor(
              loyalty: _profile.loyalty,
              onChanged: (l) {
                setState(() {
                  _profile = _profile.copyWith(loyalty: l);
                });
              },
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _save,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemDialog extends StatefulWidget {
  final OwnerMenuItem? existing;

  const _MenuItemDialog({this.existing});

  @override
  State<_MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<_MenuItemDialog> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _photoUrl;
  late bool _available;
  late bool _special;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _desc = TextEditingController(text: widget.existing?.description ?? '');
    _price = TextEditingController(
      text: widget.existing == null ? '' : widget.existing!.price.toString(),
    );
    _photoUrl = TextEditingController(text: widget.existing?.photoUrl ?? '');
    _available = widget.existing?.available ?? true;
    _special = widget.existing?.isDailySpecial ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return AlertDialog(
      title: Text(existing == null ? 'Add menu item' : 'Edit menu item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (AUD)'),
            ),
            TextField(
              controller: _photoUrl,
              decoration: const InputDecoration(labelText: 'Photo URL (optional)'),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _available,
              onChanged: (v) => setState(() {
                _available = v ?? true;
              }),
              title: const Text('Available'),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _special,
              onChanged: (v) => setState(() {
                _special = v ?? false;
              }),
              title: const Text('Daily special'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final p = double.tryParse(_price.text.trim()) ?? 0;
            final item = OwnerMenuItem(
              id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
              name: _name.text.trim(),
              description: _desc.text.trim(),
              price: p,
              photoUrl: _photoUrl.text.trim(),
              available: _available,
              isDailySpecial: _special,
            );
            Navigator.pop(context, item);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PromotionDialog extends StatefulWidget {
  final OwnerPromotion? existing;

  const _PromotionDialog({this.existing});

  @override
  State<_PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<_PromotionDialog> {
  late final TextEditingController _title;
  late final TextEditingController _details;
  late final TextEditingController _until;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _details = TextEditingController(text: widget.existing?.details ?? '');
    _until = TextEditingController(text: widget.existing?.validUntil ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    _until.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return AlertDialog(
      title: Text(existing == null ? 'Add promotion' : 'Edit promotion'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _details,
              decoration: const InputDecoration(labelText: 'Details'),
              maxLines: 3,
            ),
            TextField(
              controller: _until,
              decoration: const InputDecoration(
                labelText: 'Valid until (optional)',
                hintText: 'e.g. 28 Feb 2026',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final promo = OwnerPromotion(
              id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
              title: _title.text.trim(),
              details: _details.text.trim(),
              validUntil: _until.text.trim(),
            );
            Navigator.pop(context, promo);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _LoyaltyEditor extends StatefulWidget {
  final OwnerLoyaltyConfig loyalty;
  final ValueChanged<OwnerLoyaltyConfig> onChanged;

  const _LoyaltyEditor({
    required this.loyalty,
    required this.onChanged,
  });

  @override
  State<_LoyaltyEditor> createState() => _LoyaltyEditorState();
}

class _LoyaltyEditorState extends State<_LoyaltyEditor> {
  late final TextEditingController _stamps;
  late final TextEditingController _reward;
  late final TextEditingController _message;

  @override
  void initState() {
    super.initState();
    _stamps = TextEditingController(text: widget.loyalty.stampsNeeded.toString());
    _reward = TextEditingController(text: widget.loyalty.reward);
    _message = TextEditingController(text: widget.loyalty.comebackMessage);
  }

  @override
  void dispose() {
    _stamps.dispose();
    _reward.dispose();
    _message.dispose();
    super.dispose();
  }

  void _emit() {
    final stamps = int.tryParse(_stamps.text.trim()) ?? widget.loyalty.stampsNeeded;
    widget.onChanged(
      widget.loyalty.copyWith(
        stampsNeeded: stamps <= 1 ? 1 : stamps,
        reward: _reward.text.trim(),
        comebackMessage: _message.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _stamps,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stamps needed',
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _reward,
          decoration: const InputDecoration(
            labelText: 'Reward',
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _message,
          decoration: const InputDecoration(
            labelText: 'Come back message',
          ),
          maxLines: 2,
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
