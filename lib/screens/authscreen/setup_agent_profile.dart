import 'package:eafind/theme/app_palette.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/services/cloud_storage_service.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/services/fservice.dart';
import 'package:eafind/services/new_auth_service.dart';
import 'package:eafind/services/providers/data_provider.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

import '../../auths/auth_service.dart';
import '../../const/constant.dart';
import '../../models/user_model.dart';
import '../../providers/userId_provider.dart';

class SetupAgentProfile extends StatefulWidget {
  const SetupAgentProfile({Key? key}) : super(key: key);

  @override
  State<SetupAgentProfile> createState() => _SetupAgentProfileState();
}

class _SetupAgentProfileState extends State<SetupAgentProfile> {
  // var userId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = false;
  UserModel? userModel;
  File? profileImage;
  final ImagePicker _picker = ImagePicker();

  getUser() async {
    var userId = Provider.of<UseridProvider>(context, listen: false).userId;
    setState(() {
      isLoading = true;
    });
    UserModel? user = await AuthService.getUserById(userId);
    setState(() {
      userModel = user;
      isLoading = false;
    });
  }

  openCamera(bool gallery) async {
    final XFile? image = await _picker.pickImage(
      source: gallery ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 80, // optional: compress a bit
    );

    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });

      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  pickImage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0))),
          content: SizedBox(
            width: width(context) * .7,
            // height: height(context) * .4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () => openCamera(true),
                      child: Container(
                        width: 150,
                        height: 40,
                        decoration: BoxDecoration(
                            color: context.palette.primaryFill, borderRadius: appRadius(20.0)),
                        child: Center(
                            child: Text(
                          'Open Gallery',
                          style: TextStyle(color: white),
                        )),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () => openCamera(false),
                      child: Container(
                        height: 40,
                        width: 150,
                        decoration: BoxDecoration(
                            color: context.palette.primaryFill, borderRadius: appRadius(20.0)),
                        child: Center(
                            child: Text(
                          'Take Photo',
                          style: TextStyle(
                            color: white,
                          ),
                        )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  uploadPro() async {
    if (profileImage == null) {
      showErrorSnackbar('Please upload a profile image', context);
    } else {
      // var userId = Provider.of<UseridProvider>(context, listen: false).userId;
      setState(() {
        isLoading = true;
      });
      try {
        List<MultipartFile> mFiles = [];
        String fileName = XFile(profileImage!.path).name;
        List<int> byteData = await XFile(profileImage!.path).readAsBytes();
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
        Map<String, dynamic> data = context.read<DataProvider>().getSignupData;
        debugPrint('data $data');
        FormData formData = FormData.fromMap({
          'profileImage': mFiles.first,
          'profile_setup': true,
          'signup_data': data
        });

        // var result = await AuthService().signupUserEndpoint(formData);
        var newResult = await NewAuthService.instance.register(data: formData);
        if (newResult.success) {
          successSnackBar(
            'Profle Successfully Setup, Login To Continue',
            context,
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => const LoginScreen(
                fromNav: false,
              ),
            ),
          );
        } else {
          setState(() {
            isLoading = false;
          });
          successSnackBar(
            newResult.message!,
            context,
          );
        }
      } on DioException catch (e) {
        setState(() {
          isLoading = false;
        });
        debugPrint('error Type ${e.type} and Error ${e.error}');
        showErrorSnackbar(
            '${e.message!} This is the error Type ${e.type}', context);
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        showErrorSnackbar(
            'Ooops something went wrong, please try again', context);
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // getUser();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: grey.withOpacity(.01),
        elevation: 0.0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: StepProgressIndicator(
          totalSteps: 3,
          currentStep: 3,
          selectedColor: context.palette.accent,
        ),
      ),
      bottomSheet: GestureDetector(
        onTap: (() => uploadPro()),
        child: Container(
          height: 45,
          width: width(context),
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration:
              BoxDecoration(color: context.palette.primaryFill, borderRadius: appRadius(10.0)),
          child: Center(
            child: isLoading
                ? LoadingAnimationWidget.fallingDot(color: white, size: 45)
                : Text(
                    'FINISH ',
                    textAlign: TextAlign.center,
                    style: tStyleWhite,
                  ),
          ),
        ),
      ),
      body: isLoading
          ? LoadingAnimationWidget.fallingDot(color: context.palette.accent, size: 50)
          : Consumer<DataProvider>(
              builder: (BuildContext context, data, Widget? child) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          'Congratulations, you are almost done!',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          'Setup Profile',
                          style: tHeading.copyWith(color: context.palette.accent),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: width(context) / 2,
                          alignment: Alignment.center,
                          child: Stack(children: [
                            userProfile(),
                            Positioned(
                              bottom: 10,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => pickImage(),
                                child: Icon(
                                  Icons.edit,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Choose a profile image',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${data.getSignupData['first_name']} ${data.getSignupData['last_name']}',
                              style: TextStyle(fontSize: 18),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  data.getSignupData['user_type'],
                                  style: TextStyle(fontSize: 12, color: grey),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 2.0),
                                  child: Icon(
                                    Icons.no_accounts,
                                    color: context.palette.accent,
                                    size: 15,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      )
                    ]);
              },
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
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      )
                    : Consumer<DataProvider>(
                        builder: (context, data, child) {
                          return AppCard(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 130,
                                  child: StepProgressIndicator(
                                    totalSteps: 3,
                                    currentStep: 3,
                                    selectedColor: AppColors.primary,
                                    unselectedColor: AppColors.border,
                                    roundedEdges: const Radius.circular(6),
                                    size: 6,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  "You're almost done!",
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.textGrey),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Set up your profile',
                                  style: TextStyle(
                                    fontFamily: 'Fraunces',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Stack(
                                  children: [
                                    _webUserProfile(),
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: pickImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.edit,
                                              color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Choose a profile image',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.textGrey),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '${data.getSignupData['first_name']} ${data.getSignupData['last_name']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data.getSignupData['user_type']}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textGrey),
                                ),
                                const SizedBox(height: 28),
                                MiaButton(text: 'Finish', onPressed: uploadPro),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Web-safe preview: Image.file/dart:io reads aren't supported on the
  // web target, so the picked XFile's path (a blob: URL there) is shown
  // via Image.network instead.
  Widget _webUserProfile() {
    return Container(
      height: 110,
      width: 110,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1, color: AppColors.primary),
        borderRadius: BorderRadius.circular(55),
      ),
      child: ClipOval(
        child: profileImage == null
            ? Image.asset(imageRounte(name: 'no-img.png'), fit: BoxFit.cover)
            : Image.network(profileImage!.path, fit: BoxFit.cover),
      ),
    );
  }

  Widget userProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: 100,
            padding: EdgeInsets.all(3.0),
            decoration: BoxDecoration(
                color: context.palette.paper,
                border: Border.all(
                  width: 1.0,
                  color: context.palette.accent,
                ),
                borderRadius: appRadius(50.0)),
            child: ClipOval(
              child: profileImage == null
                  ? Image.asset(
                      imageRounte(name: 'no-img.png'),
                      fit: BoxFit.cover,
                    )
                  : Image.file(File(profileImage!.path)),
            ),
          ),
        ],
      ),
    );
  }
}
