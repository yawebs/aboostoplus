import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../const/constant.dart';
import '../authscreen/login_screen.dart';

class SuccessfullySent extends StatefulWidget {
  final email;
  const SuccessfullySent({Key? key, required this.email});

  @override
  State<SuccessfullySent> createState() => _SuccessfullySentState();
}

class _SuccessfullySentState extends State<SuccessfullySent> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    bool showSheet = MediaQuery.of(context).viewInsets.bottom == 0.0;

    return Scaffold(
      backgroundColor: context.palette.paper,
      bottomSheet: showSheet
          ? GestureDetector(
              onTap: () async {
                goTo(context, LoginScreen(fromNav: false), false);
              },
              child: Container(
                height: 45,
                margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                decoration: BoxDecoration(
                  color: context.palette.primaryFill,
                  borderRadius: appRadius(8.0),
                ),
                child: Center(
                    child: Text(
                  'Proceed to login screen',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: white),
                )),
              ),
            )
          : null,
      body: _isLoading
          ? appLoader(50.0)
          : ListView(
              children: [
                h40(),
                Image.asset(
                  imageRounte(name: logoPath),
                  width: 100,
                  height: 100,
                ),
                h10(),
                Text(
                  'Password Reset Link Sent',
                  textAlign: TextAlign.center,
                  style: tStyle(color: context.palette.ink, size: 24.0),
                ),
                h10(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Please check your email (${widget.email}) and spam box for a password reset link',
                    textAlign: TextAlign.center,
                    style: tStyle(color: context.palette.ink, size: 14.0),
                  ),
                ),
                h40(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'didnt recieve password reset link?',
                    textAlign: TextAlign.center,
                    style: tStyle(color: context.palette.accent, size: 14.0),
                  ),
                ),
                h15(),
                Center(
                  child: GestureDetector(
                    onTap: () => goBack(context),
                    child: Container(
                      width: width(context) / 2,
                      height: 50,
                      decoration: BoxDecoration(
                          color: context.palette.primaryFill, borderRadius: appRadius(20.0)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.loop,
                            color: white,
                          ),
                          Text(
                            'Resend',
                            style: tStyle(color: white),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AppCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_read_rounded,
                          color: AppColors.success, size: 32),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Password reset link sent',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please check your email (${widget.email}) and spam folder for a password reset link',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 24),
                    MiaButton(
                      text: 'Proceed to login',
                      onPressed: () =>
                          goTo(context, LoginScreen(fromNav: false), false),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => goBack(context),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Resend'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
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
