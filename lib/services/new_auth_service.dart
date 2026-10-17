// auth_service.dart
//
// Dependencies (pubspec.yaml):
//   http: ^1.2.0
//   flutter_secure_storage: ^9.2.2
//
// Tokens are stored in flutter_secure_storage (Keychain on iOS,
// EncryptedSharedPreferences on Android) rather than shared_preferences,
// since a leaked auth token is equivalent to a leaked password for the
// lifetime of that token.
//
// Uses the project's existing UserModel — adjust the import path below
// to wherever that file actually lives.

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';
import 'social_auth.dart';

class AuthResult {
  final bool success;
  final UserModel? user;
  final String? message;
  AuthResult({required this.success, this.user, this.message});
}

class NewAuthService {
  NewAuthService._internal();
  static final NewAuthService instance = NewAuthService._internal();

  static const String baseUrl = 'https://aboostoplus.com/api';
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  String? _cachedToken;

  /// Call once at app startup (e.g. in main() or a splash screen) to
  /// restore a saved session without forcing the user to log in again.
  Future<bool> tryRestoreSession() async {
    final token = await getToken();
    return token != null;
  }

  Future<String?> getToken() async {
    _cachedToken ??= await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  Future<bool> get isLoggedIn async => (await getToken()) != null;

  Future<AuthResult> login(
      {required String email, required String password}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/login.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        await _storage.write(key: _tokenKey, value: body['token']);
        _cachedToken = body['token'];
        // login.php returns the raw users row (firstname, userType,
        // leadUid, etc.), matching what UserModel.fromDoc expects.
        return AuthResult(success: true, user: UserModel.fromDoc(body['user']));
      }

      return AuthResult(
          success: false, message: body['message'] ?? 'Login failed');
    } catch (e) {
      return AuthResult(success: false, message: 'Could not reach the server');
    }
  }
// Add this method to NewAuthService, right after login(). It follows
// the exact same pattern: http.post -> jsonDecode -> store token ->
// UserModel.fromDoc(body['user']).
//
// PHP side (social_login.php): receives { provider, id_token, email,
// name }, verifies id_token against Google's or Apple's public keys
// depending on `provider`, then finds-or-creates a row in your users
// table and returns the exact same { success, token, user, message }
// shape login.php already returns — that's what makes this drop in
// without touching UserModel or anything downstream.

  Future<AuthResult> socialLogin({
    required String provider, // 'google' | 'apple'
    required String idToken,
    String? email,
    String? name,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/social_login.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'provider': provider,
              'id_token': idToken,
              if (email != null) 'email': email,
              if (name != null) 'name': name,
            }),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        // A PHP fatal error or a missing endpoint returns HTML or nothing,
        // which isn't the same problem as having no connection.
        debugPrint('social_login.php HTTP ${res.statusCode}: ${res.body}');
        return AuthResult(
            success: false,
            message: 'The server had a problem (error ${res.statusCode}). '
                'Please try again later.');
      }

      if (res.statusCode == 200 && body['success'] == true) {
        await _storage.write(key: _tokenKey, value: body['token']);
        _cachedToken = body['token'];
        // Same assumption as login(): social_login.php returns the raw
        // users row, so UserModel.fromDoc can parse it unchanged.
        return AuthResult(success: true, user: UserModel.fromDoc(body['user']));
      }

      return AuthResult(
          success: false,
          message: body['message'] ??
              '${provider[0].toUpperCase()}${provider.substring(1)} sign-in failed');
    } catch (e) {
      debugPrint('socialLogin error: $e');
      return AuthResult(success: false, message: 'Could not reach the server');
    }
  }

  Future<AuthResult> register({required FormData data}) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    try {
      final res = await dio.post('$baseUrl/register.php', data: data);

      // Dio already decodes JSON responses into a Map — don't jsonDecode again.
      final body = res.data is String
          ? jsonDecode(res.data) as Map<String, dynamic>
          : res.data as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        await _storage.write(key: _tokenKey, value: body['token']);
        _cachedToken = body['token'];
        return AuthResult(success: true, user: UserModel.fromDoc(body['user']));
      }

      return AuthResult(
          success: false, message: body['message'] ?? 'Registration failed');
    } on DioException catch (e) {
      debugPrint('Dio error type: ${e.type}');
      debugPrint('Dio error message: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      debugPrint('Status code: ${e.response?.statusCode}');

      // If the server actually responded with an error body, surface its message
      if (e.response?.data is Map &&
          (e.response?.data as Map)['message'] != null) {
        return AuthResult(success: false, message: e.response!.data['message']);
      }

      return AuthResult(
          success: false, message: 'Could not reach the server: ${e.type}');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return AuthResult(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout.php'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {
        // Even if the network call fails, still clear the local token
        // below so the user is logged out on-device.
      }
    }
    await _storage.delete(key: _tokenKey);
    _cachedToken = null;
    // Otherwise "Continue with Google" silently reuses the last account.
    await SocialAuth.signOutGoogle();
  }

  /// Permanently deletes the signed-in account (delete-account.php), then
  /// clears the local session. Returns null on success, or an error message.
  Future<String?> deleteAccount() async {
    try {
      final res = await authorizedPost('/delete-account.php', {'confirm': 'DELETE'})
          .timeout(const Duration(seconds: 20));
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        debugPrint('delete-account.php HTTP ${res.statusCode}: ${res.body}');
      }
      if (res.statusCode != 200 || body['success'] != true) {
        return (body['message'] as String?) ??
            'We could not delete your account right now. Please try again.';
      }
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      return 'Could not reach the server. Check your connection and try again.';
    }
    // The server already removed every session; this just clears the device.
    await logout();
    return null;
  }

  /// Convenience wrapper for making authenticated requests elsewhere in
  /// the app (e.g. ReportService) without repeating the header logic.
  Future<http.Response> authorizedPost(
      String path, Map<String, dynamic> body) async {
    final token = await getToken();
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }
}
