import 'package:eafind/theme/app_palette.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/filter_result.dart';
import 'package:eafind/widgets/rangeslider_item.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../const/constant.dart';
import '../models/house_type_model.dart';
import '../models/property_model.dart';
import '../models/states_model.dart';
import '../utility/states_data.dart';

class FilterWidget extends StatefulWidget {
  const FilterWidget({Key? key}) : super(key: key);

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
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
  bool isLoading = false;

  filterProperty() async {
    try {
      List<PropertyModel> results = [];
      if (selectedState != 'Choose State' &&
          selectedCity != 'Choose City' &&
          selectedHouseType != 'Property Type' &&
          community.isNotEmpty) {
        setState(() {
          isLoading = true;
        });
        FormData formData = FormData.fromMap({
          'filter': 1,
          'propertyType': selectedHouseType,
          'state': selectedState,
          'city': selectedCity,
          'community': community,
        });
        var response =
            await Dio().post(endPoint('search-property.php'), data: formData);
        if (response.data['status'] == 'Success') {
          for (var data in response.data['data']) {
            PropertyModel p = PropertyModel.fromMap(data);
            results.add(p);
          }
          setState(() {
            searchProperties = results;
            isLoading = false;
          });
          goTo(
              context, FilterResultScreen(properties: searchProperties), false);
        } else {
          debugPrint(response.data.toString());
          setState(() {
            searchProperties = results;
            isLoading = false;
          });
        }
      } else {
        if (selectedState == 'Choose State') {
          showErrorSnackbar('Please Choose State', context);
        } else if (selectedCity == 'Choose City') {
          showErrorSnackbar('Please Choose City', context);
        } else if (selectedHouseType == 'Property Type') {
          showErrorSnackbar('Please Choose Property Type', context);
        } else if (community.isEmpty) {
          showErrorSnackbar('Please Choose Provider Community', context);
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint(e.toString());
    }
  }

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    itemsHouseTypes = houseTypes.map((e) => e.type).toList();
    getStates();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    bool showFab = MediaQuery.of(context).viewInsets.bottom == 0.0;
    return Container(
      height: height(context) / 1.05,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: Scaffold(
        backgroundColor: transparent,
        bottomSheet: showFab
            ? GestureDetector(
                onTap: () => filterProperty(),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: appRadius(10.0), color: context.palette.primaryFill),
                  width: width(context),
                  height: 45,
                  child: Center(
                    child: isLoading
                        ? appSearchLoader(white, 20.0)
                        : Text(
                            'Show Properties',
                            style: TextStyle(color: white),
                          ),
                  ),
                ),
              )
            : null,
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Text('Reset'),
                  ),
                  GestureDetector(
                    onTap: () {
                      goBack(context);
                    },
                    child: Icon(
                      Icons.remove,
                      size: 15,
                      color: context.palette.ink,
                    ),
                  )
                ],
              ),
            ),
            const Text('Property Type'),
            const SizedBox(height: 10),
            roomTypeDropdownWidget(),
            RangeSliderItem(
              title: 'Price Yearly',
              initialMinValue: 2,
              initialMaxValue: 80,
              onMinValueChanged: (v) {},
              onMaxValueChanged: (v) {},
            ),
            const SizedBox(height: 15),
            const Text('Bathrooms'),
            const SizedBox(height: 10),
            Container(
              height: 40,
              child: ListView.builder(
                  itemCount: rooms.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: ((context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedBathrooms = index;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color:
                              selectedBathrooms == index ? context.palette.primaryFill : context.palette.paper,
                          borderRadius: appRadius(10.0),
                          border: Border.all(
                            width: 1,
                            color: grey.withOpacity(.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            rooms[index].toString(),
                            style: TextStyle(
                              color: selectedBathrooms == index ? white : context.palette.ink,
                            ),
                          ),
                        ),
                      ),
                    );
                  })),
            ),
            h10(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7.0),
              child: DropdownButton(
                  alignment: AlignmentDirectional.centerStart,
                  isExpanded: true,
                  hint: Text(selectedState),
                  items: itemsStates,
                  onChanged: (value) {}),
            ),
            selectedState == 'Choose State'
                ? const SizedBox.shrink()
                : const Padding(
                    padding: EdgeInsets.only(left: 8.0, top: 10),
                    child: Text('City'),
                  ),
            selectedState == 'Choose State'
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7.0),
                    child: DropdownButton(
                        alignment: AlignmentDirectional.centerStart,
                        isExpanded: true,
                        hint: Text(selectedCity),
                        items: itemsCities,
                        onChanged: (value) {}),
                  ),
            h10(),
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: formContainer(
                title: 'Community Location Of House',
                context: context,
                child: TextFormField(
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value!.trim().isEmpty) {
                      return 'Community is required';
                    }
                    return null;
                  },
                  onChanged: (newValue) {
                    setState(() {
                      community = newValue;
                    });
                  },
                  decoration: const InputDecoration(
                      label: Text('Enter community'),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(left: 10)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter properties',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => goBack(context),
                        child: const Icon(Icons.close, color: AppColors.textGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedHouseType == 'Property Type'
                              ? null
                              : selectedHouseType,
                          decoration:
                              const InputDecoration(labelText: 'Property type'),
                          hint: const Text('Choose property type'),
                          items: itemsHouseTypes
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => selectedHouseType = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        RangeSliderItem(
                          title: 'Price yearly',
                          initialMinValue: 2,
                          initialMaxValue: 80,
                          onMinValueChanged: (v) {},
                          onMaxValueChanged: (v) {},
                        ),
                        const SizedBox(height: 16),
                        const Text('Bathrooms',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (var i = 0; i < rooms.length; i++)
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedBathrooms = i),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selectedBathrooms == i
                                          ? AppColors.primary
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      rooms[i].toString(),
                                      style: TextStyle(
                                        color: selectedBathrooms == i
                                            ? Colors.white
                                            : AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        WebFormRow(children: [
                          DropdownButtonFormField<String>(
                            value: selectedState == 'Choose State'
                                ? null
                                : selectedState,
                            decoration: const InputDecoration(labelText: 'State'),
                            hint: const Text('Choose state'),
                            items: allStatesAndCities
                                .map((s) => DropdownMenuItem(
                                    value: s.state, child: Text(s.state)))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => selectedState = value);
                              getCities(value);
                            },
                          ),
                          if (selectedState != 'Choose State')
                            DropdownButtonFormField<String>(
                              value: selectedCity == 'Choose City'
                                  ? null
                                  : selectedCity,
                              decoration:
                                  const InputDecoration(labelText: 'City'),
                              hint: const Text('Choose city'),
                              items: itemsCities
                                  .map((item) => DropdownMenuItem(
                                      value: item.value,
                                      child: item.child))
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => selectedCity = value);
                              },
                            ),
                        ]),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Community',
                          hint: 'Enter community',
                          onChanged: (value) =>
                              setState(() => community = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                MiaButton(
                  text: 'Show properties',
                  isEnabled: !isLoading,
                  onPressed: filterProperty,
                  prefix: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget roomTypeDropdownWidget() {
    return SizedBox(
      width: 130,
      height: 45,
      child: Card(
        color: context.palette.paper,
        shape: RoundedRectangleBorder(borderRadius: appRadius(20.0)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton2(
            isExpanded: true,
            hint: Row(
              children: [
                Icon(
                  Icons.list,
                  size: 16,
                  color: context.palette.accent,
                ),
                const SizedBox(
                  width: 4,
                ),
                Expanded(
                  child: Text(
                    selectedHouseType,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.palette.ink,
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.palette.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            // value: selectedHouseType,
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
              maxHeight: 300,
              padding: null,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: context.palette.paper,
              ),
              elevation: 8,
            ),
          ),
        ),
      ),
    );
  }
}
