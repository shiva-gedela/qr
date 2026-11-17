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
    final response = await http.get(
      Uri.parse(AppConstants.eventsUrl),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List results = decoded is List ? decoded : (decoded['results'] ?? []);
      return results.map((e) => EventModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load events: ${response.statusCode}');
    }
  }

  static Future<EventModel> createEvent(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(AppConstants.eventsUrl),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return EventModel.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error.toString());
    }
  }

  // Business API
  static Future<List<BusinessModel>> getBusinesses() async {
    final response = await http.get(
      Uri.parse(AppConstants.businessUrl),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List results = decoded is List ? decoded : (decoded['results'] ?? []);
      return results.map((b) => BusinessModel.fromJson(b)).toList();
    } else {
      throw Exception('Failed to load businesses');
    }
  }

  static Future<BusinessModel> getPublicBusiness(String slug) async {
    final response = await http.get(
      Uri.parse('${AppConstants.businessUrl}public/$slug/'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return BusinessModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Business profile not found');
    }
  }

  // Subscriptions API
  static Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    final response = await http.get(
      Uri.parse('${AppConstants.subscriptionsUrl}plans/'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List results = decoded is List ? decoded : (decoded['results'] ?? []);
      return results.map((p) => SubscriptionPlanModel.fromJson(p)).toList();
    } else {
      throw Exception('Failed to load subscription plans');
    }
  }
}
