import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/event_model.dart';
import '../models/business_model.dart';
import '../models/subscription_model.dart';

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
    } catch (_) {
      // Offline fallback: return offline events
    }
    return _getOfflineDemoEvents();
  }

  static Future<EventModel> createEvent(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.eventsUrl),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 201) {
        return EventModel.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error.toString());
      }
    } catch (e) {
      // Local fallback for offline mode
      return EventModel(
        id: DateTime.now().millisecondsSinceEpoch,
        title: data['title'] ?? 'New Event',
        slug: 'offline-event-${DateTime.now().millisecondsSinceEpoch}',
        eventType: data['event_type'] ?? 'wedding',
        eventTypeName: 'Celebration',
        eventTypeIcon: '🎉',
        eventDate: data['event_date'] ?? '2026-12-01',
        venueName: data['venue_name'],
        venueAddress: data['venue_address'],
        isPublished: true,
      );
    }
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
        eventTypeName: 'Wedding',
        eventTypeIcon: '💍',
        eventDate: '2026-12-15',
        eventTime: '10:00:00',
        venueName: 'The Leela Palace Ballroom',
        venueAddress: 'Old Airport Road, Kodihalli, Bengaluru, Karnataka 560008',
        hostNames: 'Sharma & Gupta Families',
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
        eventTypeName: 'Birthday',
        eventTypeIcon: '🎂',
        eventDate: '2026-11-25',
        eventTime: '17:30:00',
        venueName: 'Taj Krishna Grand Hall',
        venueAddress: 'Road No 1, Banjara Hills, Hyderabad, Telangana 500034',
        hostNames: 'Pooja & Rajesh',
        isPublished: true,
        eventHashtag: '#AaravTurnsOne',
        dressCode: 'Smart Casual / Pastel',
      ),
      EventModel(
        id: 3,
        title: 'Sneha & Amit Ring Ceremony',
        slug: 'test-engagement-event',
        eventType: 'engagement',
        eventTypeName: 'Engagement',
        eventTypeIcon: '💑',
        eventDate: '2026-12-05',
        venueName: 'JW Marriott Banquets',
        venueAddress: 'Senapati Bapat Marg, Lower Parel, Mumbai, Maharashtra 400013',
        hostNames: 'Mehta & Kapoor Families',
        isPublished: true,
        eventHashtag: '#SnehaAmitForever',
      ),
      EventModel(
        id: 4,
        title: '25th Silver Jubilee Anniversary',
        slug: 'test-anniversary-event',
        eventType: 'anniversary',
        eventTypeName: 'Anniversary',
        eventTypeIcon: '❤️',
        eventDate: '2026-12-28',
        venueName: 'ITC Grand Chola Banquet',
        venueAddress: '63 Mount Road, Guindy, Chennai, Tamil Nadu 600032',
        hostNames: 'Children & Family',
        isPublished: true,
      ),
      EventModel(
        id: 5,
        title: 'New Sweet Home - Griha Pravesh',
        slug: 'test-housewarming-event',
        eventType: 'housewarming',
        eventTypeName: 'Housewarming',
        eventTypeIcon: '🏠',
        eventDate: '2026-12-10',
        venueName: 'Villa 42, Palm Meadows',
        venueAddress: 'Whitefield Main Road, Bengaluru, Karnataka 560066',
        hostNames: 'Sunita & Ramesh',
        isPublished: true,
      ),
      EventModel(
        id: 6,
        title: 'Doctorate Celebration of Dr. Vikram',
        slug: 'test-graduation-event',
        eventType: 'graduation',
        eventTypeName: 'Graduation',
        eventTypeIcon: '🎓',
        eventDate: '2026-12-20',
        venueName: 'Senate Convocation Pavilion',
        venueAddress: 'University Campus, Connaught Place, New Delhi 110001',
        hostNames: 'Dr. Vikram & Proud Parents',
        isPublished: true,
      ),
    ];
  }
}
