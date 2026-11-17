import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;

  AuthResult({required this.success, this.errorMessage, this.user});
}

class AuthService {
  static Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        if (data['token'] != null) {
          await prefs.setString('auth_token', data['token']);
        }
        UserModel? user;
        if (data['user'] != null) {
          await prefs.setString('user_data', jsonEncode(data['user']));
          user = UserModel.fromJson(data['user']);
        }
        return AuthResult(success: true, user: user);
      } else {
        try {
          final errData = jsonDecode(response.body);
          final msg = errData['error'] ?? errData['detail'] ?? 'Invalid credentials';
          return AuthResult(success: false, errorMessage: msg.toString());
        } catch (_) {
          return AuthResult(success: false, errorMessage: 'Server returned HTTP ${response.statusCode}');
        }
      }
    } on SocketException catch (_) {
      return AuthResult(
        success: false,
        errorMessage: 'Cannot connect to backend server at ${AppConstants.baseUrl}. Please check Server Settings (⚙️).',
      );
    } on TimeoutException catch (_) {
      return AuthResult(
        success: false,
        errorMessage: 'Connection timed out. Check your network or Server Settings (⚙️).',
      );
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Error: ${e.toString()}');
    }
  }

  static Future<AuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'confirm_password': password,
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthResult(success: true);
      } else {
        try {
          final errData = jsonDecode(response.body);
          final msg = errData['error'] ?? errData['detail'] ?? errData.toString();
          return AuthResult(success: false, errorMessage: msg.toString());
        } catch (_) {
          return AuthResult(success: false, errorMessage: 'Registration failed (HTTP ${response.statusCode})');
        }
      }
    } on SocketException catch (_) {
      return AuthResult(
        success: false,
        errorMessage: 'Cannot connect to backend server at ${AppConstants.baseUrl}. Please check Server Settings (⚙️).',
      );
    } on TimeoutException catch (_) {
      return AuthResult(
        success: false,
        errorMessage: 'Connection timed out. Check your network or Server Settings (⚙️).',
      );
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Error: ${e.toString()}');
    }
  }

  static Future<bool> testConnection(String url) async {
    try {
      String clean = url.trim();
      if (clean.endsWith('/')) clean = clean.substring(0, clean.length - 1);
      final testUri = Uri.parse('$clean/api/login/');
      final response = await http.get(testUri).timeout(const Duration(seconds: 5));
      // Even if 405 Method Not Allowed (since GET on POST endpoint), the host is reachable!
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token') || prefs.getBool('is_offline_demo') == true;
  }

  static Future<void> setOfflineDemo(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_offline_demo', enabled);
  }

  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data != null) {
      return UserModel.fromJson(jsonDecode(data));
    }
    if (prefs.getBool('is_offline_demo') == true) {
      return UserModel(
        id: 999,
        email: 'demo@eventconnect.com',
        firstName: 'Guest',
        lastName: 'Demo',
        phone: '+91 98765 43210',
        emailVerified: true,
        isPremium: true,
      );
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('is_offline_demo');
  }
}
