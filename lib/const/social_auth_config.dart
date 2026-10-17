// OAuth client IDs for "Continue with Google" / "Continue with Apple".
//
// Google: both IDs come from the Google Cloud project behind the Firebase
// project (eafind-385a8) -> APIs & Services -> Credentials.
//   * googleWebClientId: the "Web application" OAuth client. google_sign_in
//     v7 needs it on Android and iOS so the ID token is issued for the
//     backend; social_login.php checks the token's audience against it.
//   * googleIosClientId: the "iOS" OAuth client. Its reversed form also has
//     to be added as a URL scheme in ios/Runner/Info.plist.
//
// Apple needs no client ID in the app: on iOS the token's audience is the
// bundle ID (com.aboostoplus.app), which social_login.php checks.
class SocialAuthConfig {
  static const String googleWebClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  static const String googleIosClientId =
      'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  static bool get isGoogleConfigured => !googleWebClientId.startsWith('YOUR_');
}
