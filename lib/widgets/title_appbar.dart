import 'package:flutter/material.dart';

class TitleAppBar extends StatelessWidget {
  TitleAppBar(
    this.title, {
    Key? key,
  })  : preferredSize = const Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize;

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
    );
  }
}
