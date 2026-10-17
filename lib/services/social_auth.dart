import 'dart:io' show Platform;

import 'package:eafind/const/social_auth_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Google / Apple sign-in, shared by the login and sign-up screens.
///
/// Both flows end at NewAuthService.socialLogin (social_login.php), which
/// verifies the provider's ID token, logs in the matching account or
/// creates a new "User" account, and returns the same session as the
/// email/password login.
class SocialAuth {
  static Future<void>? _googleInit;

  /// google_sign_in v7 must be initialised exactly once per app run.
  static Future<void> ensureGoogleInitialized() {
    return _googleInit ??= GoogleSignIn.instance
        .initialize(
      serverClientId: SocialAuthConfig.googleWebClientId,
      clientId:
          !kIsWeb && Platform.isIOS ? SocialAuthConfig.googleIosClientId : null,
    )
        .catchError((Object e) {
      _googleInit = null; // allow a retry on the next tap
      throw e;
    });
  }

  /// Clears the Google session so the account picker shows next time.
  static Future<void> signOutGoogle() async {
    if (_googleInit == null) return;
    try {
      await _googleInit;
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  /// Apple's guidelines require it on iOS whenever Google is offered.
  /// Android would need an Apple Services ID and a web redirect, so it's
  /// iOS only for now.
  static bool get appleAvailable => !kIsWeb && Platform.isIOS;
}
