import 'package:eafind/theme/app_palette.dart';
import 'dart:ui';

import 'package:eafind/services/db_services.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../const/constant.dart';
import '../models/user_model.dart';
import '../screens/agents/user_account.dart';

class UserListWidget extends StatefulWidget {
  const UserListWidget({Key? key}) : super(key: key);

  @override
  State<UserListWidget> createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    // UserModel currentUser = Provider.of<UserDataProvider>(context).user!;
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: height(context) - 100,
          decoration: BoxDecoration(
            color: black,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border:
                Border.symmetric(horizontal: BorderSide(color: context.palette.accent)),
          ),
          child: ListView(
            children: [
              Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => goBack(context),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.cancel,
                          size: 20,
                          color: context.palette.accent,
                        ),
                      ),
                    ),
                  ),
                  h10(),
                  Center(
                    child: Container(
                      width: 40,
                      height: 3,
                      color: context.palette.primaryFill,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<UserModel>>(
                      future: DbServices.getAllUsers(),
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return appShimmerLoading(context);
                        }
                        List<UserModel>? users = snapshot.data;
                        if (users == null || users.isEmpty) {
                          return Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(color: white),
                            ),
                          );
                        }
                        ;
                        return Column(
                          children: [
                            Text(
                              'Total Users: ${users.length}',
                              style: TextStyle(color: white),
                            ),
                            SizedBox(height: 20),
                            GridView.builder(
                                shrinkWrap: true,
                                primary: false,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4),
                                itemCount: users.length,
                                itemBuilder: (ctx, index) {
                                  UserModel user = users[index];
                                  return GestureDetector(
                                    onTap: () => goTo(
                                        context,
                                        UserAccount(
                                          userId: user.id,
                                        ),
                                        false),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundImage: (user.profileImage ==
                                                      null ||
                                                  user.profileImage == '')
                                              ? AssetImage(imageRounte(
                                                      name: 'avatar.png'))
                                                  as ImageProvider<Object>
                                              : NetworkImage(user.profileImage!)
                                                  as ImageProvider<Object>,
                                        ),
                                        Text(
                                          user.firstName,
                                          style: TextStyle(
                                              fontSize: 12, color: white),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      ],
                                    ),
                                  );
                                }),
                          ],
                        );
                      }),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All users',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => goBack(context),
                        child: const Icon(Icons.close, color: AppColors.textGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: FutureBuilder<List<UserModel>>(
                      future: DbServices.getAllUsers(),
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary)),
                          );
                        }
                        List<UserModel>? users = snapshot.data;
                        if (users == null || users.isEmpty) {
                          return const EmptyState(
                            icon: Icons.people_outline,
                            title: 'No users found',
                          );
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          primary: false,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 120,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: users.length,
                          itemBuilder: (ctx, index) {
                            UserModel user = users[index];
                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => goTo(
                                    context, UserAccount(userId: user.id), false),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: (user.profileImage ==
                                                  null ||
                                              user.profileImage == '')
                                          ? AssetImage(
                                                  imageRounte(name: 'avatar.png'))
                                              as ImageProvider<Object>
                                          : NetworkImage(user.profileImage!)
                                              as ImageProvider<Object>,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.firstName,
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textDark),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
