import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/widgets/report_options_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../const/constant.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../screens/house_details_screen.dart';
import '../services/db_services.dart';
import '../utility/audio_manager.dart';
import 'comment_sheet.dart';

class VideoReactionsWidget extends StatefulWidget {
  final PropertyModel property;
  final dynamic showWhite;

  const VideoReactionsWidget({
    Key? key,
    required this.property,
    this.showWhite,
  }) : super(key: key);

  @override
  State<VideoReactionsWidget> createState() => _VideoReactionsWidgetState();
}

class _VideoReactionsWidgetState extends State<VideoReactionsWidget> {
  int comments = 0;
  int thumbsUp = 0;
  int thumbsDown = 0;
  int shares = 0;

  bool hasThumbUp = false;
  bool hasThumbDown = false;
  bool isReacting = false;

  UserModel? onlineUser;

  Timer? _reactionTimer;
  Timer? _commentsTimer;

  // ===========================================================================
  // GET USER
  // ===========================================================================

  Future<void> getUser() async {
    try {
      final currentUser = context.read<UsermodelProvider>().getUserModel();

      if (!mounted) return;

      setState(() {
        onlineUser = currentUser;
      });
    } catch (e) {
      debugPrint('getUser error: $e');
    }
  }

  // ===========================================================================
  // INITIAL DATA
  // ===========================================================================

  Future<void> _loadInitialData() async {
    await getUser();

    if (!mounted) return;

    await Future.wait([
      getComments(),
      getReactions(),
    ]);
  }

  // ===========================================================================
  // COMMENTS MODAL
  // ===========================================================================

  void showCommentModal() {
    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      builder: (ctx) {
        return CommentSheet(
          property: widget.property,
          thumbsUp: thumbsUp,
          hasThumbsUp: hasThumbUp,
        );
      },
    );
  }

  // ===========================================================================
  // GET COMMENTS
  // ===========================================================================

  Future<void> getComments() async {
    List<CommentModel> sComments = [];

    try {
      final formData = FormData.fromMap({
        'propertyId': widget.property.id.toString(),
      });

      final response = await Dio().post(
        endPoint('get-comments.php'),
        data: formData,
      );

      if (response.data['status'] != 'Success') {
        return;
      }

      if (response.data['data'] == null) {
        return;
      }

      for (final data in response.data['data']) {
        final commentModel = CommentModel.fromMap(data);

        sComments.add(commentModel);
      }

      if (!mounted) return;

      setState(() {
        comments = sComments.length;
      });
    } catch (e) {
      debugPrint('getComments error: $e');
    }
  }

  // ===========================================================================
  // REACT TO PROPERTY
  // ===========================================================================

  Future<void> reactToProperty(
    String reactionType,
  ) async {
    final user = onlineUser;

    if (user == null) {
      return;
    }

    if (mounted) {
      setState(() {
        isReacting = true;
      });
    }

    try {
      final formData = FormData.fromMap({
        'propertyId': widget.property.id,
        'userId': user.id,
        'reactionType': reactionType,
        'userName': user.userName,
      });

      final response = await Dio().post(
        endPoint('reaction.php'),
        data: formData,
      );

      debugPrint(
        'Reaction response: $response',
      );
    } catch (e) {
      debugPrint(
        'reactToProperty error: $e',
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isReacting = false;
      });
    }
  }

  // ===========================================================================
  // GET REACTIONS
  // ===========================================================================

  Future<void> getReactions() async {
    List sThumbsUp = [];
    List sThumbsDown = [];

    try {
      final formData = FormData.fromMap({
        'propertyId': widget.property.id.toString(),
      });

      final response = await Dio().post(
        endPoint('get-reactions.php'),
        data: formData,
      );

      if (response.data['status'] != 'Success') {
        return;
      }

      final data = response.data['data'];

      if (data != null) {
        for (final item in data) {
          if (item['thumb_up'] == 1) {
            sThumbsUp.add(item);
          } else if (item['thumb_down'] == 1) {
            sThumbsDown.add(item);
          }
        }
      }

      // -----------------------------------------------------------------------
      // Find current user's reactions only if logged in.
      // -----------------------------------------------------------------------

      bool userThumbUp = false;
      bool userThumbDown = false;

      final user = onlineUser;

      if (user != null) {
        final thumbDown = sThumbsDown.where(
          (element) =>
              element['userId'] == user.id && element['thumb_down'] == 1,
        );

        final thumbUp = sThumbsUp.where(
          (element) => element['userId'] == user.id && element['thumb_up'] == 1,
        );

        userThumbDown = thumbDown.isNotEmpty;
        userThumbUp = thumbUp.isNotEmpty;
      }

      if (!mounted) return;

      setState(() {
        thumbsDown = sThumbsDown.length;
        thumbsUp = sThumbsUp.length;

        hasThumbDown = userThumbDown;
        hasThumbUp = userThumbUp;
      });
    } catch (e) {
      debugPrint(
        'getReactions error: $e',
      );
    }
  }

  // ===========================================================================
  // REPORT
  // ===========================================================================

  void showReportModal() {
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
        return ReportOptionsSheet(
          property: widget.property,
        );
      },
    );
  }

  // ===========================================================================
  // THUMBS UP
  // ===========================================================================

  Future<void> _handleThumbUp() async {
    final user = onlineUser;

    if (user == null) {
      goTo(
        context,
        const LoginScreen(fromNav: false),
        false,
      );

      return;
    }

    // If currently thumbs down, remove it locally.
    if (hasThumbDown) {
      setState(() {
        thumbsDown = thumbsDown > 0 ? thumbsDown - 1 : 0;

        hasThumbDown = false;
      });
    }

    // Toggle thumbs up.
    if (hasThumbUp) {
      setState(() {
        thumbsUp = thumbsUp > 0 ? thumbsUp - 1 : 0;

        hasThumbUp = false;
      });
    } else {
      AudioManager.playSfx('like.mp3');

      setState(() {
        thumbsUp++;
        hasThumbUp = true;
      });
    }

    await reactToProperty('thumbs up');

    if (!mounted) return;

    await getReactions();
  }

  // ===========================================================================
  // THUMBS DOWN
  // ===========================================================================

  Future<void> _handleThumbDown() async {
    final user = onlineUser;

    if (user == null) {
      goTo(
        context,
        const LoginScreen(fromNav: false),
        false,
      );

      return;
    }

    AudioManager.playSfx('like.mp3');

    // Remove thumbs up if currently active.
    if (hasThumbUp) {
      setState(() {
        thumbsUp = thumbsUp > 0 ? thumbsUp - 1 : 0;

        hasThumbUp = false;
      });
    }

    // Toggle thumbs down.
    if (hasThumbDown) {
      setState(() {
        thumbsDown = thumbsDown > 0 ? thumbsDown - 1 : 0;

        hasThumbDown = false;
      });
    } else {
      setState(() {
        thumbsDown++;
        hasThumbDown = true;
      });
    }

    await reactToProperty('thumbs down');

    if (!mounted) return;

    await getReactions();
  }

  // ===========================================================================
  // INIT STATE
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    // IMPORTANT:
    //
    // We don't call getUser(), getComments() and getReactions()
    // independently anymore.
    //
    // _loadInitialData waits for the user before checking
    // the user's personal reactions.
    //
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadInitialData();
    });
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _reactionTimer?.cancel();
    _commentsTimer?.cancel();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // =====================================================================
        // THUMBS UP
        // =====================================================================

        GestureDetector(
          onTap: isReacting ? null : _handleThumbUp,
          child: _RailItem(
            icon: Icons.thumb_up,
            iconColor: hasThumbUp ? primaryColor : white,
            label: '$thumbsUp',
          ),
        ),

        const SizedBox(height: 18),

        // =====================================================================
        // THUMBS DOWN
        // =====================================================================

        GestureDetector(
          onTap: isReacting ? null : _handleThumbDown,
          child: _RailItem(
            icon: Icons.thumb_down,
            iconColor: hasThumbDown ? primaryColor : white,
            label: '$thumbsDown',
          ),
        ),

        const SizedBox(height: 18),

        // =====================================================================
        // COMMENTS
        // =====================================================================

        GestureDetector(
          onTap: showCommentModal,
          child: _RailItem(
            icon: Icons.comment,
            iconColor: white,
            label: '$comments',
          ),
        ),

        // =====================================================================
        // DETAILS
        // =====================================================================

        if (widget.property.isHouse != 0) ...[
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              goTo(
                context,
                HouseDetailsScreen(
                  property: widget.property,
                ),
                false,
              );
            },
            child: _RailItem(
              icon: Icons.contact_support,
              iconColor: white,
              label: 'Details',
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// RAIL ITEM
// =============================================================================

class _RailItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _RailItem({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: const BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 27,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
