import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:eafind/auths/auth_service.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/screens/marketplace/search_marketplace.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:hexcolor/hexcolor.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

import '../models/story_model.dart';
import '../screens/authscreen/login_screen.dart';
import '../screens/agents/user_account.dart';
import '../screens/reports/submit_report.dart';
import '../screens/reports/user/customer_report.dart';
import '../services/new_auth_service.dart';
import '../widgets/report_options_widget.dart';
import '../widgets/search_sheet.dart';
import '../widgets/user_list_widget.dart';
import '../widgets/view_photo_widget.dart';

Color primaryColor = const Color.fromRGBO(63, 34, 79, 1);
Color lightGrey4Form = Colors.grey.shade300.withOpacity(.5);
const GoogleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
imageRounte({name}) {
  return 'assets/images/$name';
}

String pusherAppId = "YOUR_PUSHER_APP_ID";
String pusherKey = "YOUR_PUSHER_KEY";
String pusherSecret = ""; // never put the Pusher secret in the app; it lives on the server
String pusherCluster = "YOUR_PUSHER_CLUSTER";

class AppTextStyles {
  static TextStyle serif({
    double size = 22,
    FontWeight weight = FontWeight.w600,
    FontStyle style = FontStyle.normal,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'Fraunces',
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      color: color,
    );
  }

  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}

String logoPath = 'logo.png';
Color blackWithOp = black.withOpacity(.5);
List<Color> gradientColors = [
  Color.fromRGBO(218, 173, 73, 1),
  primaryColor,
  white,
  primaryColor,
  Color.fromRGBO(240, 75, 25, 1)
];
List<Color> gradientColors4 = const [
  Color.fromRGBO(240, 75, 25, 1),
  Color.fromRGBO(255, 217, 0, 1),
];
List<Color> gradientColors2 = const [
  Color.fromRGBO(150, 10, 20, 1),
  Color.fromRGBO(43, 25, 25, 1),
  Color.fromRGBO(32, 6, 6, 1),
];
List<Color> postColors = [
  Color.fromARGB(255, 255, 255, 255),
  const Color.fromARGB(255, 65, 10, 75),
  Color.fromARGB(255, 36, 19, 128),
  Color.fromARGB(255, 139, 85, 3),
  Color.fromARGB(255, 2, 142, 160),
  Color.fromARGB(255, 0, 0, 0),
];
Color getTextColor(index) {
  Color color = white;
  if (index == 0) {
    color = black;
  }
  return color;
}

TextStyle tStyle({color, size}) {
  return TextStyle(color: color, fontSize: size);
}

String myIpAddress = '72.14.201.90';
Widget formWrapperContainer({child}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20),
    decoration:
        BoxDecoration(color: lightGrey4Form, borderRadius: appRadius(10.0)),
    child: child,
  );
}

userListModal(context) {
  showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      context: context,
      builder: (ctx) {
        return UserListWidget();
      });
}

void showToast(String label) {
  Fluttertoast.showToast(
    msg: label,
    backgroundColor: primaryColor,
    gravity: ToastGravity.CENTER,
  );
}

List<Color> gradientColors3 = const [
  Color.fromRGBO(249, 74, 63, 1),
  Color.fromRGBO(228, 49, 123, 1),
];
Widget appLoader(size) {
  return LoadingAnimationWidget.twistingDots(
      leftDotColor: primaryColor, rightDotColor: grey, size: size);
}

// A slim, minimal ring spinner for full-bleed black video surfaces (the
// vertical feed, embedded property videos) - swapped in for appLoader's
// bouncing dots there, which read as playful rather than premium against
// a dark, edge-to-edge video background.
Widget videoLoader({double size = 36}) {
  return SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      strokeWidth: 2.4,
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8A93B)),
      backgroundColor: Colors.white.withOpacity(0.14),
    ),
  );
}

Widget appSearchLoader(color, size) {
  return Center(
    child: LoadingAnimationWidget.hexagonDots(
      color: color,
      size: size,
    ),
  );
}

gridLoader() {
  return SkeletonGridLoader(
    builder: Card(
      color: Colors.transparent,
      child: GridTile(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 50,
              height: 10,
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Container(
              width: 70,
              height: 10,
              color: Colors.white,
            ),
          ],
        ),
      ),
    ),
    items: 9,
    itemsPerRow: 3,
    period: Duration(seconds: 2),
    highlightColor: primaryColor.withOpacity(.3),
    direction: SkeletonDirection.ltr,
    childAspectRatio: 1,
  );
}

listLoader() {
  return SkeletonLoader(
    builder: Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 30,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: 10,
                  color: Colors.white,
                ),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    items: 8,
    period: Duration(seconds: 2),
    highlightColor: primaryColor.withOpacity(.3),
    direction: SkeletonDirection.ltr,
  );
}

//primary color hex code #3f224f;
Color white = HexColor('#E6E6FA');
Color whiteOp = white.withOpacity(.9);
Color black = Colors.black;
Color grey300 = Colors.grey..shade200;
Color grey = Colors.grey;
Color transparent = Colors.transparent;
Color lightGrey = Color.fromARGB(255, 238, 243, 243);
Color red = const Color.fromARGB(255, 218, 35, 21);
Color darkGrey = black.withOpacity(.9);
Color shadowColor = Color.fromARGB(113, 0, 0, 0);
TextStyle tHeading = TextStyle(
  fontSize: 26,
  color: primaryColor,
  fontWeight: FontWeight.bold,
);
TextStyle tStyleWhite = TextStyle(color: white);
TextStyle th6 = TextStyle(fontSize: 15);
TextStyle tHead =
    TextStyle(color: primaryColor, fontSize: 30, fontWeight: FontWeight.bold);
TextStyle tHead2 = const TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.bold,
);
TextStyle tHead3 = const TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.bold,
);
TextStyle tHead4 = const TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.bold,
);

String avatarImage = 'avatar.png';
String endPoint(address) {
  return 'https://aboostoplus.com/api/$address';
}

Widget appButton({callback, label, color, textColor}) {
  return GestureDetector(
    onTap: () => callback(),
    child: Container(
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: appRadius(10.0), color: color),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Widget dividerH() {
  return const Text(
    '|',
    style: TextStyle(
        color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 30),
  );
}

int getSuccessRate(List<dynamic> data) {
  int successRate = 100;
  try {
    List<dynamic> cancelledDeals =
        data.where((deal) => deal['dealStatus'] == 'Cancelled').toList();
    int rat = 5 * cancelledDeals.length;
    successRate = successRate - rat;
  } catch (_) {}
  return successRate;
}

h10() {
  return const SizedBox(height: 10);
}

h5() {
  return const SizedBox(height: 5);
}

h20() {
  return const SizedBox(height: 20);
}

h30() {
  return const SizedBox(height: 30);
}

h40() {
  return const SizedBox(height: 40);
}

h80() {
  return const SizedBox(height: 80);
}

h15() {
  return const SizedBox(height: 15);
}

w10() {
  return const SizedBox(width: 10);
}

w5() {
  return const SizedBox(width: 5);
}

w20() {
  return const SizedBox(width: 20);
}

w30() {
  return const SizedBox(width: 30);
}

w15() {
  return const SizedBox(width: 15);
}

height(context) {
  return MediaQuery.of(context).size.height;
}

width(context) {
  return MediaQuery.of(context).size.width;
}

goTo(context, screen, nav) {
  return pushScreen(context, screen: screen, withNavBar: nav);
}

goBack(context) {
  return Navigator.of(context).pop();
}

appRadius(radius) {
  return BorderRadius.all(Radius.circular(radius));
}

formContainer({child, title, context}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 8.0, bottom: 5),
        child: Text(
          title,
          style: TextStyle(color: grey),
        ),
      ),
      Container(
        width: width(context),
        decoration: BoxDecoration(
          border: Border.all(
            width: 1,
            color: grey,
          ),
          borderRadius: appRadius(10.0),
        ),
        child: child,
      ),
    ],
  );
}

showCustomerReportModal(context) {
  showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return const CustomerReport();
      });
}

quickIcons(currentIndex, size) {
  List<Icon> qIcons = [
    Icon(
      Icons.home_filled,
      size: size,
      color: currentIndex == 0 ? white : grey,
    ),
    Icon(
      Icons.houseboat,
      size: size,
      color: currentIndex == 1 ? white : grey,
    ),
    Icon(
      Icons.landscape,
      size: size,
      color: currentIndex == 2 ? white : grey,
    ),
    Icon(
      Icons.landslide_sharp,
      size: size,
      color: currentIndex == 3 ? white : grey,
    ),
    Icon(
      Icons.landscape,
      size: size,
      color: currentIndex == 4 ? white : grey,
    ),
  ];
  return qIcons;
}

viewPhotoDialog(images, property, context) {
  showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return ViewPhotoWidget(
          images: images,
          propertyModel: property,
        );
      });
}

appShimmerLoading(context) {
  bool isDarkMode =
      MediaQuery.of(context).platformBrightness == Brightness.dark;
  return Container(
    color: black,
    child: ListView.separated(
      shrinkWrap: true,
      itemBuilder: (_, i) {
        final delay = (i * 300);
        return Container(
          decoration: BoxDecoration(
              color: isDarkMode ? Color(0xff242424) : Colors.white,
              borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              FadeShimmer.round(
                size: 60,
                fadeTheme: isDarkMode ? FadeTheme.dark : FadeTheme.light,
                millisecondsDelay: delay,
              ),
              SizedBox(
                width: 8,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeShimmer(
                    height: 8,
                    width: 150,
                    radius: 4,
                    millisecondsDelay: delay,
                    fadeTheme: isDarkMode ? FadeTheme.dark : FadeTheme.light,
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  FadeShimmer(
                    height: 8,
                    millisecondsDelay: delay,
                    width: 170,
                    radius: 4,
                    fadeTheme: isDarkMode ? FadeTheme.dark : FadeTheme.light,
                  ),
                ],
              )
            ],
          ),
        );
      },
      itemCount: 20,
      separatorBuilder: (_, __) => SizedBox(
        height: 16,
      ),
    ),
  );
}

String showDisplayName(UserModel user) {
  return '${user.firstName} ${user.lastName}';
}

showReportModal(property, context) {
  showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      context: context,
      builder: (ctx) {
        return ReportOptionsSheet(property: property);
      });
}

showSubmitReportModal(report, context, changeStatus) {
  showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SubmitReport(
          report: report,
          changeStatus: changeStatus,
        );
      });
}

Widget widgetWithTitle(context, title, color) {
  return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    GestureDetector(
      onTap: (() => goBack(context)),
      child: Row(
        children: [
          Icon(
            Icons.arrow_back_ios,
            color: grey300,
            size: 18,
          )
          // Stack(
          //   children: [
          //     CircleAvatar(
          //       backgroundColor: white,
          //       child: Image.asset(
          //         imageRounte(name: 'logo.png'),
          //         width: 35,
          //       ),
          //     )
          //   ],
          // ),
        ],
      ),
    ),
    Container(
      alignment: Alignment.center,
      child: Text(
        'Videos',
        style: tStyleWhite,
      ),
    ),
    Container(
      child: Align(
        alignment: Alignment.topRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => goTo(context, showSearchSheet(context), false),
              child: Container(
                width: 30,
                height: 30,
                child: CircleAvatar(
                  backgroundColor: grey300,
                  child: Icon(
                    Icons.search,
                    color: white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Container(
              width: 30,
              height: 30,
              child: CircleAvatar(
                backgroundColor: grey300,
                child: Icon(
                  Icons.notifications,
                  color: white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    )
  ]);
}

Widget onlineUserWidget(onlineUser, context, title, color) {
  return Container(
    color: color,
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      onlineUser == null
          ? GestureDetector(
              onTap: (() => goTo(
                  context,
                  const LoginScreen(
                    fromNav: false,
                  ),
                  false)),
              child: Row(
                children: [
                  Container(
                      width: 40,
                      height: 40,
                      child: ClipOval(
                          child: Image.asset(
                        imageRounte(name: avatarImage),
                        fit: BoxFit.cover,
                        color: white,
                      ))),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Hi,Anonymus',
                      style: TextStyle(color: white, fontSize: 14),
                    ),
                  )
                ],
              ),
            )
          : GestureDetector(
              onTap: (() => goTo(
                  context,
                  UserAccount(
                    userId: onlineUser.id,
                  ),
                  false)),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Image.asset(
                        imageRounte(name: 'logo.png'),
                        width: 35,
                      )
                    ],
                  ),
                ],
              ),
            ),
      Align(
        alignment: Alignment.center,
        child: Text(
          'Videos',
          style: tStyleWhite,
        ),
      ),
      Expanded(
        child: Align(
          alignment: Alignment.topRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => goTo(context, showSearchSheet(context), false),
                child: Container(
                  width: 30,
                  height: 30,
                  child: CircleAvatar(
                    backgroundColor: grey300,
                    child: Icon(
                      Icons.search,
                      color: white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Container(
                width: 30,
                height: 30,
                child: CircleAvatar(
                  backgroundColor: grey300,
                  child: Icon(
                    Icons.notifications,
                    color: white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    ]),
  );
}

showSearchSheet(context) {
  showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      context: context,
      builder: (ctx) {
        return const SearchSheet();
      });
}

showSearchSheetProducts(context) {
  showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      context: context,
      builder: (ctx) {
        return const SearchMarketplace();
      });
}

List<StoryModel> storyItem = [
  StoryModel(
    imageUrl: 'h1.jpg',
    points: [
      'Get that apartment without stress| From one room to 3 Bedroom flat etc',
      'Interract directly with the landlord',
      'Get the best',
    ],
    title: 'House Rental',
  ),
  StoryModel(
    imageUrl: 'h2.jpg',
    points: [
      'Get the best Land deals without moving',
      'Get connected with the best land agents',
      'Trusted, reliable and affordable',
    ],
    title: 'Land Deals',
  ),
  StoryModel(
    imageUrl: 'h3.jpg',
    points: [
      'We have brought together the best halls u would need',
      'Halls for events',
      'Halls for weeding receptions etc',
    ],
    title: 'Hall Deals',
  ),
  StoryModel(
    imageUrl: 'h5.jpg',
    points: [
      'Get connected with the best office space deals ',
      'Search and filter based on your office specification',
    ],
    title: 'OFFICE SPACE',
  ),
  StoryModel(
    imageUrl: 'h6.jpg',
    points: [
      'Get connected with the best office space deals ',
      'Search and filter based on your office specification',
    ],
    title: 'OFFICE SPACE',
  ),
  StoryModel(
    imageUrl: 'h7.jpg',
    points: [
      'Get connected with the best office space deals ',
      'Search and filter based on your office specification',
    ],
    title: 'OFFICE SPACE',
  ),
];
Widget reportDevider() {
  return Divider(
    color: grey.withOpacity(.2),
  );
}

showErrorSnackbar(String message, context) {
  final snackbar = SnackBar(
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    content: AwesomeSnackbarContent(
      contentType: ContentType.failure,
      title: 'Error',
      message: message,
    ),
  );
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackbar);
}

List<String> propertyTypes = [
  'Houses',
  'Lands',
  'Shops',
  'Event Halls',
  'Properties'
];
successSnackBar(String message, context) {
  final snackbar = SnackBar(
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    content: AwesomeSnackbarContent(
      contentType: ContentType.success,
      title: 'Success',
      message: message,
    ),
  );
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackbar);
}

logoutDialog(context) {
  bool isLoading = false;

  showDialog(
    context: context,
    barrierDismissible: !isLoading,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return PopScope(
            canPop:
                !isLoading, // block back-button/barrier dismiss while loading
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: appRadius(15.0),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.logout_rounded, color: red, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Logout',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to logout?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: appRadius(10.0),
                          child: InkWell(
                            borderRadius: appRadius(10.0),
                            onTap: isLoading ? null : () => goBack(ctx),
                            child: Container(
                              height: 45,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 1,
                                  color: isLoading
                                      ? Colors.grey.shade300
                                      : primaryColor,
                                ),
                                borderRadius: appRadius(10.0),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: isLoading
                                      ? Colors.grey.shade400
                                      : primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: red,
                          borderRadius: appRadius(10.0),
                          child: InkWell(
                            borderRadius: appRadius(10.0),
                            onTap: isLoading
                                ? null
                                : () async {
                                    setState(() => isLoading = true);
                                    try {
                                      await NewAuthService.instance.logout();
                                      if (!ctx.mounted) return;
                                      Navigator.of(ctx).pop(); // close dialog
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (ctxx) =>
                                              const LoginScreen(fromNav: false),
                                        ),
                                        (_) => false,
                                      );
                                    } catch (e) {
                                      setState(() => isLoading = false);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Logout failed. Try again.'),
                                        ),
                                      );
                                    }
                                  },
                            child: Container(
                              height: 45,
                              alignment: Alignment.center,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Logout',
                                      style: TextStyle(color: white),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showUpdateDialog(
  BuildContext context, {
  bool isForced = false,
  String? version,
  List<String>? whatsNew,
  required VoidCallback onUpdate,
}) {
  return showDialog(
    context: context,
    barrierDismissible: !isForced,
    builder: (ctx) {
      return PopScope(
        canPop: !isForced,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: appRadius(20.0)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    color: primaryColor,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  isForced ? 'Update Required' : 'New Update Available',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  isForced
                      ? 'Please update the app to continue. This version is no longer supported.'
                      : 'A new version${version != null ? ' ($version)' : ''} is ready with improvements for a better experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: Colors.grey[600]),
                ),

                // Optional "what's new" list
                if (whatsNew != null && whatsNew.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: appRadius(12.0),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: whatsNew
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 16, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    if (!isForced) ...[
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: appRadius(12.0),
                          child: InkWell(
                            borderRadius: appRadius(12.0),
                            onTap: () => goBack(ctx),
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: appRadius(12.0),
                              ),
                              child: Text(
                                'Later',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: isForced ? 1 : 1,
                      child: Material(
                        color: primaryColor,
                        borderRadius: appRadius(12.0),
                        child: InkWell(
                          borderRadius: appRadius(12.0),
                          onTap: onUpdate,
                          child: Container(
                            height: 46,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download_rounded,
                                    color: white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Update Now',
                                  style: TextStyle(
                                    color: white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class CategoryItem extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;

  final bool isActive;
  const CategoryItem(
      {Key? key,
      required this.categoryName,
      required this.categoryIcon,
      required this.isActive})
      : super(key: key);

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.isActive ? primaryColor : grey.withOpacity(.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              widget.categoryIcon,
              size: 30,
              color: grey,
            )),
        SizedBox(height: 5),
        Text(
          widget.categoryName,
          style: tStyle(color: grey),
        ),
      ],
    );
  }
}
