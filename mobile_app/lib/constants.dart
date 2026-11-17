import 'package:flutter/material.dart';

class AppConstants {
  // Replace with your machine's local IP (e.g. 192.168.1.X) when testing on a physical phone,
  // or use 10.0.2.2 for Android Studio Emulator to point to Django's 127.0.0.1:8000.
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String apiBaseUrl = '$baseUrl/api';

  // Endpoints
  static const String loginUrl = '$apiBaseUrl/login/';
  static const String registerUrl = '$apiBaseUrl/register/';
  static const String profileUrl = '$apiBaseUrl/profile/';
  static const String eventsUrl = '$apiBaseUrl/events/';
  static const String businessUrl = '$apiBaseUrl/business/';
  static const String subscriptionsUrl = '$apiBaseUrl/subscriptions/';

  // Branding Colors
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color successColor = Color(0xFF10B981);
  static const Color dangerColor = Color(0xFFEF4444);
}
