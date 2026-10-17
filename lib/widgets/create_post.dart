import 'package:eafind/theme/app_palette.dart';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/services/providers/tagged_users_provider.dart';
import 'package:eafind/widgets/tag_agent.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/states_model.dart';
import '../models/user_model.dart';
import '../screens/agents/user_account.dart';
import '../utility/states_data.dart';
import 'home_bottom_navbar.dart';

class CreatePostSheet extends StatefulWidget {
  final UserModel user;
  const CreatePostSheet({Key? key, required this.user}) : super(key: key);

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  int colorIndex = 0;
  FocusNode focusNode = FocusNode();
  TextEditingController descriptionController = TextEditingController();
  String taggedUser = 'Anonymous';
  List<DropdownMenuItem<String>> itemsCities = [];
  List<DropdownMenuItem<String>> itemsStates = [];
  String selectedState = 'Choose State';
  String selectedCity = 'Choose City';
  List<UserModel> taggedAgents = [];

  var location;
  bool isUploading = false;

  getCities(String gState) async {
    List<String> lCity = [];
    debugPrint('Just picked is now gstate  $gState');
    StatesModel pickedState =
        allStatesAndCities.firstWhere((element) => element.state == gState);
    debugPrint('Just picked is now $pickedState');

    List<DropdownMenuItem<String>> fCities = [];
    for (var city in pickedState.areas) {
      var data = DropdownMenuItem<String>(
        value: city,
        child: Text(city),
        onTap: () {
          setState(() {
            selectedCity = city;
          });
        },
      );
      fCities.add(data);
    }
    setState(() {
      itemsCities = fCities;
    });
  }

  getStates() async {
    List<DropdownMenuItem<String>> fStates = [];
    for (var state in allStatesAndCities) {
      var data = DropdownMenuItem<String>(
        value: state.state,
        child: Text(state.state),
        onTap: () {
          setState(() {
            selectedState = state.state;
          });
          getCities(selectedState);
        },
      );
      fStates.add(data);
    }
    setState(() {
      itemsStates = fStates;
    });
  }

  submitUpload() async {
    if (descriptionController.text.isEmpty) {
      showErrorSnackbar('Please provide post description', context);
    } else {
      setState(() {
        isUploading = true;
      });
      List emptyImages = [];
      List emtpyRequirements = [];
      var encodeImages = json.encode(emptyImages);
      var encodeRequirements = json.encode(emtpyRequirements);
      FormData formData = FormData.fromMap({
        'title': 'title',
        'description': descriptionController.text,
        'category': 'selectedHouseType',
        'ownerId': widget.user.id,
        'location': selectedState,
        'amount': int.parse('200'),
        'userType': widget.user.userType,
        'rooms': 1,
        'imageUrls': encodeImages,
        'bathrooms': 1,
        'requirements': encodeRequirements,
        'userName': widget.user.firstName,
        'community': widget.user.city,
        'color_code': colorIndex,
        'tagged_userId': taggedUser,
        'is_house': 0,
        'property_plot': 0,
        'hCity': selectedCity,
        'cautionFee': 0,
        'legalFee': 0,
        'agentFee': 0,
        'isVideo': false
      });
      try {
        var response =
            await Dio().post(endPoint('upload-house.php'), data: formData);

        debugPrint('Checking response is ${response}');
        setState(() {
          isUploading = false;
          descriptionController.clear();
        });
        successSnackBar('Property Successfully Added', context);
        goTo(context, BottomNavHome(), false);
      } on DioException catch (e) {
        String message = '';
        setState(() {
          isUploading = false;
        });
        if (e.message!.contains('The connection errored')) {
          setState(() {
            message =
                'Network Error: Please ensure you have a good internet connection and retry';
          });
        } else {
          setState(() {
            message = e.message.toString();
          });
        }
        showErrorSnackbar(message, context);
      } on SocketException catch (_) {
        setState(() {
          isUploading = false;
        });

        showErrorSnackbar(
            'Network Error: Please ensure you have a good internet connection and retry',
            context);
      } catch (e) {
        debugPrint(e.toString());
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      selectedState = widget.user.state;
      selectedCity = widget.user.city;
    });
    getStates();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    List<UserModel> tgAgents =
        Provider.of<TaggedAgentsProvider>(context).getTaggedAgents();
    if (tgAgents.isNotEmpty) {
      setState(() {
        taggedAgents = tgAgents;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () {
          focusNode.unfocus();
        },
        child: Scaffold(
          backgroundColor: context.palette.paper,
          appBar: AppBar(
            elevation: 1.0,
            backgroundColor: context.palette.paper,
            leading: GestureDetector(
              onTap: () => goTo(context, BottomNavHome(), false),
              child: Icon(
                Icons.arrow_back_ios,
                color: context.palette.ink,
              ),
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: GestureDetector(
                    onTap: () {
                      if (descriptionController.text.isNotEmpty) {
                        submitUpload();
                      } else {
                        showErrorSnackbar(
                            'Post Description Is Required', context);
                      }
                    },
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: isUploading
                              ? appSearchLoader(context.palette.accent, 25.0)
                              : Text(
                                  'Post Now',
                                  style: TextStyle(
                                      color: descriptionController.text.isEmpty
                                          ? grey
                                          : context.palette.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => goTo(
                            context,
                            UserAccount(
                              userId: widget.user.id,
                            ),
                            false),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              child: ClipOval(
                                child: Image.asset(
                                  imageRounte(name: avatarImage),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.user.userName,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 10,
                                        color: grey,
                                      ),
                                      Text(
                                        widget.user.city,
                                        style: TextStyle(
                                          color: grey,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color: grey.withOpacity(.3),
                        ),
                        borderRadius: appRadius(5.0),
                        color: postColors[colorIndex]),
                    child: TextField(
                      focusNode: focusNode,
                      minLines: null,
                      maxLines: null,
                      expands: true,
                      controller: descriptionController,
                      style: TextStyle(
                        color: getTextColor(colorIndex),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                          hintText:
                              'Connect With Agents about your property requirements.....',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: getTextColor(colorIndex),
                            overflow: TextOverflow.visible,
                          ),
                          contentPadding: const EdgeInsets.all(15)),
                    ),
                  ),
                ),
                h10(),
                Container(
                  height: 50,
                  child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: postColors.length,
                      itemBuilder: (ctx, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              colorIndex = index;
                            });
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: appRadius(8.0)),
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                  color: postColors[index],
                                  border: Border.all(
                                    color: context.palette.paper,
                                  ),
                                  borderRadius: appRadius(8.0)),
                            ),
                          ),
                        );
                      }),
                ),
                Divider(
                  color: grey,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: GestureDetector(
                    onTap: () => goTo(context, TagAgentWidget(), false),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_add,
                              color: context.palette.accent,
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Tag an agent',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        taggedAgents.isEmpty
                            ? const SizedBox.shrink()
                            : Row(
                                children: [
                                  Text(
                                    '${taggedAgents.length} ',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: context.palette.ink,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    taggedAgents.length > 1
                                        ? 'Agents Tagged'
                                        : 'Agent Tagged',
                                    style: TextStyle(fontSize: 10, color: grey),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Icon(
                                      Icons.person_add,
                                      color: context.palette.accent,
                                      size: 15,
                                    ),
                                  ),
                                ],
                              )
                      ],
                    ),
                  ),
                ),
                Divider(
                  color: grey,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: context.palette.accent,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7.0),
                          child: DropdownButton(
                              alignment: AlignmentDirectional.centerStart,
                              isExpanded: true,
                              hint: Text(selectedState),
                              items: itemsStates,
                              onChanged: (value) {}),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: grey,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_city,
                        color: context.palette.accent,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7.0),
                          child: DropdownButton(
                              alignment: AlignmentDirectional.centerStart,
                              isExpanded: true,
                              hint: Text(selectedCity),
                              items: itemsCities,
                              onChanged: (value) {}),
                        ),
                      ),
                    ],
                  ),
                ),
                h10(),
                Divider(
                  color: grey,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: GestureDetector(
                    onTap: () => successSnackBar('Comming Soon', context),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_clock,
                          color: context.palette.accent,
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Schedule Post',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  color: grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
