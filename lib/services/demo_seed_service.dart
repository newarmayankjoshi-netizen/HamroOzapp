import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../auth_page.dart';

class DemoSeedResult {
  final int usersSeeded;
  final int roomsSeeded;
  final int jobsSeeded;
  final int itemsSeeded;

  const DemoSeedResult({
    required this.usersSeeded,
    required this.roomsSeeded,
    required this.jobsSeeded,
    required this.itemsSeeded,
  });
}

class DemoSeedService {
  static const int _userCount = 10;

  static List<User> buildDemoUsers() {
    final now = DateTime.now();

    const suburbs = <String>[
      'Parramatta',
      'Harris Park',
      'Auburn',
      'Blacktown',
      'Chatswood',
      'Hurstville',
      'Liverpool',
      'Bankstown',
      'Strathfield',
      'Ryde',
    ];

    const states = <String>['NSW', 'VIC', 'QLD', 'WA', 'SA'];

    final users = <User>[];
    for (var i = 1; i <= _userCount; i++) {
      final index = i - 1;
      final id = 'seed_user_${i.toString().padLeft(2, '0')}';
      final email = 'seed${i.toString().padLeft(2, '0')}@example.com';
      final name = 'Test User ${i.toString().padLeft(2, '0')}';
      final suburb = suburbs[index % suburbs.length];
      final state = states[index % states.length];

      users.add(
        User(
          id: id,
          email: email,
          passwordHash: 'seeded',
          name: name,
          phone: '+61 400 00${i.toString().padLeft(2, '0')} 00',
          state: state,
          location: '$suburb, $state',
          role: index % 3 == 0 ? 'Student' : 'Worker',
          badges: index % 4 == 0
              ? const ['verified']
              : (index % 5 == 0 ? const ['trusted'] : const []),
          rating: 4.0 + ((index % 5) * 0.2),
          ratingCount: 3 + (index % 12),
          showPhone: true,
          showEmail: false,
          createdAt: now.subtract(Duration(days: 30 + index * 7)),
        ),
      );
    }

    return users;
  }

  static Future<DemoSeedResult> seed({bool writeFirestore = true}) async {
    final users = buildDemoUsers();
    AuthService.upsertUsers(users);

    if (!writeFirestore || Firebase.apps.isEmpty) {
      return DemoSeedResult(
        usersSeeded: users.length,
        roomsSeeded: 0,
        jobsSeeded: 0,
        itemsSeeded: 0,
      );
    }

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final now = DateTime.now();

    for (var i = 0; i < users.length; i++) {
      final user = users[i];
      final isClosedVariant = i % 4 == 0;

      // Seed a Firestore user doc (badges are system-assigned; do not write badges here).
      batch.set(firestore.collection('users').doc(user.id), {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'state': user.state,
        'location': user.location,
        'role': user.role,
        'showPhone': user.showPhone,
        'showEmail': user.showEmail,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'phoneVerified': false,
        'emailVerified': false,
        'idUploaded': false,
        'reportsCount': 0,
      }, SetOptions(merge: true));

      final roomId = 'seed_room_${user.id}';
      batch.set(
        firestore.collection('community_rooms').doc(roomId),
        {
          'title': 'Room near ${user.location ?? 'Sydney'}',
          'suburb': (user.location ?? 'Sydney').split(',').first.trim(),
          'city': 'Sydney',
          'pricePerWeek': 250 + (i * 10),
          'roomType': i % 2 == 0 ? 'Single' : 'Shared',
          'description':
              'Seed room listing for testing public profile cards and stats.',
          'address': '123 Example St',
          'phoneNumber': user.phone ?? '',
          'email': user.email,
          'landlordName': user.name,
          'photoUrl': 'assets/room_placeholder.jpg',
          'photoUrls': <String>[],
          'amenities': <String>['WiFi', 'Bills included'],
          'createdBy': user.id,
          'postedDate': Timestamp.fromDate(now.subtract(Duration(days: i))),
          'viewCount': i * 2,
          'isClosed': isClosedVariant,
        },
        SetOptions(merge: true),
      );

      final jobId = 'seed_job_${user.id}';
      batch.set(firestore.collection('community_jobs').doc(jobId), {
        'title': i % 2 == 0 ? 'Kitchen Hand' : 'Retail Assistant',
        'company': 'Seed Company ${i + 1}',
        'location': user.location ?? 'Sydney, NSW',
        'description':
            'Seed job listing for testing public profile cards and stats.',
        'jobType': i % 3 == 0 ? 'Casual' : 'Part-time',
        'salary': i % 3 == 0 ? r'$25/hr' : r'$55k - $65k',
        'phoneNumber': user.phone ?? '',
        'email': user.email,
        'category': i % 2 == 0 ? 'Hospitality' : 'Retail',
        'sourceUrl': '',
        'imageUrl': '',
        'createdBy': user.id,
        'postedDate': Timestamp.fromDate(now.subtract(Duration(days: i + 1))),
        'viewCount': i,
        'isClosed': i % 6 == 0,
      }, SetOptions(merge: true));

      final itemId = 'seed_item_${user.id}';
      batch.set(
        firestore.collection('marketplace_items').doc(itemId),
        {
          'title': i % 2 == 0 ? 'Used Bicycle' : 'Study Desk',
          'description':
              'Seed marketplace item for testing seller public profile cards.',
          'price': 60.0 + (i * 5),
          'category': i % 2 == 0 ? 'Other' : 'Furniture',
          'condition': i % 3 == 0 ? 'Like New' : 'Good',
          'location': user.location ?? 'Sydney',
          'sellerId': user.id,
          'sellerName': user.name,
          'sellerPhone': user.phone,
          'postedDate': Timestamp.fromDate(
            now.subtract(Duration(hours: i * 6)),
          ),
          'images': <String>[],
          'viewCount': i * 3,
          'isClosed': i % 5 == 0,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    return DemoSeedResult(
      usersSeeded: users.length,
      roomsSeeded: users.length,
      jobsSeeded: users.length,
      itemsSeeded: users.length,
    );
  }

  static Future<void> clear({bool clearFirestore = true}) async {
    if (!clearFirestore || Firebase.apps.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (var i = 1; i <= _userCount; i++) {
      final userId = 'seed_user_${i.toString().padLeft(2, '0')}';
      batch.delete(firestore.collection('users').doc(userId));
      batch.delete(
        firestore.collection('community_rooms').doc('seed_room_$userId'),
      );
      batch.delete(
        firestore.collection('community_jobs').doc('seed_job_$userId'),
      );
      batch.delete(
        firestore.collection('marketplace_items').doc('seed_item_$userId'),
      );
    }

    await batch.commit();
  }
}
