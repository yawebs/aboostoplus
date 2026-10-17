import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/const/constant.dart';
import 'package:flutter/material.dart';

class ExploreWidget extends StatelessWidget {
  String image;
  String title;
  ExploreWidget({Key? key, required this.image, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: context.palette.primaryFill,
        image: DecorationImage(
          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.screen),
          fit: BoxFit.cover,
          image: AssetImage(image),
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(color: white),
          ),
          Container(
            width: 100,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: context.palette.paper,
              borderRadius: const BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            child: MaterialButton(
              onPressed: () => '',
              child: Row(children: [
                Text(
                  'Explore',
                  style: TextStyle(color: context.palette.accent),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: context.palette.accent,
                )
              ]),
            ),
          )
        ],
      ),
    );
  }
}
