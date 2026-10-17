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
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:eafind/widgets/percentage_formatter.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../models/house_type_model.dart';
import '../../models/states_model.dart';
import '../../utility/states_data.dart';

import 'package:path_provider/path_provider.dart';

import '../../widgets/currency_formatter.dart';

class UploadProduct extends StatefulWidget {
  const UploadProduct({Key? key}) : super(key: key);

  @override
  State<UploadProduct> createState() => _UploadProductState();
}

class _UploadProductState extends State<UploadProduct> {
  String selectedItemCategory = 'Item Category';
  String selectedState = 'Choose State';
  String selectedCity = 'Choose City';
  List<String> itemProductsCategory = [];
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

  List<String> requirements = ['one', 'two', 'three'];

  pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile> result = await _picker.pickMultiImage(
      imageQuality: 85, // Optional compression
      limit: 5, // Optional cap on selection count
    );

    if (result.isNotEmpty) {
      setState(() {
        images = result.map((e) => File(e.path)).toList();
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
        if (images.isEmpty) {
          showErrorSnackbar(
              'You must upload atleast 1 images And not more that 8 Images of house',
              context);
          setState(() {
            isUploading = false;
          });
        } else if (selectedItemCategory == 'Item Category') {
          showErrorSnackbar('Please Item Type To Proceed', context);
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
        } else if (selectedItemCategory == 'Property Type') {
          showErrorSnackbar('Please Property Type To Proceed', context);
          setState(() {
            isUploading = false;
          });
        } else {
          processAndReturnVideoUrls();
        }
      }
    }
  }

  processAndReturnVideoUrls() async {
    var bStreams = [];
    List<MultipartFile> mFiles = [];
    MultipartFile? emptyMultipart;
    List<dynamic> downloadedImageUrls = [];

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
    final dDirectory = await getApplicationSupportDirectory();

    var imageP = '$dDirectory/images/logo.png';
    File file = File(imageP);

    // List<int> byteData = await XFile(file.path).readAsBytes();
    // String fileName2 = XFile(file.path).name;
    MultipartFile multipartFile = await MultipartFile.fromString(
      imageP,
      filename: 'logo.png',
      contentType: MediaType(
        'image',
        'logo.png',
      ),
    );
    setState(() {
      mFiles.add(multipartFile);
    });

    FormData formData = FormData.fromMap({'files[]': mFiles});
    debugPrint(
        'Checking response is formdata length is ${formData.files.length}');
    try {
      var response = await Dio().post(
        endPoint('upload-images.php'),
        data: formData,
        // options: Options(
        //   contentType: 'application/json',
        //   responseType: ResponseType.plain,
        // )
      );

      if (response.data['status'] == true) {
        setState(() {
          uploadedCount = uploadedCount + 1;
          downloadedImageUrls = response.data['imagePath'];
        });
      }
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

  processAndReturnImageUrls() async {
    var bStreams = [];
    List<MultipartFile> mFiles = [];
    List<dynamic> downloadedImageUrls = [];

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
    var encodeRequirements = json.encode(requirements);
    double newAmount = getRawValue(amount!);
    debugPrint('New amount is $newAmount');

    FormData formData = FormData.fromMap({
      'product_upload': 'true',
      'item_name': title,
      'item_desc': description,
      'category': selectedItemCategory,
      'item_state': userData!.state,
      'amount': getRawValue(amount!),
      'area': community,
      'item_owner_data': json.encode(userData!.toJson()),
      'images': encodeImages,
      'ownerId': userData!.id,
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

    itemProductsCategory = itemTypes;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
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
              _mobileHeader(context),
              Expanded(
                child: busy
                    ? _busyState()
                    : ListView(
                        controller: _controller,
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                        children: [
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Item category',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: context.palette.textDark),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: selectedItemCategory == 'Item Category'
                                      ? null
                                      : selectedItemCategory,
                                  hint: const Text('Choose item category'),
                                  items: itemProductsCategory
                                      .map((item) => DropdownMenuItem(
                                          value: item, child: Text(item)))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => selectedItemCategory = value);
                                    if (value == 'Land') {
                                      goTo(context, const LandUploadScreen(),
                                          false);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Form(
                            key: _formkey,
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTextField(
                                    label: 'Item name',
                                    hint: 'Enter item name',
                                    validator: (value) => value!.trim().isEmpty
                                        ? 'Title is required'
                                        : null,
                                    onSaved: (v) => title = v,
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    label: 'Description',
                                    hint: 'Enter description',
                                    maxLines: 4,
                                    validator: (value) => value!.trim().isEmpty
                                        ? 'Description is required'
                                        : null,
                                    onSaved: (v) => description = v,
                                  ),
                                  const SizedBox(height: 16),
                                  WebFormRow(children: [
                                    AppTextField(
                                      label: 'Amount',
                                      hint: 'Enter amount',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        CurrencyInputFormatter(),
                                      ],
                                      validator: (value) =>
                                          value!.trim().isEmpty
                                              ? 'Amount is required'
                                              : null,
                                      onSaved: (v) => amount = v,
                                    ),
                                    AppTextField(
                                      label: 'Location (area)',
                                      hint: 'Ex: Woji, Rumuodara...',
                                      validator: (value) =>
                                          value!.trim().isEmpty
                                              ? 'Community is required'
                                              : null,
                                      onSaved: (v) => community = v,
                                    ),
                                  ]),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Product images',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: context.palette.textDark),
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: pickImages,
                                    child: Container(
                                      height: 110,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: context.palette.surface,
                                        border:
                                            Border.all(color: context.palette.border),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.upload_file,
                                              color: context.palette.accent),
                                          const SizedBox(height: 6),
                                          Text('Choose images',
                                              style: TextStyle(
                                                  color: context.palette.textDark)),
                                          if (images.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 4),
                                              child: Text(
                                                  '${images.length} selected',
                                                  style: TextStyle(
                                                      color:
                                                          context.palette.textGrey,
                                                      fontSize: 12)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (images.isNotEmpty) ...[
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
                                                        const EdgeInsets.all(2),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.black54,
                                                      shape: BoxShape.circle,
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

  // Black, rounded-bottom header matching the Marketplace tab's own
  // identity (see MarketHome's app bar) so this screen reads as part of
  // that flow rather than a generic upload form.
  Widget _mobileHeader(BuildContext context) {
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
            colors: [Color(0xFF6A3D7A), Color(0xFF3F224F), Color(0xFF1B1020)],
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
                    colors: [Color(0x4DE8A93B), Colors.transparent],
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
                        'MARKETPLACE',
                        style: TextStyle(
                          color: Color(0xFFE8A93B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'New Listing',
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

  // A small "pop in" storefront badge with a sparkle accent - a bit of
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
              color: const Color(0xFFE8A93B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8A93B).withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Color(0xFF241428), size: 20),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1020),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFE8A93B), size: 10),
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
          text: 'Publish to Marketplace',
          prefix: const Icon(Icons.storefront_outlined,
              color: Colors.white, size: 18),
          onPressed: submitUpload,
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: isLoading || isUploading
                    ? AppCard(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            if (isUploading) ...[
                              const SizedBox(height: 16),
                              Text('Please do not leave this screen',
                                  style: TextStyle(color: AppColors.textDark)),
                              const SizedBox(height: 8),
                              Text(
                                'Uploading $uploadedCount/${isVideo == 0 ? images.length : 1}',
                                style: TextStyle(color: AppColors.textGrey),
                              ),
                            ],
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () =>
                                      goTo(context, BottomNavHome(), false),
                                  child: Text('Back',
                                      style:
                                          TextStyle(color: AppColors.textGrey)),
                                ),
                              ),
                              Text(
                                'Upload item',
                                style: TextStyle(
                                  fontFamily: 'Fraunces',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              MiaButton(
                                text: 'Publish',
                                onPressed: submitUpload,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formkey,
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Item category',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: selectedItemCategory ==
                                            'Item Category'
                                        ? null
                                        : selectedItemCategory,
                                    hint: const Text('Choose item category'),
                                    items: itemProductsCategory
                                        .map((item) => DropdownMenuItem(
                                            value: item, child: Text(item)))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(
                                          () => selectedItemCategory = value);
                                      if (value == 'Land') {
                                        goTo(context, const LandUploadScreen(),
                                            false);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    label: 'Item name',
                                    hint: 'Enter item name',
                                    validator: (value) => value!.trim().isEmpty
                                        ? 'Title is required'
                                        : null,
                                    onSaved: (v) => title = v,
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    label: 'Description',
                                    hint: 'Enter description',
                                    maxLines: 4,
                                    validator: (value) => value!.trim().isEmpty
                                        ? 'Description is required'
                                        : null,
                                    onSaved: (v) => description = v,
                                  ),
                                  const SizedBox(height: 16),
                                  WebFormRow(children: [
                                    AppTextField(
                                      label: 'Amount',
                                      hint: 'Enter amount',
                                      keyboardType: TextInputType.number,
                                      validator: (value) =>
                                          value!.trim().isEmpty
                                              ? 'Amount is required'
                                              : null,
                                      onSaved: (v) => amount = v,
                                    ),
                                    AppTextField(
                                      label: 'Location (area)',
                                      hint: 'Ex: Woji, Rumuodara...',
                                      validator: (value) =>
                                          value!.trim().isEmpty
                                              ? 'Community is required'
                                              : null,
                                      onSaved: (v) => community = v,
                                    ),
                                  ]),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Product images',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 10),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: pickImages,
                                      child: Container(
                                        height: 110,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          border: Border.all(
                                              color: AppColors.border),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.upload_file,
                                                color: AppColors.primary),
                                            const SizedBox(height: 6),
                                            Text('Choose images',
                                                style: TextStyle(
                                                    color: AppColors.textDark)),
                                            if (images.isNotEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(top: 4),
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
                                  ),
                                  if (images.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      primary: false,
                                      itemCount: images.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 140,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                        childAspectRatio: 1,
                                      ),
                                      itemBuilder: (context, index) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              // Image.file/dart:io isn't
                                              // supported on web — the
                                              // picked XFile's path is a
                                              // blob: URL there, so
                                              // Image.network renders it.
                                              Image.network(
                                                images[index].path,
                                                fit: BoxFit.cover,
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() =>
                                                        images.removeAt(index));
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(2),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.black54,
                                                      shape: BoxShape.circle,
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
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
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
