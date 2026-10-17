// ignore_for_file: prefer_const_constructors, prefer_final_fields
import 'package:dotted_border/dotted_border.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/navigation_provider.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/screens/explore.dart';
import 'package:eafind/screens/home_screen.dart';
import 'package:eafind/screens/agents/dashboard.dart';
import 'package:eafind/screens/agents/user_account.dart';
import 'package:eafind/screens/users/user_dashboard.dart';
import 'package:eafind/upload_forms/house_upload.dart';
import 'package:eafind/widgets/create_post.dart';
import 'package:eafind/widgets/recomended_videos.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:eafind/services/update_checker.dart';

import 'package:provider/provider.dart';

import '../const/constant.dart';
import '../theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:eafind/services/notification_router.dart';

import '../screens/leads/leads_dashboard.dart';
import '../screens/marketplace/market_home.dart';

class BottomNavHome extends StatefulWidget {
  const BottomNavHome({Key? key}) : super(key: key);

  @override
  _BottomNavHomeState createState() => _BottomNavHomeState();
}

class _BottomNavHomeState extends State<BottomNavHome> {
  int currentTabIndex = 0;
  // UserData? userData;
  UserModel? user;
  bool canPop = false;
  onTapped(int index) {
    setState(() {
      currentTabIndex = index;
    });
  }

// UserModel _userModel = Provider.of<Signup>(context)
  ontapItem(int index) {
    setState(() {
      currentTabIndex = index;
    });
  }

  getUser() async {
    UserModel? _user =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    setState(() {
      user = _user;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
    setState(() {
      currentTabIndex =
          Provider.of<NavigationProvider>(context, listen: false).getScreen();
    });
    // Once per app launch: prompt to update if a newer build is published
    // (see lib/call/app-version.php).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) UpdateChecker.check(context);
      // Opens any notification that was tapped to launch the app.
      NotificationRouter.markReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvoked: (d) => showDialog<bool>(
        context: context,
        barrierColor: Colors.black45,
        builder: (c) => AlertDialog(
          title: Text('Exiting App'),
          content: Container(
            height: 40,
            child: Column(
              children: [
                Text('Do you really want to exit app?'),
                Divider(),
              ],
            ),
          ),
          actions: [
            MaterialButton(
              child: Text('Yes'),
              onPressed: () => SystemNavigator.pop(),
            ),
            MaterialButton(
              child: Text('No'),
              onPressed: () => Navigator.pop(c, false),
            ),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: black,
        resizeToAvoidBottomInset: true,
        extendBody: true,
        body: _buildScreens()[currentTabIndex],
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.transparent,
          ),
          // Lifts the floating pill above the system navigation area
          // (gesture bar / 3-button bar). Uses at least 16px of margin,
          // or the device's bottom inset when that's larger.
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(35.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35.0),
                // BottomNavigationBar adds the bottom system inset to its
                // own height. Inside a floating pill that made the pill
                // stretch toward the screen edge on devices with a gesture
                // bar / on-screen buttons. The SafeArea above already
                // handles the inset, so strip it here.
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: BottomNavigationBar(
                    items: _navBarsItems(),
                    type: BottomNavigationBarType.fixed,
                    currentIndex: currentTabIndex,
                    onTap: ontapItem,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    showSelectedLabels: false,
                    showUnselectedLabels: false,
                    selectedItemColor: primaryColor,
                    unselectedItemColor: white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reuses the exact same `_buildScreens()` tab content and
  // `currentTabIndex` state as mobile — only the navigation chrome
  // (bottom tab bar vs. drawer/rail/sidebar) differs on web.
  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: ResponsiveWebShell(
        currentIndex: currentTabIndex,
        onTap: ontapItem,
        screens: _buildScreens(),
        items: const [
          WebNavItem(icon: Icons.home_rounded, label: 'Home'),
          WebNavItem(icon: Icons.video_collection_rounded, label: 'Videos'),
          WebNavItem(icon: Icons.add_circle_outline_rounded, label: 'Post'),
          WebNavItem(icon: Icons.storefront_rounded, label: 'MarketHub'),
          WebNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
        ],
      ),
    );
  }

  List<Widget> _buildScreens() {
    debugPrint('user is ${user?.userType}');
    return [
      HomeScreen(),
      RecommendedVideos(
        properties: [],
      ),
      (user == null)
          ? LoginScreen(
              fromNav: true,
            )
          : user!.userType == 'User'
              ? CreatePostSheet(
                  user: user!,
                )
              : HouseUploadScreen(),
      (user == null)
          ? LoginScreen(
              fromNav: true,
            )
          : MarketHome(),
      user == null
          ? LoginScreen(
              fromNav: true,
            )
          : user!.userType == 'User'
              ? const UserDashboard()
              : user!.userType == 'Lead'
                  ? LeadsDashboard()
                  : Dashboard()
    ];
  }

  List<BottomNavigationBarItem> _navBarsItems() {
    return [
      BottomNavigationBarItem(
        icon: currentTabIndex == 0
            ? Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                    borderRadius: appRadius(20.0),
                    gradient: LinearGradient(colors: gradientColors)),
                child: Icon(
                  Icons.home,
                  color: white,
                ),
              )
            : Icon(Icons.home),
        label: ("Home"),
      ),
      BottomNavigationBarItem(
        icon: currentTabIndex == 1
            ? Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                    borderRadius: appRadius(20.0),
                    gradient: LinearGradient(colors: gradientColors)),
                child: Icon(
                  Icons.video_collection,
                  color: white,
                ),
              )
            : Icon(Icons.video_collection),
        label: ("Videos"),
      ),
      BottomNavigationBarItem(
        icon: Container(
          width: 50,
          height: 50,
          padding: EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            borderRadius: appRadius(20.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Container(
            width: 40,
            height: 40,
            padding: EdgeInsets.all(7.0),
            decoration: BoxDecoration(
              borderRadius: appRadius(20.0),
              color: black,
            ),
            child: DottedBorder(
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Color.fromARGB(204, 255, 255, 255),
                ),
              ),
            ),
          ),
        ),
        label: '',
      ),
      // BottomNavigationBarItem(
      //   icon: currentTabIndex == 3
      //       ? Container(
      //           width: 35,
      //           height: 35,
      //           decoration: BoxDecoration(
      //               borderRadius: appRadius(20.0),
      //               gradient: LinearGradient(colors: gradientColors)),
      //           child: Icon(
      //             Icons.person_outline_sharp,
      //           ),
      //         )
      //       : Icon(Icons.incomplete_circle),
      //   label: ("Portfolio"),
      // ),
      //       BottomNavigationBarItem(
      //   icon: currentTabIndex == 3
      //       ? Container(
      //           width: 35,
      //           height: 35,
      //           decoration: BoxDecoration(
      //               borderRadius: appRadius(20.0),
      //               gradient: LinearGradient(colors: gradientColors)),
      //           child: Icon(
      //             Icons.person_outline_sharp,
      //           ),
      //         )
      //       : Icon(Icons.incomplete_circle),
      //   label: ("Portfolio"),
      // ),
      BottomNavigationBarItem(
        icon: currentTabIndex == 3
            ? Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                    borderRadius: appRadius(20.0),
                    gradient: LinearGradient(colors: gradientColors)),
                child: Icon(
                  Icons.shopping_cart_rounded,
                ),
              )
            : Icon(Icons.shopping_cart_rounded),
        label: ("MarketHub"),
      ),
      BottomNavigationBarItem(
        icon: currentTabIndex == 4
            ? Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                    borderRadius: appRadius(20.0),
                    gradient: LinearGradient(colors: gradientColors)),
                child: Icon(
                  Icons.dashboard,
                ),
              )
            : Icon(
                Icons.dashboard,
              ),
        label: ("Dashboard"),
      ),
    ];
  }
}
