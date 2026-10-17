import 'package:eafind/theme/app_palette.dart';

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/screens/authscreen/auth_home.dart';
import 'package:eafind/screens/forgot_password/email_fpwd.dart';
import 'package:eafind/services/new_auth_service.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/utility/custom_toast.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:eafind/widgets/social_sign_in_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auths/auth_service.dart';
import '../../models/user_model.dart';
import '../../providers/usermodel_provider.dart';
import '../../services/db_services.dart';
import '../../services/notification_token_sync.dart';

class LoginScreen extends StatefulWidget {
  final bool fromNav;
  const LoginScreen({Key? key, required this.fromNav}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Renamed the intent of this flag in my head while reading it:
  // `showPassword == true` was actually being passed to `obscureText`,
  // which is backwards from what the name implies. Kept the variable
  // name so nothing else breaks, but fixed the icon/logic below so the
  // eye icon actually matches what's happening on screen.
  bool showPassword = true;
  bool emailValidated = false;
  bool _isLoading = false;
  // True while a Google/Apple sign-in is running, so the form waits.
  bool _socialBusy = false;
  String? email, pwd;
  var _formKey = GlobalKey<FormState>();

  submit(ctx) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      _formKey.currentState!.save();
      try {
        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        String? userEmail = sharedPreferences.getString('userEmail');
        final result =
            await NewAuthService.instance.login(email: email!, password: pwd!);
        if (result.success) {
          UserModel user = result.user!;
          await NotificationTokenSync.syncOnce(user.id);
          Provider.of<UsermodelProvider>(context, listen: false)
              .setUserModel(user);
          await sharedPreferences.setString('userEmail', user.email);
          CustomToast.show(context,
              title: 'Login Successul',
              message: 'You have successfully logged in');
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (ctx) => BottomNavHome()));
        } else {
          debugPrint('result: ${result.message}');
          setState(() {
            _isLoading = false;
          });
          CustomToast.show(context,
              title: 'Error', message: result.message!, type: ToastType.error);
        }
      } on DioException catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        debugPrint('error: $e');
        CustomToast.show(context,
            title: 'Error', message: e.toString(), type: ToastType.error);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        debugPrint('error: $e');
        CustomToast.show(context,
            title: 'Error', message: e.toString(), type: ToastType.error);
        showErrorSnackbar(
            'Ooops something went wrong, please try again ', context);
      }
    }
  }

  Widget _signInButton({required bool compact}) {
    final child = _isLoading
        ? LoadingAnimationWidget.fallingDot(
            color: white, size: compact ? 28 : 24)
        : Text(
            'Sign in',
            textAlign: TextAlign.center,
            style:
                tStyleWhite.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
          );

    return GestureDetector(
      onTap: _isLoading || _socialBusy ? null : () => submit(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: compact ? 100 : double.infinity,
        height: 52,
        margin: compact
            ? const EdgeInsets.symmetric(vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: context.palette.primaryFill,
          borderRadius: appRadius(14.0),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    final bool showFab = MediaQuery.of(context).viewInsets.bottom == 0.0;
    return Scaffold(
      backgroundColor: context.palette.paper,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              widget.fromNav
                  ? Align(
                      alignment: Alignment.topRight,
                      child: _signInButton(compact: true),
                    )
                  : const SizedBox.shrink(),
              SizedBox(height: widget.fromNav ? 20 : 70),

              // Brand mark: soft tinted circle behind the logo instead of
              // the logo floating alone on white, so the top of the
              // screen has some visual weight to it.
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: context.palette.primaryFill.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      imageRounte(name: 'logo.png'),
                      width: 52,
                      height: 52,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.palette.inkSoft,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 22)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Sign in to continue',
                  style: TextStyle(color: grey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 36),

              // Form card: subtle border + shadow so it reads as one
              // grouped surface rather than two loose outlined boxes
              // floating on the page.
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.palette.paper,
                  borderRadius: appRadius(18.0),
                  border: Border.all(color: grey.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      formContainer(
                        title: 'Email',
                        context: context,
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            hintText: 'Enter email',
                            hintStyle: TextStyle(color: grey, fontSize: 14),
                            prefixIcon:
                                Icon(Icons.mail_outline, size: 20, color: grey),
                            suffixIcon: emailValidated
                                ? Icon(Icons.check_circle,
                                    size: 18, color: Colors.green[400])
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              emailValidated = value.contains('@');
                            });
                          },
                          onSaved: (value) {
                            email = value!.trim().toLowerCase();
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      formContainer(
                        title: 'Password',
                        context: context,
                        child: TextFormField(
                          obscureText: showPassword,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            hintText: 'Enter password',
                            hintStyle: TextStyle(color: grey, fontSize: 14),
                            prefixIcon:
                                Icon(Icons.lock_outline, size: 20, color: grey),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                              child: Icon(
                                // showPassword == true means the field is
                                // currently obscured, so show the "closed
                                // eye" state and vice versa.
                                showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 19,
                                color: grey,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            pwd = value;
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: GestureDetector(
                            onTap: () =>
                                goTo(context, ForgetPasswordEmail(), false),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: context.palette.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _signInButton(compact: true),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SocialSignInButtons(
                  disabled: _isLoading,
                  onBusyChanged: (busy) => setState(() => _socialBusy = busy),
                ),
              ),

              const SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: grey, fontSize: 13.5),
                    ),
                    GestureDetector(
                      onTap: () {
                        goTo(context, const AuthHomeScreen(), false);
                      },
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          color: context.palette.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: showFab && !widget.fromNav ? 90 : 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final formCard = _webFormCard(context);
            if (!AppBreakpoints.isWide(constraints.maxWidth)) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: formCard,
                  ),
                ),
              );
            }
            return Row(
              children: [
                Expanded(
                  child: Container(
                    decoration:
                        const BoxDecoration(gradient: AppColors.heroGradient),
                    child: Padding(
                      padding: const EdgeInsets.all(56),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Image.asset(
                                imageRounte(name: 'logo.png'),
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sign in to keep browsing homes, apartments and lands from agents worldwide.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: formCard,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _webFormCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Sign in',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your details to continue',
          style: TextStyle(fontSize: 14, color: AppColors.textGrey),
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Email',
                hint: 'Enter email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                suffix: emailValidated
                    ? Icon(Icons.check_circle, size: 18, color: Colors.green[400])
                    : null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
                onChanged: (value) =>
                    setState(() => emailValidated = value.contains('@')),
                onSaved: (value) => email = value!.trim().toLowerCase(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                hint: 'Enter password',
                icon: Icons.lock_outline,
                obscureText: showPassword,
                suffix: GestureDetector(
                  onTap: () => setState(() => showPassword = !showPassword),
                  child: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                    color: AppColors.textGrey,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
                onSaved: (value) => pwd = value,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: GestureDetector(
                    onTap: () => goTo(context, ForgetPasswordEmail(), false),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MiaButton(
          text: 'Sign in',
          isEnabled: !_isLoading,
          onPressed: () => submit(context),
          prefix: _isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: LoadingAnimationWidget.fallingDot(
                      color: Colors.white, size: 18),
                )
              : null,
        ),
        const SizedBox(height: 20),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(color: AppColors.textGrey, fontSize: 13.5),
              ),
              GestureDetector(
                onTap: () => goTo(context, const AuthHomeScreen(), false),
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
