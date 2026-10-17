import 'package:eafind/const/constant.dart';
import 'package:eafind/const/social_auth_config.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/leads/lead_bottom_navbar.dart';
import 'package:eafind/services/new_auth_service.dart';
import 'package:eafind/services/notification_token_sync.dart';
import 'package:eafind/services/social_auth.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/utility/custom_toast.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// "Continue with Google / Apple" buttons, shared by the login and sign-up
/// screens. Both flows end at NewAuthService.socialLogin (social_login.php),
/// which verifies the provider token and logs in or creates the account.
class SocialSignInButtons extends StatefulWidget {
  /// Text in the divider that separates the buttons from the email form.
  final String dividerText;

  /// Divider above the buttons (they follow a form) or below them (they
  /// come first, above a form).
  final bool dividerOnTop;

  /// Lets the parent screen disable its own form while a social sign-in
  /// is in progress (and vice versa via [disabled]).
  final ValueChanged<bool>? onBusyChanged;
  final bool disabled;

  const SocialSignInButtons({
    Key? key,
    this.dividerText = 'or continue with',
    this.dividerOnTop = true,
    this.onBusyChanged,
    this.disabled = false,
  }) : super(key: key);

  @override
  State<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends State<SocialSignInButtons> {
  String? _busy; // 'google' | 'apple' | null

  void _setBusy(String? provider) {
    if (!mounted) return;
    setState(() => _busy = provider);
    widget.onBusyChanged?.call(provider != null);
  }

  void _error(String message) {
    if (!mounted) return;
    CustomToast.show(context,
        title: 'Sign-in failed', message: message, type: ToastType.error);
  }

  Future<void> _google() async {
    if (_busy != null || widget.disabled) return;
    if (!SocialAuthConfig.isGoogleConfigured) {
      _error('Google sign-in is not set up for this build yet.');
      return;
    }
    _setBusy('google');
    try {
      await SocialAuth.ensureGoogleInitialized();
      final account =
          await GoogleSignIn.instance.authenticate(scopeHint: const ['email']);
      final idToken = account.authentication.idToken;
      if (idToken == null) throw Exception('No ID token from Google');
      await _complete(
        provider: 'google',
        idToken: idToken,
        email: account.email,
        name: account.displayName,
      );
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        debugPrint('Google sign-in error: ${e.code} ${e.description}');
        _error('Could not sign in with Google. Please try again.');
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      _error('Could not sign in with Google. Please try again.');
    } finally {
      _setBusy(null);
    }
  }

  Future<void> _apple() async {
    if (_busy != null || widget.disabled) return;
    _setBusy('apple');
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) throw Exception('No identity token from Apple');
      // Apple only shares the name on the very first authorisation.
      final name = [credential.givenName, credential.familyName]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(' ');
      await _complete(
        provider: 'apple',
        idToken: idToken,
        email: credential.email,
        name: name.isEmpty ? null : name,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        debugPrint('Apple sign-in error: ${e.code} ${e.message}');
        _error('Could not sign in with Apple. Please try again.');
      }
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      _error('Could not sign in with Apple. Please try again.');
    } finally {
      _setBusy(null);
    }
  }

  Future<void> _complete({
    required String provider,
    required String idToken,
    String? email,
    String? name,
  }) async {
    final result = await NewAuthService.instance.socialLogin(
        provider: provider, idToken: idToken, email: email, name: name);
    if (!mounted) return;
    if (!result.success) {
      _error(result.message ?? 'Sign-in failed');
      return;
    }

    final UserModel user = result.user!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', user.email);
    await NotificationTokenSync.syncOnce(user.id);
    if (!mounted) return;
    Provider.of<UsermodelProvider>(context, listen: false).setUserModel(user);
    CustomToast.show(context,
        title: 'Welcome', message: 'You have successfully signed in');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            user.userType == 'Lead' ? LeadBottomNavbar() : BottomNavHome(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final divider = Padding(
      padding: EdgeInsets.only(
          top: widget.dividerOnTop ? 16 : 4,
          bottom: widget.dividerOnTop ? 16 : 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: p.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(widget.dividerText,
                style: TextStyle(color: p.textGrey, fontSize: 12.5)),
          ),
          Expanded(child: Divider(color: p.border)),
        ],
      ),
    );

    return Column(
      children: [
        if (widget.dividerOnTop) divider,
        _button(
          provider: 'google',
          label: 'Continue with Google',
          icon: SvgPicture.asset(imageRounte(name: 'google_g.svg'),
              width: 18, height: 18),
          background: p.card,
          foreground: p.ink,
          border: p.border,
          onTap: _google,
        ),
        if (SocialAuth.appleAvailable)
          // Apple's guidelines: black button on light backgrounds, white on
          // dark.
          _button(
            provider: 'apple',
            label: 'Continue with Apple',
            icon: Icon(Icons.apple,
                size: 22, color: isDark ? Colors.black : Colors.white),
            background: isDark ? Colors.white : Colors.black,
            foreground: isDark ? Colors.black : Colors.white,
            border: isDark ? Colors.white : Colors.black,
            onTap: _apple,
          ),
        if (!widget.dividerOnTop) divider,
      ],
    );
  }

  Widget _button({
    required String provider,
    required String label,
    required Widget icon,
    required Color background,
    required Color foreground,
    required Color border,
    required VoidCallback onTap,
  }) {
    final loading = _busy == provider;
    final disabled = widget.disabled || (_busy != null && !loading);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: appRadius(14.0),
            side: BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: disabled || loading ? null : onTap,
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: Center(
                child: loading
                    ? LoadingAnimationWidget.fallingDot(
                        color: foreground, size: 22)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          icon,
                          const SizedBox(width: 10),
                          Text(label,
                              style: TextStyle(
                                  color: foreground,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
