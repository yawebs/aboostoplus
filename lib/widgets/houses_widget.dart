import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/screens/house_details_screen.dart';
import 'package:eafind/screens/agents/user_account.dart';
import 'package:flutter/material.dart';

class HousesWidget extends StatefulWidget {
  var property;
  HousesWidget({
    required this.property,
    Key? key,
  }) : super(key: key);

  @override
  State<HousesWidget> createState() => _HousesWidgetState();
}

class _HousesWidgetState extends State<HousesWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), topRight: Radius.circular(10)),
      ),
      child: Container(
        width: 250,
        child: Column(
          children: [
            Container(
              height: 150,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: (() => goTo(
                        context,
                        HouseDetailsScreen(
                          property: widget.property,
                        ),
                        false)),
                    child: SizedBox(
                      height: 150,
                      width: width(context),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                        child: Image.network(
                          widget.property.images.first,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 5.0,
                    top: 5.0,
                    child: Container(
                      width: 40,
                      height: 40,
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: appRadius(20.0)),
                        child: Icon(
                          Icons.remove_red_eye,
                          size: 15,
                          color: context.palette.accent,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: EdgeInsets.only(left: 5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.house_siding_rounded,
                          size: 20,
                          color: context.palette.accent,
                        ),
                        Text(widget.property.category)
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 3.0, horizontal: 2.0),
                    child: Row(
                      children: [
                        Text('₦${widget.property.amount}'),
                        Text(
                          '/Yearly',
                          style: TextStyle(
                            color: grey300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 15,
                          color: context.palette.accent,
                        ),
                        Text(
                          widget.property.location,
                          style: TextStyle(color: grey300),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: (() => goTo(
                        context,
                        UserAccount(
                          userId: widget.property.ownerId,
                        ),
                        false)),
                    child: Container(
                      width: 270,
                      margin: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 25,
                                width: 30,
                                child: const CircleAvatar(
                                  backgroundImage: AssetImage(
                                    'assets/images/agent1.jpg',
                                  ),
                                ),
                              ),
                              Text('agentName'),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 5.0),
                            child: Card(
                                child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Text(widget.property.userType),
                            )),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
