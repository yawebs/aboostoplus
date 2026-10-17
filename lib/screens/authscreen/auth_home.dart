import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/screens/authscreen/signup_agent.dart';
import 'package:eafind/screens/authscreen/signup_user.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AuthHomeScreen extends StatefulWidget {
  const AuthHomeScreen({Key? key}) : super(key: key);

  @override
  State<AuthHomeScreen> createState() => _AuthHomeScreenState();
}

class _AuthHomeScreenState extends State<AuthHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Top image/header section
            Stack(
              children: [
                Container(
                  height: height(context) * 0.36,
                  width: width(context),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(imageRounte(name: 'bg_intro.png')),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => goTo(context, BottomNavHome(), false),
                    child: Card(
                      color: context.palette.primaryFill,
                      shape: RoundedRectangleBorder(
                        borderRadius: appRadius(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 5),
                        child: Text('Skip', style: TextStyle(color: white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Text(
                    'Home | Event Centers | Apartments | Lands',
                    textAlign: TextAlign.center,
                    style: tHeading.copyWith(color: context.palette.accent),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connecting you to millions of Agents and Landlords worldwide',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Clear "choose your role" label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'I want to sign up as',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Two distinct role cards
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    _RoleCard(
                      icon: Icons.person_search_rounded,
                      title: 'A User',
                      subtitle:
                          'Looking to find a home, apartment or event center',
                      isPrimary: true,
                      onTap: () => goTo(context, SignupUser(), false),
                    ),
                    const SizedBox(height: 14),
                    _RoleCard(
                      icon: Icons.real_estate_agent_rounded,
                      title: 'An Agent / Landlord',
                      subtitle: 'Listing properties for people to find',
                      isPrimary: false,
                      onTap: () => goTo(context, SignAgent(), false),
                    ),
                  ],
                ),
              ),
            ),

            // Login link, pinned at bottom, clearly separated
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 10),
              child: GestureDetector(
                onTap: () =>
                    goTo(context, const LoginScreen(fromNav: false), false),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(
                          color: context.palette.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
            final content = _WebAuthContent(
              onSkip: () => goTo(context, const BottomNavHome(), false),
            );
            if (!AppBreakpoints.isWide(constraints.maxWidth)) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: content,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Aboostoplus',
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 44,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Home | Event Centers | Apartments | Lands',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Connecting you to millions of Agents and Landlords worldwide',
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
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: content,
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
}

class _WebAuthContent extends StatelessWidget {
  final VoidCallback onSkip;
  const _WebAuthContent({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Get started',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            TextButton(
              onPressed: onSkip,
              child: const Text('Skip', style: TextStyle(color: AppColors.textGrey)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'I want to sign up as',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 18),
        _WebRoleCard(
          icon: Icons.person_search_rounded,
          title: 'A User',
          subtitle: 'Looking to find a home, apartment or event center',
          isPrimary: true,
          onTap: () => goTo(context, SignupUser(), false),
        ),
        const SizedBox(height: 14),
        _WebRoleCard(
          icon: Icons.real_estate_agent_rounded,
          title: 'An Agent / Landlord',
          subtitle: 'Listing properties for people to find',
          isPrimary: false,
          onTap: () => goTo(context, SignAgent(), false),
        ),
        const SizedBox(height: 28),
        Center(
          child: GestureDetector(
            onTap: () => goTo(context, const LoginScreen(fromNav: false), false),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Login',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WebRoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _WebRoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_WebRoleCard> createState() => _WebRoleCardState();
}

class _WebRoleCardState extends State<_WebRoleCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.isPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: isPrimary
                ? null
                : Border.all(color: AppColors.border, width: 1.2),
            boxShadow: _hovering ? AppShadows.card : const [],
          ),
          transform: _hovering
              ? (Matrix4.identity()..translate(0.0, -2.0))
              : Matrix4.identity(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.18)
                      : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: isPrimary ? Colors.white : AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPrimary ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPrimary
                            ? Colors.white.withOpacity(0.85)
                            : AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isPrimary ? Colors.white : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? context.palette.primaryFill : context.palette.paper,
      borderRadius: appRadius(14.0),
      child: InkWell(
        borderRadius: appRadius(14.0),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: appRadius(14.0),
            border: isPrimary
                ? null
                : Border.all(color: context.palette.accent.withOpacity(0.4), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.18)
                      : context.palette.primaryFill.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? white : context.palette.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPrimary ? white : context.palette.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPrimary
                            ? Colors.white.withOpacity(0.85)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isPrimary ? white : context.palette.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
