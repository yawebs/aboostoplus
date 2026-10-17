import 'package:eafind/theme/app_palette.dart';
import 'package:flutter/material.dart';

import '../const/constant.dart';

class SelfContainForm extends StatefulWidget {
  const SelfContainForm({Key? key}) : super(key: key);

  @override
  State<SelfContainForm> createState() => _SelfContainFormState();
}

class _SelfContainFormState extends State<SelfContainForm> {
  bool isFrontView = false;
  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('Front View'),
                trailing: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFrontView = !isFrontView;
                    });
                  },
                  child: Icon(
                    isFrontView ? Icons.remove : Icons.add,
                  ),
                ),
              ),
              isFrontView
                  ? Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      width: width(context),
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: context.palette.accent,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder,
                            color: context.palette.accent,
                            size: 40,
                          ),
                          Text('Choose Front View Image')
                        ],
                      ),
                    )
                  : Container()
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('Palour'),
                trailing: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFrontView = !isFrontView;
                    });
                  },
                  child: Icon(
                    isFrontView ? Icons.remove : Icons.add,
                  ),
                ),
              ),
              isFrontView
                  ? Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      width: width(context),
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: context.palette.accent,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder,
                            color: context.palette.accent,
                            size: 40,
                          ),
                          Text('Choose Front View Image')
                        ],
                      ),
                    )
                  : Container()
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('Kitchen'),
                trailing: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFrontView = !isFrontView;
                    });
                  },
                  child: Icon(
                    isFrontView ? Icons.remove : Icons.add,
                  ),
                ),
              ),
              isFrontView
                  ? Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      width: width(context),
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: context.palette.accent,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder,
                            color: context.palette.accent,
                            size: 40,
                          ),
                          Text('Choose Front View Image')
                        ],
                      ),
                    )
                  : Container()
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('Bath Room'),
                trailing: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFrontView = !isFrontView;
                    });
                  },
                  child: Icon(
                    isFrontView ? Icons.remove : Icons.add,
                  ),
                ),
              ),
              isFrontView
                  ? Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      width: width(context),
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: context.palette.accent,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder,
                            color: context.palette.accent,
                            size: 40,
                          ),
                          Text('Choose Front View Image')
                        ],
                      ),
                    )
                  : Container()
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('Room 1'),
                trailing: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFrontView = !isFrontView;
                    });
                  },
                  child: Icon(
                    isFrontView ? Icons.remove : Icons.add,
                  ),
                ),
              ),
              isFrontView
                  ? Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      width: width(context),
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: context.palette.accent,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder,
                            color: context.palette.accent,
                            size: 40,
                          ),
                          Text('Choose Front View Image')
                        ],
                      ),
                    )
                  : Container()
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('Room 2'),
                trailing: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFrontView = !isFrontView;
                    });
                  },
                  child: Icon(
                    isFrontView ? Icons.remove : Icons.add,
                  ),
                ),
              ),
              isFrontView
                  ? Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      width: width(context),
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: context.palette.accent,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder,
                            color: context.palette.accent,
                            size: 40,
                          ),
                          Text('Choose Front View Image')
                        ],
                      ),
                    )
                  : Container()
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10),
          child: const TextField(
            decoration: InputDecoration(hintText: 'Price'),
            keyboardType: TextInputType.number,
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10),
          child: const TextField(
            decoration: InputDecoration(hintText: 'Community'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Please only enter community name, with no address',
            style: TextStyle(fontSize: 10, color: context.palette.accent),
          ),
        )
      ],
    );
  }
}
