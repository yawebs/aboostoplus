import 'package:eafind/theme/app_palette.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../const/constant.dart';
import '../models/property_model.dart';
import '../models/states_model.dart';
import '../utility/states_data.dart';

class EasyAccessWidget extends StatefulWidget {
  const EasyAccessWidget({Key? key}) : super(key: key);

  @override
  State<EasyAccessWidget> createState() => _EasyAccessWidgetState();
}

class _EasyAccessWidgetState extends State<EasyAccessWidget> {
  String selectedState = 'Choose State';
  String selectedCity = 'Choose City';
  List<String> itemsHouseTypes = [];
  String selectedHouseType = 'Property Type';
  List states = [];
  List cities = [];
  String community = '';
  List<PropertyModel> searchProperties = [];
  List<DropdownMenuItem<String>> itemsStates = [];
  List<DropdownMenuItem<String>> itemsCities = [];
  int selectedBathrooms = 1;
  List<int> rooms = [1, 2, 3, 4, 5];
  bool hideState = false;
  bool isLoading = false;

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
            hideState = true;
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getStates();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
          color: HexColor('#E6E6FA'),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10.0),
          )),
      width: width(context),
      height: height(context) / 1.5,
      child: ListView(
        shrinkWrap: true,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => goBack(context),
                child: Icon(
                  Icons.cancel,
                  color: red,
                ),
              ),
            ),
          ),
          h10(),
          Center(
            child: Image.asset(
              imageRounte(name: 'hamster.png'),
              width: 100,
            ),
          ),
          Center(
            child: Text(
              'Hello Chris',
              style: tHeading.copyWith(color: context.palette.accent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'For a smooth EXPERIENCE kindly answer the following questions',
              textAlign: TextAlign.center,
            ),
          ),
          Divider(
            color: lightGrey,
          ),
          h10(),
          hideState == false
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInLeft(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                'Which state do you need this property?',
                                style: TextStyle(color: grey),
                              ),
                            ),
                            h10(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 7.0),
                              child: DropdownButton(
                                  alignment: AlignmentDirectional.centerStart,
                                  isExpanded: true,
                                  hint: Text(selectedState),
                                  items: itemsStates,
                                  onChanged: (value) {}),
                            ),
                          ],
                        ),
                      ),
                      selectedState == 'Choose State'
                          ? const SizedBox.shrink()
                          : FadeInRight(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(left: 8.0, top: 10),
                                    child: Text('City'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7.0),
                                    child: DropdownButton(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        isExpanded: true,
                                        hint: Text(selectedCity),
                                        items: itemsCities,
                                        onChanged: (value) {}),
                                  ),
                                ],
                              ),
                            )
                    ],
                  ),
                )
              : SizedBox.shrink(),
          hideState
              ? FadeInLeft(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        bottom: 80, left: 10, right: 10, top: 10),
                    child: formContainer(
                      title:
                          'Which Area in $selectedCity do you need this property?',
                      context: context,
                      child: TextFormField(
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value!.trim().isEmpty) {
                            return 'Area is required';
                          }
                          return null;
                        },
                        onChanged: (newValue) {
                          setState(() {
                            community = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                            label: Text('Enter area'),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 10)),
                      ),
                    ),
                  ),
                )
              : SizedBox.shrink(),
          community.isNotEmpty
              ? FadeInRight(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        isLoading = true;
                      });
                      SharedPreferences sharedPreferences =
                          await SharedPreferences.getInstance();
                      List<String> settings = [];
                      settings.add(selectedState);
                      settings.add(selectedCity);
                      settings.add(community);
                      sharedPreferences.setStringList('userFilter', settings);

                      goBack(context);
                    },
                    child: Container(
                      width: width(context),
                      margin:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      height: 45,
                      decoration: BoxDecoration(
                        color: context.palette.primaryFill,
                        borderRadius: appRadius(10.0),
                      ),
                      child: Center(
                        child: isLoading
                            ? CircularProgressIndicator(
                                color: white,
                              )
                            : Text(
                                'Save Settings',
                                style: tStyleWhite,
                              ),
                      ),
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
