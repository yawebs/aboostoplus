import 'package:eafind/theme/app_palette.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/services/providers/rebuild_provider.dart';
import 'package:eafind/widgets/report_options_widget.dart';
import 'package:eafind/widgets/reactors_sheet.dart';
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

class ReactionsWidget extends StatefulWidget {
  final PropertyModel property;
  final showWhite;
  // Swaps the bordered "Details" box for a filled pill button - used by
  // the immersive photo viewer, where the bar sits on a dark glass
  // background rather than a light card.
  final bool filledDetailsButton;
  const ReactionsWidget(
      {Key? key,
      required this.property,
      this.showWhite,
      this.filledDetailsButton = false})
      : super(key: key);

  @override
  State<ReactionsWidget> createState() => _ReactionsWidgetState();
}

class _ReactionsWidgetState extends State<ReactionsWidget> {
  int comments = 0;
  int thumbsUp = 0;
  int thumbsDown = 0;
  int shares = 0;
  bool hasThumbUp = false;
  bool hasThumbDown = false;
  bool isReacting = false;
  Timer? _reactionTimer;

  UserModel? onlineUser;

  Timer? _commentsTimer;
  getUser() async {
    UserModel? currentUser = context.read<UsermodelProvider>().getUserModel();
    if (currentUser != null) {
      if (!mounted) return;
      setState(() {
        onlineUser = currentUser;
      });
    }
  }

  showCommentModal() {
    showModalBottomSheet(
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15.0), topRight: Radius.circular(15.0)),
        ),
        builder: (ctx) {
          return CommentSheet(
            property: widget.property,
            thumbsUp: thumbsUp,
            hasThumbsUp: hasThumbUp,
          );
        });
  }

  getComments() async {
    List<CommentModel> sComments = [];
    try {
      FormData formData =
          FormData.fromMap({'propertyId': widget.property.id.toString()});
      var response =
          await Dio().post(endPoint('get-comments.php'), data: formData);
      if (response.data['status'] == 'Success') {
        if (response.data['data'] == null) {
        } else {
          for (var data in response.data['data']) {
            CommentModel commentModel = CommentModel.fromMap(data);
            sComments.add(commentModel);
          }
          if (sComments.length > comments) {
            if (!mounted) return;
            setState(() {
              comments = sComments.length;
            });
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  reactToProperty(reactionType) async {
    setState(() {
      isReacting = true;
    });
    try {
      FormData formData = FormData.fromMap({
        'propertyId': widget.property.id,
        'userId': onlineUser!.id,
        'reactionType': reactionType,
        'userName': onlineUser!.userName
      });
      var response = await Dio().post(endPoint('reaction.php'), data: formData);
      debugPrint('Response is $response');
      setState(() {
        isReacting = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isReacting = false;
      });
    }
  }

  getReactions() async {
    List sThumbsUp = [];
    List sThumbsDown = [];
    try {
      FormData formData =
          FormData.fromMap({'propertyId': widget.property.id.toString()});
      var response =
          await Dio().post(endPoint('get-reactions.php'), data: formData);
      if (response.data['status'] == 'Success') {
        if (response.data['data'] == null) {
        } else {
          for (var data in response.data['data']) {
            if (data['thumb_up'] == 1) {
              sThumbsUp.add(data);
            } else if (data['thumb_down'] == 1) {
              sThumbsDown.add(data);
            }
          }

          var isThumbdown = sThumbsDown.firstWhere(
            (element) =>
                element['userId'] == onlineUser!.id &&
                element['thumb_down'] == 1,
            orElse: () => null,
          );
          if (isThumbdown != null) {
            if (!mounted) return;
            setState(() {
              hasThumbDown = true;
            });
          } else {
            if (!mounted) return;
            setState(() {
              hasThumbDown = false;
            });
          }
          if (!mounted) return;
          setState(() {
            thumbsDown = sThumbsDown.length;
          });

          var isThumbup = sThumbsUp.firstWhere(
            (element) =>
                element['userId'] == onlineUser!.id && element['thumb_up'] == 1,
            orElse: () => null,
          );
          if (isThumbup != null) {
            if (!mounted) return;
            setState(() {
              hasThumbUp = true;
            });
          } else {
            if (!mounted) return;
            setState(() {
              hasThumbUp = false;
            });
          }
          if (!mounted) return;
          setState(() {
            thumbsUp = sThumbsUp.length;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  showReportModal() {
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
          return ReportOptionsSheet(property: widget.property);
        });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
    getComments();
    getReactions();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  // @override
  // void didChangeDependencies() async {
  //   // TODO: implement didChangeDependencies
  //   super.didChangeDependencies();
  //   if (Provider.of<RebuildProvider>(context).getRebuild() == true) {
  //     await getComments();
  //     await getReactions();
  //     if (!mounted) return;
  //     Provider.of<RebuildProvider>(context, listen: false).setRebuild(false);
  //   }
  // }

  void _showReactors(bool dislikes) {
    final id = int.tryParse('${widget.property.id}') ?? 0;
    if (id <= 0) return;
    showReactorsSheet(context, propertyId: id, startOnDislikes: dislikes);
  }

  // Tapping the number opens who reacted (tapping the icon reacts).
  Widget _count(int value, {required bool dislikes}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showReactors(dislikes),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 6, 9, 6),
        child: Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: value > 0 ? TextDecoration.underline : null,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: widget.showWhite == null ? grey : white,
            color: widget.showWhite == null ? null : white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (onlineUser != null) {
                    if (hasThumbDown) {
                      setState(() {
                        thumbsDown = thumbsDown - 1;
                        hasThumbDown = false;
                      });
                    }
                    if (hasThumbUp) {
                      setState(() {
                        thumbsUp = thumbsUp - 1;
                        hasThumbUp = false;
                      });
                    } else {
                      AudioManager.playSfx('like.mp3');
                      setState(() {
                        thumbsUp = thumbsUp + 1;
                        hasThumbUp = true;
                      });
                    }
                    await reactToProperty('thumbs up');
                    await getReactions();
                    getComments();
                  } else {
                    goTo(
                        context,
                        const LoginScreen(
                          fromNav: false,
                        ),
                        false);
                  }
                },
                onLongPress: () => _showReactors(false),
                child: Icon(
                  Icons.thumb_up,
                  size: 18,
                  color: hasThumbUp ? context.palette.accent : grey,
                ),
              ),
              _count(thumbsUp, dislikes: false),
              Padding(
                padding: EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onLongPress: () => _showReactors(true),
                  onTap: () async {
                    if (onlineUser != null) {
                      AudioManager.playSfx('like.mp3');
                      if (hasThumbUp) {
                        setState(() {
                          thumbsUp = thumbsUp - 1;
                          hasThumbUp = false;
                        });
                      }
                      if (hasThumbDown) {
                        setState(() {
                          thumbsDown = thumbsDown - 1;
                          hasThumbDown = false;
                        });
                      } else {
                        AudioManager.playSfx('like.mp3');
                        setState(() {
                          thumbsDown = thumbsDown + 1;
                          hasThumbDown = true;
                        });
                      }
                      await reactToProperty('thumbs down');
                      await getReactions();
                      getComments();
                    } else {
                      goTo(
                          context,
                          const LoginScreen(
                            fromNav: false,
                          ),
                          false);
                    }
                  },
                  child: Icon(
                    Icons.thumb_down,
                    size: 18,
                    color: hasThumbDown ? context.palette.accent : grey,
                  ),
                ),
              ),
              _count(thumbsDown, dislikes: true),
              GestureDetector(
                onTap: () => showCommentModal(),
                child: Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment,
                        size: 18,
                        color: grey,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 5.0),
                        child: Text('$comments',
                            style: TextStyle(
                                color:
                                    widget.showWhite == null ? null : white)),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
          widget.property.isHouse == 0
              ? SizedBox.shrink()
              : GestureDetector(
                  onTap: () => goTo(context,
                      HouseDetailsScreen(property: widget.property), false),
                  child: widget.filledDetailsButton
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8A93B),
                            borderRadius: appRadius(24.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Property Details',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF241428),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: const Color(0xFF241428),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: grey,
                            ),
                            borderRadius: appRadius(10.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.contact_support,
                                size: 10,
                                color: grey,
                              ),
                              Text(
                                'Details',
                                style: TextStyle(
                                  color: widget.showWhite == null
                                      ? context.palette.accent
                                      : white,
                                ),
                              ),
                            ],
                          ),
                        ),
                )
        ],
      ),
    );
  }
}
