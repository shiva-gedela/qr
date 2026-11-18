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
    try {
      final response = await http.get(
        Uri.parse(AppConstants.eventsUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List results = decoded is List ? decoded : (decoded['results'] ?? []);
        return results.map((e) => EventModel.fromJson(e)).toList();
      }
      throw Exception('Unable to load events (HTTP ${response.statusCode})');
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('is_offline_demo') != true) rethrow;
      return _getOfflineDemoEvents();
    }
  }

  static Future<List<EventModel>> getCheckInEvents() async {
    final events = <EventModel>[];
    final baseUri = Uri.parse(AppConstants.eventsUrl);
    String? nextUrl = baseUri.toString();
    while (nextUrl != null) {
      final response = await http.get(
        Uri.parse(nextUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('Unable to load assigned events (HTTP ${response.statusCode})');
      }
      final decoded = jsonDecode(response.body);
      final List results = decoded is List ? decoded : (decoded['results'] ?? []);
      events.addAll(results.map((event) => EventModel.fromJson(event)));
      final next = decoded is Map ? decoded['next'] : null;
      if (next is String) {
        final nextUri = baseUri.resolve(next);
        if (nextUri.origin != baseUri.origin) {
          throw Exception('Event API returned a pagination link to an unexpected host.');
        }
        nextUrl = nextUri.toString();
      } else {
        nextUrl = null;
      }
    }
    return events;
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
    final response = await http.post(
      Uri.parse(AppConstants.eventsUrl),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 201) {
      return EventModel.fromJson(jsonDecode(response.body));
    }
    final error = jsonDecode(response.body);
    throw Exception(error.toString());
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
      ),
    ];
  }
}
