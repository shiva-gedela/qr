import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/event_model.dart';
import '../models/business_model.dart';
import '../models/subscription_model.dart';
import '../models/booking_model.dart';
import '../models/social_post_model.dart';

class ApiConnectionException implements Exception {
  final String message;
  ApiConnectionException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static Future<bool> testConnection(String url) async {
    try {
      String clean = url.trim();
      if (clean.endsWith('/')) clean = clean.substring(0, clean.length - 1);
      final response = await http.get(Uri.parse('$clean/api/events/')).timeout(const Duration(seconds: 4));
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // Events API
  static Future<List<EventModel>> getEvents() async {
    final prefs = await SharedPreferences.getInstance();

    // Load locally created events
    final localEventsRaw = prefs.getStringList('local_created_events') ?? [];
    final List<EventModel> localEvents = [];
    for (final raw in localEventsRaw) {
      try {
        localEvents.add(EventModel.fromJson(jsonDecode(raw)));
      } catch (_) {}
    }

    try {
      final response = await http.get(
        Uri.parse(AppConstants.eventsUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List results = decoded is List ? decoded : (decoded['results'] ?? []);
        final serverEvents = results.map((e) => EventModel.fromJson(e)).toList();
        await prefs.setString('cached_events', jsonEncode(results));
        return [...localEvents, ...serverEvents];
      }
    } catch (_) {
      // Offline fallback
    }

    final cached = prefs.getString('cached_events');
    if (cached != null) {
      try {
        final List decoded = jsonDecode(cached);
        final list = decoded.map((e) => EventModel.fromJson(e)).toList();
        return [...localEvents, ...list];
      } catch (_) {}
    }

    return [...localEvents, ..._getOfflineDemoEvents()];
  }

  static Future<List<EventModel>> getCheckInEvents() async {
    try {
      final events = <EventModel>[];
      final baseUri = Uri.parse(AppConstants.eventsUrl);
      String? nextUrl = baseUri.toString();
      final response = await http.get(
        Uri.parse(nextUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List results = decoded is List ? decoded : (decoded['results'] ?? []);
        events.addAll(results.map((event) => EventModel.fromJson(event)));
        if (events.isNotEmpty) return events;
      }
    } catch (_) {}
    return getEvents();
  }

  static Future<Map<String, dynamic>> verifyInvitation(int eventId, String token) async {
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('${AppConstants.eventsUrl}$eventId/check-in/'),
        headers: await _getHeaders(),
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 10));
    } on SocketException catch (error) {
      throw ApiConnectionException(error.message);
    } on TimeoutException {
      throw ApiConnectionException('Connection timed out.');
    } on http.ClientException catch (error) {
      throw ApiConnectionException(error.message);
    }
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(decoded['detail'] ?? 'Check-in failed (HTTP ${response.statusCode})');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static Future<Map<String, dynamic>> getCheckInSummary(int eventId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.eventsUrl}$eventId/check-in/'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Unable to load check-in summary (HTTP ${response.statusCode})');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  static Future<void> queuePendingCheckIn(int eventId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_check_ins') ?? [];
    final entry = jsonEncode({'event_id': eventId, 'token': token});
    final exists = pending.any((item) {
      final decoded = jsonDecode(item);
      return decoded['event_id'] == eventId && decoded['token'] == token;
    });
    if (!exists) pending.add(entry);
    await prefs.setStringList('pending_check_ins', pending);
  }

  static Future<int> pendingCheckInCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('pending_check_ins') ?? []).length;
  }

  static Future<List<Map<String, dynamic>>> syncPendingCheckIns() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_check_ins') ?? [];
    final remaining = <String>[];
    final results = <Map<String, dynamic>>[];
    for (final item in pending) {
      final scan = Map<String, dynamic>.from(jsonDecode(item));
      try {
        final result = await verifyInvitation(scan['event_id'] as int, scan['token'] as String);
        results.add({'scan': scan, 'result': result});
      } catch (error) {
        remaining.add(item);
        results.add({'scan': scan, 'error': error.toString()});
      }
    }
    await prefs.setStringList('pending_check_ins', remaining);
    return results;
  }

  static Future<EventModel> createEvent(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final slug = 'event-${DateTime.now().millisecondsSinceEpoch}';
    final targetUrl = 'https://${AppConstants.appWebsite}/events/e/$slug/';

    try {
      final response = await http.post(
        Uri.parse(AppConstants.eventsUrl),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 201) {
        return EventModel.fromJson(jsonDecode(response.body));
      }
    } catch (_) {
      // Offline fallback
    }

    final venueName = data['venue_name'] as String? ?? 'Celebration Venue';
    final venueAddress = data['venue_address'] as String? ?? '';
    final encodedQuery = Uri.encodeComponent('$venueName $venueAddress'.trim());

    final localEvent = EventModel(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: data['title'] ?? 'My Event',
      slug: slug,
      eventType: data['event_type'] ?? 'wedding',
      hostNames: data['host_names'] ?? 'Host',
      description: data['description'] ?? '',
      eventDate: data['event_date'] ?? DateTime.now().toString().split(' ')[0],
      eventTime: data['event_time'] ?? '10:00:00',
      venueName: venueName,
      venueAddress: venueAddress,
      googleMapsUrl: data['maps_url'] ?? 'https://maps.google.com/?q=$encodedQuery',
      googleMapsDirectionsUrl: 'https://maps.google.com/maps/dir/?api=1&destination=$encodedQuery',
      instagramUrl: data['instagram_url'],
      youtubeUrl: data['youtube_url'],
      eventHashtag: data['event_hashtag'],
      dressCode: data['dress_code'],
      isPublished: true,
      targetUrl: targetUrl,
    );

    final localList = prefs.getStringList('local_created_events') ?? [];
    localList.insert(0, jsonEncode(localEvent.toJson()));
    await prefs.setStringList('local_created_events', localList);

    return localEvent;
  }

  // Business / Vendor API
  static Future<List<BusinessModel>> getBusinesses() async {
    final prefs = await SharedPreferences.getInstance();
    final localVendorsRaw = prefs.getStringList('local_created_vendors') ?? [];
    final List<BusinessModel> localVendors = [];
    for (final raw in localVendorsRaw) {
      try {
        localVendors.add(BusinessModel.fromJson(jsonDecode(raw)));
      } catch (_) {}
    }

    try {
      final response = await http.get(
        Uri.parse(AppConstants.businessUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List results = decoded is List ? decoded : (decoded['results'] ?? []);
        final serverVendors = results.map((b) => BusinessModel.fromJson(b)).toList();
        return [...localVendors, ...serverVendors];
      }
    } catch (_) {}

    if (localVendors.isNotEmpty) {
      return [...localVendors, ..._getOfflineDemoVendors()];
    }
    return _getOfflineDemoVendors();
  }

  static Future<BusinessModel> createBusiness({
    required String name,
    required String category,
    required String tagline,
    required String phone,
    required String whatsapp,
    String email = '',
    String website = '',
    required String address,
    required String city,
    String state = 'Karnataka',
    String description = '',
    List<BusinessServiceModel> services = const [],
  }) async {
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final newVendor = BusinessModel(
      id: id,
      name: name,
      slug: '$slug-$id',
      tagline: tagline,
      category: category,
      categoryDisplay: null,
      description: description,
      phone: phone,
      whatsapp: whatsapp.isNotEmpty ? whatsapp : phone,
      email: email,
      website: website,
      address: address,
      city: city,
      state: state,
      isVerified: true,
      isActive: true,
      services: services,
      qrImageUrl: null,
    );

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    final localVendorsRaw = prefs.getStringList('local_created_vendors') ?? [];
    localVendorsRaw.insert(0, jsonEncode(newVendor.toJson()));
    await prefs.setStringList('local_created_vendors', localVendorsRaw);

    // Attempt server sync if possible
    try {
      await http.post(
        Uri.parse(AppConstants.businessUrl),
        headers: await _getHeaders(),
        body: jsonEncode(newVendor.toJson()),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return newVendor;
  }

  static List<BusinessModel> _getOfflineDemoVendors() {
    return [
      BusinessModel(
        id: 101,
        name: 'Royal Feast Caterers',
        slug: 'royal-feast-caterers',
        tagline: '5-Star Traditional & International Wedding Menus',
        category: 'catering',
        description: 'Over 15 years serving exquisite multi-cuisine banquets, live chat counters, and desserts for grand celebrations.',
        phone: '+91 98450 12345',
        whatsapp: '+91 98450 12345',
        email: 'info@royalfeastcaterers.in',
        website: 'https://qroutex.com/v/royal-feast',
        address: 'MG Road, Central Bengaluru',
        city: 'Bengaluru',
        state: 'Karnataka',
        isVerified: true,
        isActive: true,
        services: [
          BusinessServiceModel(id: 1, name: 'Royal Gold Banquet Buffet', description: 'Complete 7-course multi-cuisine buffet spread', priceDisplay: '₹750 / plate', isAvailable: true),
          BusinessServiceModel(id: 2, name: 'Live Chaat & Dessert Counter', description: '8 interactive live food and beverage stations', priceDisplay: '₹250 / plate', isAvailable: true),
        ],
      ),
      BusinessModel(
        id: 102,
        name: 'Lumière Wedding Studios',
        slug: 'lumiere-wedding-studios',
        tagline: 'Cinematic Wedding & Candid Pre-Shoot Photography',
        category: 'photography',
        description: 'Award-winning photojournalists capturing timeless emotion, cinematic 4K video, drone footage, and luxury albums.',
        phone: '+91 98860 67890',
        whatsapp: '+91 98860 67890',
        email: 'contact@lumierephotos.com',
        website: 'https://qroutex.com/v/lumiere-studios',
        address: 'Indiranagar 100ft Road',
        city: 'Bengaluru',
        state: 'Karnataka',
        isVerified: true,
        isActive: true,
        services: [
          BusinessServiceModel(id: 3, name: 'Complete 2-Day Wedding Package', description: 'Traditional + Candid + 4K Teaser Film + Drone', priceDisplay: '₹1,25,000', isAvailable: true),
          BusinessServiceModel(id: 4, name: 'Pre-Wedding Outdoor Shoot', description: 'Full day shoot at 2 scenic locations with stylist', priceDisplay: '₹35,000', isAvailable: true),
        ],
      ),
      BusinessModel(
        id: 103,
        name: 'Flora Magic Decor & Mandap',
        slug: 'flora-magic-decor',
        tagline: 'Exotic Floral Stage, Mandap & Fairytale Lighting',
        category: 'decoration',
        description: 'Customized luxury theme setups, eco-friendly floral mandaps, fairy light tunnels, and grand reception stages.',
        phone: '+91 98765 11223',
        whatsapp: '+91 98765 11223',
        email: 'hello@floramagic.in',
        website: 'https://qroutex.com/v/flora-magic',
        address: 'Koramangala 4th Block',
        city: 'Bengaluru',
        state: 'Karnataka',
        isVerified: true,
        isActive: true,
        services: [
          BusinessServiceModel(id: 5, name: 'Grand Royal Mandap & Stage', description: 'Fresh imported florals, crystal chandeliers & velvet backdrop', priceDisplay: '₹85,000', isAvailable: true),
        ],
      ),
      BusinessModel(
        id: 104,
        name: 'DJ SoundVibe & Live Band',
        slug: 'dj-soundvibe',
        tagline: 'High-Energy Bollywood, Punjabi & EDM Sangeet DJ',
        category: 'dj',
        description: 'Professional sound engineering, JBL line array systems, concert lighting, and top celebrity DJs.',
        phone: '+91 99112 33445',
        whatsapp: '+91 99112 33445',
        email: 'bookings@djsoundvibe.com',
        website: 'https://qroutex.com/v/soundvibe',
        address: 'HSR Layout Sector 2',
        city: 'Bengaluru',
        state: 'Karnataka',
        isVerified: true,
        isActive: true,
        services: [
          BusinessServiceModel(id: 6, name: 'Sangeet & Cocktail DJ Setup', description: '5 hours live DJ performance + dual truss intelligent lights', priceDisplay: '₹40,000', isAvailable: true),
        ],
      ),
      BusinessModel(
        id: 105,
        name: 'The Grand Heritage Palace & Lawn',
        slug: 'grand-heritage-palace',
        tagline: '1,500 Guest Capacity Luxury Convention Lawn & AC Hall',
        category: 'venue',
        description: 'Sprawling green lawns, 50,000 sq ft pillarless AC hall, 20 air-conditioned guest suites, and valet parking for 400 cars.',
        phone: '+91 98440 99887',
        whatsapp: '+91 98440 99887',
        email: 'events@grandheritagepalace.com',
        website: 'https://qroutex.com/v/grand-heritage',
        address: 'Hebbal, Near Airport Expressway',
        city: 'Bengaluru',
        state: 'Karnataka',
        isVerified: true,
        isActive: true,
        services: [
          BusinessServiceModel(id: 7, name: 'Full Day Hall & Lawn Rental', description: 'Includes 10 guest rooms, electricity backup & valet', priceDisplay: '₹2,50,000 / day', isAvailable: true),
        ],
      ),
    ];
  }

  static Future<BusinessModel> getPublicBusiness(String slug) async {
    final response = await http.get(
      Uri.parse('${AppConstants.businessUrl}public/$slug/'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      return BusinessModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Business profile not found');
    }
  }

  // Subscriptions API
  static Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.subscriptionsUrl}plans/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List results = decoded is List ? decoded : (decoded['results'] ?? []);
        return results.map((p) => SubscriptionPlanModel.fromJson(p)).toList();
      }
    } catch (_) {}
    return [];
  }

  static List<EventModel> _getOfflineDemoEvents() {
    return [
      EventModel(
        id: 1,
        title: 'Priya & Rahul Grand Wedding',
        slug: 'test-wedding-event',
        eventType: 'wedding',
        eventDate: '2026-12-15',
        eventTime: '10:00:00',
        venueName: 'The Leela Palace Ballroom',
        venueAddress: 'Old Airport Road, Kodihalli, Bengaluru, Karnataka 560008',
        hostNames: 'Sharma & Gupta Families',
        description: 'Join us to celebrate the wedding ceremony of Priya and Rahul.',
        isPublished: true,
        instagramUrl: 'https://instagram.com/priyawedsrahul',
        eventHashtag: '#PriyaWedsRahul',
        dressCode: 'Royal Traditional Indian Attire',
        coverImageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&q=80',
        capacity: 350,
        guestCount: 280,
        targetUrl: 'https://qroutex.com/events/e/test-wedding-event/',
        googleMapsDirectionsUrl: 'https://maps.google.com/?q=The+Leela+Palace+Bengaluru',
      ),
      EventModel(
        id: 2,
        title: 'Aarav 1st Birthday Celebration',
        slug: 'test-birthday-event',
        eventType: 'birthday',
        eventDate: '2026-11-25',
        eventTime: '17:30:00',
        venueName: 'Taj Krishna Grand Hall',
        venueAddress: 'Road No 1, Banjara Hills, Hyderabad, Telangana 500034',
        hostNames: 'Pooja & Rajesh',
        description: 'Celebrate Aarav turning one with cake and fun activities.',
        isPublished: true,
        eventHashtag: '#AaravTurnsOne',
        dressCode: 'Smart Casual / Pastel',
        coverImageUrl: 'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=800&q=80',
        capacity: 120,
        guestCount: 95,
        targetUrl: 'https://qroutex.com/events/e/test-birthday-event/',
        googleMapsDirectionsUrl: 'https://maps.google.com/?q=Taj+Krishna+Hyderabad',
      ),
      EventModel(
        id: 3,
        title: 'Sneha & Amit Ring Ceremony',
        slug: 'test-engagement-event',
        eventType: 'engagement',
        eventDate: '2026-12-05',
        venueName: 'JW Marriott Banquets',
        venueAddress: 'Senapati Bapat Marg, Lower Parel, Mumbai, Maharashtra 400013',
        hostNames: 'Mehta & Kapoor Families',
        description: 'Ring exchange and cocktail dinner.',
        isPublished: true,
        eventHashtag: '#SnehaAmitForever',
        coverImageUrl: 'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?w=800&q=80',
        capacity: 200,
        guestCount: 160,
        targetUrl: 'https://qroutex.com/events/e/test-engagement-event/',
        googleMapsDirectionsUrl: 'https://maps.google.com/?q=JW+Marriott+Mumbai',
      ),
      EventModel(
        id: 4,
        title: '25th Silver Jubilee Anniversary',
        slug: 'test-anniversary-event',
        eventType: 'anniversary',
        eventDate: '2026-12-28',
        venueName: 'ITC Grand Chola Banquet',
        venueAddress: '63 Mount Road, Guindy, Chennai, Tamil Nadu 600032',
        hostNames: 'Children & Family',
        description: 'Celebrating 25 years of love and companionship.',
        isPublished: true,
        coverImageUrl: 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=800&q=80',
        capacity: 150,
        guestCount: 120,
        targetUrl: 'https://qroutex.com/events/e/test-anniversary-event/',
        googleMapsDirectionsUrl: 'https://maps.google.com/?q=ITC+Grand+Chola+Chennai',
      ),
      EventModel(
        id: 5,
        title: 'New Sweet Home - Griha Pravesh',
        slug: 'test-housewarming-event',
        eventType: 'housewarming',
        eventDate: '2026-12-10',
        venueName: 'Villa 42, Palm Meadows',
        venueAddress: 'Whitefield Main Road, Bengaluru, Karnataka 560066',
        hostNames: 'Sunita & Ramesh',
        description: 'Pooja followed by lunch at our new home.',
        isPublished: true,
        coverImageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
        capacity: 80,
        guestCount: 65,
        targetUrl: 'https://qroutex.com/events/e/test-housewarming-event/',
        googleMapsDirectionsUrl: 'https://maps.google.com/?q=Palm+Meadows+Bengaluru',
      ),
      EventModel(
        id: 6,
        title: 'Doctorate Celebration of Dr. Vikram',
        slug: 'test-graduation-event',
        eventType: 'graduation',
        eventDate: '2026-12-20',
        venueName: 'Senate Convocation Pavilion',
        venueAddress: 'University Campus, Connaught Place, New Delhi 110001',
        hostNames: 'Dr. Vikram & Proud Parents',
        description: 'Celebration of Vikram achieving his Ph.D.',
        isPublished: true,
        coverImageUrl: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800&q=80',
        capacity: 100,
        guestCount: 80,
        targetUrl: 'https://qroutex.com/events/e/test-graduation-event/',
        googleMapsDirectionsUrl: 'https://maps.google.com/?q=Delhi+University+Senate',
      ),
    ];
  }

  // ══ Restaurant & Business Bookings ════════════════════════════════════════
  static Future<bool> createBooking(BookingModel booking) async {
    final prefs = await SharedPreferences.getInstance();
    final listRaw = prefs.getStringList('user_bookings') ?? [];
    listRaw.insert(0, jsonEncode(booking.toJson()));
    await prefs.setStringList('user_bookings', listRaw);

    // Attempt backend sync
    try {
      await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/business/${booking.businessId}/bookings/'),
        headers: await _getHeaders(),
        body: jsonEncode(booking.toJson()),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}

    return true;
  }

  static Future<List<BookingModel>> getUserBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final listRaw = prefs.getStringList('user_bookings') ?? [];
    if (listRaw.isNotEmpty) {
      final list = <BookingModel>[];
      for (final raw in listRaw) {
        try {
          list.add(BookingModel.fromJson(jsonDecode(raw)));
        } catch (_) {}
      }
      return list;
    }

    // Default seed booking for demonstration
    final demoBooking = BookingModel(
      id: 'BK-${DateTime.now().millisecondsSinceEpoch % 10000}',
      businessId: 1,
      businessName: 'Royal Spice Banquet & Restaurant',
      businessCategory: 'Restaurant & Dining',
      serviceName: 'VIP Table Reservation (4 Guests)',
      servicePrice: 1200.0,
      date: 'Tomorrow, 08:00 PM',
      timeSlot: '08:00 PM - 10:00 PM',
      guestsCount: 4,
      status: 'confirmed',
      specialRequests: 'Near window seat with celebration dessert',
      customerName: 'Shiva Gedela',
      customerPhone: '+91 98765 43210',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    );
    await createBooking(demoBooking);
    return [demoBooking];
  }

  static Future<bool> cancelBooking(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final listRaw = prefs.getStringList('user_bookings') ?? [];
    final updated = <String>[];
    for (final raw in listRaw) {
      try {
        final data = jsonDecode(raw);
        if (data['id'] == bookingId) {
          data['status'] = 'cancelled';
          updated.add(jsonEncode(data));
        } else {
          updated.add(raw);
        }
      } catch (_) {
        updated.add(raw);
      }
    }
    await prefs.setStringList('user_bookings', updated);
    return true;
  }

  // ══ Social Feed & Moments ════════════════════════════════════════════════
  static Future<List<SocialPostModel>> getSocialPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('social_posts') ?? [];
    if (raw.isNotEmpty) {
      final list = <SocialPostModel>[];
      for (final r in raw) {
        try {
          list.add(SocialPostModel.fromJson(jsonDecode(r)));
        } catch (_) {}
      }
      return list;
    }

    // Seed realistic social posts
    final seedPosts = [
      SocialPostModel(
        id: 'post_1',
        userName: 'Priya & Rahul',
        userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
        eventTitle: 'Priya & Rahul Grand Wedding',
        eventTag: '#PriyaWedsRahul',
        caption: 'The most magical evening of our lives! Thank you everyone for scanning and joining via QRouteX GPS routes! ✨💍❤️',
        imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&q=80',
        likesCount: 142,
        isLiked: false,
        comments: [
          SocialCommentModel(id: 'c1', userName: 'Ananya', text: 'Stunning couple! Loved the instant QR entry!', createdAt: DateTime.now().subtract(const Duration(hours: 4))),
          SocialCommentModel(id: 'c2', userName: 'Karthik', text: 'Congratulations both of you!! 🎉', createdAt: DateTime.now().subtract(const Duration(hours: 2))),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      SocialPostModel(
        id: 'post_2',
        userName: 'Aarav’s Parents',
        userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
        eventTitle: 'Aarav turns 5! Superhero Bash',
        eventTag: '#AaravTurnsFive',
        caption: 'Spiderman arrived! Kids had a blast at the superhero birthday bash! 🦸‍♂️🎂🎈',
        imageUrl: 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=800&q=80',
        likesCount: 89,
        isLiked: true,
        comments: [
          SocialCommentModel(id: 'c3', userName: 'Divya', text: 'Happy birthday little champion! 🎈', createdAt: DateTime.now().subtract(const Duration(hours: 5))),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      SocialPostModel(
        id: 'post_3',
        userName: 'Dr. Vikram',
        userAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
        eventTitle: 'Doctorate Celebration',
        eventTag: '#DrVikramPhD',
        caption: 'Years of hard work encapsulated in this beautiful moment with family and mentors. 🎓✨',
        imageUrl: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800&q=80',
        likesCount: 215,
        isLiked: false,
        comments: [],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    await prefs.setStringList('social_posts', seedPosts.map((p) => jsonEncode(p.toJson())).toList());
    return seedPosts;
  }

  static Future<bool> createSocialPost(SocialPostModel post) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSocialPosts();
    list.insert(0, post);
    await prefs.setStringList('social_posts', list.map((p) => jsonEncode(p.toJson())).toList());
    return true;
  }

  static Future<bool> toggleLikePost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSocialPosts();
    for (final p in list) {
      if (p.id == postId) {
        p.isLiked = !p.isLiked;
        p.likesCount += p.isLiked ? 1 : -1;
        break;
      }
    }
    await prefs.setStringList('social_posts', list.map((p) => jsonEncode(p.toJson())).toList());
    return true;
  }

  static Future<bool> addPostComment(String postId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSocialPosts();
    for (final p in list) {
      if (p.id == postId) {
        p.comments.add(SocialCommentModel(
          id: 'c_${DateTime.now().millisecondsSinceEpoch}',
          userName: 'You',
          text: text,
          createdAt: DateTime.now(),
        ));
        break;
      }
    }
    await prefs.setStringList('social_posts', list.map((p) => jsonEncode(p.toJson())).toList());
    return true;
  }

  // ══ Advanced QR Scan & History ════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('qr_scan_history') ?? [];
    return raw.map((r) => Map<String, dynamic>.from(jsonDecode(r))).toList();
  }

  static Future<void> saveScanRecord(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('qr_scan_history') ?? [];
    raw.insert(0, jsonEncode(record));
    if (raw.length > 50) raw.removeLast();
    await prefs.setStringList('qr_scan_history', raw);
  }
}
