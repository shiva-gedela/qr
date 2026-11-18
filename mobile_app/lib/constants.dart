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

  // Branding Colors - Signature PhonePe Royal Purple Theme
  static const Color primaryColor = Color(0xFF5F259F); // PhonePe Royal Purple
  static const Color primaryDark = Color(0xFF4A148C);  // PhonePe Deep Violet
  static const Color primaryLight = Color(0xFF7C4DFF); // PhonePe Vibrant Violet
  static const Color accentColor = Color(0xFFFFB703);  // PhonePe Reward Gold
  static const Color purpleSurface = Color(0xFFF3E8FF);// PhonePe Soft Violet Tint
  static const Color backgroundColor = Color(0xFFF4F4F8); // Clean PhonePe Background
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1F1F24);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color successColor = Color(0xFF00BFA5); // PhonePe Verified Teal / Green
  static const Color dangerColor = Color(0xFFE53935);
}
