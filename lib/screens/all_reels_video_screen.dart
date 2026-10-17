import 'dart:io';

import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:eafind/widgets/video_reels_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AllReelsVideoScreen extends StatefulWidget {
  final List<PropertyModel> allProperties;
  // Pass NeverScrollableScrollPhysics when embedding a single video inside
  // another horizontal list (e.g. a featured card), so the inner list
  // doesn't swallow the swipe meant for the outer one.
  final ScrollPhysics? physics;
  const AllReelsVideoScreen(
      {Key? key, required this.allProperties, this.physics})
      : super(key: key);

  @override
  State<AllReelsVideoScreen> createState() => _AllReelsVideoScreenState();
}

class _AllReelsVideoScreenState extends State<AllReelsVideoScreen> {
  bool isLoading = false;
  bool isBadNetwork = false;
  List<PropertyModel> videoReels = [];
  Future<dynamic> filterVideoFiles() async {
    List<PropertyModel> videoProperties = [];
    setState(() {
      isLoading = true;
    });
    try {
      videoProperties =
          widget.allProperties.where((p) => p.isVideo == 1).toList();

      isLoading = false;

      setState(() {
        videoReels = videoProperties;
      });
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
    filterVideoFiles();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return isLoading
        ? appLoader(50.0)
        : ListView.builder(
            itemCount: videoReels.length,
            primary: false,
            physics: widget.physics,
            scrollDirection: Axis.horizontal,
            itemBuilder: (ctx, index) {
              PropertyModel propertyModel = videoReels[index];
              return VideoReelsWidget(
                property: propertyModel,
                index: index,
              );
            });
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: isLoading
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            )
          : videoReels.isEmpty
              ? const EmptyState(
                  icon: Icons.videocam_off_outlined,
                  title: 'No video reels yet',
                )
              : SizedBox(
                  height: 260,
                  child: ListView.separated(
                    itemCount: videoReels.length,
                    primary: false,
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (ctx, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: VideoReelsWidget(
                          property: videoReels[index],
                          index: index,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
