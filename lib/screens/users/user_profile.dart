import 'package:eafind/widgets/verified_badge.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/app_drawer.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/db_services.dart';
import '../../widgets/deals_widget.dart';

class UserProfile extends StatefulWidget {
  final userId;
  const UserProfile({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile>
    with TickerProviderStateMixin {
  TabController? tabController;
  bool showingProperties = true;
  ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  UserModel? onlineUser;
  bool isFollowing = false;
  int followersCount = 0;
  bool isLoading = false;

  getIsFollowing() async {
    UserModel? currentUser = context.read<UsermodelProvider>().getUserModel();
    if (currentUser != null) return;
    FormData formData = FormData.fromMap(
        {'currentUserId': currentUser!.id, 'userId': widget.userId});
    try {
      var response =
          await Dio().post(endPoint('get-isfollowing.php'), data: formData);
      debugPrint('Printing Response is $response');
      if (response.data['status'] == 'Success') {
        if (response.data['data'] > 0) {
          setState(() {
            isFollowing = true;
          });
        } else {
          setState(() {
            isFollowing = false;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  getFollowers(shouldLoad) async {
    if (shouldLoad == true) {
      setState(() {
        isLoading = true;
      });
    }
    FormData formData = FormData.fromMap({'userId': widget.userId});
    try {
      var response =
          await Dio().post(endPoint('get-followers.php'), data: formData);
      debugPrint('Printing Response of followers is $response');
      if (response.data['status'] == 'Success') {
        List followers = response.data['data'];
        setState(() {
          followersCount = followers.length;
          isLoading = false;
        });
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      isLoading = false;
      debugPrint(e.toString());
    }
  }

  followUser() async {
    UserModel? currentUser = context.read<UsermodelProvider>().getUserModel();
    if (currentUser == null) {
      goTo(context, const LoginScreen(fromNav: true), false);
    } else {
      try {
        FormData formData = FormData.fromMap({
          'currentUserId': currentUser!.uid,
          'userId': widget.userId,
          'isUnfollowing': isFollowing ? 1 : 0
        });
        if (isFollowing == true) {
          setState(() {
            followersCount = followersCount - 1;
            isFollowing = !isFollowing;
          });
        } else {
          setState(() {
            followersCount = followersCount + 1;
            isFollowing = !isFollowing;
          });
        }
        var response =
            await Dio().post(endPoint('add-follower.php'), data: formData);
        await getIsFollowing();
        await getFollowers(false);
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  getUser() async {
    UserModel? user = context.read<UsermodelProvider>().getUserModel();
    setState(() {
      onlineUser = user;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    getUser();
    getIsFollowing();
    getFollowers(true);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    UserModel? currentUser = context.read<UsermodelProvider>().getUserModel();
    return Scaffold(
      key: _scaffoldKey,
      drawer: onlineUser == null
          ? null
          : AppDrawer(
              sKey: _scaffoldKey,
              onlineUser: onlineUser!,
            ),
      backgroundColor: context.palette.paper,
      body: currentUser == null
          ? Center(
              child: LoadingAnimationWidget.fallingDot(
                  color: context.palette.accent, size: 50),
            )
          : ListView(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => goTo(context, BottomNavHome(), false),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: context.palette.accent,
                        size: 20,
                      ),
                    ),
                    Text(
                      widget.userId == currentUser!.uid
                          ? 'Your Profile'
                          : '${onlineUser!.userType} Profile',
                      style: TextStyle(
                          color: context.palette.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    (widget.userId == currentUser.uid)
                        ? GestureDetector(
                            onTap: () {
                              _scaffoldKey.currentState!.openDrawer();
                            },
                            child: Icon(
                              Icons.settings,
                              color: context.palette.accent,
                              size: 18,
                            ),
                          )
                        : GestureDetector(
                            onTap: () => followUser(),
                            child: Container(
                              width: 70,
                              padding: EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                  color: context.palette.primaryFill,
                                  border: Border.all(
                                    width: 3,
                                    color: context.palette.paper,
                                  ),
                                  borderRadius: appRadius(15.0)),
                              child: Center(
                                  child: Text(
                                isFollowing ? 'Unfollow' : 'Follow',
                                style: TextStyle(color: white, fontSize: 12),
                              )),
                            ),
                          )
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                height: height(context),
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  borderRadius: appRadius(20.0),
                  color: context.palette.card,
                ),
                child: ListView(
                  shrinkWrap: true,
                  primary: false,
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    userProfile(),
                    swithBar(),
                    FutureBuilder(
                        future: DbServices.getCustomerDeals(onlineUser!.id),
                        builder:
                            (context, AsyncSnapshot<List<dynamic>> snapshot) {
                          if (!snapshot.hasData) {
                            return listLoader();
                          }
                          if (snapshot.data!.isEmpty) {
                            return Container(
                              height: height(context) / 1.3,
                              child: const Center(
                                child: Text('No Data Found'),
                              ),
                            );
                          }
                          var userDeals = snapshot.data;
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: userDeals!.length,
                            primary: false,
                            itemBuilder: ((context, index) {
                              var data = userDeals[index];
                              return DealsWidget(
                  data: data, backgroundColor: context.palette.paper);
                            }),
                          );
                        }),
                  ],
                ),
              )
            ]),
    );
  }

  Widget _buildWeb(BuildContext context) {
    UserModel? currentUser = context.read<UsermodelProvider>().getUserModel();
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        endDrawer: onlineUser == null
            ? null
            : AppDrawer(sKey: _scaffoldKey, onlineUser: onlineUser!),
        body: SafeArea(
          child: currentUser == null
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () =>
                                      goTo(context, BottomNavHome(), false),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back_ios_new,
                                          size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text('Back',
                                          style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              if (widget.userId == currentUser!.uid)
                                _webIconButton(
                                  Icons.settings_outlined,
                                  () => _scaffoldKey.currentState
                                      ?.openEndDrawer(),
                                )
                              else
                                MiaButton(
                                  text: isFollowing ? 'Unfollow' : 'Follow',
                                  onPressed: followUser,
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AppCard(
                            child: Column(
                              children: [
                                _webProfileRow(),
                                const SizedBox(height: 20),
                                _webSwitchBar(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          FutureBuilder(
                            future: DbServices.getCustomerDeals(onlineUser!.id),
                            builder:
                                (context, AsyncSnapshot<List<dynamic>> snapshot) {
                              if (!snapshot.hasData) {
                                return Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.primary)),
                                );
                              }
                              if (snapshot.data!.isEmpty) {
                                return const EmptyState(
                                  icon: Icons.inbox_outlined,
                                  title: 'No data found',
                                );
                              }
                              var userDeals = snapshot.data;
                              return Column(
                                children: [
                                  for (final data in userDeals!)
                                    DealsWidget(data: data),
                                ],
                              );
                            },
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

  Widget _webIconButton(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.card,
          ),
          child: Icon(icon, color: AppColors.textDark, size: 20),
        ),
      ),
    );
  }

  Widget _webProfileRow() {
    return Row(
      children: [
        Container(
          height: 70,
          width: 70,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: AppColors.primary),
            borderRadius: BorderRadius.circular(35),
          ),
          child: ClipOval(
            child: onlineUser!.profileImage.toString().isEmpty
                ? Image.asset(imageRounte(name: avatarImage), fit: BoxFit.cover)
                : Image.network(onlineUser!.profileImage, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${onlineUser!.firstName} ${onlineUser!.lastName}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(onlineUser!.userType,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                  VerifiedBadge(userId: onlineUser!.id, gap: 3),
                ],
              ),
            ],
          ),
        ),
        Column(
          children: [
            isLoading
                ? SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : Text(followersCount.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const Text('Followers',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _webSwitchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => showingProperties = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: showingProperties
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text('Inspections',
                        style: TextStyle(
                            color: showingProperties
                                ? Colors.white
                                : AppColors.textDark,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => showingProperties = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !showingProperties
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text('History',
                        style: TextStyle(
                            color: !showingProperties
                                ? Colors.white
                                : AppColors.textDark,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget swithBar() {
    return Container(
        width: width(context),
        height: 45,
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: appRadius(50.0),
          color: context.palette.paper,
        ),
        child: Card(
          color: context.palette.paper,
          shape: RoundedRectangleBorder(borderRadius: appRadius(50.0)),
          elevation: 15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: (() {
                  setState(() {
                    showingProperties = true;
                  });
                }),
                child: Container(
                  width: width(context) / 2.5,
                  decoration: BoxDecoration(
                    borderRadius: appRadius(50.0),
                    color: showingProperties ? context.palette.primaryFill : context.palette.paper,
                  ),
                  child: Center(
                    child: Text(
                      'Inspections',
                      style: TextStyle(
                        color: showingProperties ? white : context.palette.accent,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: (() {
                  setState(() {
                    showingProperties = false;
                  });
                }),
                child: Container(
                  width: width(context) / 2.5,
                  decoration: BoxDecoration(
                    borderRadius: appRadius(50.0),
                    color: showingProperties == false ? context.palette.primaryFill : context.palette.paper,
                  ),
                  child: Center(
                    child: Text(
                      'Historys',
                      style: TextStyle(
                        color:
                            showingProperties == false ? white : context.palette.accent,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }

  Widget userProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 60,
                width: 60,
                padding: EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                    color: context.palette.paper,
                    border: Border.all(
                      width: 1.0,
                      color: context.palette.accent,
                    ),
                    borderRadius: appRadius(50.0)),
                child: onlineUser!.profileImage.toString().isEmpty
                    ? ClipOval(
                        child: Image.asset(
                          imageRounte(name: avatarImage),
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                        ),
                      )
                    : ClipOval(
                        child: Image.network(
                          onlineUser!.profileImage,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${onlineUser!.firstName} ${onlineUser!.lastName}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          onlineUser!.userType,
                          style: TextStyle(fontSize: 12, color: grey),
                        ),
                        VerifiedBadge(userId: onlineUser!.id, gap: 2)
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 0.0, right: 10),
            child: Column(
              children: [
                isLoading
                    ? LoadingAnimationWidget.waveDots(
                        color: context.palette.accent, size: 15)
                    : Text(
                        followersCount.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: context.palette.ink),
                      ),
                const Padding(
                  padding: EdgeInsets.only(left: 2.0),
                  child: Text(
                    'Followers',
                    style: TextStyle(
                      color: Color.fromARGB(255, 36, 36, 36),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
