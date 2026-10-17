import 'package:eafind/theme/app_palette.dart';
import 'dart:io';

import 'package:eafind/screens/agents/user_account.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/create_post.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:eafind/widgets/view_photo_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:provider/provider.dart';

import '../const/constant.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../providers/usermodel_provider.dart';
import '../services/db_services.dart';
import '../widgets/filter_widget.dart';
import '../widgets/recomemded_widget.dart';
import 'house_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  UserModel? onlineUser;

  List<PropertyModel> allProperties = [];
  bool isLoadingVertical = false;
  int increament = 10;
  bool firstLoading = true;
  bool isLoading = false;
  getUser() async {
    UserModel? fUser =
        Provider.of<UsermodelProvider>(context, listen: false).userModel;
    if (!mounted) return;
    setState(() {
      onlineUser = fUser;
    });
  }

  filterDialog() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        builder: (ctx) {
          return const FilterWidget();
        });
  }

  viewPhotoDialog(property) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (ctx) {
          return ViewPhotoWidget(
            images: [],
            propertyModel: property,
          );
        });
  }

  showAddCommentDialog() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        useSafeArea: true,
        builder: (ctx) {
          return CreatePostSheet(
            user: onlineUser!,
          );
        });
  }

  Future<dynamic> getAllProperties(selectedPropertyType) async {
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
          await DbServices.fetchMixed(true, increament);

      allProperties = prpties;

      setState(() {
        isLoadingVertical = false;
        increament = increament + increament;
        isLoading = false;
        firstLoading = false;
      });

      return allProperties;
    } on SocketException catch (_) {
    } catch (e) {}
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
    getUser();
    getAllProperties('selectedPropertyType');
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    UserModel? currentUser = Provider.of<UsermodelProvider>(context).userModel;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: context.palette.paper,
        appBar: AppBar(
          backgroundColor: context.palette.paper,
          automaticallyImplyLeading: false,
          elevation: 0,
          toolbarHeight: 60,
          title: Column(
            children: [
              const SizedBox(height: 10),
              onlineUserWidget(onlineUser, context, '', white),
            ],
          ),
        ),
        body: LazyLoadScrollView(
          onEndOfPage: () async {
            setState(() {
              isLoadingVertical = true;
            });
            await getAllProperties('selectedPropertyType');
            setState(() {
              isLoadingVertical = false;
            });
          },
          child: Scrollbar(
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (currentUser == null) {
                            goTo(context, LoginScreen(fromNav: true), false);
                          } else {
                            goTo(context, UserAccount(userId: currentUser!.uid),
                                false);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          child: ClipOval(
                            child: Image.asset(
                              imageRounte(name: avatarImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (currentUser == null) {
                            goTo(context, LoginScreen(fromNav: true), false);
                          } else {
                            showAddCommentDialog();
                          }
                        },
                        child: Container(
                          width: width(context) * 0.75,
                          height: 30,
                          margin: EdgeInsets.only(left: 5, right: 5),
                          child: Row(
                            children: [
                              Container(
                                height: 30,
                                width: width(context) / 1.5,
                                decoration: BoxDecoration(
                                    borderRadius: appRadius(15.0),
                                    color: context.palette.paper,
                                    border: Border.all(
                                      width: 1,
                                      color: grey,
                                    )),
                                child: TextField(
                                  enabled: false,
                                  scrollPadding: EdgeInsets.zero,
                                  decoration: InputDecoration(
                                      label: Text(
                                        'Make Request For A Property!',
                                        style: TextStyle(
                                            color: context.palette.ink, fontSize: 12),
                                      ),
                                      contentPadding: EdgeInsets.only(left: 10),
                                      border: InputBorder.none),
                                ),
                              ),
                              Expanded(
                                  child: Icon(
                                Icons.photo_library,
                                color: context.palette.accent,
                              ))
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Divider(
                  color: context.palette.accent,
                ),
                isLoading
                    ? listLoader()
                    : RecommendedWidget(
                        properties: allProperties,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    UserModel? currentUser = Provider.of<UsermodelProvider>(context).userModel;
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explore',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (currentUser == null) {
                                goTo(
                                    context, LoginScreen(fromNav: true), false);
                              } else {
                                goTo(
                                    context,
                                    UserAccount(userId: currentUser!.uid),
                                    false);
                              }
                            },
                            child: ClipOval(
                              child: Image.asset(
                                imageRounte(name: avatarImage),
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (currentUser == null) {
                                  goTo(context, LoginScreen(fromNav: true),
                                      false);
                                } else {
                                  showAddCommentDialog();
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(21),
                                ),
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  'Make a request for a property!',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.textGrey),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _webIconButton(Icons.tune_rounded, filterDialog),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      )
                    else if (allProperties.isEmpty)
                      const EmptyState(
                        icon: Icons.explore_outlined,
                        title: 'Nothing to explore yet',
                      )
                    else
                      WebPropertyGrid(
                        properties: allProperties,
                        onTap: (p) => goTo(
                            context, HouseDetailsScreen(property: p), false),
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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textDark, size: 20),
        ),
      ),
    );
  }

  Widget searchWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextFormField(
                  // controller: controller,
                  // onChanged: (value) {
                  //   if (controller!.text
                  //       .trim()
                  //       .toString()
                  //       .isEmpty) {
                  //    // clearAuto();
                  //   }
                  // }

                  onSaved: (value) {
                    setState(() {
                      // keyword = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Propertice..',
                    isDense: true,
                    hintStyle: TextStyle(
                      color: white,
                      fontSize: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: context.palette.paper,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: context.palette.accent,
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: Container(
                      padding: EdgeInsets.only(top: 15),
                      child: Icon(
                        Icons.graphic_eq_rounded,
                        color: white,
                      ),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        // if (controller!.text.isNotEmpty) {
                        //   searchPost(posts,
                        //       controller!.text.toString());
                        // }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.palette.paper,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.search,
                          color: context.palette.accent,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: (() => filterDialog()),
              child: Container(
                child: SvgPicture.asset(
                  'assets/images/filter.svg',
                  color: white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
