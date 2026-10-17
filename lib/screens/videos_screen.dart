import 'dart:io';

import 'package:eafind/const/constant.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/services/providers/data_provider.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/recomended_videos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/property_model.dart';
import '../models/user_model.dart';
import '../providers/usermodel_provider.dart';

class VideosScreen extends StatefulWidget {
  final PropertyModel clickedVideo;

  const VideosScreen({
    Key? key,
    required this.clickedVideo,
  }) : super(key: key);

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  UserModel? onlineUser;

  List<PropertyModel> allProperties = [];
  String selectedState = 'State';
  bool changingSettings = false;
  bool isBadNetwork = true;
  bool isLoading = false;
  String selectedPropertyType = 'Houses';
  getUser() async {
    UserModel? fUser =
        Provider.of<UsermodelProvider>(context, listen: false).userModel;
    if (!mounted) return;
    setState(() {
      onlineUser = fUser;
    });
  }

  Future<dynamic> getAllProperties() async {
    setState(() {
      allProperties.insert(0, widget.clickedVideo);
      isLoading = true;
    });
    try {
      setState(() {
        allProperties = Provider.of<DataProvider>(context, listen: false)
            .getData()
            .where((p) => p.isVideo == 1 && p.id != widget.clickedVideo.id)
            .toList();
        allProperties.insert(0, widget.clickedVideo);
        isLoading = false;
      });

      return allProperties;
    } on SocketException catch (_) {
      setState(() {
        isBadNetwork = true;
      });
    } catch (e) {}
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
    getAllProperties();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
        backgroundColor: blackWithOp,
        body: RecommendedVideos(properties: allProperties));
  }

  // A vertical reels feed stretched full-width looks wrong on a wide
  // desktop browser, so it's centered in a phone-proportioned column
  // instead, matching how reels feeds are usually presented on the web.
  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.textDark,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: RecommendedVideos(properties: allProperties),
          ),
        ),
      ),
    );
  }
}
