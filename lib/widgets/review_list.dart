import 'package:eafind/widgets/verified_badge.dart';
import 'package:dio/dio.dart';
import 'package:eafind/models/property_model.dart';
import 'package:flutter/material.dart';

import '../const/constant.dart';
import '../models/comment_model.dart';

class ReviewList extends StatefulWidget {
  final PropertyModel property;
  const ReviewList({Key? key, required this.property}) : super(key: key);

  @override
  State<ReviewList> createState() => _ReviewListState();
}

class _ReviewListState extends State<ReviewList> {
  List<CommentModel> comments = [];
  bool isLoading = false;
  getComments() async {
    List<CommentModel> sComments = [];
    try {
      setState(() {
        isLoading = true;
      });
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
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getComments();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100.0),
      child: isLoading
          ? listLoader()
          : comments.isEmpty
              ? Center(child: Text('No Comments'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: comments.length,
                  primary: false,
                  itemBuilder: (context, reIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  ClipOval(
                                    child: Image.asset(
                                      imageRounte(name: 'avatar.png'),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(comments[reIndex].commenterName),
                                        const SizedBox(height: 3),
                                        Text(
                                          comments[reIndex].dateCreated,
                                          style: TextStyle(
                                              color: grey, fontSize: 12),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              VerifiedBadge(
                                  userId: comments[reIndex].commenterId,
                                  size: 18)
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              comments[reIndex].comment,
                            ),
                          )
                        ],
                      ),
                    );
                  }),
    );
  }
}
