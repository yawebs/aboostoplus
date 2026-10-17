import 'package:eafind/widgets/verified_badge.dart';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/services/db_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../const/constant.dart';
import '../screens/agents/user_account.dart';
import '../utility/custom_toast.dart';

class AgentAccountProfile extends StatefulWidget {
  final PropertyModel property;
  final color;
  const AgentAccountProfile({Key? key, required this.property, this.color})
      : super(key: key);

  @override
  State<AgentAccountProfile> createState() => _AgentAccountProfileState();
}

class _AgentAccountProfileState extends State<AgentAccountProfile> {
  UserModel? user;
  bool isLoading = false;

  // The listing's owner, from the owner snapshot stored on the property.
  // Never falls back to the logged-in user - that showed your own avatar
  // (and opened your own profile) on listings with no owner data.
  getUser() async {
    try {
      if (widget.property.propertyOwner != null &&
          widget.property.propertyOwner != '') {
        UserModel? propertyOwner =
            UserModel.fromDoc2(json.decode(widget.property.propertyOwner!));

        setState(() {
          user = propertyOwner;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    UserModel? activeUserOnline =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    return GestureDetector(
      onTap: () {
        if (activeUserOnline == null) {
          CustomToast.show(
            context,
            title: 'Login Required',
            message: 'Please login to view agent profile',
            type: ToastType.error,
          );
          goTo(context, LoginScreen(fromNav: true), false);
        } else {
          // ownerId is always set on a listing; the owner snapshot may not be.
          final ownerId = (user?.id.toString().isNotEmpty ?? false)
              ? user!.id
              : widget.property.ownerId;
          goTo(
            context,
            UserAccount(userId: ownerId, profileUser: user),
            false,
          );
        }
      },
      child: Row(
        children: [
          isLoading
              ? appLoader(15.0)
              : ClipRRect(
                  borderRadius: appRadius(50.0),
                  child: (user?.profileImage ?? '').toString().isEmpty
                      ? Image.asset(
                          imageRounte(name: avatarImage),
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          cacheHeight: 80,
                          cacheWidth: 80,
                        )
                      : CachedNetworkImage(
                          imageUrl: user!.profileImage,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          memCacheWidth:
                              80, // ~2x display size for retina screens, decoded resolution capped here
                          memCacheHeight: 80,
                        ),
                ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.property.userName,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: widget.color),
                    ),
                    VerifiedBadge(userId: widget.property.ownerId, size: 15),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 10,
                      color: grey,
                    ),
                    Text(
                      widget.property.community,
                      style: TextStyle(
                        color: grey,
                      ),
                    ),
                    w10(),
                    Icon(
                      Icons.punch_clock,
                      size: 12,
                      color: grey,
                    ),
                    w5(),
                    Text(
                      timeago
                          .format(DateTime.parse(widget.property.dateCreated)),
                      style: tStyle(color: grey),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
