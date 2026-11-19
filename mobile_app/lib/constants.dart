import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  static const String appName = 'QRouteX';
  static const String appWebsite = 'qroutex.com';

  // Default fallback baseUrl
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
  static String get qrScanUrl => '$apiBaseUrl/qr/scan/';

  // ── Premium QRouteX Design System (Deep Indigo, Electric Violet & Cyan) ──
  static const Color primaryColor = Color(0xFF4F46E5);    // Deep Indigo
  static const Color primaryDark = Color(0xFF312E81);     // Midnight Indigo
  static const Color primaryLight = Color(0xFF6366F1);   // Bright Indigo
  static const Color secondaryColor = Color(0xFF7C3AED); // Electric Violet
  static const Color accentColor = Color(0xFF06B6D4);    // Cyan
  static const Color purpleSurface = Color(0xFFEEF2FF);  // Soft Indigo Tint
  static const Color passvantaBlue = Color(0xFF2563EB);  // Electric Blue

  // Background & Surfaces
  static const Color backgroundColor = Color(0xFFF8FAFC);     // Light clean background
  static const Color darkBackgroundColor = Color(0xFF0F172A); // Dark Slate
  static const Color cardColor = Colors.white;
  static const Color darkCardColor = Color(0xFF1E293B);       // Slate Dark Card

  // Typography Colors
  static const Color textDark = Color(0xFF111827);       // Pitch Ink
  static const Color textLight = Color(0xFFF8FAFC);      // Clean White
  static const Color textMuted = Color(0xFF64748B);      // Slate Muted
  static const Color textMutedDark = Color(0xFF94A3B8);  // Slate Light Muted

  // Feedback Colors
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color dangerColor = Color(0xFFEF4444);  // Rose

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Backward compatibility aliases
  static const LinearGradient passvantaGradient = primaryGradient;
  static const LinearGradient passvantaCardGradient = heroGradient;
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
