import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eafind/auths/auth_service.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/firebase_options.dart';
import 'package:eafind/providers/location_provider.dart';
import 'package:eafind/providers/navigation_provider.dart';
import 'package:eafind/providers/refresh_deal_provider.dart';
import 'package:eafind/providers/report_property_provider.dart';
import 'package:eafind/providers/userId_provider.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/auth_home.dart';
import 'package:eafind/screens/leads/lead_bottom_navbar.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/services/new_auth_service.dart';
import 'package:eafind/services/providers/data_provider.dart';
import 'package:eafind/services/providers/marketplace_provider.dart';
import 'package:eafind/services/providers/rebuild_provider.dart';
import 'package:eafind/services/providers/tagged_users_provider.dart';
import 'package:eafind/services/providers/theme_mode_provider.dart';
import 'package:eafind/services/providers/saved_homes_provider.dart';
import 'package:eafind/services/notification_router.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:eafind/widgets/network_status_banner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/user_model.dart';
import 'screens/onboarding/feature_tour.dart';
import 'services/permision_handler_service.dart';
import 'services/push_notification_service.dart';

// Top-level background handler (Must be outside any class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PushNotificationService.initializeLocalNotifications();
  await PushNotificationService.showDataOnlyNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService.initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await PermissionService.requestNotificationPermission();
  // final binding = WidgetsFlutterBinding.ensureInitialized();
  // FlutterNativeSplash.preserve(widgetsBinding: binding);
  // Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  final themeModeProvider = await ThemeModeProvider.load();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<UsermodelProvider>(
      create: (_) => UsermodelProvider(),
    ),
    ChangeNotifierProvider<DataProvider>(
      create: (_) => DataProvider(),
    ),
    ChangeNotifierProvider<MarketplaceProvider>(
      create: (_) => MarketplaceProvider(),
    ),
    ChangeNotifierProvider<RefreshDealProvider>(
      create: (_) => RefreshDealProvider(),
    ),
    ChangeNotifierProvider<ReportPropertyProvider>(
      create: (_) => ReportPropertyProvider(),
    ),
    ChangeNotifierProvider<LocationProvider>(
      create: (context) => LocationProvider(),
    ),
    ChangeNotifierProvider<RebuildProvider>(
      create: (context) => RebuildProvider(),
    ),
    ChangeNotifierProvider<NavigationProvider>(
      create: (context) => NavigationProvider(),
    ),
    ChangeNotifierProvider<TaggedAgentsProvider>(
      create: (context) => TaggedAgentsProvider(),
    ),
    ChangeNotifierProvider<UseridProvider>(
      create: (context) => UseridProvider(),
    ),
    ChangeNotifierProvider<ThemeModeProvider>.value(value: themeModeProvider),
    // Saved homes follow whoever is signed in.
    ChangeNotifierProxyProvider<UsermodelProvider, SavedHomesProvider>(
      create: (_) => SavedHomesProvider(),
      update: (_, users, saved) =>
          (saved ?? SavedHomesProvider())..syncUser(users.userModel?.id),
    ),
  ], child: MyApp()));
  // unawaited(_requestSystemNotificationPermission());
  FlutterNativeSplash.remove();
}

Future<void> _requestSystemNotificationPermission() async {
  try {
    await PermissionService.requestNotificationPermission();
  } catch (error) {
    debugPrint('post-launch notification permission error: $error');
  }
}

// Flutter's default ScrollBehavior omits PointerDeviceKind.mouse from
// dragDevices, so click-and-drag doesn't work on web/desktop — PageViews
// (property image galleries, story viewers, etc.) only respond to touch.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  UserModel? onlineUser;

  bool _isLoading = false;
  // First launch: show the feature tour before the sign-up screen.
  bool _showTour = false;
  @override
  initState() {
    super.initState();
    getUser(context);
    // Deferred to a post-frame callback: these providers sit above MyApp
    // in the tree (see the MultiProvider in main()), so calling them here
    // synchronously would notifyListeners() into that ancestor while the
    // initial build pass from runApp() is still locked, which throws
    // "setState() or markNeedsBuild() called during build."
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Fetched once for the lifetime of the app - screens read the cached
      // data from these providers instead of refetching on every mount.
      Provider.of<DataProvider>(context, listen: false)
          .fetchProperties(context, propertyType: 'Houses');
      Provider.of<DataProvider>(context, listen: false)
          .fetchFeaturedProperties();
      Provider.of<MarketplaceProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dark mode is mobile-only: web always renders the light theme.
    final themeMode = kIsWeb
        ? ThemeMode.light
        : context.select<ThemeModeProvider, ThemeMode>((p) => p.mode);
    return MaterialApp(
      // Lets notification taps open screens (see NotificationRouter).
      navigatorKey: appNavigatorKey,
      title: 'Aboostoplus',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: kIsWeb
          ? ThemeData(primaryColor: primaryColor)
          : AppTheme.mobileLight,
      darkTheme: kIsWeb ? null : AppTheme.mobileDark,
      themeMode: themeMode,
      builder: (context, child) =>
          NetworkStatusBanner(child: child ?? const SizedBox.shrink()),
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: context.palette.paper,
          body: Center(
            child: _isLoading
                ? loaderWithBg(context)
                : onlineUser == null
                    ? (_showTour
                        ? FeatureTour(onDone: () => setState(() => _showTour = false))
                        : AuthHomeScreen())
                    : onlineUser!.userType == 'Lead'
                        ? LeadBottomNavbar()
                        : BottomNavHome(),
          ),
        ),
      ),
    );
  }

  Future<UserModel?> getUser(context) async {
    UserModel? uUser;
    setState(() {
      _isLoading = true;
    });
    try {
      _showTour = await FeatureTour.shouldShow();
      final loggedIn = await NewAuthService.instance.tryRestoreSession();
      if (loggedIn) {
        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        String? userEmail = sharedPreferences.getString('userEmail');
        debugPrint('userEmail is: $userEmail');

        if (userEmail != null) {
          Response response = await AuthService().getUserEndpoint(userEmail);
          if (response.statusCode == 200) {
            UserModel user = UserModel.fromDoc(response.data['data']);
            Provider.of<UsermodelProvider>(context, listen: false)
                .setUserModel(user);
            setState(() {
              onlineUser = user;
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        return uUser;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint(e.toString());
    }
    return uUser;
  }

  Widget loaderWithBg(BuildContext context) {
    return Container(
      height: height(context),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            imageRounte(name: 'bg_intro.png'),
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: SingleChildScrollView(
        child: ListView(
          shrinkWrap: true,
          children: [
            Container(
              height: height(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 150,
                  ),
                  const Text(
                    'Lets Help Find that dreamed',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    'Home| Event Centers |Apartments |Lands',
                    textAlign: TextAlign.center,
                    style: tHeading.copyWith(color: context.palette.accent),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'By connecting you to millions of Agent and Landlords worldwide',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  SizedBox(width: 40, height: 40, child: appLoader(35.0)),
                  Text('Validating Info...')
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
