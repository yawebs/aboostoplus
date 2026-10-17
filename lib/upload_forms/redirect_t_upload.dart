import 'package:eafind/const/constant.dart';
import 'package:eafind/upload_forms/house_upload.dart';
import 'package:flutter/material.dart';

class RedirectToUploadScreen extends StatefulWidget {
  const RedirectToUploadScreen({Key? key}) : super(key: key);

  @override
  State<RedirectToUploadScreen> createState() => _RedirectToUploadScreenState();
}

class _RedirectToUploadScreenState extends State<RedirectToUploadScreen> {
  redirect() async {
    Future.delayed(const Duration(seconds: 1)).then((onValue) {
      goTo(context, HouseUploadScreen(), false);
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
      body: Container(
        height: height(context),
        child: Center(
          child: appLoader(50.0),
        ),
      ),
    );
  }
}
