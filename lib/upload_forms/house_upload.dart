import 'package:eafind/theme/app_palette.dart';
import 'dart:convert';
import 'dart:io';
// import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/upload_forms/land_upload.dart';
import 'package:eafind/utility/custom_toast.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:eafind/widgets/percentage_formatter.dart';
import 'package:eafind/widgets/property_type_picker.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../models/house_type_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/states_model.dart';
import '../utility/states_data.dart';
import '../widgets/currency_formatter.dart';

// Top-level function
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     switch (task) {
//       case 'uploadImage':
//         await uploadImage(inputData!['filePath'], inputData['url']);
//         return true;
//       default:
//         return false;
//     }
//   });
// }

class HouseUploadScreen extends StatefulWidget {
  const HouseUploadScreen({Key? key}) : super(key: key);

  @override
  State<HouseUploadScreen> createState() => _HouseUploadScreenState();
}

class _HouseUploadScreenState extends State<HouseUploadScreen> {
  String selectedHouseType = 'Property Type';
  String selectedState = 'Choose State';
  String selectedCity = 'Choose City';
  List<String> itemsHouseTypes = [];
  List<DropdownMenuItem<String>> itemsStates = [];
  bool isFrontView = false;
  bool isPalour = false;
  bool isKitchen = false;
  bool isLoading = false;
  var _formkey = GlobalKey<FormState>();
  List<File> images = [];

  String? title, description, community, state, amount;
  int? rooms, bathrooms;
  String caustionFee = '0';
  String legalFee = '0';
  String agentFee = '%0';
  int isVideo = 0;

  List<File> videoFile = [];
  var authUser = FirebaseAuth.instance.currentUser;
  ScrollController _controller = ScrollController();

  List<DropdownMenuItem<String>> itemsCities = [];

  UserModel? userData;
  int uploadedCount = 0;
  bool isUploading = false;
  bool imageUploadError = false;
  setIndex(category) {
    int index = 1;
    switch (category) {
      case 'Land':
        index = 3;
        break;
      case 'Property Sales':
        index = 3;
        break;
      case 'Office Space':
        index = 3;
        break;
      case 'Hall':
        index = 3;
        break;
      // Kept out of the main houses feed (which only shows is_house = 1);
      // service apartments get their own section on the home screen.
      case kServiceApartment:
        index = 3;
        break;
      default:
        index = 1;
        break;
    }
    return index;
  }

  List<String> requirements = ['one', 'two', 'three'];
  final Set<String> selectedAmenities = {};
  bool get isServiceApartment => selectedHouseType == kServiceApartment;
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

  pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile> result = await _picker.pickMultiImage(
      imageQuality: 85, // Optional compression
      limit: 5, // Optional cap on selection count
    );

    if (result.isNotEmpty) {
      if (result.length < 4) {
        CustomToast.show(context,
            title: 'Error', message: 'Please select atleast for images');
      }
      setState(() {
        images = result.map((e) => File(e.path)).toList();
      });
    }
  }

  List<XFile> filterAndCheckVideos(List<XFile> files) {
    // Define common video extensions
    final videoExtensions = {'.mp4', '.mov', '.avi', '.mkv', '.flv', '.wmv'};

    // Separate videos from images
    final List<XFile> videoFiles = [];
    final List<XFile> imageFiles = [];

    for (var file in files) {
      // Extract extension in lowercase (e.g., '.mp4')
      final ext = p.extension(file.path).toLowerCase();

      if (videoExtensions.contains(ext)) {
        videoFiles.add(file);
      } else {
        imageFiles.add(file);
      }
    }

    // Print summary to console
    print('Found ${videoFiles.length} videos and ${imageFiles.length} images.');

    return videoFiles;
  }

  pickVideo() async {
    List<XFile> videosInit = [];
    final ImagePicker _picker = ImagePicker();
    var result = await _picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (result != null) {
      debugPrint('Vido file picked');
      videosInit.add(result);
      setState(() {
        videoFile =
            filterAndCheckVideos(videosInit).map((e) => File(e.path)).toList();
      });
    }
  }

  getUser() async {
    UserModel? tUser = context.read<UsermodelProvider>().getUserModel();
    setState(() {
      userData = tUser;
    });
  }

  submitUpload() async {
    if (_formkey.currentState!.validate()) {
      setState(() {
        isUploading = true;
      });
      _formkey.currentState!.save();
      if (isVideo == 0) {
        if (images.isEmpty || images.length < 4 || images.length > 8) {
          showErrorSnackbar(
              'You must upload atleast 4 images And not more that 8 Images of house',
              context);
          setState(() {
            isUploading = false;
          });
        } else if (selectedState == 'Choose State') {
          showErrorSnackbar('Please choose state to proceed', context);
          setState(() {
            isUploading = false;
          });
        } else if (selectedCity == 'Choose City') {
          showErrorSnackbar('Please choose City to proceed', context);
          setState(() {
            isUploading = false;
          });
        } else if (selectedHouseType == 'Property Type') {
          showErrorSnackbar('Please Property Type To Proceed', context);
          setState(() {
            isUploading = false;
          });
        } else {
          processAndReturnImageUrls();
        }
      } else {
        if (videoFile.isEmpty) {
          showErrorSnackbar(
              'You are required to upload one video file', context);
          setState(() {
            isUploading = false;
          });
        } else if (selectedState == 'Choose State') {
          showErrorSnackbar('Please choose state to proceed', context);
          setState(() {
            isUploading = false;
          });
        } else if (selectedCity == 'Choose City') {
          showErrorSnackbar('Please choose City to proceed', context);
          setState(() {
            isUploading = false;
          });
        } else if (selectedHouseType == 'Property Type') {
          showErrorSnackbar('Please Property Type To Proceed', context);
          setState(() {
            isUploading = false;
          });
        } else {
          processAndReturnImageUrls();
        }
      }
    }
  }

  processAndReturnImageUrls() async {
    var bStreams = [];
    List<MultipartFile> mFiles = [];
    List<dynamic> downloadedImageUrls = [];

    if (isVideo == 0) {
      for (var img in images) {
        List<int> byteData = await XFile(img.path).readAsBytes();
        String fileName = XFile(img.path).name;
        MultipartFile multipartFile = await MultipartFile.fromBytes(
          byteData,
          filename: fileName,
          contentType: MediaType(
            'image',
            fileName,
          ),
        );
        setState(() {
          mFiles.add(multipartFile);
        });
      }
    } else {
      for (var img in videoFile) {
        List<int> byteData = await XFile(img.path).readAsBytes();
        String fileName = XFile(img.path).name;
        MultipartFile multipartFile = await MultipartFile.fromBytes(
          byteData,
          filename: fileName,
          contentType: MediaType(
            'image',
            fileName,
          ),
        );
        setState(() {
          mFiles.add(multipartFile);
        });
      }
    }

    FormData formData =
        FormData.fromMap({'files[]': mFiles, 'upload_images': true});
    debugPrint(
        'Checking response is formdata length is ${formData.files.length}');
    try {
      var response =
          await Dio().post(endPoint('upload-images.php'), data: formData);

      debugPrint('Checking response is ${response}');
      if (response.data['status'] == true) {
        setState(() {
          uploadedCount = uploadedCount + 1;
          downloadedImageUrls = response.data['imagePath'];
        });
      }

      debugPrint(
          'Downloaded mFileNames count Url is ${response.data['mFileNames']}');
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        imageUploadError = true;
      });
    }

    if (imageUploadError == false) {
      await sendDataToDb(downloadedImageUrls);
    } else {
      setState(() {
        isLoading = false;
        isUploading = false;
      });
      showErrorSnackbar(
          'oops unable to Upload images, please try again', context);
    }
  }

  int getRawPercentage(String value) {
    // Removes the % sign so you can use the number for calculations
    return int.tryParse(value.replaceAll('%', '')) ?? 0;
  }

  double getRawValue(String formattedString) {
    // Removes everything except numbers and the decimal point
    String cleaned = formattedString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  sendDataToDb(downloadedImageUrls) async {
    var encodeImages = json.encode(downloadedImageUrls);
    var encodeRequirements = json
        .encode(isServiceApartment ? selectedAmenities.toList() : requirements);
    double newAmount = getRawValue(amount!);
    debugPrint('New amount is $newAmount');

    FormData formData = FormData.fromMap({
      'upload_house': true,
      'title': title,
      'description': description,
      'category': selectedHouseType,
      'ownerId': userData!.id,
      'location': selectedState,
      'amount': getRawValue(amount!),
      'userType': userData!.userType,
      'rooms': rooms,
      'imageUrls': encodeImages,
      'bathrooms': bathrooms,
      'requirements': encodeRequirements,
      'userName': userData!.firstName,
      'community': community,
      'color_code': 0,
      'tagged_userId': '',
      'is_house': setIndex(selectedHouseType),
      'property_plot': 0,
      'hCity': selectedCity,
      'cautionFee': getRawValue(caustionFee),
      'legalFee': getRawValue(legalFee),
      'agentFee': getRawPercentage(agentFee),
      'isVideo': isVideo,
      'propertyOwnerData': json.encode(userData!.toJson())
    });
    try {
      var response =
          await Dio().post(endPoint('upload-house.php'), data: formData);

      debugPrint('Checking response is ${response}');
      setState(() {
        isUploading = false;
        uploadedCount = 0;
        images = [];
      });
      successSnackBar('Property Successfully Added', context);
      goTo(context, const BottomNavHome(), false);
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
    getStates();
    itemsHouseTypes = houseTypes.map((e) => e.type).toList();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = isLoading || isUploading;

    return Theme(
      data: AppTheme.of(context),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: context.palette.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: busy
                    ? _busyState()
                    : ListView(
                        controller: _controller,
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                        children: [
                          AppCard(
                            child: PropertyTypeField(
                              value: selectedHouseType == 'Property Type'
                                  ? null
                                  : selectedHouseType,
                              types: itemsHouseTypes,
                              onChanged: (value) {
                                // Land has its own sale form; leave this
                                // form's choice as it was for when they
                                // come back.
                                if (value == 'Land') {
                                  goTo(context, const LandUploadScreen(),
                                      false);
                                  return;
                                }
                                setState(() => selectedHouseType = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Form(
                            key: _formkey,
                            child: Column(
                              children: [
                                AppCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppTextField(
                                        label: 'Title',
                                        hint: 'Enter title',
                                        validator: (value) =>
                                            value!.trim().isEmpty
                                                ? 'Title is required'
                                                : null,
                                        onSaved: (v) => title = v,
                                      ),
                                      const SizedBox(height: 16),
                                      AppTextField(
                                        label: 'Description',
                                        hint: 'Enter description',
                                        maxLines: 4,
                                        validator: (value) =>
                                            value!.trim().isEmpty
                                                ? 'Description is required'
                                                : null,
                                        onSaved: (v) => description = v,
                                      ),
                                      const SizedBox(height: 16),
                                      WebFormRow(children: [
                                        AppTextField(
                                          label: isServiceApartment
                                              ? 'Bedrooms (0 for studio)'
                                              : 'Bedrooms',
                                          hint: 'Enter rooms',
                                          keyboardType: TextInputType.number,
                                          validator: (value) =>
                                              value!.trim().isEmpty
                                                  ? 'Rooms is required'
                                                  : null,
                                          onSaved: (v) => rooms = int.parse(v!),
                                        ),
                                        AppTextField(
                                          label: 'Bathrooms',
                                          hint: 'Enter bathrooms',
                                          keyboardType: TextInputType.number,
                                          validator: (value) =>
                                              value!.trim().isEmpty
                                                  ? 'Bathrooms is required'
                                                  : null,
                                          onSaved: (v) =>
                                              bathrooms = int.parse(v!),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                                if (isServiceApartment) ...[
                                  const SizedBox(height: 16),
                                  _amenitiesCard(),
                                ],
                                const SizedBox(height: 16),
                                AppCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pricing',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: context.palette.textDark),
                                      ),
                                      const SizedBox(height: 12),
                                      AppTextField(
                                        label: isServiceApartment
                                            ? 'Price per night'
                                            : 'Amount',
                                        hint: isServiceApartment
                                            ? 'Enter nightly rate'
                                            : 'Enter amount',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          CurrencyInputFormatter(),
                                        ],
                                        validator: (value) =>
                                            value!.trim().isEmpty
                                                ? 'Amount is required'
                                                : null,
                                        onSaved: (v) => amount = v,
                                      ),
                                      const SizedBox(height: 16),
                                      WebFormRow(children: [
                                        AppTextField(
                                          label: 'Caution fee',
                                          hint: '0 if none',
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            CurrencyInputFormatter(),
                                          ],
                                          validator: (value) =>
                                              value!.trim().isEmpty
                                                  ? 'Caution fee is required'
                                                  : null,
                                          onSaved: (v) => caustionFee = v!,
                                        ),
                                        AppTextField(
                                          label: 'Legal fee',
                                          hint: '0 if none',
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            CurrencyInputFormatter(),
                                          ],
                                          validator: (value) =>
                                              value!.trim().isEmpty
                                                  ? 'Legal fee is required'
                                                  : null,
                                          onSaved: (v) => legalFee = v!,
                                        ),
                                      ]),
                                      const SizedBox(height: 16),
                                      AppTextField(
                                        label: 'Agent fee (%)',
                                        hint: '0 if none',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          PercentageInputFormatter(),
                                        ],
                                        validator: (value) =>
                                            value!.trim().isEmpty
                                                ? 'Agent fee is required'
                                                : null,
                                        onSaved: (v) => agentFee = v!,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Location',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: context.palette.textDark),
                                      ),
                                      const SizedBox(height: 12),
                                      _plainDropdownField(
                                        label: 'State',
                                        hintText: selectedState,
                                        items: itemsStates,
                                        onChanged: (_) {},
                                      ),
                                      if (selectedState != 'Choose State') ...[
                                        const SizedBox(height: 16),
                                        _plainDropdownField(
                                          label: 'City',
                                          hintText: selectedCity,
                                          items: itemsCities,
                                          onChanged: (_) {},
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      AppTextField(
                                        label: 'Community / area',
                                        hint: 'Enter community',
                                        validator: (value) =>
                                            value!.trim().isEmpty
                                                ? 'Community is required'
                                                : null,
                                        onSaved: (v) => community = v,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Photos or video',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: context.palette.textDark),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Select a minimum of 4 images, or upload one video.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: context.palette.textGrey),
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ToggleSwitch(
                                          minWidth: 80.0,
                                          cornerRadius: 20.0,
                                          activeBgColors: [
                                            [AppColors.primary],
                                            [AppColors.primary]
                                          ],
                                          activeFgColor: Colors.white,
                                          inactiveBgColor: context.palette.border,
                                          inactiveFgColor: context.palette.textGrey,
                                          initialLabelIndex: isVideo,
                                          totalSwitches: 2,
                                          labels: const ['Images', 'Video'],
                                          radiusStyle: true,
                                          onToggle: (index) =>
                                              setState(() => isVideo = index!),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: isVideo == 1
                                            ? pickVideo
                                            : pickImages,
                                        child: Container(
                                          height: 110,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: context.palette.surface,
                                            border: Border.all(
                                                color: context.palette.border),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.upload_file,
                                                  color: context.palette.accent),
                                              const SizedBox(height: 6),
                                              Text(
                                                  isVideo == 1
                                                      ? 'Choose video'
                                                      : 'Choose images',
                                                  style: TextStyle(
                                                      color:
                                                          context.palette.textDark)),
                                              if (isVideo == 1 &&
                                                  videoFile.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: Text(
                                                      '${videoFile.length} video selected',
                                                      style: const TextStyle(
                                                          color: AppColors
                                                              .textGrey,
                                                          fontSize: 12)),
                                                ),
                                              if (isVideo == 0 &&
                                                  images.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: Text(
                                                      '${images.length} selected',
                                                      style: const TextStyle(
                                                          color: AppColors
                                                              .textGrey,
                                                          fontSize: 12)),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isVideo == 0 &&
                                          images.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        GridView.builder(
                                          shrinkWrap: true,
                                          primary: false,
                                          itemCount: images.length,
                                          gridDelegate:
                                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 110,
                                            mainAxisSpacing: 8,
                                            crossAxisSpacing: 8,
                                            childAspectRatio: 1,
                                          ),
                                          itemBuilder: (context, index) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.file(
                                                    File(images[index].path),
                                                    fit: BoxFit.cover,
                                                  ),
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() => images
                                                            .removeAt(index));
                                                        successSnackBar(
                                                            'Image removed',
                                                            context);
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(2),
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.black54,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                            Icons.close,
                                                            color: Colors.white,
                                                            size: 14),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: busy ? null : _publishBar(),
      ),
    );
  }

  Widget _amenitiesCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'What do guests get with this service apartment?',
            style: TextStyle(fontSize: 12, color: context.palette.textGrey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: serviceApartmentAmenities.map((amenity) {
              final selected = selectedAmenities.contains(amenity);
              return FilterChip(
                label: Text(amenity),
                selected: selected,
                showCheckmark: false,
                selectedColor: context.palette.accent,
                backgroundColor: context.palette.surface,
                side: BorderSide(
                    color: selected ? context.palette.accent : context.palette.border),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : context.palette.textDark,
                ),
                onSelected: (value) => setState(() {
                  value
                      ? selectedAmenities.add(amenity)
                      : selectedAmenities.remove(amenity);
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Black, rounded-bottom header - mirrors the marketplace upload screen's
  // header shape so both "list something" flows feel like the same
  // product, but branded for Properties so it's unmistakable which
  // listing type this form creates.
  Widget _header(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 14, 20, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFC45A06), Color(0xFF161616), Color(0xFF0A0A0A)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Ambient glow so the gradient doesn't read flat - matches the
            // dashboards' hero treatment for a consistent "brand energy".
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 170,
                height: 170,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x4DF7821B), Colors.transparent],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (isUploading != true) {
                      goTo(context, BottomNavHome(), false);
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PROPERTIES',
                        style: TextStyle(
                          color: Color(0xFFF7821B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'List a Property',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Fraunces',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _headerBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // A small "pop in" property badge with a sparkle accent - a bit of
  // playful motion on entry instead of a static flat bar.
  Widget _headerBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.rotate(
            angle: (1 - value) * -0.5,
            child: child,
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF7821B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF7821B).withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.villa_rounded,
                color: Color(0xFF1a1a1a), size: 20),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFF7821B), size: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _busyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: AppCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: context.palette.accent),
              if (isUploading) ...[
                const SizedBox(height: 16),
                Text('Please do not leave this screen',
                    style: TextStyle(
                        color: context.palette.textDark,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'Uploading $uploadedCount/${isVideo == 0 ? images.length : 1}',
                  style: TextStyle(color: context.palette.textGrey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _publishBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        child: MiaButton(
          text: 'List Property',
          prefix: const Icon(Icons.home_work_outlined,
              color: Colors.white, size: 18),
          onPressed: submitUpload,
        ),
      ),
    );
  }

  // A plain (non-FormField) dropdown restyled to match AppTextField's
  // filled/rounded look - state/city selection here happens via each
  // DropdownMenuItem's own onTap (built in getStates()/getCities()), not
  // via this onChanged, so that wiring is left untouched.
  Widget _plainDropdownField({
    required String label,
    required String hintText,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.palette.textDark),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              alignment: AlignmentDirectional.centerStart,
              hint:
                  Text(hintText, style: TextStyle(color: context.palette.textLight)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget loaderWidget() {
    return Container(
      height: height(context) / 2,
      width: width(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LoadingAnimationWidget.progressiveDots(color: context.palette.accent, size: 30),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Uploading 1/5 Images',
              style: TextStyle(color: context.palette.accent),
            ),
          )
        ],
      ),
    );
  }
}
