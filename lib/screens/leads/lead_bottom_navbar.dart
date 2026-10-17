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
import 'package:eafind/screens/users/user_profile.dart';
import 'package:eafind/upload_forms/house_upload.dart';
import 'package:eafind/widgets/create_post.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:eafind/services/notification_router.dart';

import '../../const/constant.dart';
import '../../theme/app_theme.dart';
import 'leads_dashboard.dart';

class LeadBottomNavbar extends StatefulWidget {
  const LeadBottomNavbar({Key? key}) : super(key: key);

  @override
  _LeadBottomNavbarState createState() => _LeadBottomNavbarState();
}

class _LeadBottomNavbarState extends State<LeadBottomNavbar> {
  var currentUser = FirebaseAuth.instance.currentUser;
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
    // SharedPreferences pref = await SharedPreferences.getInstance();
    // if (pref.getString('userId') != null) {
    //   try {
    //     UserData _userData = await DbServices.getUser();
    //     setState(() {
    //       userData = _userData;
    //     });
    //   } catch (e) {
    //     debugPrint('Boss Error is ${e.toString()}');
    //   }
    // }
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
    // Opens any notification that was tapped to launch the app.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => NotificationRouter.markReady());
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
          backgroundColor: whiteOp,
          resizeToAvoidBottomInset: true,
          body: _buildScreens()[currentTabIndex],
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30.0),
              ),
              child: BottomNavigationBar(
                items: _navBarsItems(),
                type: BottomNavigationBarType.fixed,
                currentIndex: currentTabIndex,
                onTap: ontapItem,
                elevation: 15,
                selectedItemColor: primaryColor,
                unselectedItemColor: primaryColor,
              ),
            ),
          ),
        ));
  }

  // Same tab content + currentTabIndex state as mobile; only the nav
  // chrome (bottom bar vs. drawer/rail/sidebar) differs on web.
  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: ResponsiveWebShell(
        currentIndex: currentTabIndex,
        onTap: ontapItem,
        screens: _buildScreens(),
        items: const [
          WebNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
          WebNavItem(icon: Icons.home_rounded, label: 'Home'),
          WebNavItem(icon: Icons.explore_rounded, label: 'Explore'),
        ],
      ),
    );
  }

  List<Widget> _buildScreens() {
    return [
      LeadsDashboard(),
      HomeScreen(),
      ExploreScreen(),
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
                  Icons.dashboard,
                ),
              )
            : Icon(
                Icons.dashboard,
              ),
        label: ("Dashboard"),
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
                  Icons.home,
                  color: white,
                ),
              )
            : Icon(Icons.home),
        label: ("Home"),
      ),
      BottomNavigationBarItem(
        icon: currentTabIndex == 2
            ? Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                    borderRadius: appRadius(20.0),
                    gradient: LinearGradient(colors: gradientColors)),
                child: Icon(
                  Icons.explore,
                  color: white,
                ),
              )
            : Icon(Icons.explore),
        label: ("Explore"),
      ),
    ];
  }
}
