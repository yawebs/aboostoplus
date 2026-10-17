import 'package:eafind/theme/app_palette.dart';
import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/services/providers/rebuild_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../providers/usermodel_provider.dart';
import '../services/db_services.dart';

class CommentSheet extends StatefulWidget {
  PropertyModel property;
  int thumbsUp;
  bool hasThumbsUp;
  CommentSheet(
      {Key? key,
      required this.property,
      required this.thumbsUp,
      required this.hasThumbsUp})
      : super(key: key);

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  TextEditingController commentController = TextEditingController();
  var currentUser = FirebaseAuth.instance.currentUser;
  UserModel? onlineUser;
  List<CommentModel> comments = [];
  Timer? _commentsTimer;
  bool isSending = false;
  getUser() async {
    UserModel? user = context.read<UsermodelProvider>().userModel;
    setState(() {
      onlineUser = user;
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
        debugPrint('Comments fetch is ${widget.property.id}');
        if (response.data['data'] == null) {
          debugPrint('Comments fetch data is null');
        } else {
          for (var data in response.data['data']) {
            CommentModel commentModel = CommentModel.fromMap(data);

            sComments.add(commentModel);
          }
          if (sComments.length > comments.length) {
            setState(() {
              comments = sComments;
            });
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  sendComment() async {
    if (commentController.text.isNotEmpty) {
      setState(() {
        isSending = true;
      });
      String userName = '${onlineUser!.firstName} ${onlineUser!.lastName}';
      FormData formData = FormData.fromMap({
        'propertyId': widget.property.id,
        'commenterId': onlineUser!.id,
        'comment': commentController.text,
        'commenterName': userName,
        'commenterImage': onlineUser!.profileImage,
      });
      var localComment = CommentModel(
          id: 0,
          propertyId: widget.property.id,
          commenterId: onlineUser!.id,
          comment: commentController.text,
          commenterName: userName,
          dateCreated: DateTime.now().toString(),
          commenterImage: onlineUser!.profileImage);
      setState(() {
        comments.add(localComment);
        commentController.text = '';
      });
      try {
        var response =
            await Dio().post(endPoint('add-comment.php'), data: formData);
        setState(() {
          isSending = false;
        });
      } catch (e) {
        debugPrint(e.toString());
        setState(() {
          isSending = false;
        });
      }
    } else {}
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getComments();

    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height(context) / 1.2,
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: context.palette.paper,
          bottomSheet: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            width: width(context),
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: appRadius(20.0),
                  color: context.palette.paper,
                ),
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Leave A Comment',
                    prefixIcon: Icon(
                      Icons.comment,
                      size: 18,
                      color: grey,
                    ),
                    suffixIcon: isSending
                        ? Center(
                            child: LoadingAnimationWidget.twoRotatingArc(
                                color: context.palette.accent, size: 15),
                          )
                        : GestureDetector(
                            onTap: () => sendComment(),
                            child: Icon(
                              Icons.send,
                              size: 20,
                              color: Colors.green,
                            ),
                          ),
                    border: InputBorder.none,
                  ),
                )),
          ),
          body: Container(
            decoration: BoxDecoration(
              color: context.palette.paper,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0)),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            child: CircleAvatar(
                              backgroundColor: primaryColor,
                              child: Icon(
                                Icons.thumb_up_rounded,
                                size: 12,
                                color: white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 5.0),
                            child: Text(widget.hasThumbsUp
                                ? widget.thumbsUp > 1
                                    ? 'You and ${widget.thumbsUp - 1} Others'
                                    : 'You only reacted'
                                : '${widget.thumbsUp} reactions'),
                          )
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Provider.of<RebuildProvider>(context, listen: false)
                              .setRebuild(true);

                          goBack(context);
                        },
                        child: CircleAvatar(
                          backgroundColor: black.withOpacity(0.1),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: grey,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Divider(),
                h10(),
                ListView.builder(
                    shrinkWrap: true,
                    primary: false,
                    itemCount: comments.length,
                    itemBuilder: ((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              child: ClipOval(
                                child: comments[index].commenterImage == null
                                    ? Image.asset(
                                        imageRounte(name: avatarImage),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        comments[index].commenterImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            Image.asset(
                                              imageRounte(name: avatarImage),
                                              fit: BoxFit.cover,
                                            )),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Card(
                                elevation: 0.1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: appRadius(20.0),
                                ),
                                color: context.palette.paper,
                                child: Container(
                                  width: width(context) / 1.3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AutoSizeText(
                                              comments[index].commenterName,
                                              style: TextStyle(
                                                  color: context.palette.ink,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            AutoSizeText(
                                              comments[index].comment,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          TimeOfDay.fromDateTime(DateTime.parse(
                                                  comments[index].dateCreated))
                                              .format(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    }))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
