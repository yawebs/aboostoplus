import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../const/constant.dart';
import '../services/db_services.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({Key? key}) : super(key: key);

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    UserModel? user = Provider.of<UsermodelProvider>(context).getUserModel();
    return Scaffold(
      backgroundColor: context.palette.paper,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: context.palette.paper,
        leading: GestureDetector(
          onTap: () => goBack(context),
          child: Icon(
            Icons.arrow_back,
            color: context.palette.ink,
          ),
        ),
        title: Text('Notifications',
            style: TextStyle(
              color: context.palette.ink,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => goBack(context),
              child: Icon(
                Icons.remove,
                color: context.palette.ink,
                size: 15,
              ),
            ),
          )
        ],
      ),
      body: FutureBuilder(
        future: DbServices.getCustomerDeals(user!.id),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return appLoader(50.0);
          }
          return notificationBuilder(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    UserModel? user = Provider.of<UsermodelProvider>(context).getUserModel();
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder(
                      future: DbServices.getCustomerDeals(user!.id),
                      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                        if (!snapshot.hasData) {
                          return Padding(
                            padding: const EdgeInsets.all(48),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary)),
                          );
                        }
                        if (snapshot.data!.isEmpty) {
                          return const EmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: 'No notifications yet',
                          );
                        }
                        return _webNotificationList(snapshot.data!);
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

  Widget _webNotificationList(List<dynamic> notificationData) {
    return Column(
      children: [
        for (var i = 0; i < notificationData.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _webNotificationTile(notificationData[i], i == 3),
          ),
      ],
    );
  }

  Widget _webNotificationTile(dynamic notification, bool highlighted) {
    final nTime = DateTime.parse(notification['dateCreated']);
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: highlighted ? AppColors.primary : AppColors.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: highlighted ? Colors.white : AppColors.primaryLight,
            child: Icon(
              Icons.mail,
              size: 18,
              color: highlighted ? AppColors.primary : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your inspection for ${notification['property_title']} is successfully placed',
                  style: TextStyle(
                    color: highlighted ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeago.format(nTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: highlighted ? Colors.white70 : AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  notificationBuilder(List<dynamic> notificationData) {
    return ListView.builder(
        itemCount: notificationData.length,
        shrinkWrap: true,
        itemBuilder: (ctx, index) {
          var notification = notificationData[index];
          var nTime = DateTime.parse(notification['dateCreated']);
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeago.format(nTime),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                h10(),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: appRadius(8.0),
                    color: (index == 3) ? context.palette.primaryFill : context.palette.paperAlt,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  (index == 3) ? lightGrey : primaryColor,
                              child: Icon(
                                Icons.mail,
                                size: 18,
                                color: (index == 3) ? context.palette.accent : white,
                              ),
                            ),
                            w5(),
                            Expanded(
                              child: Text(
                                'Your inspection for ${notification['property_title']} is successfuly placed',
                                style: TextStyle(
                                  color: (index == 3) ? white : context.palette.ink,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          timeago.format(nTime),
                          style: TextStyle(
                              fontSize: 12,
                              color: (index == 3) ? white : context.palette.ink),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}
