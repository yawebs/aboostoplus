import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/widgets/agent_account_profile.dart';
import 'package:eafind/widgets/video_player_controlls_widget.dart';
import 'package:eafind/widgets/video_reactions_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/db_services.dart';
import 'video_playback_manager.dart';

class RecommendedVideos extends StatefulWidget {
  final List<PropertyModel> properties;

  const RecommendedVideos({
    Key? key,
    required this.properties,
  }) : super(key: key);

  @override
  State<RecommendedVideos> createState() => _RecommendedVideosState();
}

class _RecommendedVideosState extends State<RecommendedVideos> {
  late PageController _pageController;
  bool _isLoading = false;
  int _currentIndex = 0;
  List<PropertyModel> _properties = [];
  int increament = 20;

  getVideos() async {
    if (widget.properties.isEmpty) {
      setState(() {
        _isLoading = true;
      });
      try {
        List<PropertyModel> prpties =
            await DbServices.getPropertyVideosOnly('videos', increament);

        _properties = prpties;

        setState(() {
          _isLoading = false;
        });

        return prpties;
      } on DioException catch (e) {
        debugPrint(
            'Something went wrong fetching post Featured Properties ${e.message}');
      } on SocketException catch (_) {
      } catch (e) {}
    } else {
      setState(() {
        _properties = widget.properties;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getVideos();
    _pageController = PageController(
      initialPage: 0,
    );
  }

  // ===========================================================================
  // PAGE CHANGED
  // ===========================================================================

  void _onPageChanged(int index) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    VideoPlaybackManager.instance.pauseAll();

    _pageController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: videoLoader(size: 40),
            ),
          )
        : SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            child: PageView.builder(
              controller: _pageController,

              // ================================================================
              // TIKTOK STYLE
              // ================================================================

              scrollDirection: Axis.vertical,

              physics: const PageScrollPhysics(),

              itemCount: _properties.length,

              onPageChanged: _onPageChanged,

              itemBuilder: (context, index) {
                final property = _properties[index];

                final bool isActive = index == _currentIndex;

                return _RecommendedVideoPage(
                  property: property,
                  isActive: isActive,
                );
              },
            ),
          );
  }
}

// =============================================================================
// VIDEO PAGE
// =============================================================================

class _RecommendedVideoPage extends StatelessWidget {
  final PropertyModel property;
  final bool isActive;

  const _RecommendedVideoPage({
    required this.property,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ===================================================================
          // VIDEO
          // ===================================================================

          VideoWidgetPlayerControllsWidget(
            property: property,
            isActive: isActive,
          ),

          // ===================================================================
          // BOTTOM INFORMATION
          // ===================================================================

          Positioned(
            left: 15,
            right: 85,
            bottom: 125,
            child: _VideoInformation(
              property: property,
            ),
          ),

          // ===================================================================
          // RIGHT REACTION RAIL
          // ===================================================================

          Positioned(
            right: 8,
            bottom: 125,
            child: VideoReactionsWidget(
              property: property,
              showWhite: 'white',
            ),
          ),

          // ===================================================================
          // TOP PROFILE
          // ===================================================================

          Positioned(
            top: MediaQuery.of(context).padding.top + 15,
            left: 15,
            right: 70,
            child: AgentAccountProfile(
              property: property,
              color: white,
            ),
          ),

          // ===================================================================
          // MORE BUTTON
          // ===================================================================

          Positioned(
            top: MediaQuery.of(context).padding.top + 13,
            right: 15,
            child: GestureDetector(
              onTap: () {
                showReportModal(
                  property,
                  context,
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// VIDEO INFORMATION
// =============================================================================

class _VideoInformation extends StatelessWidget {
  final PropertyModel property;

  const _VideoInformation({
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // =====================================================================
        // DESCRIPTION
        // =====================================================================

        if (property.description.trim().isNotEmpty)
          if (property.isHouse != 0)
            AutoSizeText(
              property.description,
              maxLines: 3,
              minFontSize: 13,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: postColors[property.colorCode],
                borderRadius: appRadius(10),
              ),
              child: Text(
                property.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: getTextColor(
                    property.colorCode,
                  ),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

        const SizedBox(height: 10),

        // =====================================================================
        // PRICE
        // =====================================================================

        if (property.isHouse != 0)
          Text(
            '₦${NumberFormat().format(property.amount)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
