import 'package:eafind/theme/app_palette.dart';
import 'package:flutter/material.dart';

import '../const/constant.dart';
import '../models/property_model.dart';
import '../screens/all_reels_video_screen.dart';

class RealsCardHome extends StatefulWidget {
  final List<PropertyModel> properties;
  const RealsCardHome({Key? key, required this.properties}) : super(key: key);

  @override
  State<RealsCardHome> createState() => _RealsCardHomeState();
}

class _RealsCardHomeState extends State<RealsCardHome> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.video_camera_back,
                        color: context.palette.accent,
                      ),
                      w10(),
                      Text('Videos'),
                    ],
                  ),
                  Icon(
                    Icons.more_vert,
                    color: grey,
                  )
                ],
              ),
            ),
            h10(),
            Container(
                height: 300,
                child: AllReelsVideoScreen(allProperties: widget.properties))
          ],
        ),
      ),
    );
  }
}
