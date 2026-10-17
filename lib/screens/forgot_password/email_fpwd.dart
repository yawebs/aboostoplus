import 'dart:async';

import 'package:eafind/services/password_reset_service.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../const/constant.dart';

/// Forgot password: email → 6-digit code → new password → done.
/// Codes are emailed by password-reset.php through Resend.
class ForgetPasswordEmail extends StatefulWidget {
  final String? initialEmail;
  const ForgetPasswordEmail({Key? key, this.initialEmail}) : super(key: key);

  @override
  State<ForgetPasswordEmail> createState() => _ForgetPasswordEmailState();
}

enum _Step { email, code, password, done }

const _plum = Color(0xFF3F224F);
const _plum2 = Color(0xFF6A3D7A);
const _gold = Color(0xFFF5C76A);
const _amber = Color(0xFFE8A93B);
const _red = Color(0xFFE5484D);
const _green = Color(0xFF2E9E5B);
const _codeLength = 6;
const _resendSeconds = 60;

class _ForgetPasswordEmailState extends State<ForgetPasswordEmail> {
  final _service = PasswordResetService.instance;
  final _emailForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl =
      TextEditingController(text: widget.initialEmail ?? '');
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _Step _step = _Step.email;
  bool _busy = false;
  bool _hidePwd = true;
  bool _hideConfirm = true;
  String? _codeError;
  String? _resetToken;
  int _resendIn = 0;
  Timer? _resendTimer;

  String get _email => _emailCtrl.text.trim().toLowerCase();

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── actions ────────────────────────────────────────────────────────────

  Future<void> _sendCode({bool resend = false}) async {
    if (!resend && !_emailForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final r = await _service.requestCode(_email);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.success) {
      showToast(r.message);
      return;
    }
    _codeCtrl.clear();
    _startResendTimer();
    setState(() {
      _codeError = null;
      _step = _Step.code;
    });
    if (resend) showToast('A new code is on its way');
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _codeFocus.requestFocus());
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendIn = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _resendIn <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendIn = 0);
        return;
      }
      setState(() => _resendIn--);
    });
  }

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.length != _codeLength || _busy) return;
    setState(() {
      _busy = true;
      _codeError = null;
    });
    final r = await _service.verifyCode(_email, _codeCtrl.text);
    if (!mounted) return;
    if (r.success && r.resetToken != null) {
      setState(() {
        _busy = false;
        _resetToken = r.resetToken;
        _step = _Step.password;
      });
      return;
    }
    setState(() {
      _busy = false;
      _codeError = r.message;
      if (r.needsNewCode) _resendIn = 0;
    });
    _codeCtrl.clear();
    _codeFocus.requestFocus();
  }

  Future<void> _savePassword() async {
    if (!_passwordForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final r = await _service.setNewPassword(_resetToken!, _pwdCtrl.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.success) {
      setState(() => _step = _Step.done);
    } else if (r.code == 'expired') {
      showToast(r.message);
      setState(() => _step = _Step.email);
    } else {
      showToast(r.message);
    }
  }

  void _back() {
    if (_busy) return;
    switch (_step) {
      case _Step.code:
        setState(() => _step = _Step.email);
        break;
      case _Step.password:
        setState(() => _step = _Step.code);
        break;
      default:
        Navigator.of(context).maybePop();
    }
  }

  // ── layout ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final page = PopScope(
      canPop: _step == _Step.email || _step == _Step.done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: context.palette.page,
        body: LayoutBuilder(builder: (context, c) {
          if (c.maxWidth >= 900) return _wideLayout(context);
          return _narrowLayout(context);
        }),
      ),
    );
    return kIsWeb ? Theme(data: AppTheme.theme, child: page) : page;
  }

  Widget _narrowLayout(BuildContext context) {
    return Column(
      children: [
        _Hero(
          step: _step,
          title: _title,
          subtitle: _subtitle,
          onBack: _back,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
            child: _stepBody(context),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            child: _primaryButton(),
          ),
        ),
      ],
    );
  }

  Widget _wideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Hero(
            step: _step,
            title: _title,
            subtitle: _subtitle,
            onBack: _back,
            wide: true,
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _stepBody(context),
                    const SizedBox(height: 28),
                    _primaryButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _title {
    switch (_step) {
      case _Step.email:
        return 'Forgot your password?';
      case _Step.code:
        return 'Check your email';
      case _Step.password:
        return 'Create a new password';
      case _Step.done:
        return 'You’re all set';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _Step.email:
        return 'No wahala. Enter the email on your account and we’ll send you a reset code.';
      case _Step.code:
        return 'Enter the 6-digit code we sent to ${_maskEmail(_email)}.';
      case _Step.password:
        return 'Choose a strong password you haven’t used on Aboostoplus before.';
      case _Step.done:
        return 'Your password has been updated.';
    }
  }

  Widget _currentStep(BuildContext context) {
    switch (_step) {
      case _Step.email:
        return _emailStep(context);
      case _Step.code:
        return _codeStep(context);
      case _Step.password:
        return _passwordStep(context);
      case _Step.done:
        return _doneStep(context);
    }
  }

  Widget _stepBody(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(.06, 0), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_step),
        child: _currentStep(context),
      ),
    );
  }

  Widget _primaryButton() {
    switch (_step) {
      case _Step.email:
        return _GradientButton(
            label: 'Send reset code', busy: _busy, onTap: () => _sendCode());
      case _Step.code:
        return _GradientButton(
            label: 'Verify code',
            busy: _busy,
            onTap: _codeCtrl.text.length == _codeLength ? _verifyCode : null);
      case _Step.password:
        return _GradientButton(
            label: 'Update password', busy: _busy, onTap: _savePassword);
      case _Step.done:
        return _GradientButton(
            label: 'Back to sign in',
            busy: false,
            onTap: () => Navigator.of(context).maybePop());
    }
  }

  // ── steps ──────────────────────────────────────────────────────────────

  Widget _emailStep(BuildContext context) {
    final p = context.palette;
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.alternate_email_rounded,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendCode(),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Enter your email address';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'That doesn’t look like a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _InfoTile(
            icon: Icons.mark_email_read_outlined,
            color: p.accent,
            text:
                'We’ll email you a 6-digit code. It expires in 15 minutes, so keep the app open.',
          ),
        ],
      ),
    );
  }

  Widget _codeStep(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CodeInput(
          controller: _codeCtrl,
          focusNode: _codeFocus,
          hasError: _codeError != null,
          onChanged: (v) {
            if (_codeError != null) setState(() => _codeError = null);
            setState(() {});
            if (v.length == _codeLength) _verifyCode();
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _codeError == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 18, color: _red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_codeError!,
                          style: const TextStyle(
                              color: _red,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Didn’t get it? ',
                style: TextStyle(color: p.textGrey, fontSize: 14)),
            _resendIn > 0
                ? Text('Resend in 0:${_resendIn.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        color: p.textGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()]))
                : GestureDetector(
                    onTap: _busy ? null : () => _sendCode(resend: true),
                    child: Text('Resend code',
                        style: TextStyle(
                            color: p.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ),
          ],
        ),
        const SizedBox(height: 18),
        _InfoTile(
          icon: Icons.inbox_outlined,
          color: _amber,
          text:
              'Can’t find it? Check your Spam or Promotions folder for an email from Aboostoplus.',
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: _busy ? null : () => setState(() => _step = _Step.email),
            icon: Icon(Icons.edit_outlined, size: 16, color: p.textGrey),
            label: Text('Use a different email',
                style: TextStyle(color: p.textGrey, fontSize: 13.5)),
          ),
        ),
      ],
    );
  }

  Widget _passwordStep(BuildContext context) {
    final p = context.palette;
    final pwd = _pwdCtrl.text;
    final checks = <String, bool>{
      'At least ${PasswordResetService.minPasswordLength} characters':
          pwd.length >= PasswordResetService.minPasswordLength,
      'Upper and lowercase letters':
          RegExp(r'[a-z]').hasMatch(pwd) && RegExp(r'[A-Z]').hasMatch(pwd),
      'A number or symbol': RegExp(r'[0-9\W_]').hasMatch(pwd),
    };
    final score = checks.values.where((ok) => ok).length;
    final strengthLabel = score <= 1 ? 'Weak' : (score == 2 ? 'Fair' : 'Strong');
    final strengthColor = score <= 1 ? _red : (score == 2 ? _amber : _green);

    return Form(
      key: _passwordForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            label: 'New password',
            hint: 'Enter a new password',
            icon: Icons.lock_outline_rounded,
            controller: _pwdCtrl,
            obscure: _hidePwd,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            suffix: _eye(_hidePwd, () => setState(() => _hidePwd = !_hidePwd)),
            validator: (v) => (v ?? '').length < PasswordResetService.minPasswordLength
                ? 'Use at least ${PasswordResetService.minPasswordLength} characters'
                : null,
          ),
          const SizedBox(height: 12),
          Row(children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: pwd.isNotEmpty && i < score
                        ? strengthColor
                        : p.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            SizedBox(
              width: 54,
              child: Text(pwd.isEmpty ? '' : strengthLabel,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: strengthColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 14),
          for (final c in checks.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    c.value ? Icons.check_circle_rounded : Icons.circle_outlined,
                    key: ValueKey(c.value),
                    size: 17,
                    color: c.value ? _green : p.textLight,
                  ),
                ),
                const SizedBox(width: 8),
                Text(c.key,
                    style: TextStyle(
                        fontSize: 13,
                        color: c.value ? p.textDark : p.textGrey)),
              ]),
            ),
          const SizedBox(height: 14),
          _Field(
            label: 'Confirm password',
            hint: 'Type it again',
            icon: Icons.verified_user_outlined,
            controller: _confirmCtrl,
            obscure: _hideConfirm,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _savePassword(),
            suffix: _eye(
                _hideConfirm, () => setState(() => _hideConfirm = !_hideConfirm)),
            validator: (v) =>
                v != _pwdCtrl.text ? 'Passwords don’t match' : null,
          ),
        ],
      ),
    );
  }

  Widget _doneStep(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_gold, _amber]),
              boxShadow: [
                BoxShadow(
                    color: _amber.withValues(alpha: .35),
                    blurRadius: 30,
                    offset: const Offset(0, 12)),
              ],
            ),
            child: const Icon(Icons.check_rounded, size: 56, color: _plum),
          ),
        ),
        const SizedBox(height: 26),
        Text('Password updated',
            style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: p.textDark)),
        const SizedBox(height: 10),
        Text(
          'For your security, you’ve been signed out on all devices. Sign in with your new password to continue.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, height: 1.5, color: p.textGrey),
        ),
        const SizedBox(height: 22),
        _InfoTile(
          icon: Icons.shield_outlined,
          color: _green,
          text:
              'We’ve emailed you a confirmation. If you didn’t make this change, reset your password again straight away.',
        ),
      ],
    );
  }

  Widget _eye(bool hidden, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        splashRadius: 20,
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: context.palette.textGrey,
        ),
      );
}

String _maskEmail(String email) {
  final at = email.indexOf('@');
  if (at < 1) return email;
  final name = email.substring(0, at);
  final shown = name.length <= 2 ? name[0] : name.substring(0, 2);
  return '$shown${'•' * (name.length - shown.length).clamp(2, 6)}${email.substring(at)}';
}

// ── pieces ─────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final _Step step;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final bool wide;

  const _Hero({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final stepIndex = step.index; // 0..3
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: wide ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Row(children: [
          if (step != _Step.done)
            _CircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(imageRounte(name: 'logo-icon.png'),
                width: 30, height: 30),
          ),
        ]),
        SizedBox(height: wide ? 48 : 26),
        Text(
          step == _Step.done ? 'ALL DONE' : 'STEP ${stepIndex + 1} OF 3',
          style: const TextStyle(
              color: _gold,
              fontSize: 12,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Text(
            title,
            key: ValueKey(title),
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: wide ? 42 : 30,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Text(
            subtitle,
            key: ValueKey(subtitle),
            style: TextStyle(
                fontSize: wide ? 16 : 14.5,
                height: 1.45,
                color: Colors.white.withValues(alpha: .82)),
          ),
        ),
        const SizedBox(height: 22),
        Row(children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                height: 5,
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                decoration: BoxDecoration(
                  color: i <= stepIndex
                      ? _gold
                      : Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ]),
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_plum, _plum2],
        ),
        borderRadius: wide
            ? null
            : const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // soft decorative glows
          Positioned(
            right: -60,
            top: -40,
            child: _Glow(size: 220, color: _gold.withValues(alpha: .16)),
          ),
          Positioned(
            left: -50,
            bottom: -70,
            child: _Glow(size: 200, color: Colors.white.withValues(alpha: .08)),
          ),
          Positioned(
            right: 18,
            bottom: wide ? 40 : 18,
            child: Icon(Icons.key_rounded,
                size: wide ? 220 : 110,
                color: Colors.white.withValues(alpha: .06)),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: wide
                  ? const EdgeInsets.all(56)
                  : const EdgeInsets.fromLTRB(22, 12, 22, 26),
              child: wide ? Center(child: content) : content,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _Field({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: p.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          style: TextStyle(fontSize: 15.5, color: p.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: p.textLight),
            filled: true,
            fillColor: p.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            prefixIcon: Icon(icon, color: p.accent, size: 21),
            suffixIcon: suffix,
            enabledBorder: border(p.border),
            focusedBorder: border(p.accent, 1.8),
            errorBorder: border(_red),
            focusedErrorBorder: border(_red, 1.8),
          ),
        ),
      ],
    );
  }
}

/// Six boxes over one invisible text field, so paste, autofill
/// (SMS/email one-time codes) and backspace all work natively.
class _CodeInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _CodeInput({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 64,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([controller, focusNode]),
            builder: (context, _) {
              final text = controller.text;
              return Row(
                children: [
                  for (var i = 0; i < _codeLength; i++) ...[
                    // two groups of three, like the code in the email
                    if (i > 0) SizedBox(width: i == 3 ? 18 : 8),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            width: _isActive(i, text) ? 2 : 1.2,
                            color: hasError
                                ? _red
                                : _isActive(i, text)
                                    ? p.accent
                                    : i < text.length
                                        ? p.accent.withValues(alpha: .45)
                                        : p.textLight.withValues(alpha: .7),
                          ),
                          boxShadow: _isActive(i, text)
                              ? [
                                  BoxShadow(
                                      color: p.accent.withValues(alpha: .12),
                                      blurRadius: 12,
                                      spreadRadius: 1)
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          i < text.length ? text[i] : '',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: hasError ? _red : p.textDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: _codeLength,
                showCursor: false,
                enableInteractiveSelection: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onChanged,
                decoration: const InputDecoration(
                    counterText: '', border: InputBorder.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isActive(int i, String text) =>
      focusNode.hasFocus &&
      (i == text.length || (i == _codeLength - 1 && text.length == _codeLength));
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoTile({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: context.palette.textDark.withValues(alpha: .8))),
            ),
          ],
        ),
      );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onTap;
  const _GradientButton({required this.label, required this.busy, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onTap == null ? .45 : 1,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [_plum2, _plum]),
          boxShadow: [
            BoxShadow(
                color: _plum.withValues(alpha: .35),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onTap : null,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.6, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded,
                            color: _gold, size: 20),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
