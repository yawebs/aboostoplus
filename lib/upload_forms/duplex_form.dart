import 'package:eafind/theme/app_palette.dart';
import 'package:flutter/material.dart';

import '../const/constant.dart';

class DuplexForm extends StatefulWidget {
  const DuplexForm({Key? key}) : super(key: key);

  @override
  State<DuplexForm> createState() => _DuplexFormState();
}

class _DuplexFormState extends State<DuplexForm> {
  bool _isFrontView = false;
  bool _isPalourView = false;
  bool _isKitchenVeiw = false;
  bool _isBathRoomView = false;
  bool _isRoom1View = false;
  bool _isRoom2View = false;
  var price;
  var community;
  ScrollController _controller = ScrollController();

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height(context) / 1.1,
      child: ListView(
        controller: _controller,
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('Front View'),
                  trailing: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFrontView = !_isFrontView;
                      });
                    },
                    child: Icon(
                      _isFrontView ? Icons.remove : Icons.add,
                    ),
                  ),
                ),
                _isFrontView
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
                        _isPalourView = !_isPalourView;
                      });
                    },
                    child: Icon(
                      _isPalourView ? Icons.remove : Icons.add,
                    ),
                  ),
                ),
                _isPalourView
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
                            Text('Choose Palour View Image')
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
                        _isKitchenVeiw = !_isKitchenVeiw;
                      });
                    },
                    child: Icon(
                      _isKitchenVeiw ? Icons.remove : Icons.add,
                    ),
                  ),
                ),
                _isKitchenVeiw
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
                            Text('Choose Kitchen View Image')
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
                        _isBathRoomView = !_isBathRoomView;
                      });
                    },
                    child: Icon(
                      _isBathRoomView ? Icons.remove : Icons.add,
                    ),
                  ),
                ),
                _isBathRoomView
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
                            Text('Choose Bath-Room View Image')
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
                        _isRoom1View = !_isRoom1View;
                      });
                    },
                    child: Icon(
                      _isRoom1View ? Icons.remove : Icons.add,
                    ),
                  ),
                ),
                _isRoom1View
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
                            Text('Choose First Room View Image')
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
                        _isRoom2View = !_isRoom2View;
                      });
                    },
                    child: Icon(
                      _isRoom2View ? Icons.remove : Icons.add,
                    ),
                  ),
                ),
                _isRoom2View
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
                            Text('Choose Second Room View Image')
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
      ),
    );
  }
}
