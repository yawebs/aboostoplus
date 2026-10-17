import 'package:eafind/widgets/verified_badge.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/widgets/payment_sheet.dart';
import 'package:eafind/widgets/review_list.dart';
import 'package:eafind/widgets/video_player_controlls_widget.dart';
import 'package:eafind/widgets/view_photo_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../const/constant.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';
import 'video_display_widget.dart';

class HouseDetailsScreen extends StatefulWidget {
  final PropertyModel property;
  final isPreviewOnly;
  const HouseDetailsScreen(
      {Key? key, required this.property, this.isPreviewOnly})
      : super(key: key);

  @override
  State<HouseDetailsScreen> createState() => _HouseDetailsScreenState();
}

class _HouseDetailsScreenState extends State<HouseDetailsScreen> {
  String currentDetailsShowing = 'Overview';

  UserModel? user;
  bool isLoading = false;

  showPaymentInfoModal() {
    showModalBottomSheet(
        backgroundColor: context.palette.paper,
        context: context,
        // Size to the sheet's content instead of the default 9/16 cap.
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return Paymentsheet(
            property: widget.property,
            userCustomer: user!,
          );
        });
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    UserModel? fUser =
        Provider.of<UsermodelProvider>(context, listen: false).userModel;
    setState(() {
      user = fUser;
      isLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.paper,
      appBar: detailsAppBar(),
      bottomSheet: widget.isPreviewOnly == true
          ? SizedBox.shrink()
          : Card(
              color: context.palette.primaryFill,
              elevation: 10,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      agentWidget(),
                      GestureDetector(
                        onTap: () {
                          if (user == null) {
                            goTo(context, LoginScreen(fromNav: true), false);
                          } else {
                            showPaymentInfoModal();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                              border: Border.all(
                                width: 2,
                                color: grey,
                              ),
                              borderRadius: appRadius(15.0)),
                          child: Row(children: [
                            Icon(
                              Icons.calendar_month,
                              color: white,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Book Inspection',
                                style: TextStyle(color: white),
                              ),
                            ),
                          ]),
                        ),
                      )
                    ],
                  )),
            ),
      body: isLoading
          ? appSearchLoader(context.palette.accent, 50.0)
          : ListView(shrinkWrap: true, children: [
              widget.property.isVideo == 1
                  ? VideoDisplayWidget(property: widget.property)
                  : houseImageWidget(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.property.category,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text('₦${NumberFormat().format(widget.property.amount)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18))
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: grey,
                      size: 15,
                    ),
                    Text(widget.property.location,
                        style: TextStyle(color: grey))
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    houseFeatursWidget('Bathrooms',
                        widget.property.bathrooms.toString(), Icons.bathroom),
                    houseFeatursWidget('Bedrooms',
                        widget.property.rooms.toString(), Icons.bed),
                  ],
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 50,
                padding: EdgeInsets.only(left: 10, top: 10, bottom: 5.0),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  children: [
                    houseDetails('Overview'),
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            currentDetailsShowing = 'Reviews';
                          });
                        },
                        child: houseDetails('Reviews')),
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            currentDetailsShowing = 'Other Fees';
                          });
                        },
                        child: houseDetails('Other Fees')),
                    houseDetails('Reviews')
                  ],
                ),
              ),
              currentDetailsShowing == 'Reviews'
                  ? ReviewList(
                      property: widget.property,
                    )
                  : currentDetailsShowing == 'Other Fees'
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 80),
                          child: ListView(
                            shrinkWrap: true,
                            primary: false,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Agent Fee',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: grey),
                                    ),
                                    Text(
                                      '₦${NumberFormat().format(widget.property.agentFee)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    )
                                  ],
                                ),
                              ),
                              Divider(),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Caution Fee',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: grey),
                                    ),
                                    Text(
                                      '₦${NumberFormat().format(widget.property.cautionFee)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    )
                                  ],
                                ),
                              ),
                              Divider(),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Legal Fee',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: grey),
                                    ),
                                    Text(
                                      '₦${NumberFormat().format(widget.property.legalFee)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(widget.property.description),
                        ),
            ]),
    );
  }

  Widget houseDetails(label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          currentDetailsShowing = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        margin: EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
            color: currentDetailsShowing == label
                ? context.palette.primaryFill.withOpacity(0.4)
                : context.palette.paper,
            borderRadius: appRadius(10.0)),
        child: Center(
            child: Text(
          label,
          style:
              TextStyle(color: currentDetailsShowing == label ? white : grey),
        )),
      ),
    );
  }

  Widget agentWidget() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                border: Border.all(width: 2, color: grey),
                borderRadius: appRadius(50.0)),
            child: ClipOval(
                child: Image.asset(
              imageRounte(
                name: 'com.aboostoplus.app',
              ),
              cacheHeight: 80,
              cacheWidth: 80,
              color: white,
              fit: BoxFit.cover,
            )),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.property.userName,
                  style: TextStyle(color: white),
                ),
                Row(
                  children: [
                    Text(
                      widget.property.userType,
                      style: TextStyle(color: grey),
                    ),
                    VerifiedBadge(
                        userId: widget.property.ownerId, size: 11, gap: 2)
                  ],
                )
              ],
            ),
          )
        ],
      ),
    ]);
  }

  Widget houseFeatursWidget(title, number, icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: grey,
                size: 15,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(number),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(title),
          )
        ],
      ),
    );
  }

  Widget houseImageWidget() {
    return GestureDetector(
      onTap: (() => goTo(
          context,
          ViewPhotoWidget(
              images: widget.property.images, propertyModel: widget.property),
          false)),
      child: Container(
        height: 200,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Card(
              elevation: 15,
              child: Container(
                width: width(context) / 1.4,
                height: 250,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),
                  child: Image.network(widget.property.images.first,
                      fit: BoxFit.cover, cacheWidth: 200),
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
                child: ListView.builder(
                    itemCount: widget.property.images.length,
                    itemBuilder: (ctx, index) {
                      if (index == 2) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 5.0),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 1,
                                color: grey,
                              ),
                              borderRadius: appRadius(10.0),
                            ),
                            child: Center(
                              child: Text(
                                '+${widget.property.images.length}',
                                style: TextStyle(
                                  color: grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5.0),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 10,
                          child: Container(
                            height: 50,
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              child: Image.network(
                                widget.property.images[index],
                                fit: BoxFit.cover,
                                cacheWidth: 200,
                              ),
                            ),
                          ),
                        ),
                      );
                    }))
          ],
        ),
      ),
    );
  }

  AppBar detailsAppBar() {
    return AppBar(
      backgroundColor: context.palette.paper,
      elevation: 0.0,
      leading: GestureDetector(
        onTap: () => goBack(context),
        child: Icon(
          Icons.arrow_back_ios,
          color: context.palette.ink,
          size: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(
            Icons.more_horiz,
            color: context.palette.ink,
          ),
        )
      ],
    );
  }
}
