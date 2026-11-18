class BusinessServiceModel {
  final int id;
  final String name;
  final String description;
  final String? priceDisplay;
  final String? imageUrl;
  final bool isAvailable;

  BusinessServiceModel({
    required this.id,
    required this.name,
    required this.description,
    this.priceDisplay,
    this.imageUrl,
    required this.isAvailable,
  });

  factory BusinessServiceModel.fromJson(Map<String, dynamic> json) {
    return BusinessServiceModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      priceDisplay: json['price_display'] ?? (json['price'] != null ? '₹${json['price']}' : null),
      imageUrl: json['image_url'] ?? json['image'],
      isAvailable: json['is_available'] ?? true,
    );
  }
}

class BusinessModel {
  final int id;
  final String name;
  final String slug;
  final String tagline;
  final String category;
  final String? categoryDisplay;
  final String description;
  final String phone;
  final String whatsapp;
  final String email;
  final String website;
  final String address;
  final String city;
  final String state;
  final String? mapsUrl;
  final String? logoUrl;
  final String? coverImageUrl;
  final bool isVerified;
  final bool isActive;
  final List<BusinessServiceModel> services;
  final String? qrImageUrl;

  BusinessModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.tagline,
    required this.category,
    this.categoryDisplay,
    required this.description,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.website,
    required this.address,
    required this.city,
    required this.state,
    this.mapsUrl,
    this.logoUrl,
    this.coverImageUrl,
    required this.isVerified,
    required this.isActive,
    this.services = const [],
    this.qrImageUrl,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    List<BusinessServiceModel> sList = [];
    if (json['services'] != null && json['services'] is List) {
      sList = (json['services'] as List).map((s) => BusinessServiceModel.fromJson(s)).toList();
    }

    String? qrImg;
    if (json['qr_code'] != null && json['qr_code'] is Map) {
      qrImg = json['qr_code']['qr_image_url'] ?? json['qr_code']['qr_image'];
    }

    return BusinessModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      tagline: json['tagline'] ?? '',
      category: json['category'] ?? 'other',
      categoryDisplay: json['category_display'],
      description: json['description'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      email: json['email'] ?? '',
      website: json['website'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      mapsUrl: json['maps_url'],
      logoUrl: json['logo_url'] ?? json['logo'],
      coverImageUrl: json['cover_image_url'] ?? json['cover_image'],
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      services: sList,
      qrImageUrl: qrImg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'tagline': tagline,
      'category': category,
      'category_display': categoryDisplay ?? categoryTitle,
      'description': description,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'website': website,
      'address': address,
      'city': city,
      'state': state,
      'maps_url': mapsUrl,
      'logo_url': logoUrl,
      'cover_image_url': coverImageUrl,
      'is_verified': isVerified,
      'is_active': isActive,
      'services': services.map((s) => {
        'id': s.id,
        'name': s.name,
        'description': s.description,
        'price_display': s.priceDisplay,
        'is_available': s.isAvailable,
      }).toList(),
      'qr_image_url': qrImageUrl,
    };
  }

  String get categoryEmoji {
    switch (category.toLowerCase()) {
      case 'catering':
      case 'food':
        return '🍽️';
      case 'photography':
      case 'video':
        return '📸';
      case 'decoration':
      case 'decor':
      case 'flowers':
        return '🎨';
      case 'dj':
      case 'music':
      case 'sound':
        return '🎵';
      case 'venue':
      case 'hall':
      case 'resort':
        return '🏰';
      case 'makeup':
      case 'styling':
      case 'beauty':
        return '💄';
      case 'planner':
      case 'coordinator':
        return '📋';
      case 'bakery':
      case 'cake':
        return '🎂';
      default:
        return '💼';
    }
  }

  String get categoryTitle {
    if (categoryDisplay != null && categoryDisplay!.isNotEmpty) {
      return categoryDisplay!;
    }
    switch (category.toLowerCase()) {
      case 'catering':
        return 'Catering & Food';
      case 'photography':
        return 'Photography & Video';
      case 'decoration':
        return 'Decoration & Florals';
      case 'dj':
        return 'DJ, Sound & Lights';
      case 'venue':
        return 'Banquets & Venues';
      case 'makeup':
        return 'Bridal Makeup & Hair';
      case 'planner':
        return 'Event Planners';
      case 'bakery':
        return 'Custom Cakes & Treats';
      default:
        return 'Event Vendor';
    }
  }
}
