import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import 'auth_page.dart';
import 'utils/user_prefill_helper.dart';
import 'package:hamro_oz/utils/map_utils.dart';
import 'services/verification_service.dart';
import 'services/admin_log_service.dart';
import 'services/bookmark_service.dart';
import 'bookmarks_page.dart';

class Event {
  final String id;
  final String title;
  final String eventType;
  final DateTime date;
  final String time;
  final String location;
  final String address;
  final String suburb;
  final String state;
  final String postcode;
  final String description;
  final String organizerName;
  final String organizerPhone;
  final String organizerEmail;
  final String imageUrl;
  final List<String> imagePaths;
  final int viewCount;
  final int attendeeCount;
  final bool requiresRSVP;
  final String createdBy;
  final DateTime postedDate;
  final bool isClosed;

  Event({
    required this.id,
    required this.title,
    required this.eventType,
    required this.date,
    required this.time,
    required this.location,
    required this.address,
    required this.suburb,
    required this.state,
    required this.postcode,
    required this.description,
    required this.organizerName,
    required this.organizerPhone,
    required this.organizerEmail,
    required this.imageUrl,
    required this.imagePaths,
    required this.viewCount,
    required this.attendeeCount,
    required this.requiresRSVP,
    required this.createdBy,
    required this.postedDate,
    required this.isClosed,
  });

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      title: map['title'] ?? '',
      eventType: map['eventType'] ?? '',
      date: (map['date'] is Timestamp) ? (map['date'] as Timestamp).toDate() : (map['date'] as DateTime? ?? DateTime.now()),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      address: map['address'] ?? '',
      suburb: map['suburb'] ?? '',
      state: map['state'] ?? '',
      postcode: map['postcode'] ?? '',
      description: map['description'] ?? '',
      organizerName: map['organizerName'] ?? '',
      organizerPhone: map['organizerPhone'] ?? '',
      organizerEmail: map['organizerEmail'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      imagePaths: List<String>.from(map['imagePaths'] ?? []),
      viewCount: map['viewCount'] ?? 0,
      attendeeCount: map['attendeeCount'] ?? 0,
      requiresRSVP: map['requiresRSVP'] ?? false,
      createdBy: map['createdBy'] ?? '',
      postedDate: (map['postedDate'] is Timestamp) ? (map['postedDate'] as Timestamp).toDate() : (map['postedDate'] as DateTime? ?? DateTime.now()),
      isClosed: map['isClosed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'eventType': eventType,
      'date': Timestamp.fromDate(date),
      'time': time,
      'location': location,
      'address': address,
      'suburb': suburb,
      'state': state,
      'postcode': postcode,
      'description': description,
      'organizerName': organizerName,
      'organizerPhone': organizerPhone,
      'organizerEmail': organizerEmail,
      'imageUrl': imageUrl,
      'imagePaths': imagePaths,
      'viewCount': viewCount,
      'attendeeCount': attendeeCount,
      'requiresRSVP': requiresRSVP,
      'createdBy': createdBy,
      'postedDate': Timestamp.fromDate(postedDate),
      'isClosed': isClosed,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? eventType,
    DateTime? date,
    String? time,
    String? location,
    String? address,
    String? suburb,
    String? state,
    String? postcode,
    String? description,
    String? organizerName,
    String? organizerPhone,
    String? organizerEmail,
    String? imageUrl,
    List<String>? imagePaths,
    int? viewCount,
    int? attendeeCount,
    bool? requiresRSVP,
    String? createdBy,
    DateTime? postedDate,
    bool? isClosed,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      address: address ?? this.address,
      suburb: suburb ?? this.suburb,
      state: state ?? this.state,
      postcode: postcode ?? this.postcode,
      description: description ?? this.description,
      organizerName: organizerName ?? this.organizerName,
      organizerPhone: organizerPhone ?? this.organizerPhone,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePaths: imagePaths ?? this.imagePaths,
      viewCount: viewCount ?? this.viewCount,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      requiresRSVP: requiresRSVP ?? this.requiresRSVP,
      createdBy: createdBy ?? this.createdBy,
      postedDate: postedDate ?? this.postedDate,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

class EditEventPage extends StatefulWidget {
  final Event event;

  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _addressController;
  late TextEditingController _suburbController;
  late TextEditingController _postcodeController;
  late TextEditingController _organizerNameController;
  late TextEditingController _organizerPhoneController;
  late TextEditingController _organizerEmailController;

  late String _selectedState;
  late String _selectedEventType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _requiresRSVP;
  bool _isLoading = false;

  final List<String> _states = ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT'];
  final List<String> _eventTypes = ['Social', 'Cultural', 'Religious', 'Educational', 'Sports', 'Other'];
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleController = TextEditingController(text: e.title);
    _descriptionController = TextEditingController(text: e.description);
    _locationController = TextEditingController(text: e.location);
    _addressController = TextEditingController(text: e.address);
    _suburbController = TextEditingController(text: e.suburb);
    _postcodeController = TextEditingController(text: e.postcode);
    _organizerNameController = TextEditingController(text: e.organizerName);
    _organizerPhoneController = TextEditingController(text: e.organizerPhone);
    _organizerEmailController = TextEditingController(text: e.organizerEmail);

    _selectedState = e.state.isNotEmpty ? e.state : 'NSW';
    _selectedEventType = e.eventType.isNotEmpty ? e.eventType : _eventTypes.first;
    _selectedDate = e.date;
    _selectedTime = TimeOfDay(hour: int.tryParse(e.time.split(':').first) ?? 0, minute: int.tryParse(e.time.split(':').last) ?? 0);
    _requiresRSVP = e.requiresRSVP;
    _selectedImages = [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _suburbController.dispose();
    _postcodeController.dispose();
    _organizerNameController.dispose();
    _organizerPhoneController.dispose();
    _organizerEmailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // If user selected new images, upload them and set image paths.
      List<String>? uploadedPaths;
      String? uploadedCover;
      if (_selectedImages.isNotEmpty) {
        final storage = FirebaseStorage.instance;
        final List<String> urls = [];
        for (var i = 0; i < _selectedImages.length; i++) {
          final file = File(_selectedImages[i].path);
          final ref = storage.ref().child('community_events').child(widget.event.id).child('images').child('$i');
          await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
          final url = await ref.getDownloadURL();
          urls.add(url);
        }
        if (urls.isNotEmpty) {
          uploadedPaths = urls;
          uploadedCover = urls.first;
        }
      }

      final updated = widget.event.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        address: _addressController.text.trim(),
        suburb: _suburbController.text.trim(),
        postcode: _postcodeController.text.trim(),
        organizerName: _organizerNameController.text.trim(),
        organizerPhone: _organizerPhoneController.text.trim(),
        organizerEmail: _organizerEmailController.text.trim(),
        eventType: _selectedEventType,
        state: _selectedState,
        date: _selectedDate,
        time: '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        requiresRSVP: _requiresRSVP,
        imageUrl: uploadedCover ?? widget.event.imageUrl,
        imagePaths: uploadedPaths ?? widget.event.imagePaths,
      );

      await FirebaseFirestore.instance.collection('community_events').doc(updated.id).update(updated.toMap());

      // Telemetry: log the edit
      try {
        final actor = AuthState.currentUserId ?? 'unknown';
        await AdminLogService.logAction(actorId: actor, action: 'edit_event', targetType: 'community_events', targetId: updated.id, metadata: {'title': updated.title});
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update event: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event'), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Event Title *'), validator: (v) => v == null || v.isEmpty ? 'Please enter title' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: _selectedEventType, items: _eventTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _selectedEventType = v!)),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: InkWell(onTap: () => _selectDate(context), child: InputDecorator(decoration: const InputDecoration(labelText: 'Date'), child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}')))), const SizedBox(width: 12), Expanded(child: InkWell(onTap: () => _selectTime(context), child: InputDecorator(decoration: const InputDecoration(labelText: 'Time'), child: Text('${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}'))))]),
            const SizedBox(height: 12),
            TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Venue Name *'), validator: (v) => v == null || v.isEmpty ? 'Please enter venue' : null),
            const SizedBox(height: 12),

            // Images
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Images (optional)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (_selectedImages.isNotEmpty) ...[
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_selectedImages.first.path), height: 140, width: double.infinity, fit: BoxFit.cover)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(onPressed: () async { final photos = await _imagePicker.pickMultiImage(); if (!mounted) return; if (photos.isNotEmpty) setState(() => _selectedImages = photos); }, icon: const Icon(Icons.photo_library_outlined), label: const Text('Change'))),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(onPressed: () { setState(() => _selectedImages.clear()); }, icon: const Icon(Icons.delete_outline), label: const Text('Remove')),
                    ]),
                  ] else if (widget.event.imageUrl.isNotEmpty) ...[
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(widget.event.imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(onPressed: () async { final photos = await _imagePicker.pickMultiImage(); if (!mounted) return; if (photos.isNotEmpty) setState(() => _selectedImages = photos); }, icon: const Icon(Icons.photo_library_outlined), label: const Text('Change'))),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(onPressed: () { setState(() { _selectedImages = []; }); }, icon: const Icon(Icons.delete_outline), label: const Text('Remove')),
                    ]),
                  ] else ...[
                    OutlinedButton.icon(onPressed: () async { final photos = await _imagePicker.pickMultiImage(); if (!mounted) return; if (photos.isNotEmpty) setState(() => _selectedImages = photos); }, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Add photo')),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Street Address *'), validator: (v) => v == null || v.isEmpty ? 'Please enter address' : null),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: TextFormField(controller: _suburbController, decoration: const InputDecoration(labelText: 'Suburb *'), validator: (v) => v == null || v.isEmpty ? 'Please enter suburb' : null)), const SizedBox(width: 12), SizedBox(width: 120, child: DropdownButtonFormField<String>(initialValue: _selectedState, items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _selectedState = v!))) ]),
            const SizedBox(height: 12),
            TextFormField(controller: _postcodeController, decoration: const InputDecoration(labelText: 'Postcode *'), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Please enter postcode' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description *'), maxLines: 4, validator: (v) => v == null || v.isEmpty ? 'Please enter description' : null),
            const SizedBox(height: 12),
            const Text('Organizer Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(controller: _organizerNameController, decoration: const InputDecoration(labelText: 'Organizer Name *'), validator: (v) => v == null || v.isEmpty ? 'Please enter organizer name' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _organizerPhoneController, decoration: const InputDecoration(labelText: 'Contact Phone'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextFormField(controller: _organizerEmailController, decoration: const InputDecoration(labelText: 'Contact Email *'), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'Please enter valid email' : null),
            const SizedBox(height: 12),
            CheckboxListTile(title: const Text('Require RSVP'), value: _requiresRSVP, onChanged: (v) => setState(() => _requiresRSVP = v ?? false), contentPadding: EdgeInsets.zero),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _isLoading ? null : _submitForm, child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes')))),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// Page to show events created by a specific user.
class EventsByUserPage extends StatefulWidget {
  final String filterUserId;
  final String? titleOverride;

  const EventsByUserPage({super.key, required this.filterUserId, this.titleOverride});

  @override
  State<EventsByUserPage> createState() => _EventsByUserPageState();
}

class _EventsByUserPageState extends State<EventsByUserPage> {
  final Set<String> _optimisticRemoved = <String>{};

  @override
  Widget build(BuildContext context) {
    final title = widget.titleOverride ?? 'Events';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Avoid server-side ordering to prevent requiring a composite index.
        stream: FirebaseFirestore.instance
          .collection('community_events')
          .where('createdBy', isEqualTo: widget.filterUserId)
          .where('isClosed', isEqualTo: false)
          .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading events: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Sort events client-side by postedDate (most recent first)
          final docs = (snapshot.data?.docs ?? []).where((d) => !_optimisticRemoved.contains(d.id)).toList();
          docs.sort((a, b) {
            final aDate = toStringKeyMap(a.data())['postedDate'];
            final bDate = toStringKeyMap(b.data())['postedDate'];
            DateTime da = aDate is Timestamp ? aDate.toDate() : (aDate as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0));
            DateTime db = bDate is Timestamp ? bDate.toDate() : (bDate as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0));
            return db.compareTo(da);
          });
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No events posted by this user', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final event = Event.fromMap(toStringKeyMap(doc.data()), doc.id);
              final viewerId = AuthState.currentUserId;
              final isOwner = viewerId != null && viewerId == event.createdBy;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: event.imageUrl.isNotEmpty
                      ? Image.network(event.imageUrl, width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.event, size: 40),
                  title: Text(event.title),
                  subtitle: Text('${event.suburb}, ${event.state} • ${event.date.toLocal().toIso8601String().split('T').first}'),
                  onTap: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: event, currentUserId: AuthState.currentUserId)));
                    if (result is EventDetailResult) {
                      // handled by stream updates
                    }
                  },
                  trailing: isOwner
                      ? PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'bookmarks') {
                              if (!context.mounted) return;
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksPage()));
                              return;
                            }
                            if (v == 'edit') {
                              final updated = await Navigator.push<Event?>(
                                context,
                                MaterialPageRoute(builder: (_) => EditEventPage(event: event)),
                              );
                              if (updated != null) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event updated')));
                              }
                            } else if (v == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Event'),
                                  content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              try {
                                final current = AuthState.currentUserId ?? 'guest';
                                final allowed = await VerificationService.canPost(current);
                                if (!allowed) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only verified contributors may delete events.'), backgroundColor: Colors.red));
                                  return;
                                }
                                await FirebaseFirestore.instance.collection('community_events').doc(event.id).delete();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete event: $e')));
                              }
                            }
                          },
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(value: 'bookmarks', child: Text('Bookmarks')),
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FindEventsByStatePage extends StatelessWidget {
  const FindEventsByStatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final states = [
      {
        'name': 'New South Wales',
        'abbr': 'NSW',
        'icon': Icons.location_city,
        'color': const Color(0xFF2193b0),
      },
      {
        'name': 'Victoria',
        'abbr': 'VIC',
        'icon': Icons.location_city,
        'color': const Color(0xFF6dd5ed),
      },
      {
        'name': 'Queensland',
        'abbr': 'QLD',
        'icon': Icons.beach_access,
        'color': const Color(0xFFf093fb),
      },
      {
        'name': 'Western Australia',
        'abbr': 'WA',
        'icon': Icons.landscape,
        'color': const Color(0xFF4facfe),
      },
      {
        'name': 'South Australia',
        'abbr': 'SA',
        'icon': Icons.wb_sunny,
        'color': const Color(0xFF43e97b),
      },
      {
        'name': 'Tasmania',
        'abbr': 'TAS',
        'icon': Icons.forest,
        'color': const Color(0xFFfa709a),
      },
      {
        'name': 'Australian Capital Territory',
        'abbr': 'ACT',
        'icon': Icons.account_balance,
        'color': const Color(0xFFfee140),
      },
      {
        'name': 'Northern Territory',
        'abbr': 'NT',
        'icon': Icons.landscape,
        'color': const Color(0xFFf093fb),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Events'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: AuthState.isLoggedIn
          ? FutureBuilder<bool>(
              future: VerificationService.canPost(AuthState.currentUserId ?? 'guest'),
              builder: (ctx, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final allowed = snap.data == true;
                if (!allowed) {
                  return FloatingActionButton.extended(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Only verified contributors can post events.')),
                      );
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Post event'),
                  );
                }
                return FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateEventPage()),
                    );
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Post event'),
                );
              },
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Find Events by State',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse Nepalese community events happening across Australia',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ...states.map((state) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventsListPage(state: state['name'] as String),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: state['color'] as Color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          state['icon'] as IconData,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state['name'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'View community events in ${state['abbr']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Community Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with the Nepalese community across Australia. Find cultural events, festivals, meetups, and community gatherings in your area.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventsListPage extends StatefulWidget {
  final String state;

  const EventsListPage({super.key, required this.state});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  final Set<String> _optimisticRemoved = <String>{};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events in ${widget.state}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Accept events stored with either the state abbreviation (e.g. 'ACT')
        // or the full state name (e.g. 'Australian Capital Territory').
        stream: (() {
          final abbrToFull = {
            'NSW': 'New South Wales',
            'VIC': 'Victoria',
            'QLD': 'Queensland',
            'WA': 'Western Australia',
            'SA': 'South Australia',
            'TAS': 'Tasmania',
            'ACT': 'Australian Capital Territory',
            'NT': 'Northern Territory',
          };

          final stateKey = widget.state;
          final variants = <String>{stateKey};
          if (abbrToFull.containsKey(stateKey)) {
            variants.add(abbrToFull[stateKey]!);
          } else if (abbrToFull.containsValue(stateKey)) {
            // add the abbreviation if a full name was passed
            final abbr = abbrToFull.entries.firstWhere((e) => e.value == stateKey).key;
            variants.add(abbr);
          }

          final coll = FirebaseFirestore.instance.collection('community_events');
          if (variants.length == 1) {
            return coll.where('state', isEqualTo: stateKey).where('isClosed', isEqualTo: false).snapshots();
          }

          return coll.where('state', whereIn: variants.toList()).where('isClosed', isEqualTo: false).snapshots();
        })(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading events: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final events = (snapshot.data?.docs ?? []).where((d) => !_optimisticRemoved.contains(d.id)).toList();

          // Sort events by date in ascending order (earliest first)
          events.sort((a, b) {
            final eventA = Event.fromMap(toStringKeyMap(a.data()), a.id);
            final eventB = Event.fromMap(toStringKeyMap(b.data()), b.id);
            return eventA.date.compareTo(eventB.date);
          });

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events found in ${widget.state}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for upcoming events',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = Event.fromMap(
                toStringKeyMap(events[index].data()),
                events[index].id,
              );

              final viewerId = AuthState.currentUserId;
              final isOwner = viewerId != null && viewerId == event.createdBy;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(event: event, currentUserId: AuthState.currentUserId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getEventTypeColor(event.eventType),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                event.eventType,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isOwner) const SizedBox(width: 8),
                            if (isOwner)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: IconButton(
                                      onPressed: () async {
                                        final updated = await Navigator.push<Event?>(
                                          context,
                                          MaterialPageRoute(builder: (_) => EditEventPage(event: event)),
                                        );
                                        if (updated != null) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event updated')));
                                          try {
                                            final actor = AuthState.currentUserId ?? 'unknown';
                                            await AdminLogService.logAction(actorId: actor, action: 'edit_event', targetType: 'community_events', targetId: event.id, metadata: {'title': updated.title});
                                          } catch (_) {}
                                        }
                                      },
                                      icon: const Icon(Icons.edit, size: 16),
                                      tooltip: 'Edit',
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: IconButton(
                                      onPressed: () async {
                                        // Toggle closed state
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(event.isClosed ? 'Reopen Event' : 'Close Event'),
                                            content: Text(event.isClosed ? 'Reopen this event?' : 'Close this event? Closed events are hidden.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
                                            ],
                                          ),
                                        );
                                        if (confirm != true) return;
                                        try {
                                          await FirebaseFirestore.instance.collection('community_events').doc(event.id).update({'isClosed': !event.isClosed});
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(event.isClosed ? 'Event reopened' : 'Event closed')));
                                          try {
                                            final actor = AuthState.currentUserId ?? 'unknown';
                                            await AdminLogService.logAction(actorId: actor, action: event.isClosed ? 'reopen_event' : 'close_event', targetType: 'community_events', targetId: event.id, metadata: {'title': event.title});
                                          } catch (_) {}
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update event: $e')));
                                        }
                                      },
                                      icon: Icon(event.isClosed ? Icons.visibility : Icons.visibility_off, size: 16, color: event.isClosed ? Colors.green : Colors.orange),
                                      tooltip: event.isClosed ? 'Reopen' : 'Close',
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: IconButton(
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Event'),
                                            content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                              FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                            ],
                                          ),
                                        );
                                        if (confirm != true) return;
                                        setState(() => _optimisticRemoved.add(event.id));
                                        try {
                                          final current = AuthState.currentUserId ?? 'guest';
                                          final allowed = await VerificationService.canPost(current);
                                          if (!allowed) {
                                            if (!context.mounted) return;
                                            setState(() => _optimisticRemoved.remove(event.id));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only verified contributors may delete events.'), backgroundColor: Colors.red));
                                            return;
                                          }
                                          await FirebaseFirestore.instance.collection('community_events').doc(event.id).delete();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
                                          try {
                                            final actor = AuthState.currentUserId ?? 'unknown';
                                            await AdminLogService.logAction(actorId: actor, action: 'delete_event', targetType: 'community_events', targetId: event.id, metadata: {'title': event.title});
                                          } catch (_) {}
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          setState(() => _optimisticRemoved.remove(event.id));
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete event: $e')));
                                        }
                                      },
                                      icon: const Icon(Icons.delete, size: 16),
                                      color: Colors.red,
                                      tooltip: 'Delete',
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.date.day}/${event.date.month}/${event.date.year} at ${event.time}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${event.location}, ${event.suburb}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.attendeeCount} attending',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Organized by ${event.organizerName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // FAB removed from state event pages; it's now shown on the Community Events page.
    );
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'cultural':
        return const Color(0xFFf093fb);
      case 'religious':
        return const Color(0xFF4facfe);
      case 'social':
        return const Color(0xFF43e97b);
      case 'educational':
        return const Color(0xFFfa709a);
      case 'sports':
        return const Color(0xFFfee140);
      default:
        return const Color(0xFF2193b0);
    }
  }
}

class EventDetailResult {
  final Event? updatedEvent;
  final String? deletedId;

  const EventDetailResult._({this.updatedEvent, this.deletedId});

  const EventDetailResult.updated(Event e) : this._(updatedEvent: e);
  const EventDetailResult.deleted(String id) : this._(deletedId: id);
}

class EventDetailPage extends StatefulWidget {
  final Event event;
  final String? currentUserId;

  const EventDetailPage({super.key, required this.event, this.currentUserId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Event _event;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    Future.microtask(() async {
      final uid = AuthState.currentUserId;
      if (uid != null) {
        final b = await BookmarkService.isBookmarked(uid, 'community_events', _event.id);
        if (!mounted) return;
        setState(() => _isBookmarked = b);
      }
    });
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('community_events').doc(_event.id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
      Navigator.pop(context, EventDetailResult.deleted(_event.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete event: $e')));
    }
  }

  Future<void> _editEvent() async {
    final updated = await Navigator.push<Event?>(
      context,
      MaterialPageRoute(builder: (_) => EditEventPage(event: _event)),
    );
    if (updated != null) {
      setState(() {
        _event = updated;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event updated')));
    }
  }

  Future<void> _toggleClosedEvent() async {
    try {
      final newState = !_event.isClosed;
      await FirebaseFirestore.instance.collection('community_events').doc(_event.id).update({'isClosed': newState});
      if (!mounted) return;
      setState(() {
        _event = _event.copyWith(isClosed: newState);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newState ? 'Event closed' : 'Event reopened')));
      try {
        final actor = AuthState.currentUserId ?? 'unknown';
        await AdminLogService.logAction(actorId: actor, action: newState ? 'close_event' : 'reopen_event', targetType: 'community_events', targetId: _event.id, metadata: {'title': _event.title});
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update event: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.currentUserId != null && widget.currentUserId == _event.createdBy;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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
                final ok = await BookmarkService.toggleBookmark(uid, 'community_events', _event.id, title: _event.title);
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
          if (isOwner) ...[
            IconButton(onPressed: _editEvent, icon: const Icon(Icons.edit), tooltip: 'Edit'),
            IconButton(onPressed: _toggleClosedEvent, icon: Icon(_event.isClosed ? Icons.visibility : Icons.visibility_off), tooltip: _event.isClosed ? 'Reopen' : 'Close'),
            IconButton(onPressed: _deleteEvent, icon: const Icon(Icons.delete), color: Colors.red, tooltip: 'Delete'),
          ]
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _event.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getEventTypeColor(_event.eventType),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _event.eventType,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Date & Time',
                '${_event.date.day}/${_event.date.month}/${_event.date.year} at ${_event.time}'),
            _buildInfoRow(Icons.location_on, 'Location',
                '${_event.location}, ${_event.address}, ${_event.suburb}, ${_event.state} ${_event.postcode}'),
            _buildInfoRow(Icons.person, 'Organizer', _event.organizerName),
            if (_event.organizerPhone.isNotEmpty)
              _buildInfoRow(Icons.phone, 'Phone', _event.organizerPhone),
            if (_event.organizerEmail.isNotEmpty)
              _buildInfoRow(Icons.email, 'Email', _event.organizerEmail),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _event.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.people, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${_event.attendeeCount} people attending',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'cultural':
        return const Color(0xFFf093fb);
      case 'religious':
        return const Color(0xFF4facfe);
      case 'social':
        return const Color(0xFF43e97b);
      case 'educational':
        return const Color(0xFFfa709a);
      case 'sports':
        return const Color(0xFFfee140);
      default:
        return const Color(0xFF2193b0);
    }
  }
}

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _suburbController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _organizerNameController = TextEditingController();
  final _organizerPhoneController = TextEditingController();
  final _organizerEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Best-effort prefill organizer contact fields from signed-in user
    populateContactControllers(
      nameController: _organizerNameController,
      phoneController: _organizerPhoneController,
      emailController: _organizerEmailController,
    );
  }

  String _selectedState = 'NSW';
  String _selectedEventType = 'Social';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _requiresRSVP = false;
  bool _isLoading = false;

  // Image picker for event cover/photos
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];

  final List<String> _states = [
    'NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT'
  ];

  final List<String> _eventTypes = [
    'Social', 'Cultural', 'Religious', 'Educational', 'Sports', 'Other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _suburbController.dispose();
    _postcodeController.dispose();
    _organizerNameController.dispose();
    _organizerPhoneController.dispose();
    _organizerEmailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final current = AuthState.currentUserId ?? 'guest';
    final allowed = await VerificationService.canPost(current);
    if (!allowed) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Only verified contributors may post events.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final event = Event(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        eventType: _selectedEventType,
        date: _selectedDate,
        time: '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        location: _locationController.text.trim(),
        address: _addressController.text.trim(),
        suburb: _suburbController.text.trim(),
        state: _selectedState,
        postcode: _postcodeController.text.trim(),
        description: _descriptionController.text.trim(),
        organizerName: _organizerNameController.text.trim(),
        organizerPhone: _organizerPhoneController.text.trim(),
        organizerEmail: _organizerEmailController.text.trim(),
        imageUrl: '',
        imagePaths: [],
        viewCount: 0,
        attendeeCount: 0,
        requiresRSVP: _requiresRSVP,
        createdBy: AuthState.currentUserId ?? '',
        postedDate: DateTime.now(),
        isClosed: false,
      );

      final coll = FirebaseFirestore.instance.collection('community_events');
      final docRef = coll.doc();

      // store initial data (images will be updated if uploaded)
      await docRef.set(event.toMap());

      // Upload images if present
      List<String> uploaded = [];
      if (_selectedImages.isNotEmpty) {
        final storage = FirebaseStorage.instance;
        for (var i = 0; i < _selectedImages.length; i++) {
          final file = File(_selectedImages[i].path);
          final ref = storage.ref().child('community_events').child(docRef.id).child('images').child('$i');
          await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
          final url = await ref.getDownloadURL();
          uploaded.add(url);
        }

        // update document with image paths and first image as cover
        await docRef.update({
          'imagePaths': uploaded,
          'imageUrl': uploaded.isNotEmpty ? uploaded.first : '',
        });
      }
      

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating event: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  hintText: 'Enter event title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedEventType,
                decoration: const InputDecoration(
                  labelText: 'Event Type *',
                ),
                items: _eventTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date *',
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time *',
                        ),
                        child: Text(
                          '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Venue Name *',
                  hintText: 'e.g., Community Hall, Restaurant Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter venue name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Street Address *',
                  hintText: 'e.g., 123 Main Street',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter street address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _suburbController,
                      decoration: const InputDecoration(
                        labelText: 'Suburb *',
                        hintText: 'e.g., Sydney CBD',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter suburb';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                      ),
                      items: _states.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _postcodeController,
                decoration: const InputDecoration(
                  labelText: 'Postcode *',
                  hintText: 'e.g., 2000',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter postcode';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your event',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Organizer Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _organizerNameController,
                decoration: const InputDecoration(
                  labelText: 'Organizer Name *',
                  hintText: 'Your full name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter organizer name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _organizerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  hintText: 'Optional contact number',
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _organizerEmailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email *',
                  hintText: 'your.email@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              CheckboxListTile(
                title: const Text('Require RSVP'),
                subtitle: const Text('Attendees must confirm their attendance'),
                value: _requiresRSVP,
                onChanged: (value) {
                  setState(() {
                    _requiresRSVP = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 32),

              // Image upload card (optional)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Images (optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImages.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImages.first.path),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final photos = await _imagePicker.pickMultiImage();
                                  if (!mounted) return;
                                  setState(() {
                                    if (photos.isNotEmpty) {
                                      _selectedImages = photos;
                                    }
                                  });
                                },
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Change'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() => _selectedImages.clear());
                                },
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remove'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: () async {
                            final photos = await _imagePicker.pickMultiImage();
                            if (!mounted) return;
                            setState(() {
                              if (photos.isNotEmpty) _selectedImages = photos;
                            });
                          },
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Add photo'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tip: Add a photo to help attendees find your event.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Post Event'),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}