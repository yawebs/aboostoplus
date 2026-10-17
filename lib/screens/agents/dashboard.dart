import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/providers/refresh_deal_provider.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/agents/bank_details.dart';
import 'package:eafind/screens/agents/user_account.dart';
import 'package:eafind/screens/notification_view.dart';
import 'package:eafind/screens/users/edit_profile.dart';
import 'package:eafind/screens/verification/agent_verification_screen.dart';
import 'package:eafind/widgets/verified_badge.dart';
import 'package:eafind/upload_forms/house_upload.dart';
import 'package:eafind/widgets/app_drawer.dart';

import 'package:eafind/services/providers/theme_mode_provider.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/deals_widget.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/db_services.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserModel? onlineUser;
  int revenue = 0;
  int income = 0;
  int withdrawals = 0;
  int avaiable = 0;
  int pending = 0;
  var userDeals = [];
  bool isLoading = false;
  getUser() async {
    UserModel? user =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();

    setState(() {
      onlineUser = user;
    });
  }

  getDealsOnly() async {
    setState(() {
      isLoading = true;
    });
    try {
      var data = [];
      if (onlineUser!.userType == 'User') {
        data = await DbServices.getCustomerDeals(onlineUser!.id);
      } else {
        data = await DbServices.getAgentDeals(onlineUser!.id);
      }
      // The widget may have been disposed (e.g. the user navigated away)
      // while that network request was in flight.
      if (!mounted) return;

      if (data.isNotEmpty) {
        setState(() {
          userDeals = data;
          isLoading = false;
        });
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      showErrorSnackbar('Oops unable to get revenue', context);
      // getRevenue();
    }
  }

  getRevenue() async {
    setState(() {
      isLoading = true;
    });
    try {
      var data = [];
      if (onlineUser == null) return;
      data = await DbServices.getAgentDeals(onlineUser!.id);
      // The widget may have been disposed (e.g. the user navigated away)
      // while that network request was in flight.
      if (!mounted) return;

      if (data.isNotEmpty) {
        setState(() {
          userDeals = data;
          isLoading = false;
        });
        for (var items in data) {
          setState(() {
            revenue += int.parse(items['amount'].toString());
            income += int.parse(items['amount'].toString());
          });
        }
        setState(() {
          userDeals = data;
          isLoading = false;
        });
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      showErrorSnackbar('Oops unable to get revenue', context);
      // getRevenue();
    }
  }

  getBalance() async {}
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
    getRevenue();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    bool shouldRefresh = Provider.of<RefreshDealProvider>(context).getState();
    if (shouldRefresh == true) {
      getDealsOnly();
      Provider.of<RefreshDealProvider>(context, listen: false)
          .changeStateWithoutNotif(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Theme(
      data: AppTheme.of(context),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.palette.surface,
        drawer: onlineUser == null
            ? null
            : AppDrawer(
                sKey: _scaffoldKey,
                onlineUser: onlineUser!,
              ),
        body: ListView(
          // The home shell's floating navbar overlaps the body (extendBody),
          // and reports its height as the bottom padding - keep the last
          // inspection card scrollable clear of it.
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16),
          children: [
            _heroSection(context),
            if (onlineUser != null) ...[
              Transform.translate(
                offset: const Offset(0, -34),
                child: _bentoDuo(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick actions',
                      style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.palette.textDark),
                    ),
                    const SizedBox(height: 14),
                    _quickActionsRow(context),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ] else
              const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Inspections',
                        style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.palette.textDark),
                      ),
                      if (onlineUser != null && !isLoading) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.palette.primaryFill.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${userDeals.length}',
                            style: TextStyle(
                                color: context.palette.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  (onlineUser == null || isLoading)
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: context.palette.accent)),
                        )
                      : userDeals.isEmpty
                          ? const EmptyState(
                              icon: Icons.inbox_outlined,
                              title: 'No deals found',
                            )
                          : Column(
                              children: [
                                for (final data in userDeals)
                                  DealsWidget(data: data),
                              ],
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Full-bleed gradient hero: greeting/avatar + drawer/notification access,
  // then the revenue figure treated as the dashboard's headline number
  // (with a purely decorative sparkline - not bound to any real trend
  // data, since none is computed here).
  Widget _heroSection(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, topInset + 16, 22, 58),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC45A06), Color(0xFF161616), Color(0xFF0A0A0A)],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x4DF7821B), Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: onlineUser == null
                        ? SizedBox(
                            height: 44,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: LoadingAnimationWidget.fallingDot(
                                  color: Colors.white, size: 22),
                            ),
                          )
                        : Row(
                            children: [
                              _heroAvatar(),
                              const SizedBox(width: 11),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _greeting(),
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.white.withOpacity(0.6),
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 1),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        onlineUser!.firstName,
                                        style: const TextStyle(
                                            fontFamily: 'Fraunces',
                                            fontSize: 17,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      VerifiedBadge(
                                          userId: onlineUser!.id, size: 17),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  Row(
                    children: [
                      _glassIconButton(Icons.notifications_none_rounded,
                          () => goTo(context, NotificationView(), false)),
                      const SizedBox(width: 8),
                      _glassIconButton(
                          Theme.of(context).brightness == Brightness.dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          () => context
                              .read<ThemeModeProvider>()
                              .toggle(context)),
                      const SizedBox(width: 8),
                      _glassIconButton(Icons.menu_rounded,
                          () => _scaffoldKey.currentState!.openDrawer()),
                    ],
                  ),
                ],
              ),
              if (onlineUser != null) ...[
                const SizedBox(height: 30),
                Text(
                  onlineUser!.userType == 'User' ? 'TOTAL SPENT' : 'TOTAL REVENUE',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: Color(0xFFF7821B)),
                ),
                const SizedBox(height: 6),
                Text(
                  '₦${NumberFormat().format(revenue)}',
                  style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 210,
                  height: 32,
                  child: CustomPaint(
                      painter: _SparklinePainter(), size: const Size(210, 32)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroAvatar() {
    final hasImage = onlineUser!.profileImage != null &&
        onlineUser!.profileImage.toString().isNotEmpty;
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(onlineUser!.profileImage, fit: BoxFit.cover)
            : Image.asset(imageRounte(name: avatarImage), fit: BoxFit.cover),
      ),
    );
  }

  Widget _glassIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // Pending / Available - deliberately unequal widths and one dark, one
  // light card so the pair reads as a designed duo rather than a
  // symmetric stat grid.
  Widget _bentoDuo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 42,
            child: _bentoCard(
              icon: Icons.hourglass_empty_rounded,
              iconBg: AppColors.secondary.withOpacity(0.14),
              iconColor: const Color(0xFFD96A0B),
              value: '₦${NumberFormat().format(income)}',
              label: 'Pending',
              bg: context.palette.card,
              valueColor: context.palette.textDark,
              labelColor: context.palette.textGrey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 58,
            child: _bentoCard(
              icon: Icons.account_balance_wallet_outlined,
              iconBg: Colors.white.withOpacity(0.14),
              iconColor: Colors.white,
              value: '₦${NumberFormat().format(withdrawals)}',
              label: 'Available to withdraw',
              bg: AppColors.primary,
              valueColor: Colors.white,
              labelColor: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bentoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required Color bg,
    required Color valueColor,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
        ],
      ),
    );
  }

  Widget _quickActionsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _actionCircle(
              Icons.file_upload_outlined,
              'Uploads',
              context.palette.accent,
              context.palette.accent.withOpacity(0.14),
              () => goTo(context, HouseUploadScreen(), false)),
          const SizedBox(width: 14),
          _actionCircle(
              Icons.verified_outlined,
              'Verification',
              VerifiedBadge.blue,
              VerifiedBadge.blue.withOpacity(0.12),
              () => goTo(context, const AgentVerificationScreen(), false)),
          const SizedBox(width: 14),
          _actionCircle(
              Icons.account_balance_outlined,
              'Bank details',
              const Color(0xFFD96A0B),
              AppColors.secondary.withOpacity(0.14),
              () => goTo(context, BankDetails(), false)),
          const SizedBox(width: 14),
          _actionCircle(
              Icons.edit_outlined,
              'Edit profile',
              const Color(0xFF3E6FB0),
              const Color(0x1F3E6FB0),
              () => goTo(context, EditProfile(), false)),
          if (onlineUser!.userType == 'Admin') ...[
            const SizedBox(width: 14),
            _actionCircle(
                Icons.people_outline,
                'Users',
                AppColors.success,
                AppColors.success.withOpacity(0.12),
                () => userListModal(context)),
          ],
        ],
      ),
    );
  }

  Widget _actionCircle(IconData icon, String label, Color iconColor, Color bg,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5,
                  color: context.palette.textDark,
                  fontWeight: FontWeight.w500),
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
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        endDrawer: onlineUser == null
            ? null
            : AppDrawer(sKey: _scaffoldKey, onlineUser: onlineUser!),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: userProfile()),
                        _iconButton(
                          Icons.notifications_none_rounded,
                          () => goTo(context, NotificationView(), false),
                        ),
                        const SizedBox(width: 10),
                        _iconButton(
                          Icons.settings_outlined,
                          () => _scaffoldKey.currentState?.openEndDrawer(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    onlineUser == null
                        ? const SizedBox.shrink()
                        : Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: 240,
                                child: StatTile(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: onlineUser!.userType == 'User'
                                      ? 'Spent'
                                      : 'Revenue',
                                  value: '₦${NumberFormat().format(revenue)}',
                                ),
                              ),
                              SizedBox(
                                width: 240,
                                child: StatTile(
                                  icon: Icons.hourglass_empty_rounded,
                                  label: 'Pending',
                                  value: '₦${NumberFormat().format(income)}',
                                  accentColor: AppColors.secondary,
                                ),
                              ),
                              SizedBox(
                                width: 240,
                                child: StatTile(
                                  icon: Icons.savings_outlined,
                                  label: 'Available',
                                  value:
                                      '₦${NumberFormat().format(withdrawals)}',
                                  accentColor: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 28),
                    Text(
                      'Actions',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _actionTile(Icons.add, 'Uploads',
                            () => goTo(context, HouseUploadScreen(), false)),
                        if (onlineUser != null &&
                            onlineUser!.userType == 'Admin')
                          _actionTile(Icons.account_box, 'Users',
                              () => userListModal(context)),
                        _actionTile(Icons.home_outlined, 'Bank details',
                            () => goTo(context, BankDetails(), false)),
                        _actionTile(Icons.edit_outlined, 'Edit profile',
                            () => goTo(context, EditProfile(), false)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Inspections',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    (onlineUser == null || isLoading)
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary)),
                          )
                        : userDeals.isEmpty
                            ? const EmptyState(
                                icon: Icons.inbox_outlined,
                                title: 'No deals found',
                              )
                            : Column(
                                children: [
                                  for (final data in userDeals)
                                    DealsWidget(data: data),
                                ],
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

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.palette.background,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.card,
          ),
          child: Icon(icon, color: context.palette.textDark, size: 20),
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: context.palette.accent),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: context.palette.textDark, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget userProfile() {
    return onlineUser == null
        ? LoadingAnimationWidget.fallingDot(color: white, size: 25)
        : Row(
            children: [
              Container(
                height: 50,
                width: 50,
                padding: EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                    color: context.palette.paper,
                    border: Border.all(
                      width: 1.0,
                      color: context.palette.border,
                    ),
                    borderRadius: appRadius(50.0)),
                child: (onlineUser!.profileImage == null ||
                        onlineUser!.profileImage.toString().isEmpty)
                    ? ClipOval(
                        child: Image.asset(
                          imageRounte(name: avatarImage),
                          fit: BoxFit.cover,
                        ),
                      )
                    : ClipOval(
                        child: Image.network(
                        onlineUser!.profileImage,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, ${onlineUser!.firstName}",
                      style: TextStyle(fontSize: 18, color: context.palette.accent),
                    ),
                    // GestureDetector(
                    //   onTap: () =>
                    //       goTo(context, const AgentVerificationScreen(), false),
                    //   child: Container(
                    //       decoration: BoxDecoration(
                    //         color: primaryColor.withOpacity(.1),
                    //         borderRadius: appRadius(10.0),
                    //       ),
                    //       padding: EdgeInsets.all(2.0),
                    //       child: Row(
                    //         children: [
                    //           w5(),
                    //           Text(
                    //             'verify account',
                    //             style: tStyle(color: primaryColor, size: 12.0),
                    //           ),
                    //           w5(),
                    //           Icon(
                    //             Icons.arrow_forward_ios,
                    //             size: 12,
                    //             color: primaryColor,
                    //           )
                    //         ],
                    //       )),
                    // )
                  ],
                ),
              )
            ],
          );
  }
}

// Purely decorative flourish behind the hero revenue figure - not bound
// to any real trend data.
class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.78)
      ..cubicTo(
        size.width * 0.14,
        size.height * 0.85,
        size.width * 0.20,
        size.height * 0.22,
        size.width * 0.32,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.44,
        size.height * 0.62,
        size.width * 0.50,
        size.height * 0.88,
        size.width * 0.61,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.0,
        size.width * 0.80,
        size.height * 0.10,
        size.width * 1.0,
        size.height * 0.26,
      );
    final paint = Paint()
      ..color = const Color(0xFFF7821B).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
