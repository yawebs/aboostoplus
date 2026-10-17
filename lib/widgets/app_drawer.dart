import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/screens/agents/bank_details.dart';
import 'package:eafind/screens/users/delete_account.dart';
import 'package:eafind/screens/users/edit_profile.dart';
import 'package:eafind/services/providers/saved_homes_provider.dart';
import 'package:eafind/services/providers/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:eafind/screens/explore_area/explore_area_screen.dart';
import 'package:eafind/screens/saved/saved_homes_screen.dart';
import 'package:eafind/screens/saved/search_alerts_screen.dart';
import 'package:eafind/screens/services/moving_services_screen.dart';
import 'package:eafind/screens/verification/agent_verification_screen.dart';
import 'package:eafind/services/verification_service.dart';
import 'package:eafind/widgets/verified_badge.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Side menu: gradient profile header, grouped sections (house hunting,
// account, appearance, support) and a footer with sign-out.
class AppDrawer extends StatefulWidget {
  final GlobalKey<ScaffoldState> sKey;
  final UserModel onlineUser;
  const AppDrawer({Key? key, required this.sKey, required this.onlineUser})
      : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  static const _gold = Color(0xFFF5C76A);
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    }).catchError((_) {});
  }

  // Close the drawer first so it isn't still open when the user comes back.
  void _open(Widget screen) {
    Navigator.of(context).pop();
    goTo(context, screen, false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final screenW = MediaQuery.of(context).size.width;
    final saved = context.watch<SavedHomesProvider>();

    return Drawer(
      width: screenW * 0.84 > 340 ? 340 : screenW * 0.84,
      backgroundColor: palette.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _header(palette, saved.count),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              children: [
                _sectionLabel(palette, 'HOUSE HUNTING'),
                _tile(
                  palette,
                  icon: Icons.travel_explore_rounded,
                  color: const Color(0xFF8E5BD8),
                  title: 'Explore an area',
                  subtitle: 'AI briefing on any neighbourhood',
                  badge: 'AI',
                  onTap: () => _open(const ExploreAreaScreen()),
                ),
                _tile(
                  palette,
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFE5484D),
                  title: 'Saved homes',
                  subtitle: 'Listings you hearted',
                  badge: saved.count > 0 ? '${saved.count}' : null,
                  onTap: () => _open(const SavedHomesScreen()),
                ),
                _tile(
                  palette,
                  icon: Icons.notifications_active_rounded,
                  color: const Color(0xFFE8A93B),
                  title: 'Search alerts',
                  subtitle: 'Get notified about new matches',
                  onTap: () => _open(const SearchAlertsScreen()),
                ),
                _tile(
                  palette,
                  icon: Icons.local_shipping_rounded,
                  color: const Color(0xFF6A3D7A),
                  title: 'Moving & home services',
                  subtitle: 'Movers, cleaners, power & more',
                  onTap: () => _open(const MovingServicesScreen()),
                ),
                _sectionLabel(palette, 'ACCOUNT'),
                if (widget.onlineUser.userType != 'User')
                  ValueListenableBuilder<int>(
                    valueListenable: VerifiedUsers.instance.changes,
                    builder: (_, __, ___) {
                      final verified = VerifiedUsers.instance
                              .isVerified(widget.onlineUser.id) ==
                          true;
                      return _tile(
                        palette,
                        icon: Icons.verified_rounded,
                        color: VerifiedBadge.blue,
                        title: verified ? 'Verified agent' : 'Get verified',
                        subtitle: verified
                            ? 'Your badge is live'
                            : 'Earn the blue tick renters trust',
                        badge: verified ? null : 'NEW',
                        onTap: () => _open(const AgentVerificationScreen()),
                      );
                    },
                  ),
                _tile(
                  palette,
                  icon: Icons.person_rounded,
                  color: const Color(0xFF3A86E0),
                  title: 'Edit profile',
                  subtitle: 'Name, photo & contact details',
                  onTap: () => _open(EditProfile()),
                ),
                _tile(
                  palette,
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFF2E9E8F),
                  title: 'Bank details',
                  subtitle: 'Where your payouts go',
                  onTap: () => _open(const BankDetails()),
                ),
                _sectionLabel(palette, 'APPEARANCE'),
                _themeSelector(palette),
                _sectionLabel(palette, 'SUPPORT'),
                _tile(
                  palette,
                  icon: Icons.support_agent_rounded,
                  color: const Color(0xFF2E9E5B),
                  title: 'Help & feedback',
                  subtitle: 'Questions, ideas or a problem?',
                  onTap: () => launchUrl(Uri.parse('https://aboostoplus.com'),
                      mode: LaunchMode.externalApplication),
                ),
              ],
            ),
          ),
          _footer(palette),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _header(AppPalette palette, int savedCount) {
    final user = widget.onlineUser;
    final name = '${user.firstName} ${user.lastName}'.trim();
    final image = (user.profileImage ?? '').toString();
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.45)!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primaryFill, deep],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 10, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar with a gold ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: [_gold, Color(0xFFE8A93B)]),
                        ),
                        child: CircleAvatar(
                          radius: 31,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              image.isNotEmpty ? NetworkImage(image) : null,
                          onBackgroundImageError:
                              image.isNotEmpty ? (_, __) {} : null,
                          child: image.isEmpty
                              ? Text(
                                  name.isEmpty ? '?' : name[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: palette.primaryFill,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name.isEmpty ? 'Welcome' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      VerifiedBadge(userId: user.id, size: 20, gap: 6),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: _gold.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          user.userType,
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _headerPill(
                        icon: Icons.edit_rounded,
                        label: 'Edit profile',
                        onTap: () => _open(EditProfile()),
                      ),
                      const SizedBox(width: 8),
                      _headerPill(
                        icon: Icons.favorite_rounded,
                        label: '$savedCount saved',
                        onTap: () => _open(const SavedHomesScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerPill(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sections & rows ──────────────────────────────────────────────────────
  Widget _sectionLabel(AppPalette palette, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: palette.inkMuted,
          ),
        ),
      );

  Widget _tile(
    AppPalette palette, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: palette.ink)),
                      const SizedBox(height: 1),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5, color: palette.inkMuted)),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                Icon(Icons.chevron_right_rounded,
                    color: palette.inkMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // System / Light / Dark segmented selector (see ThemeModeProvider).
  Widget _themeSelector(AppPalette palette) {
    final themeMode = context.watch<ThemeModeProvider>();
    Widget option(ThemeMode mode, IconData icon, String label) {
      final selected = themeMode.mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => themeMode.setMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? palette.primaryFill : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 18, color: selected ? Colors.white : palette.inkSoft),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : palette.inkSoft,
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          option(ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
          option(ThemeMode.light, Icons.light_mode_rounded, 'Light'),
          option(ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────
  Widget _footer(AppPalette palette) {
    const danger = Color(0xFFD64545);
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => logoutDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.ink,
                side: BorderSide(color: palette.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton(
                onPressed: () => _open(DeleteAccount()),
                style: TextButton.styleFrom(
                  foregroundColor: danger,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Delete account',
                    style: TextStyle(fontSize: 12.5)),
              ),
              const Spacer(),
              Text(
                _version.isEmpty ? 'Aboostoplus' : 'Aboostoplus v$_version',
                style: TextStyle(fontSize: 11.5, color: palette.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Faint scattered stars for the header.
class _StarsPainter extends CustomPainter {
  static const List<List<double>> _stars = [
    [0.12, 0.18, 1.2],
    [0.35, 0.08, 0.9],
    [0.62, 0.22, 1.4],
    [0.82, 0.12, 1.0],
    [0.92, 0.42, 1.2],
    [0.55, 0.55, 0.8],
    [0.78, 0.7, 1.1],
    [0.25, 0.86, 0.9],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (final s in _stars) {
      canvas.drawCircle(
          Offset(size.width * s[0], size.height * s[1]), s[2], paint);
    }
    canvas.drawCircle(
      Offset(size.width * 1.05, size.height * 0.05),
      110,
      Paint()
        ..color = const Color(0xFFF5C76A).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
