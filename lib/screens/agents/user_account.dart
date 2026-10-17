import 'package:eafind/widgets/verified_badge.dart';
import 'package:eafind/theme/app_palette.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/app_drawer.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:eafind/widgets/shared_widgets.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import '../../auths/auth_service.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../services/db_services.dart';
import '../../widgets/deals_widget.dart';
import '../../widgets/recomemded_widget.dart';
import '../house_details_screen.dart';

// Profile page for [userId] - the logged-in user's own account or anyone
// else's. [profileUser], when the caller already has it (e.g. the owner data
// stored on a listing), is shown immediately while fresh data loads.
class UserAccount extends StatefulWidget {
  final userId;
  final UserModel? profileUser;
  const UserAccount({Key? key, required this.userId, this.profileUser})
      : super(key: key);

  @override
  State<UserAccount> createState() => _UserAccountState();
}

class _UserAccountState extends State<UserAccount>
    with TickerProviderStateMixin {
  TabController? tabController;
  bool showingProperties = true;
  ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // The logged-in user (may be null) vs. the person whose profile this is.
  UserModel? onlineUser;
  UserModel? profileUser;
  bool isFollowing = false;
  int followersCount = 0;
  bool isLoading = false;
  bool isLoadingVertical = false;
  List<PropertyModel> allProperties = [];
  int increament = 10;
  bool firstLoading = true;

  bool get isOwnProfile =>
      onlineUser != null &&
      (onlineUser!.id == widget.userId.toString() ||
          onlineUser!.uid?.toString() == widget.userId.toString());

  getIsFollowing() async {
    if (onlineUser == null || isOwnProfile) return;
    FormData formData = FormData.fromMap(
        {'currentUserId': onlineUser!.id, 'userId': widget.userId});
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
      setState(() {
        isLoading = false;
      });
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
      setState(() {
        isLoading = false;
      });
      debugPrint(e.toString());
    }
  }

  followUser() async {
    if (onlineUser == null) {
      goTo(context, const LoginScreen(fromNav: true), false);
    } else {
      try {
        FormData formData = FormData.fromMap({
          'currentUserId': onlineUser!.id,
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
        setState(() {
          isLoading = false;
        });
        debugPrint(e.toString());
      }
    }
  }

  getUser() async {
    UserModel? user = context.read<UsermodelProvider>().getUserModel();
    setState(() {
      onlineUser = user;
      profileUser = isOwnProfile ? user : widget.profileUser;
    });
    if (isOwnProfile) return;
    getIsFollowing();
    // Someone else's profile: load their current details by id rather than
    // relying only on the snapshot passed in.
    try {
      final response = await AuthService.getUserById(widget.userId.toString());
      final data = response?.data;
      if (!mounted || data is! Map || data['data'] is! Map) return;
      setState(() {
        profileUser =
            UserModel.fromDoc(Map<String, dynamic>.from(data['data']));
      });
    } catch (e) {
      debugPrint('Could not load profile ${widget.userId}: $e');
    }
  }

  Future<dynamic> getAllProperties() async {
    setState(() {
      isLoadingVertical = true;
    });
    if (firstLoading == true) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      List<PropertyModel> prpties =
          await DbServices.fetchAgentProperties(widget.userId, increament);

      setState(() {
        allProperties = prpties;
        isLoadingVertical = false;
        increament = increament + increament;
        isLoading = false;
        firstLoading = false;
      });

      return allProperties;
    } on SocketException catch (_) {
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching properties: ${e.toString()}');
    }
    setState(() {
      isLoadingVertical = false;
      isLoading = false;
    });
    // if (prpties.isEmpty) {

    //   if (prpties.isNotEmpty) {
    //     Provider.of<DataProvider>(context, listen: false)
    //         .setProperties(prpties);
    //   }
    // }
    // prpties = Provider.of<DataProvider>(context, listen: false).getData();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    getUser();
    getFollowers(true);
    getAllProperties();
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
    return Scaffold(
      key: _scaffoldKey,
      // Settings drawer only belongs on your own profile.
      drawer: !isOwnProfile
          ? null
          : AppDrawer(
              sKey: _scaffoldKey,
              onlineUser: onlineUser!,
            ),
      backgroundColor: context.palette.paper,
      body: profileUser == null
          ? Center(
              child: LoadingAnimationWidget.fallingDot(
                  color: context.palette.accent, size: 50),
            )
          : LazyLoadScrollView(
              onEndOfPage: () async {
                setState(() {
                  isLoadingVertical = true;
                });
                await getAllProperties();
                setState(() {
                  isLoadingVertical = false;
                });
              },
              isLoading: isLoadingVertical,
              child: Container(
                color: context.palette.paper,
                child: ListView(children: [
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
                          isOwnProfile
                              ? 'Your Profile'
                              : '${profileUser!.userType} Profile',
                          style: TextStyle(
                              color: context.palette.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        isOwnProfile
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
                                  width: 90,
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
                                    style:
                                        TextStyle(color: white, fontSize: 12),
                                  )),
                                ),
                              )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Card(
                    color: context.palette.paper,
                    elevation: 15,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: appRadius(20.0),
                        color: context.palette.paper,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        primary: false,
                        children: [
                          const SizedBox(
                            height: 30,
                          ),
                          userProfile(),
                          // Deals are private to the account holder, so
                          // other people's profiles only list properties.
                          if (isOwnProfile)
                            swithBar()
                          else
                            const SizedBox(height: 12),
                          showingProperties || !isOwnProfile
                              ? isLoading
                                  ? listLoader()
                                  : RecommendedWidget(
                                      properties: allProperties,
                                    )
                              : dealBuilder(),
                        ],
                      ),
                    ),
                  )
                ]),
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
        endDrawer: !isOwnProfile
            ? null
            : AppDrawer(sKey: _scaffoldKey, onlineUser: onlineUser!),
        body: SafeArea(
          child: profileUser == null
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
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
                              if (isOwnProfile)
                                _webIconButton(
                                  Icons.settings_outlined,
                                  () => _scaffoldKey.currentState
                                      ?.openEndDrawer(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AppCard(
                            child: Column(
                              children: [
                                _webProfileRow(),
                                if (isOwnProfile) ...[
                                  const SizedBox(height: 20),
                                  _webSwitchBar(),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          showingProperties || !isOwnProfile
                              ? (isLoading
                                  ? Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              color: AppColors.primary)),
                                    )
                                  : allProperties.isEmpty
                                      ? const EmptyState(
                                          icon: Icons.home_work_outlined,
                                          title: 'No properties yet',
                                        )
                                      : WebPropertyGrid(
                                          properties: allProperties,
                                          onTap: (p) => goTo(
                                              context,
                                              HouseDetailsScreen(property: p),
                                              false),
                                        ))
                              : dealBuilder(),
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
          height: 76,
          width: 76,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: AppColors.primary),
            borderRadius: BorderRadius.circular(38),
          ),
          child: ClipOval(
            child: (profileUser!.profileImage.toString().isEmpty ||
                    profileUser!.profileImage == null)
                ? Image.asset(imageRounte(name: avatarImage), fit: BoxFit.cover)
                : Image.network(profileUser!.profileImage, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${profileUser!.firstName} ${profileUser!.lastName}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(profileUser!.userType,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                  VerifiedBadge(userId: profileUser!.id, gap: 3),
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
        if (!isOwnProfile) ...[
          const SizedBox(width: 16),
          MiaButton(
            text: isFollowing ? 'Unfollow' : 'Follow',
            onPressed: followUser,
          ),
        ],
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
                    child: Text('Properties',
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
                    child: Text('Deals',
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

  dealBuilder() {
    return FutureBuilder(
        future: DbServices.getCustomerDeals(onlineUser!.id),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
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
        });
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
                      'Properties',
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
                      'Deals',
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
                height: 70,
                width: 70,
                padding: EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                    color: context.palette.paper,
                    border: Border.all(
                      width: 1.0,
                      color: context.palette.accent,
                    ),
                    borderRadius: appRadius(50.0)),
                child: (profileUser!.profileImage.toString().isEmpty ||
                        profileUser!.profileImage == null)
                    ? ClipOval(
                        child: Image.asset(
                          imageRounte(name: avatarImage),
                          fit: BoxFit.cover,
                        ),
                      )
                    : ClipOval(
                        child: Image.network(
                          profileUser!.profileImage,
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
                          '${profileUser!.firstName} ${profileUser!.lastName}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          profileUser!.userType,
                          style: TextStyle(fontSize: 12, color: grey),
                        ),
                        VerifiedBadge(userId: profileUser!.id, gap: 2)
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
                Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Text(
                    'Followers',
                    style: TextStyle(
                      color: context.palette.inkSoft,
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
