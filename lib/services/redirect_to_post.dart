import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/widgets/create_post.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RedirectToPost extends StatefulWidget {
  const RedirectToPost({Key? key}) : super(key: key);

  @override
  State<RedirectToPost> createState() => _RedirectToPostState();
}

class _RedirectToPostState extends State<RedirectToPost> {
  bool _isLoading = true;
  redirect() async {
    UserModel? user =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    await Future.delayed(const Duration(seconds: 1)).then((onValue) {
      goTo(
          context,
          user == null
              ? LoginScreen(fromNav: true)
              : CreatePostSheet(user: user),
          false);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    redirect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.paper,
      body: Container(
        height: height(context),
        child: Center(
          child: appLoader(35.0),
        ),
      ),
    );
  }
}
