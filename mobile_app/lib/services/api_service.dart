import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/event_model.dart';
import '../models/business_model.dart';
import '../models/subscription_model.dart';

class ApiConnectionException implements Exception {
  final String message;
  ApiConnectionException(this.message);

  @override
  String toString() => message;
}

class ApiService {
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

  // Business API
  static Future<List<BusinessModel>> getBusinesses() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.businessUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List results = decoded is List ? decoded : (decoded['results'] ?? []);
        return results.map((b) => BusinessModel.fromJson(b)).toList();
      }
    } catch (_) {}
    return [];
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
}
