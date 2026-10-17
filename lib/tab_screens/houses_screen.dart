import 'package:eafind/theme/app_palette.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/house_type_model.dart';
import 'package:eafind/screens/view_story_screen.dart';
import 'package:eafind/widgets/houses_widget.dart';
import 'package:flutter/material.dart';
import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/utils.dart';
import 'package:story_view/widgets/story_view.dart';

class HousesScreen extends StatefulWidget {
  const HousesScreen({Key? key}) : super(key: key);

  @override
  State<HousesScreen> createState() => _HousesScreenState();
}

class _HousesScreenState extends State<HousesScreen> {
  final controller = StoryController();
  String? selectedCommunity;
  String? selectedHouseType;
  List<String> itemsHouseTypes = [];
  List<String> itemCommunities = [];

  showStories() {
    List<StoryItem> storyItems = [
      StoryItem.text(title: 'Duplex Apartment', backgroundColor: primaryColor),
      StoryItem.pageImage(
          url:
              'https://image.ibb.co/cU4WGx/Omotuo-Groundnut-Soup-braperucci-com-1.jpg',
          controller: controller),
      StoryItem.pageImage(
          url:
              'https://image.ibb.co/cU4WGx/Omotuo-Groundnut-Soup-braperucci-com-1.jpg',
          controller: controller)
    ];
    return StoryView(
        storyItems: storyItems,
        controller: controller, // pass controller here too
        repeat: true, // should the stories be slid forever
        onStoryShow: (s, index) {},
        onComplete: () {},
        onVerticalSwipeComplete: (direction) {
          if (direction == Direction.down) {
            Navigator.pop(context);
          }
        } // To disable vertical swipe gestures, ignore this parameter.
        // Preferrably for inline story view.
        );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    itemsHouseTypes = houseTypes.map((e) => e.type).toList();
    itemCommunities = communities;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                child: Card(
                  color: black,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2(
                      isExpanded: true,
                      hint: Row(
                        children: [
                          Icon(
                            Icons.list,
                            size: 16,
                            color: white,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Expanded(
                            child: Text(
                              'Duplex',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      items: itemsHouseTypes
                          .map((item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      value: selectedHouseType,
                      onChanged: (value) {
                        setState(() {
                          selectedHouseType = value as String;
                        });
                      },
                      iconStyleData: IconStyleData(
                        icon: Icon(
                          Icons.arrow_drop_down,
                          size: 25,
                          color: context.palette.ink,
                        ),
                        iconSize: 14,
                        iconEnabledColor: white,
                        iconDisabledColor: Colors.grey,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 40,
                        padding: null,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          color: context.palette.paper,
                        ),
                        elevation: 8,
                        offset: const Offset(-20, 0),
                      ),
                      // icon: const Icon(
                      //   Icons.arrow_drop_down,
                      //   size: 25,
                      // ),
                      // iconSize: 14,
                      // iconEnabledColor: white,
                      // iconDisabledColor: Colors.grey,
                      // buttonHeight: 30,
                      // buttonWidth: 160,
                      // buttonPadding: const EdgeInsets.only(left: 14, right: 14),
                      // buttonElevation: 2,
                      // itemHeight: 40,
                      // itemPadding: const EdgeInsets.only(left: 14, right: 14),
                      // dropdownMaxHeight: 200,
                      // dropdownWidth: 200,
                      // dropdownPadding: null,
                      // dropdownDecoration: BoxDecoration(
                      //   borderRadius: BorderRadius.circular(14),
                      //   color: primaryColor,
                      // ),
                      // dropdownElevation: 8,
                      // scrollbarRadius: const Radius.circular(40),
                      // scrollbarThickness: 6,
                      // scrollbarAlwaysShow: true,
                      // offset: const Offset(-20, 0),
                    ),
                  ),
                ),
              ),
              Card(
                color: black,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    isExpanded: true,
                    hint: Row(
                      children: [
                        Icon(
                          Icons.list,
                          size: 16,
                          color: white,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Expanded(
                          child: Text(
                            'Community',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    items: itemCommunities
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    value: selectedCommunity,
                    onChanged: (value) {
                      setState(() {
                        selectedCommunity = value as String;
                      });
                    },

                    iconStyleData: IconStyleData(
                      icon: Icon(
                        Icons.arrow_drop_down,
                        size: 25,
                        color: context.palette.ink,
                      ),
                      iconSize: 14,
                      iconEnabledColor: white,
                      iconDisabledColor: Colors.grey,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 40,
                      padding: null,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: context.palette.paper,
                      ),
                      elevation: 8,
                      offset: const Offset(-20, 0),
                    ),

                    // icon: const Icon(
                    //   Icons.arrow_drop_down,
                    //   size: 25,
                    // ),
                    // iconSize: 14,
                    // iconEnabledColor: white,
                    // iconDisabledColor: Colors.grey,
                    // buttonHeight: 30,
                    // buttonWidth: 160,
                    // buttonPadding: const EdgeInsets.only(left: 14, right: 14),
                    // buttonElevation: 2,
                    // itemHeight: 40,
                    // itemPadding: const EdgeInsets.only(left: 14, right: 14),
                    // dropdownMaxHeight: 200,
                    // dropdownWidth: 200,
                    // dropdownPadding: null,
                    // dropdownDecoration: BoxDecoration(
                    //   borderRadius: BorderRadius.circular(14),
                    //   color: primaryColor,
                    // ),
                    // dropdownElevation: 8,
                    // scrollbarRadius: const Radius.circular(40),
                    // scrollbarThickness: 6,
                    // scrollbarAlwaysShow: true,
                    // offset: const Offset(-20, 0),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 210,
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: () {
                  print('zee is tapped ');
                  goTo(
                      context,
                      const ViewStoryScreen(
                        images: [],
                      ),
                      false);
                },
                child: HousesWidget(
                  property: null,
                ),
              ),
              HousesWidget(
                property: null,
              )
            ],
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Row(
          children: const [
            Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Self-Contain'),
              ),
            ),
          ],
        ),
        Container(
          height: 210,
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            children: [
              HousesWidget(
                property: null,
              ),
              HousesWidget(
                property: null,
              )
            ],
          ),
        ),
      ],
    );
  }
}
