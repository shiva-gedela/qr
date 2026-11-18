import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  static const String appName = 'QRouteX';
  static const String appWebsite = 'qroutex.com';

  // Default fallback baseUrl:
  // - Physical devices on local network: use host machine's Wi-Fi IP (e.g. http://10.22.84.118:8000)
  // - Android Studio Emulator: http://10.0.2.2:8000
  // - Production / Render Cloud: https://your-app.onrender.com
  static const String defaultBaseUrl = 'http://10.22.84.118:8000';
  static String _currentBaseUrl = defaultBaseUrl;

  static String get baseUrl => _currentBaseUrl;

  static Future<void> initBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _currentBaseUrl = prefs.getString('custom_base_url') ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String newUrl) async {
    String cleanUrl = newUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    _currentBaseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_base_url', cleanUrl);
  }

  static String get apiBaseUrl => '$_currentBaseUrl/api';

  // Dynamic Endpoints
  static String get loginUrl => '$apiBaseUrl/login/';
  static String get logoutUrl => '$apiBaseUrl/logout/';
  static String get registerUrl => '$apiBaseUrl/register/';
  static String get profileUrl => '$apiBaseUrl/profile/';
  static String get eventsUrl => '$apiBaseUrl/events/';
  static String get businessUrl => '$apiBaseUrl/business/';
  static String get subscriptionsUrl => '$apiBaseUrl/subscriptions/';

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
