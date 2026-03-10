import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
// Google Maps removed from Room details view; import unused.

import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

import 'services/security_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/room_scam_detector_service.dart';
import 'rent_calculator_page.dart';
import 'auth_page.dart';
import 'utils/user_prefill_helper.dart';
import 'profile_page.dart';
import 'services/verification_service.dart';
import 'services/bookmark_service.dart';

class Room {
  final String id;
  final String title;
  final String suburb;
  final String city;
  final double pricePerWeek;
  final String roomType;
  final String description;
  final String address;
  final String phoneNumber;
  final String email;
  final String landlordName;
  final String photoUrl;
  final List<String> photoPaths;
  final List<String> amenities;
  final String createdBy;
  final DateTime postedDate;
  final double? latitude;
  final double? longitude;
  final int viewCount;
  final bool isClosed;
  final String? closedReason;
  final DateTime? closedAt;

  const Room({
    required this.id,
    required this.title,
    required this.suburb,
    required this.city,
    required this.pricePerWeek,
    required this.roomType,
    required this.description,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.landlordName,
    required this.photoUrl,
    required this.photoPaths,
    required this.amenities,
    required this.createdBy,
    required this.postedDate,
    this.latitude,
    this.longitude,
    this.viewCount = 0,
    this.isClosed = false,
    this.closedReason,
    this.closedAt,
  });

  Room copyWith({
    String? id,
    String? title,
    String? suburb,
    String? city,
    double? pricePerWeek,
    String? roomType,
    String? description,
    String? address,
    String? phoneNumber,
    String? email,
    String? landlordName,
    String? photoUrl,
    List<String>? photoPaths,
    List<String>? amenities,
    String? createdBy,
    DateTime? postedDate,
    double? latitude,
    double? longitude,
    int? viewCount,
    bool? isClosed,
    String? closedReason,
    DateTime? closedAt,
  }) {
    return Room(
      id: id ?? this.id,
      title: title ?? this.title,
      suburb: suburb ?? this.suburb,
      city: city ?? this.city,
      pricePerWeek: pricePerWeek ?? this.pricePerWeek,
      roomType: roomType ?? this.roomType,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      landlordName: landlordName ?? this.landlordName,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPaths: photoPaths ?? this.photoPaths,
      amenities: amenities ?? this.amenities,
      createdBy: createdBy ?? this.createdBy,
      postedDate: postedDate ?? this.postedDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      viewCount: viewCount ?? this.viewCount,
      isClosed: isClosed ?? this.isClosed,
      closedReason: closedReason ?? this.closedReason,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}

class RoomsPage extends StatefulWidget {
  final String? filterUserId;
  final String? titleOverride;

  const RoomsPage({super.key, this.filterUserId, this.titleOverride});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  bool _showMyRooms = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FirebaseBootstrap.tryInit().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  CollectionReference<Map<String, dynamic>> get _roomsCollection =>
      FirebaseFirestore.instance.collection('community_rooms');

  static DateTime _timestampToDate(dynamic value, DateTime fallback) {
    if (value is Timestamp) return value.toDate();
    return fallback;
  }

  static DateTime? _timestampToNullableDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static String _closedReasonLabel(String? reason) {
    switch (reason) {
      case 'sold_in_app':
        return 'Sold/Rented from this app';
      case 'sold_other_app':
        return 'Sold/Rented from other app';
      case 'other':
        return 'Other';
      default:
        return '';
    }
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

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return fallback;
  }

  static bool _isRemoteUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool _looksLikeLocalFilePath(String value) {
    if (value.isEmpty) return false;
    if (_isRemoteUrl(value)) return false;
    if (value.startsWith('assets/')) return false;
    return true;
  }

  static String _prettyFirestoreError(Object? error) {
    if (error == null) return 'Unknown error';
    if (error is FirebaseException) {
      final message = (error.message ?? '').trim();
      return message.isEmpty ? error.code : '${error.code}: $message';
    }
    return error.toString();
  }

  Query<Map<String, dynamic>> _roomsQuery({
    required bool myRooms,
    required String currentUserId,
    String? filterUserId,
  }) {
    Query<Map<String, dynamic>> query = _roomsCollection;
    final createdByFilter = (filterUserId != null && filterUserId.isNotEmpty)
        ? filterUserId
        : (myRooms ? currentUserId : null);

    if (createdByFilter != null) {
      // Avoid requiring a composite index for (createdBy == X) + orderBy(postedDate).
      // We'll sort by postedDate client-side for "My Rooms".
      return query.where('createdBy', isEqualTo: createdByFilter);
    }

    // Public browse can use Firestore ordering (single-field index).
    return query.orderBy('postedDate', descending: true);
  }

  Room _roomFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final now = DateTime.now();
    final postedDate = _timestampToDate(data['postedDate'], now);

    final photosDynamic = data['photoUrls'] ?? data['photoPaths'];
    final photoPaths = photosDynamic is List
        ? photosDynamic.whereType<String>().toList()
        : <String>[];

    final amenitiesDynamic = data['amenities'];
    final amenities = amenitiesDynamic is List
        ? amenitiesDynamic.whereType<String>().toList()
        : <String>[];

    return Room(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      suburb: (data['suburb'] ?? '') as String,
      city: (data['city'] ?? '') as String,
      pricePerWeek: _asDouble(data['pricePerWeek']),
      roomType: (data['roomType'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      address: (data['address'] ?? '') as String,
      phoneNumber: (data['phoneNumber'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      landlordName: (data['landlordName'] ?? '') as String,
      photoUrl: (data['photoUrl'] ?? 'assets/room_placeholder.jpg') as String,
      photoPaths: photoPaths,
      amenities: amenities,
      createdBy: (data['createdBy'] ?? 'guest') as String,
      postedDate: postedDate,
      latitude: data['latitude'] is num
          ? (data['latitude'] as num).toDouble()
          : null,
      longitude: data['longitude'] is num
          ? (data['longitude'] as num).toDouble()
          : null,
      viewCount: _asInt(data['viewCount']),
      isClosed: _asBool(data['isClosed']),
      closedReason: data['closedReason'] is String
          ? (data['closedReason'] as String)
          : null,
      closedAt: _timestampToNullableDate(data['closedAt']),
    );
  }

  Future<List<String>> _uploadRoomPhotosIfNeeded({
    required String roomId,
    required List<String> photoPaths,
  }) async {
    final storage = FirebaseStorage.instance;
    final result = <String>[];

    for (var i = 0; i < photoPaths.length; i++) {
      final pathOrUrl = photoPaths[i];
      if (_looksLikeLocalFilePath(pathOrUrl)) {
        try {
          final file = File(pathOrUrl);
          final extension = pathOrUrl.contains('.')
              ? '.${pathOrUrl.split('.').last.toLowerCase()}'
              : '';
          final ref = storage.ref().child(
            'community_rooms/$roomId/photos/$i$extension',
          );
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          result.add(url);
          continue;
        } catch (_) {
          // Fall through to keep the original path.
        }
      }
      result.add(pathOrUrl);
    }

    return result;
  }

  Future<void> _incrementViewCount(String roomId) async {
    try {
      await _roomsCollection.doc(roomId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<void> _setRoomClosed(
    String roomId, {
    required bool isClosed,
    String? reason,
  }) async {
    if (!isClosed) {
      await _roomsCollection.doc(roomId).update({
        'isClosed': false,
        'closedReason': FieldValue.delete(),
        'closedAt': FieldValue.delete(),
        'reopenedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _roomsCollection.doc(roomId).update({
      'isClosed': true,
      'closedReason': reason,
      'closedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> _promptCloseReason(BuildContext context) async {
    String selected = 'sold_in_app';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Close Room Listing'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Closing will hide your room from public browsing. Select a reason (helps us improve the app):',
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: selected,
                    onChanged: (v) => setLocalState(() => selected = v ?? selected),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'sold_in_app',
                          title: const Text('Sold/Rented from this app'),
                        ),
                        RadioListTile<String>(
                          value: 'sold_other_app',
                          title: const Text('Sold/Rented from other app'),
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

  Future<void> _createRoomInFirestore(Room room) async {
    final docRef = _roomsCollection.doc();
    final now = DateTime.now();

    await docRef.set({
      'title': room.title,
      'suburb': room.suburb,
      'city': room.city,
      'pricePerWeek': room.pricePerWeek,
      'roomType': room.roomType,
      'description': room.description,
      'address': room.address,
      'phoneNumber': room.phoneNumber,
      'email': room.email,
      'landlordName': room.landlordName,
      'photoUrl': 'assets/room_placeholder.jpg',
      'photoUrls': <String>[],
      'amenities': room.amenities,
      'createdBy': room.createdBy,
      'postedDate': Timestamp.fromDate(now),
      'latitude': room.latitude,
      'longitude': room.longitude,
      'viewCount': 0,
      'isClosed': false,
    });

    final uploaded = await _uploadRoomPhotosIfNeeded(
      roomId: docRef.id,
      photoPaths: room.photoPaths,
    );

    await docRef.update({
      'photoUrls': uploaded,
      'photoUrl': uploaded.isNotEmpty ? uploaded.first : room.photoUrl,
    });
  }

  Future<void> _updateRoomInFirestore(Room room) async {
    final uploaded = await _uploadRoomPhotosIfNeeded(
      roomId: room.id,
      photoPaths: room.photoPaths,
    );

    await _roomsCollection.doc(room.id).update({
      'title': room.title,
      'suburb': room.suburb,
      'city': room.city,
      'pricePerWeek': room.pricePerWeek,
      'roomType': room.roomType,
      'description': room.description,
      'address': room.address,
      'phoneNumber': room.phoneNumber,
      'email': room.email,
      'landlordName': room.landlordName,
      'photoUrls': uploaded,
      'photoUrl': uploaded.isNotEmpty ? uploaded.first : room.photoUrl,
      'amenities': room.amenities,
      'latitude': room.latitude,
      'longitude': room.longitude,
    });
  }

  Future<void> _deleteRoom(Room room) async {
    for (final photoUrl in room.photoPaths) {
      if (_isRemoteUrl(photoUrl)) {
        try {
          await FirebaseStorage.instance.refFromURL(photoUrl).delete();
        } catch (_) {
          // Ignore failures.
        }
      }
    }
    await _roomsCollection.doc(room.id).delete();
  }

  double? _minPrice;
  double? _maxPrice;
  String _keyword = '';
  String? _roomType;
  String? _suburb;
  String? _city;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewerUserId = AuthState.currentUserId;
    final currentUserIdForQueries = viewerUserId ?? 'guest';
    final filterUserId = widget.filterUserId;

    final isUserFiltered = filterUserId != null && filterUserId.isNotEmpty;
    if (isUserFiltered) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.titleOverride ?? 'Rooms'),
        ),
        floatingActionButton: isUserFiltered
            ? null
            : FutureBuilder<bool>(
                future: VerificationService.canPost(viewerUserId ?? 'guest'),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final allowed = snap.data == true;
                  if (!allowed) {
                    return FloatingActionButton.extended(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Only verified contributors can post rooms.')),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Post Room'),
                    );
                  }
                  return FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateRoomPage(
                            onRoomCreated: (room) {
                              _createRoomInFirestore(room).then((_) {
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Room posted')),
                                );
                              });
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Post Room'),
                  );
                },
              ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firebaseReady
              ? _roomsQuery(
                  myRooms: false,
                  currentUserId: currentUserIdForQueries,
                  filterUserId: filterUserId,
                ).snapshots()
              : Stream<QuerySnapshot<Map<String, dynamic>>>.empty(),
          builder: (context, snapshot) {
            if (!_firebaseReady) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load rooms. ${_prettyFirestoreError(snapshot.error)}',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? const [];
            final rooms = _applyFilters(docs.map(_roomFromDoc).toList());

            rooms.sort((a, b) {
              return b.postedDate.compareTo(a.postedDate);
            });

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search rooms...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _keyword = '';
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                            ),
                            onChanged: (v) => setState(() => _keyword = v),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Filter',
                          icon: const Icon(Icons.filter_list),
                          onPressed: () => _openFilterDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 0, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${rooms.length} items found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildRoomsGrid(
                    theme: theme,
                    viewerUserId: viewerUserId,
                    rooms: rooms,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titleOverride ?? 'Rooms'),
        actions: [
          IconButton(
            icon: Icon(_showMyRooms ? Icons.public : Icons.person),
            tooltip: _showMyRooms ? 'View All Rooms' : 'View My Rooms',
            onPressed: () {
              if (!_showMyRooms && viewerUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login to view My Rooms')),
                );
                return;
              }
              setState(() {
                _showMyRooms = !_showMyRooms;
              });
            },
          ),
        ],
      ),
      floatingActionButton: isUserFiltered
          ? null
          : FutureBuilder<bool>(
              future: VerificationService.canPost(viewerUserId ?? 'guest'),
              builder: (ctx, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final allowed = snap.data == true;
                if (!allowed) {
                  return FloatingActionButton.extended(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Only verified contributors can post rooms.')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Post Room'),
                  );
                }
                return FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateRoomPage(
                          onRoomCreated: (room) {
                            _createRoomInFirestore(room).then((_) {
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Room posted')),
                              );
                            });
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Post Room'),
                );
              },
            ),

      body: _showMyRooms && viewerUserId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      'Login to view and manage your rooms.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firebaseReady
                  ? _roomsQuery(
                      myRooms: _showMyRooms,
                      currentUserId: _showMyRooms
                          ? (viewerUserId ?? 'guest')
                          : currentUserIdForQueries,
                      filterUserId: null,
                    ).snapshots()
                  : Stream<QuerySnapshot<Map<String, dynamic>>>.empty(),
              builder: (context, snapshot) {
                if (!_firebaseReady) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load rooms. ${_prettyFirestoreError(snapshot.error)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? const [];
                final rooms = _applyFilters(docs.map(_roomFromDoc).toList());

                rooms.sort((a, b) {
                  return b.postedDate.compareTo(a.postedDate);
                });
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search rooms...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _keyword = '';
                                              _searchController.clear();
                                            });
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                ),
                                onChanged: (v) => setState(() => _keyword = v),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Filter',
                              icon: const Icon(Icons.filter_list),
                              onPressed: () => _openFilterDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 0, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${rooms.length} items found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildRoomsGrid(
                        theme: theme,
                        viewerUserId: viewerUserId,
                        rooms: rooms,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  List<Room> _applyFilters(List<Room> rooms) {
    final keyword = _keyword.trim().toLowerCase();

    return rooms.where((room) {
      // Only show open rooms.
      if (room.isClosed) return false;
      if (_minPrice != null && room.pricePerWeek < _minPrice!) return false;
      if (_maxPrice != null && room.pricePerWeek > _maxPrice!) return false;
      if (_roomType != null &&
          _roomType!.isNotEmpty &&
          room.roomType != _roomType) {
        return false;
      }
      if (_suburb != null && _suburb!.isNotEmpty && room.suburb != _suburb) {
        return false;
      }
      if (_city != null && _city!.isNotEmpty && room.city != _city) {
        return false;
      }
      if (keyword.isEmpty) return true;

      final haystack =
          '${room.title} ${room.suburb} ${room.city} ${room.address} ${room.description}'
              .toLowerCase();
      return haystack.contains(keyword);
    }).toList();
  }

  Widget _buildRoomsGrid({
    required ThemeData theme,
    required String? viewerUserId,
    required List<Room> rooms,
  }) {
    if (rooms.isEmpty) {
      return Center(
        child: Text(
          'No rooms found',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: rooms.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          // display one card per row to match Events list
          crossAxisCount: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.0,
          mainAxisExtent: 320,
        ),
        itemBuilder: (context, index) {
          final room = rooms[index];

          return RoomCard(
            room: room,
            viewerUserId: viewerUserId,
            onTap: () async {
              final isOwner = viewerUserId != null && viewerUserId == room.createdBy;
              if (!isOwner) {
                _incrementViewCount(room.id);
              }
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RoomDetailPage(room: room, viewerUserId: viewerUserId),
                ),
              );
            },
            onEdit: (viewerUserId != null && viewerUserId == room.createdBy)
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditRoomPage(
                          room: room,
                          onRoomUpdated: (updated) {
                            _updateRoomInFirestore(updated).then((_) {
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Room updated')),
                              );
                            });
                          },
                        ),
                      ),
                    );
                  }
                : null,
            onToggleClosed: (viewerUserId != null && viewerUserId == room.createdBy)
                ? () {
                    if (room.isClosed) {
                      _setRoomClosed(room.id, isClosed: false).then((_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Listing reopened')),
                        );
                      });
                      return;
                    }

                    _promptCloseReason(context).then((reason) {
                      if (reason == null) return;
                      _setRoomClosed(room.id, isClosed: true, reason: reason)
                          .then((_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Listing closed${reason.isNotEmpty ? ' (${_closedReasonLabel(reason)})' : ''}',
                                ),
                              ),
                            );
                          });
                    });
                  }
                : null,
            onDelete: (viewerUserId != null && viewerUserId == room.createdBy)
                ? () => _confirmDelete(context, room)
                : null,
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Room'),
        content: const Text(
          'Are you sure you want to delete this room listing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
            FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final current = AuthState.currentUserId ?? 'guest';
              final allowed = await VerificationService.canPost(current);
              if (!allowed) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only verified contributors may delete rooms.'), backgroundColor: Colors.red));
                return;
              }
              _deleteRoom(room).then((_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Room deleted')));
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => RoomFilterDialog(
        initialMinPrice: _minPrice,
        initialMaxPrice: _maxPrice,
        initialKeyword: _keyword,
        initialRoomType: _roomType,
        initialSuburb: _suburb,
        initialCity: _city,
        onClearFilters: () {
          setState(() {
            _minPrice = null;
            _maxPrice = null;
            _keyword = '';
            _roomType = null;
            _suburb = null;
            _city = null;
          });
          Navigator.pop(context);
        },
        onApplyFilters: (minPrice, maxPrice, keyword, roomType, suburb, city) {
          setState(() {
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _keyword = keyword;
            _roomType = roomType;
            _suburb = suburb;
            _city = city;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  final String? viewerUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleClosed;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    required this.viewerUserId,
    this.onEdit,
    this.onDelete,
    this.onToggleClosed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quickAnalysis = RoomScamDetectorService.quickAssess(
      RoomListingInput(
        title: room.title,
        suburb: room.suburb,
        city: room.city,
        pricePerWeek: room.pricePerWeek,
        roomType: room.roomType,
        description: room.description,
        address: room.address,
        photoUrls: room.photoPaths,
      ),
    );
    final likelihood = quickAnalysis.likelihood;

    Color badgeBg;
    Color badgeFg;
    switch (likelihood) {
      case ScamLikelihood.high:
        badgeBg = const Color(0xFFFEE2E2);
        badgeFg = const Color(0xFF991B1B);
        break;
      case ScamLikelihood.medium:
        badgeBg = const Color(0xFFFFF3CD);
        badgeFg = const Color(0xFF92400E);
        break;
      case ScamLikelihood.low:
        badgeBg = const Color(0xFFDCFCE7);
        badgeFg = const Color(0xFF166534);
        break;
      case ScamLikelihood.unknown:
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
            // Room Image Placeholder
            Container(
              height: 160,
              color: theme.colorScheme.primaryContainer,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (room.photoPaths.isNotEmpty)
                    (() {
                      final cover = room.photoPaths[0];
                      final fallback = Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_outlined,
                              size: 40,
                              color: theme.colorScheme.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: room.roomType == 'Private'
                                    ? theme.colorScheme.primary.withAlpha(51)
                                    : Colors.orange.withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                room.roomType,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: room.roomType == 'Private'
                                      ? theme.colorScheme.primary
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (cover.startsWith('http://') ||
                          cover.startsWith('https://')) {
                        return Image.network(
                          cover,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return fallback;
                          },
                        );
                      }

                      if (cover.startsWith('assets/')) {
                        return Image.asset(
                          cover,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return fallback;
                          },
                        );
                      }

                      return Image.file(
                        File(cover),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return fallback;
                        },
                      );
                    })()
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_outlined,
                            size: 40,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: room.roomType == 'Private'
                                  ? theme.colorScheme.primary.withAlpha(51)
                                  : Colors.orange.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              room.roomType,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: room.roomType == 'Private'
                                    ? theme.colorScheme.primary
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (room.isClosed)
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'CLOSED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if ((room.closedReason ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Text(
                                    _RoomsPageState._closedReasonLabel(
                                      room.closedReason,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
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
                          border: Border.all(color: badgeFg.withValues(alpha: 0.3)),
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
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      room.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Price
                    Text(
                      '\$${room.pricePerWeek.toStringAsFixed(0)}/week',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                            '${room.suburb}, ${room.city}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    // Posted date + views (single line to avoid overflow)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(room.postedDate),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.visibility_outlined,
                          size: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${room.viewCount} views',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    if (viewerUserId != null && viewerUserId == room.createdBy)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
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
                                  room.isClosed
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                color: room.isClosed
                                    ? Colors.green
                                    : Colors.orange,
                                tooltip: room.isClosed ? 'Reopen' : 'Close',
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}
 
class RoomDetailResult {
  final Room? updatedRoom;
  final String? deletedId;

  const RoomDetailResult._({this.updatedRoom, this.deletedId});

  const RoomDetailResult.updated(Room room) : this._(updatedRoom: room);

  const RoomDetailResult.deleted(String id) : this._(deletedId: id);
}

class RoomDetailPage extends StatefulWidget {
  final Room room;
  final String? viewerUserId;

  const RoomDetailPage({
    super.key,
    required this.room,
    required this.viewerUserId,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  int _currentPhotoIndex = 0;
  late Room _room;
  Future<RoomScamAnalysis>? _scamAnalysisFuture;
  bool _isBookmarked = false;

  CollectionReference<Map<String, dynamic>> get _roomsCollection =>
      FirebaseFirestore.instance.collection('community_rooms');

  static bool _isRemoteUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool _looksLikeLocalFilePath(String value) {
    if (value.isEmpty) return false;
    if (_isRemoteUrl(value)) return false;
    if (value.startsWith('assets/')) return false;
    return true;
  }

  Future<List<String>> _uploadRoomPhotosIfNeeded({
    required String roomId,
    required List<String> photoPaths,
  }) async {
    final storage = FirebaseStorage.instance;
    final result = <String>[];

    for (var i = 0; i < photoPaths.length; i++) {
      final pathOrUrl = photoPaths[i];
      if (_looksLikeLocalFilePath(pathOrUrl)) {
        try {
          final file = File(pathOrUrl);
          final extension = pathOrUrl.contains('.')
              ? '.${pathOrUrl.split('.').last.toLowerCase()}'
              : '';
          final ref = storage.ref().child(
            'community_rooms/$roomId/photos/$i$extension',
          );
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          result.add(url);
          continue;
        } catch (_) {
          // Keep original value if upload fails.
        }
      }
      result.add(pathOrUrl);
    }
    return result;
  }

  Future<Room> _persistRoomUpdate(Room updatedRoom) async {
    final uploaded = await _uploadRoomPhotosIfNeeded(
      roomId: updatedRoom.id,
      photoPaths: updatedRoom.photoPaths,
    );

    await _roomsCollection.doc(updatedRoom.id).update({
      'title': updatedRoom.title,
      'suburb': updatedRoom.suburb,
      'city': updatedRoom.city,
      'pricePerWeek': updatedRoom.pricePerWeek,
      'roomType': updatedRoom.roomType,
      'description': updatedRoom.description,
      'address': updatedRoom.address,
      'phoneNumber': updatedRoom.phoneNumber,
      'email': updatedRoom.email,
      'landlordName': updatedRoom.landlordName,
      'photoUrls': uploaded,
      'photoUrl': uploaded.isNotEmpty ? uploaded.first : updatedRoom.photoUrl,
      'amenities': updatedRoom.amenities,
      'latitude': updatedRoom.latitude,
      'longitude': updatedRoom.longitude,
    });

    return updatedRoom.copyWith(
      photoPaths: uploaded,
      photoUrl: uploaded.isNotEmpty ? uploaded.first : updatedRoom.photoUrl,
    );
  }

  Future<void> _setClosedWithReason({
    required bool isClosed,
    String? reason,
  }) async {
    if (!isClosed) {
      await _roomsCollection.doc(_room.id).update({
        'isClosed': false,
        'closedReason': FieldValue.delete(),
        'closedAt': FieldValue.delete(),
        'reopenedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _room = _room.copyWith(
          isClosed: false,
          closedReason: null,
          closedAt: null,
        );
      });
      return;
    }

    await _roomsCollection.doc(_room.id).update({
      'isClosed': true,
      'closedReason': reason,
      'closedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    setState(() {
      _room = _room.copyWith(isClosed: true, closedReason: reason);
    });
  }

  Future<String?> _promptCloseReason(BuildContext context) async {
    String selected = 'sold_in_app';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Close Room Listing'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Closing will hide your room from public browsing. Select a reason (helps us improve the app):',
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: selected,
                    onChanged: (v) => setLocalState(() => selected = v ?? selected),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'sold_in_app',
                          title: const Text('Sold/Rented from this app'),
                        ),
                        RadioListTile<String>(
                          value: 'sold_other_app',
                          title: const Text('Sold/Rented from other app'),
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

  Future<void> _deleteListing() async {
    for (final photoUrl in _room.photoPaths) {
      if (_isRemoteUrl(photoUrl)) {
        try {
          await FirebaseStorage.instance.refFromURL(photoUrl).delete();
        } catch (_) {
          // Ignore failures.
        }
      }
    }
    await _roomsCollection.doc(_room.id).delete();
  }

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _scamAnalysisFuture = _analyzeRoom();
    Future.microtask(() async {
      final uid = AuthState.currentUserId;
      if (uid != null) {
        final b = await BookmarkService.isBookmarked(uid, 'community_rooms', _room.id);
        if (!mounted) return;
        setState(() => _isBookmarked = b);
      }
    });
  }

  RoomListingInput _listingFromRoom(Room room) {
    return RoomListingInput(
      title: room.title,
      suburb: room.suburb,
      city: room.city,
      pricePerWeek: room.pricePerWeek,
      roomType: room.roomType,
      description: room.description,
      address: room.address,
      photoUrls: room.photoPaths,
    );
  }

  Future<RoomScamAnalysis> _analyzeRoom({bool forceRefresh = false}) {
    return RoomScamDetectorService.analyze(
      roomId: _room.id,
      listing: _listingFromRoom(_room),
      forceRefresh: forceRefresh,
    );
  }

  void _openAiSafetyDetails() {
    final room = _room;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomSafetyCheckDetailPage(room: room)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rootContext = context;
    final room = _room;
    final hasPhotos = room.photoPaths.isNotEmpty;
    final isOwner = widget.viewerUserId != null && widget.viewerUserId == room.createdBy;
    final canOpenListerProfile =
        room.createdBy.trim().isNotEmpty && room.createdBy != 'guest';
    final listerName =
        AuthService.getUserById(room.createdBy)?.name ?? room.landlordName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Details'),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            tooltip: _isBookmarked ? 'Remove bookmark' : 'Bookmark',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              developer.log('BookmarkDebug: currentUser uid=${user?.uid} email=${user?.email}', name: 'BookmarkDebug');
              developer.log('BookmarkDebug: projectId=${Firebase.app().options.projectId}', name: 'BookmarkDebug');
              final messenger = ScaffoldMessenger.of(context);
              if (user == null) {
                if (!mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('Please sign in to bookmark items.')));
                return;
              }
              final uid = user.uid;
              final previous = _isBookmarked;
              setState(() => _isBookmarked = !previous);
              try {
                final ok = await BookmarkService.toggleBookmark(uid, 'community_rooms', _room.id, title: _room.title);
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
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  rootContext,
                  MaterialPageRoute(
                    builder: (_) => EditRoomPage(
                      room: room,
                      onRoomUpdated: (updatedRoom) {
                        _persistRoomUpdate(updatedRoom).then((saved) {
                          if (!rootContext.mounted) return;
                          setState(() {
                            _room = saved;
                          });
                          Navigator.pop(rootContext);
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(content: Text('Room updated')),
                          );
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: room.isClosed ? 'Reopen listing' : 'Close listing',
              icon: Icon(
                room.isClosed ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                if (room.isClosed) {
                  _setClosedWithReason(isClosed: false).then((_) {
                    if (!rootContext.mounted) return;
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      const SnackBar(content: Text('Listing reopened')),
                    );
                  });
                  return;
                }

                _promptCloseReason(rootContext).then((reason) {
                  if (reason == null) return;
                  _setClosedWithReason(isClosed: true, reason: reason).then((_) {
                    if (!rootContext.mounted) return;
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      const SnackBar(content: Text('Listing closed')),
                    );
                  });
                });
              },
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: rootContext,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete Room'),
                    content: Text(
                      'Are you sure you want to delete "${room.title}"? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _deleteListing().then((_) {
                            if (!rootContext.mounted) return;
                            Navigator.pop(rootContext);
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              const SnackBar(content: Text('Room deleted')),
                            );
                          });
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header media (ItemDetailPage-style)
            Container(
              height: 300,
              width: double.infinity,
              color: theme.colorScheme.primaryContainer,
              child: hasPhotos
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: _buildMediaDisplay(
                            room.photoPaths[_currentPhotoIndex],
                          ),
                        ),
                        if (room.photoPaths.length > 1)
                          Positioned(
                            left: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _currentPhotoIndex =
                                        (_currentPhotoIndex -
                                            1 +
                                            room.photoPaths.length) %
                                        room.photoPaths.length;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.chevron_left,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (room.photoPaths.length > 1)
                          Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _currentPhotoIndex =
                                        (_currentPhotoIndex + 1) %
                                        room.photoPaths.length;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (room.photoPaths.length > 1)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                '${_currentPhotoIndex + 1}/${room.photoPaths.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Center(
                      child: Icon(
                        Icons.home_outlined,
                        size: 100,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
            ),
            if (hasPhotos && room.photoPaths.length > 1)
              Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(room.photoPaths.length, (index) {
                      final isSelected = index == _currentPhotoIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentPhotoIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey[300]!,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: _isVideoFile(room.photoPaths[index])
                                  ? Container(
                                      color: Colors.black87,
                                      child: const Icon(
                                        Icons.play_circle_filled,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    )
                                  : (_isRemoteUrl(room.photoPaths[index])
                                        ? Image.network(
                                            room.photoPaths[index],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.black12,
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported_outlined,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          )
                                        : (room.photoPaths[index].startsWith(
                                                'assets/',
                                              )
                                              ? Image.asset(
                                                  room.photoPaths[index],
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.file(
                                                  File(room.photoPaths[index]),
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          color: Colors.black12,
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .image_not_supported_outlined,
                                                              size: 18,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                ))),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${room.pricePerWeek.toStringAsFixed(0)}/week',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          room.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (room.isClosed) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: const Text('CLOSED'),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF991B1B),
                          ),
                          backgroundColor: const Color(0xFFFEE2E2),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Builder(builder: (ctx) {
                        final rows = <Widget>[];

                        if (room.address.trim().isNotEmpty) {
                          rows.add(_DetailRow(icon: Icons.location_on_outlined, label: 'Address', value: room.address));
                        }

                        final area = [room.suburb.trim(), room.city.trim()].where((s) => s.isNotEmpty).join(', ');
                        if (area.isNotEmpty) {
                          rows.add(_DetailRow(icon: Icons.map_outlined, label: 'Area', value: area));
                        }

                        if (room.roomType.trim().isNotEmpty) {
                          rows.add(_DetailRow(icon: Icons.meeting_room_outlined, label: 'Room Type', value: room.roomType));
                        }

                        if (room.amenities.isNotEmpty) {
                          rows.add(_DetailRow(icon: Icons.checklist_outlined, label: 'Amenities', value: room.amenities.join(', ')));
                        }

                        if (rows.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          children: List<Widget>.generate(rows.length * 2 - 1, (i) {
                            if (i.isEven) return rows[i ~/ 2];
                            return const Divider(height: 24);
                          }),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    room.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _openAiSafetyDetails,
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FutureBuilder<RoomScamAnalysis>(
                          future: _scamAnalysisFuture,
                          builder: (context, snapshot) {
                            final analysis = snapshot.data;

                            ScamLikelihood likelihood = ScamLikelihood.unknown;
                            String subtitle = 'Tap to view details';
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              subtitle = 'Checking listing… (tap for details)';
                            } else if (snapshot.hasError) {
                              subtitle =
                                  'Could not run AI check (tap for tips)';
                            } else if (analysis != null) {
                              likelihood = analysis.likelihood;
                              subtitle = 'Tap to view red flags and advice';
                            }

                            Color badgeBg;
                            Color badgeFg;
                            switch (likelihood) {
                              case ScamLikelihood.high:
                                badgeBg = const Color(0xFFFEE2E2);
                                badgeFg = const Color(0xFF991B1B);
                                break;
                              case ScamLikelihood.medium:
                                badgeBg = const Color(0xFFFFF3CD);
                                badgeFg = const Color(0xFF92400E);
                                break;
                              case ScamLikelihood.low:
                                badgeBg = const Color(0xFFDCFCE7);
                                badgeFg = const Color(0xFF166534);
                                break;
                              case ScamLikelihood.unknown:
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
                                              color: const Color(0xFF6B7280),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RentCalculatorPage(
                              initialWeeklyRent: room.pricePerWeek,
                            ),
                          ),
                        );
                      },
                      leading: Icon(
                        Icons.calculate_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Rent Calculator'),
                      subtitle: const Text(
                        'Monthly, bond (4 weeks), split, move-in cost',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  Text(
                    'Lister Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: !canOpenListerProfile
                          ? null
                          : () {
                              Navigator.push(
                                rootContext,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(
                                    profileUserId: room.createdBy,
                                    displayNameOverride: listerName,
                                  ),
                                ),
                              );
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                    listerName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    canOpenListerProfile
                                        ? 'View profile'
                                        : 'Contact details',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (room.phoneNumber.trim().isNotEmpty)
                                    Text(
                                      room.phoneNumber,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF6B7280),
                                          ),
                                    ),
                                  if (room.email.trim().isNotEmpty)
                                    Text(
                                      room.email,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF6B7280),
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            if (canOpenListerProfile)
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF6B7280),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Location map removed from detail view per request.
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isOwner
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
                        onPressed: room.phoneNumber.trim().isEmpty
                            ? null
                            : _sendMessage,
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
                        onPressed: room.phoneNumber.trim().isEmpty
                            ? null
                            : _callLandlord,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call, size: 20),
                            SizedBox(width: 8),
                            Text('Call'),
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

  Widget _buildMediaDisplay(String mediaPath) {
    if (_isRemoteUrl(mediaPath)) {
      return Image.network(
        mediaPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.black12,
            child: const Center(
              child: Icon(Icons.image_not_supported_outlined),
            ),
          );
        },
      );
    }

    return _isVideoFile(mediaPath)
        ? Container(
            color: Colors.black87,
            child: const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 72,
              ),
            ),
          )
        : Image.file(
            File(mediaPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black12,
                child: const Center(
                  child: Icon(Icons.image_not_supported_outlined),
                ),
              );
            },
          );
  }

  bool _isVideoFile(String filePath) {
    final lowerPath = filePath.toLowerCase();
    return lowerPath.endsWith('.mp4') || lowerPath.endsWith('.mov');
  }

  Future<void> _callLandlord() async {
    final phoneNumber = _room.phoneNumber.trim();
    if (phoneNumber.isEmpty) return;

    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final telUri = Uri.parse('tel:$cleanedNumber');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  Future<void> _sendMessage() async {
    final phoneNumber = _room.phoneNumber.trim();
    if (phoneNumber.isEmpty) return;

    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final message =
        'Hi, I\'m interested in your room listing: ${_room.title} in ${_room.suburb}. Is it still available?';
    final smsUri = Uri.parse(
      'sms:$cleanedNumber?body=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }
}

class RoomSafetyCheckDetailPage extends StatefulWidget {
  final Room room;

  const RoomSafetyCheckDetailPage({super.key, required this.room});

  @override
  State<RoomSafetyCheckDetailPage> createState() =>
      _RoomSafetyCheckDetailPageState();
}

class _RoomSafetyCheckDetailPageState extends State<RoomSafetyCheckDetailPage> {
  Future<RoomScamAnalysis>? _future;

  Future<void> _openScamwatch(BuildContext context) async {
    final url = Uri.parse('https://www.scamwatch.gov.au/report-a-scam');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Scamwatch website')),
      );
    }
  }

  RoomListingInput _listingFromRoom(Room room) {
    return RoomListingInput(
      title: room.title,
      suburb: room.suburb,
      city: room.city,
      pricePerWeek: room.pricePerWeek,
      roomType: room.roomType,
      description: room.description,
      address: room.address,
      photoUrls: room.photoPaths,
    );
  }

  @override
  void initState() {
    super.initState();
    _future = RoomScamDetectorService.analyze(
      roomId: widget.room.id,
      listing: _listingFromRoom(widget.room),
    );
  }

  Color _colorFor(ScamLikelihood l) {
    switch (l) {
      case ScamLikelihood.high:
        return const Color(0xFF991B1B);
      case ScamLikelihood.medium:
        return const Color(0xFF92400E);
      case ScamLikelihood.low:
        return const Color(0xFF166534);
      case ScamLikelihood.unknown:
        return const Color(0xFF374151);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Safety Check'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _future = RoomScamDetectorService.analyze(
                  roomId: widget.room.id,
                  listing: _listingFromRoom(widget.room),
                  forceRefresh: true,
                );
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<RoomScamAnalysis>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Could not run AI check right now.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'General safety tips:\n'
                    '• Insist on an inspection (or live video walkthrough)\n'
                    '• Never send bond/deposit before viewing and signing\n'
                    '• Use your state bond authority for bond lodgement\n'
                    '• Verify the address and the person’s identity',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _openScamwatch(context),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Report to Scamwatch (ACCC)'),
                  ),
                ],
              ),
            );
          }

          final analysis =
              snapshot.data ??
              RoomScamDetectorService.quickAssess(
                _listingFromRoom(widget.room),
              );
          final color = _colorFor(analysis.likelihood);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'AI Safety Check: ${analysis.likelihood.label}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Source: ${analysis.source}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                analysis.explanation,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 18),
              if (analysis.redFlags.isNotEmpty) ...[
                Text(
                  'Red flags',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...analysis.redFlags.map(
                  (flag) => ListTile(
                    dense: true,
                    leading: Icon(Icons.flag_outlined, color: color),
                    title: Text(flag),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                'What to do next',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                analysis.advice,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              if (analysis.saferAlternatives.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Safer alternatives',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...analysis.saferAlternatives
                    .take(6)
                    .map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: color)),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 18),
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
                        onPressed: () => _openScamwatch(context),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Scamwatch'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
 

class CreateRoomPage extends StatefulWidget {
  final void Function(Room) onRoomCreated;

  const CreateRoomPage({super.key, required this.onRoomCreated});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _securityService = SecurityService();
  final _imagePicker = ImagePicker();

  final _titleController = TextEditingController();
  final _suburbController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _landlordNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedCity = 'NSW';
  String _selectedRoomType = 'Private';
  final Set<String> _selectedAmenities = {};
  final List<XFile> _selectedPhotos = [];
  double? _latitude;
  double? _longitude;

  static const _cities = ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT'];
  static const _roomTypes = ['Private', 'Shared'];
  static const _amenitiesList = [
    'WiFi',
    'Furnished',
    'Air Conditioning',
    'Laundry',
    'Parking',
    'Kitchen',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _suburbController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _landlordNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Best-effort: prefill contact fields from signed-in user.
    populateContactControllers(
      nameController: _landlordNameController,
      phoneController: _phoneController,
      emailController: _emailController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List a Room')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a title'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _suburbController,
              decoration: const InputDecoration(labelText: 'Suburb *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a suburb'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              decoration: const InputDecoration(labelText: 'State *'),
              items: _cities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCity = v ?? 'NSW'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price per week *'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a price';
                return double.tryParse(v.trim()) == null
                    ? 'Enter a valid number'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedRoomType,
              decoration: const InputDecoration(labelText: 'Room type *'),
              items: _roomTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRoomType = v ?? 'Private'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description *'),
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a description'
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Amenities',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _amenitiesList.map((a) {
                final selected = _selectedAmenities.contains(a);
                return FilterChip(
                  label: Text(a),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedAmenities.add(a);
                      } else {
                        _selectedAmenities.remove(a);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Landlord Contact',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _landlordNameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
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
                    if (_selectedPhotos.isNotEmpty) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _selectedPhotos.length + 1,
                        itemBuilder: (context, idx) {
                          if (idx == _selectedPhotos.length) {
                            return InkWell(
                              onTap: _selectedPhotos.length < 5 ? _pickPhotos : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedPhotos.length < 5
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 28,
                                        color: _selectedPhotos.length < 5
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_selectedPhotos.length}/5',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: _selectedPhotos.length < 5
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final photo = _selectedPhotos[idx];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(photo.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stack) => Container(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    child: const Center(child: Icon(Icons.image_not_supported_outlined)),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedPhotos.removeAt(idx)),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedPhotos.length} photo${_selectedPhotos.length != 1 ? 's' : ''} added',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: _pickPhotos,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text('Add photos (${_selectedPhotos.length})'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tip: Add photos to help renters trust your listing.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Post Room'),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final photos = await _imagePicker.pickMultiImage();
    if (!mounted) return;
    setState(() {
      _selectedPhotos
        ..clear()
        ..addAll(photos);
    });
  }

  // _useCurrentLocation removed: location attachment from the UI disabled.

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final current = AuthState.currentUserId ?? 'guest';
    final allowed = await VerificationService.canPost(current);
    if (!allowed) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Only verified contributors may post rooms.')));
      return;
    }

    final room = Room(
      id: 'room_${DateTime.now().microsecondsSinceEpoch}',
      title: _securityService.sanitizeInput(_titleController.text),
      suburb: _securityService.sanitizeInput(_suburbController.text),
      city: _selectedCity,
      pricePerWeek: double.parse(_priceController.text.trim()),
      roomType: _selectedRoomType,
      description: _securityService.sanitizeInput(_descriptionController.text),
      address: _securityService.sanitizeInput(_addressController.text),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      landlordName: _securityService.sanitizeInput(_landlordNameController.text),
      photoUrl: _selectedPhotos.isNotEmpty ? _selectedPhotos.first.path : '',
      photoPaths: _selectedPhotos.map((p) => p.path).toList(),
      amenities: _selectedAmenities.toList(),
      createdBy: AuthState.currentUserId ?? 'guest',
      postedDate: DateTime.now(),
      latitude: _latitude,
      longitude: _longitude,
    );

    widget.onRoomCreated(room);
  }
}

class EditRoomPage extends StatefulWidget {
  final Room room;
  final void Function(Room) onRoomUpdated;

  const EditRoomPage({
    super.key,
    required this.room,
    required this.onRoomUpdated,
  });

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _securityService = SecurityService();
  final _imagePicker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _suburbController;
  late final TextEditingController _addressController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _landlordNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late String _selectedCity;
  late String _selectedRoomType;
  late final Set<String> _selectedAmenities;
  List<XFile> _selectedPhotos = [];
  double? _latitude;
  double? _longitude;

  static const _cities = ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT'];
  static const _roomTypes = ['Private', 'Shared'];
  static const _amenitiesList = [
    'WiFi',
    'Furnished',
    'Air Conditioning',
    'Laundry',
    'Parking',
    'Kitchen',
  ];

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _titleController = TextEditingController(text: room.title);
    _suburbController = TextEditingController(text: room.suburb);
    _addressController = TextEditingController(text: room.address);
    _priceController = TextEditingController(text: room.pricePerWeek.toStringAsFixed(0));
    _descriptionController = TextEditingController(text: room.description);
    _landlordNameController = TextEditingController(text: room.landlordName);
    _phoneController = TextEditingController(text: room.phoneNumber);
    _emailController = TextEditingController(text: room.email);
    _selectedCity = _cities.contains(room.city) && room.city.isNotEmpty ? room.city : _cities.first;
    _selectedRoomType = _roomTypes.contains(room.roomType) && room.roomType.isNotEmpty ? room.roomType : _roomTypes.first;
    _selectedAmenities = room.amenities.toSet();
    _latitude = room.latitude;
    _longitude = room.longitude;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _suburbController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _landlordNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Room')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a title'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _suburbController,
              decoration: const InputDecoration(labelText: 'Suburb *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a suburb'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              decoration: const InputDecoration(labelText: 'State *'),
              items: _cities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCity = v ?? _selectedCity),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price per week *'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a price';
                return double.tryParse(v.trim()) == null
                    ? 'Enter a valid number'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedRoomType,
              decoration: const InputDecoration(labelText: 'Room type *'),
              items: _roomTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedRoomType = v ?? _selectedRoomType),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description *'),
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a description'
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Amenities',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _amenitiesList.map((a) {
                final selected = _selectedAmenities.contains(a);
                return FilterChip(
                  label: Text(a),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedAmenities.add(a);
                      } else {
                        _selectedAmenities.remove(a);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Landlord Contact',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _landlordNameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text('Replace photos (${_selectedPhotos.length})'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Update room'),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final photos = await _imagePicker.pickMultiImage();
    if (!mounted) return;
    setState(() {
      _selectedPhotos = photos;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.room.copyWith(
      title: _securityService.sanitizeInput(_titleController.text),
      suburb: _securityService.sanitizeInput(_suburbController.text),
      city: _selectedCity,
      address: _securityService.sanitizeInput(_addressController.text),
      pricePerWeek: double.parse(_priceController.text.trim()),
      roomType: _selectedRoomType,
      description: _securityService.sanitizeInput(_descriptionController.text),
      landlordName: _securityService.sanitizeInput(_landlordNameController.text),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      amenities: _selectedAmenities.toList(),
      photoUrl: _selectedPhotos.isNotEmpty
          ? _selectedPhotos.first.path
          : widget.room.photoUrl,
      photoPaths: _selectedPhotos.isNotEmpty
          ? _selectedPhotos.map((p) => p.path).toList()
          : widget.room.photoPaths,
      latitude: _latitude,
      longitude: _longitude,
    );

    widget.onRoomUpdated(updated);
  }
}

class RoomFilterDialog extends StatefulWidget {
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final String initialKeyword;
  final String? initialRoomType;
  final String? initialSuburb;
  final String? initialCity;

  final VoidCallback onClearFilters;
  final void Function(
    double? minPrice,
    double? maxPrice,
    String keyword,
    String? roomType,
    String? suburb,
    String? city,
  ) onApplyFilters;

  const RoomFilterDialog({
    super.key,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.initialKeyword,
    required this.initialRoomType,
    required this.initialSuburb,
    required this.initialCity,
    required this.onClearFilters,
    required this.onApplyFilters,
  });

  @override
  State<RoomFilterDialog> createState() => _RoomFilterDialogState();
}

class _RoomFilterDialogState extends State<RoomFilterDialog> {
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  late final TextEditingController _keywordController;
  late final TextEditingController _suburbController;
  String? _roomType;
  String? _city;

  static const _cities = ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT'];
  static const _roomTypes = ['Private', 'Shared'];

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
      text: widget.initialMinPrice?.toStringAsFixed(0) ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialMaxPrice?.toStringAsFixed(0) ?? '',
    );
    _keywordController = TextEditingController(text: widget.initialKeyword);
    _suburbController = TextEditingController(text: widget.initialSuburb ?? '');
    _roomType = widget.initialRoomType;
    _city = widget.initialCity;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _keywordController.dispose();
    _suburbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Rooms'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _keywordController,
              decoration: const InputDecoration(labelText: 'Keyword'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min \$/week'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max \$/week'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _roomType,
              decoration: const InputDecoration(labelText: 'Room Type'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any')),
                ..._roomTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))),
              ],
              onChanged: (v) => setState(() => _roomType = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _city,
              decoration: const InputDecoration(labelText: 'State'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any')),
                ..._cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (v) => setState(() => _city = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _suburbController,
              decoration: const InputDecoration(labelText: 'Suburb'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onClearFilters,
          child: const Text(
            'Clear',
            style: TextStyle(color: Colors.red),
          ),
        ),
        FilledButton(
          onPressed: () {
            final minPrice = double.tryParse(_minPriceController.text.trim());
            final maxPrice = double.tryParse(_maxPriceController.text.trim());
            final keyword = _keywordController.text;
            final suburb = _suburbController.text.trim().isEmpty
                ? null
                : _suburbController.text.trim();
            widget.onApplyFilters(
              minPrice,
              maxPrice,
              keyword,
              _roomType,
              suburb,
              _city,
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

