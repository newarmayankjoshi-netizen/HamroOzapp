import 'dart:convert';

String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

class OwnerMenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String photoUrl;
  final bool available;
  final bool isDailySpecial;

  const OwnerMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.photoUrl,
    required this.available,
    required this.isDailySpecial,
  });

  factory OwnerMenuItem.create() {
    return const OwnerMenuItem(
      id: '',
      name: '',
      description: '',
      price: 0,
      photoUrl: '',
      available: true,
      isDailySpecial: false,
    );
  }

  OwnerMenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? photoUrl,
    bool? available,
    bool? isDailySpecial,
  }) {
    return OwnerMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      photoUrl: photoUrl ?? this.photoUrl,
      available: available ?? this.available,
      isDailySpecial: isDailySpecial ?? this.isDailySpecial,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'photoUrl': photoUrl,
        'available': available,
        'isDailySpecial': isDailySpecial,
      };

  factory OwnerMenuItem.fromJson(Map<String, dynamic> json) {
    return OwnerMenuItem(
      id: (json['id'] as String?) ?? _newId(),
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      photoUrl: (json['photoUrl'] as String?) ?? '',
      available: (json['available'] as bool?) ?? true,
      isDailySpecial: (json['isDailySpecial'] as bool?) ?? false,
    );
  }
}

class OwnerPromotion {
  final String id;
  final String title;
  final String details;
  final String validUntil;

  const OwnerPromotion({
    required this.id,
    required this.title,
    required this.details,
    required this.validUntil,
  });

  OwnerPromotion copyWith({
    String? id,
    String? title,
    String? details,
    String? validUntil,
  }) {
    return OwnerPromotion(
      id: id ?? this.id,
      title: title ?? this.title,
      details: details ?? this.details,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'details': details,
        'validUntil': validUntil,
      };

  factory OwnerPromotion.fromJson(Map<String, dynamic> json) {
    return OwnerPromotion(
      id: (json['id'] as String?) ?? _newId(),
      title: (json['title'] as String?) ?? '',
      details: (json['details'] as String?) ?? '',
      validUntil: (json['validUntil'] as String?) ?? '',
    );
  }
}

class OwnerLoyaltyConfig {
  final int stampsNeeded;
  final String reward;
  final String comebackMessage;

  const OwnerLoyaltyConfig({
    required this.stampsNeeded,
    required this.reward,
    required this.comebackMessage,
  });

  Map<String, dynamic> toJson() => {
        'stampsNeeded': stampsNeeded,
        'reward': reward,
        'comebackMessage': comebackMessage,
      };

  factory OwnerLoyaltyConfig.fromJson(Map<String, dynamic> json) {
    return OwnerLoyaltyConfig(
      stampsNeeded: (json['stampsNeeded'] as num?)?.toInt() ?? 10,
      reward: (json['reward'] as String?) ?? 'Free momo (10 stamps)',
      comebackMessage:
          (json['comebackMessage'] as String?) ?? 'Come back soon!',
    );
  }

  OwnerLoyaltyConfig copyWith({
    int? stampsNeeded,
    String? reward,
    String? comebackMessage,
  }) {
    return OwnerLoyaltyConfig(
      stampsNeeded: stampsNeeded ?? this.stampsNeeded,
      reward: reward ?? this.reward,
      comebackMessage: comebackMessage ?? this.comebackMessage,
    );
  }
}

class OwnerRestaurantProfile {
  final String id;
  final String ownerUserId;
  final String name;
  final String address;
  final String phone;
  final String website;
  final String story;
  final double rating;
  final String reviewsUrl;
  final String reviewHighlights;
  final List<OwnerMenuItem> menu;
  final List<OwnerPromotion> promotions;
  final String bookingUrl;
  final String orderUrl;
  final OwnerLoyaltyConfig loyalty;

  const OwnerRestaurantProfile({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.address,
    required this.phone,
    required this.website,
    required this.story,
    required this.rating,
    required this.reviewsUrl,
    required this.reviewHighlights,
    required this.menu,
    required this.promotions,
    required this.bookingUrl,
    required this.orderUrl,
    required this.loyalty,
  });

  factory OwnerRestaurantProfile.create() {
    return OwnerRestaurantProfile(
      id: _newId(),
      ownerUserId: '',
      name: '',
      address: '',
      phone: '',
      website: '',
      story: '',
      rating: 0,
      reviewsUrl: '',
      reviewHighlights: '',
      menu: const [],
      promotions: const [],
      bookingUrl: '',
      orderUrl: '',
      loyalty: const OwnerLoyaltyConfig(
        stampsNeeded: 10,
        reward: 'Free momo (10 stamps)',
        comebackMessage: 'Come back soon! Show this message for a surprise.',
      ),
    );
  }

  OwnerRestaurantProfile copyWith({
    String? id,
    String? ownerUserId,
    String? name,
    String? address,
    String? phone,
    String? website,
    String? story,
    double? rating,
    String? reviewsUrl,
    String? reviewHighlights,
    List<OwnerMenuItem>? menu,
    List<OwnerPromotion>? promotions,
    String? bookingUrl,
    String? orderUrl,
    OwnerLoyaltyConfig? loyalty,
  }) {
    return OwnerRestaurantProfile(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      story: story ?? this.story,
      rating: rating ?? this.rating,
      reviewsUrl: reviewsUrl ?? this.reviewsUrl,
      reviewHighlights: reviewHighlights ?? this.reviewHighlights,
      menu: menu ?? this.menu,
      promotions: promotions ?? this.promotions,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      orderUrl: orderUrl ?? this.orderUrl,
      loyalty: loyalty ?? this.loyalty,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
      'ownerUserId': ownerUserId,
        'name': name,
        'address': address,
        'phone': phone,
        'website': website,
        'story': story,
      'rating': rating,
      'reviewsUrl': reviewsUrl,
      'reviewHighlights': reviewHighlights,
        'menu': menu.map((e) => e.toJson()).toList(),
        'promotions': promotions.map((e) => e.toJson()).toList(),
        'bookingUrl': bookingUrl,
        'orderUrl': orderUrl,
        'loyalty': loyalty.toJson(),
      };

  factory OwnerRestaurantProfile.fromJson(Map<String, dynamic> json) {
    final menuJson = (json['menu'] as List?) ?? const [];
    final promosJson = (json['promotions'] as List?) ?? const [];

    return OwnerRestaurantProfile(
      id: (json['id'] as String?) ?? _newId(),
      ownerUserId: (json['ownerUserId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      website: (json['website'] as String?) ?? '',
      story: (json['story'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsUrl: (json['reviewsUrl'] as String?) ?? '',
      reviewHighlights: (json['reviewHighlights'] as String?) ?? '',
      menu: menuJson
          .whereType<Map>()
          .map((e) => OwnerMenuItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      promotions: promosJson
          .whereType<Map>()
          .map((e) => OwnerPromotion.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      bookingUrl: (json['bookingUrl'] as String?) ?? '',
      orderUrl: (json['orderUrl'] as String?) ?? '',
      loyalty: json['loyalty'] is Map
          ? OwnerLoyaltyConfig.fromJson(
              Map<String, dynamic>.from(json['loyalty'] as Map),
            )
          : const OwnerLoyaltyConfig(
              stampsNeeded: 10,
              reward: 'Free momo (10 stamps)',
              comebackMessage: 'Come back soon!',
            ),
    );
  }

  static List<OwnerRestaurantProfile> listFromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => OwnerRestaurantProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static String listToJsonString(List<OwnerRestaurantProfile> profiles) {
    return jsonEncode(profiles.map((e) => e.toJson()).toList());
  }
}
