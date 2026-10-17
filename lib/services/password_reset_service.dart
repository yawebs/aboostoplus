// Forgot-password flow against password-reset.php (code emailed through Resend).
//
//   requestCode(email)            -> emails a 6-digit code
//   verifyCode(email, code)       -> returns a short-lived reset token
//   setNewPassword(token, pwd)    -> saves the password, signs out every device

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'new_auth_service.dart';

class PasswordResetResult {
  final bool success;
  final String message;

  /// Server reason when it failed: 'wrong', 'expired' or 'locked'.
  final String? code;
  final String? resetToken;

  const PasswordResetResult({
    required this.success,
    this.message = '',
    this.code,
    this.resetToken,
  });

  bool get needsNewCode => code == 'expired' || code == 'locked';
}

class PasswordResetService {
  PasswordResetService._();
  static final PasswordResetService instance = PasswordResetService._();

  static const int minPasswordLength = 8;
  static final Uri _endpoint =
      Uri.parse('${NewAuthService.baseUrl}/password-reset.php');

  Future<PasswordResetResult> requestCode(String email) =>
      _post({'action': 'request', 'email': email.trim().toLowerCase()});

  Future<PasswordResetResult> verifyCode(String email, String code) => _post({
        'action': 'verify',
        'email': email.trim().toLowerCase(),
        'code': code,
      });

  Future<PasswordResetResult> setNewPassword(
          String resetToken, String password) =>
      _post({
        'action': 'complete',
        'reset_token': resetToken,
        'password': password,
      });

  Future<PasswordResetResult> _post(Map<String, dynamic> payload) async {
    try {
      final res = await http
          .post(_endpoint,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        debugPrint('password-reset.php HTTP ${res.statusCode}: ${res.body}');
        return PasswordResetResult(
            success: false,
            message:
                'The server had a problem (error ${res.statusCode}). Please try again later.');
      }

      return PasswordResetResult(
        success: res.statusCode == 200 && body['success'] == true,
        message: (body['message'] ?? '') as String,
        code: body['code'] as String?,
        resetToken: body['reset_token'] as String?,
      );
    } on TimeoutException {
      return const PasswordResetResult(
          success: false,
          message: 'The request timed out. Check your connection and try again.');
    } catch (e) {
      debugPrint('PasswordResetService error: $e');
      return const PasswordResetResult(
          success: false,
          message: 'Could not reach the server. Check your connection.');
    }
  }
}
