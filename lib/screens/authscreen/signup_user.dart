import 'package:eafind/theme/app_palette.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/utility/custom_toast.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shortid/shortid.dart';

import 'package:step_progress_indicator/step_progress_indicator.dart';
import '../../auths/auth_service.dart';
import '../../const/constant.dart';
import '../../models/states_model.dart';
import '../../services/new_auth_service.dart';
import '../../services/push_notification_service.dart';
import '../../utility/states_data.dart';
import '../../widgets/social_sign_in_buttons.dart';

class SignupUser extends StatefulWidget {
  const SignupUser({Key? key}) : super(key: key);

  @override
  State<SignupUser> createState() => _SignupUserState();
}

class _SignupUserState extends State<SignupUser> {
  String? firstName, lastName, email, state, city, pwd, phone;
  bool showPassword = true;
  List<String> states = [];
  List<dynamic> cities = [];
  String selectedState = 'State';
  String selectedCity = 'Choose City';
  var _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  // True while a Google/Apple sign-up is running, so the form waits.
  bool _socialBusy = false;

  getStates() async {
    List<String> allStates = [];
    for (var state in allStatesAndCities) {
      allStates.add(state.state);
    }
    setState(() {
      states = allStates;
    });
  }

  getCities(String gState) async {
    List<String> lCity = [];
    debugPrint('Just picked is now gstate  $gState');
    StatesModel pickedState =
        allStatesAndCities.firstWhere((element) => element.state == gState);
    debugPrint('Just picked is now $pickedState');

    setState(() {
      cities = pickedState.areas;
    });
    debugPrint('Fetchted cities');
  }

  submitForm() async {
    if (selectedState == 'State') {
      showErrorSnackbar('Choose State', context);
    } else if (selectedCity == 'Choose City') {
      showErrorSnackbar('Choose City', context);
    } else {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
          _formKey.currentState!.save();
        });

        try {
          String? deviceId = await PushNotificationService.getDeviceToken();
          Map<String, dynamic> data = {
            'auth_user': 'Agent',
            'first_name': firstName,
            'last_name': lastName,
            'password': pwd,
            'email': email,
            'lead_uid': '',
            'unique_id': shortid.generate(),
            'phone': phone,
            'address': '',
            'state': selectedState,
            'city': selectedCity,
            'user_type': 'User',
            'notification_id': deviceId ?? '',
          };
          FormData formData =
              FormData.fromMap({'profile_setup': true, 'signup_data': data});
          var newResult =
              await NewAuthService.instance.register(data: formData);
          if (newResult.success == false) {
            setState(() {
              _isLoading = false;
            });
            CustomToast.show(context,
                title: 'Error',
                message: newResult.message!,
                type: ToastType.error);
          } else {
            CustomToast.show(context,
                title: 'Success',
                message: 'Signup Successful, Please login to continue',
                type: ToastType.success);

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (ctx) => LoginScreen(
                  fromNav: false,
                ),
              ),
            );
          }
        } on DioException catch (e) {
          setState(() {
            _isLoading = false;
          });
          CustomToast.show(context,
              title: 'Error',
              message: e.message ??
                  'Unable to create an account now, please try again later',
              type: ToastType.error);
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          CustomToast.show(context,
              title: 'Error',
              message: 'Unable to create account please try again',
              type: ToastType.error);
        }
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getStates();
  }

  // Same section header treatment used on the agent signup screen, for
  // visual consistency across the auth flow.
  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.palette.primaryFill.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: context.palette.accent),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.palette.inkSoft,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Card wrapper replacing the bare `formWrapperContainer`, so each
  // group of fields reads as one grouped, shadowed surface.
  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.paper,
        borderRadius: appRadius(16.0),
        border: Border.all(color: grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    final bool showFab = MediaQuery.of(context).viewInsets.bottom == 0.0;
    return Scaffold(
      backgroundColor: context.palette.page,
      bottomSheet: showFab
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: GestureDetector(
                onTap: _isLoading || _socialBusy
                    ? null
                    : () {
                        submitForm();
                      },
                child: Container(
                  height: 52,
                  width: width(context),
                  decoration: BoxDecoration(
                    color: context.palette.primaryFill,
                    borderRadius: appRadius(14.0),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? appLoader(28.0)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Create Account',
                                textAlign: TextAlign.center,
                                style: tStyleWhite.copyWith(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 16),
                            ],
                          ),
                  ),
                ),
              ),
            )
          : null,
      appBar: AppBar(
        backgroundColor: context.palette.page,
        elevation: 0.0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: StepProgressIndicator(
            totalSteps: 3,
            currentStep: 2,
            selectedColor: context.palette.accent,
            unselectedColor: grey.withOpacity(0.25),
            roundedEdges: const Radius.circular(6),
            size: 6,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: ListView(shrinkWrap: true, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              'Create User Account',
              style: tHeading.copyWith(color: context.palette.accent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 16),
            child: Text(
              'Step 2 of 3 — tell us a bit about yourself',
              style: TextStyle(color: grey, fontSize: 13.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SocialSignInButtons(
              dividerText: 'or fill in your details',
              dividerOnTop: false,
              disabled: _isLoading,
              onBusyChanged: (busy) => setState(() => _socialBusy = busy),
            ),
          ),
          Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(Icons.person_outline, 'Personal Info'),
                    _sectionCard(
                      child: Column(
                        children: [
                          formContainer(
                            title: 'First Name',
                            context: context,
                            child: TextFormField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10),
                                label: Text('Enter first name'),
                              ),
                              validator: (value) {
                                if (value!.trim().isEmpty) {
                                  return 'First name is required';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                setState(() {
                                  firstName = newValue;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          formContainer(
                            title: 'Last Name',
                            context: context,
                            child: TextFormField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10),
                                label: Text('Enter last name'),
                              ),
                              validator: (value) {
                                if (value!.trim().isEmpty) {
                                  return 'Last name is required';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                setState(() {
                                  lastName = newValue;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          formContainer(
                            title: 'Contact',
                            context: context,
                            child: TextFormField(
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10),
                                label: Text('Enter phone number'),
                              ),
                              validator: (value) {
                                if (value!.trim().isEmpty) {
                                  return 'Email is required';
                                } else if (value.length < 11) {
                                  return 'Invalid phone number';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                setState(() {
                                  phone = newValue;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    h20(),
                    _sectionHeader(Icons.contact_mail_outlined, 'Contact Data'),
                    _sectionCard(
                      child: Column(
                        children: [
                          formContainer(
                            title: 'Email',
                            context: context,
                            child: TextFormField(
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10),
                                label: Text('Enter email'),
                              ),
                              validator: (value) {
                                if (value!.trim().isEmpty) {
                                  return 'Email is required';
                                } else if (!value.contains('@') &&
                                    !value.contains('.com')) {
                                  return 'Invalid emaill address';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                setState(() {
                                  email = newValue;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          formContainer(
                            title: 'State',
                            context: context,
                            child: Padding(
                              padding: const EdgeInsets.all(0.0),
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
                                          selectedState,
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
                                  items: states
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
                                  onChanged: (value) {
                                    setState(() {
                                      selectedState = value as String;
                                      getCities(value);
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
                                    maxHeight: 200,
                                    padding: null,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: context.palette.paper,
                                    ),
                                    elevation: 8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          cities.isEmpty
                              ? const SizedBox.shrink()
                              : formContainer(
                                  title: 'City',
                                  context: context,
                                  child: Padding(
                                    padding: const EdgeInsets.all(0.0),
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
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  selectedCity,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: context.palette.ink,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        items: cities
                                            .map((item) =>
                                                DropdownMenuItem<String>(
                                                  value: item,
                                                  child: Text(
                                                    item,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: context.palette.ink,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedCity = value as String;
                                            // getDataReport();
                                            // getComparison();
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
                                          maxHeight: 200,
                                          padding: null,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: context.palette.paper,
                                          ),
                                          elevation: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(
                            height: 10,
                          ),
                          formContainer(
                            title: 'Password',
                            context: context,
                            child: TextFormField(
                              obscureText: showPassword,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                suffixIcon: GestureDetector(
                                  onTap: (() {
                                    setState(() {
                                      showPassword = !showPassword;
                                    });
                                  }),
                                  child: Icon(
                                    // showPassword == true means the field
                                    // is currently obscured — show the
                                    // "closed eye" state, open eye once
                                    // revealed (original had these swapped).
                                    showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: grey,
                                  ),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10),
                                label: Text('Enter Password'),
                              ),
                              validator: (value) {
                                if (value!.trim().isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                setState(() {
                                  pwd = newValue;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(color: grey, fontSize: 13.5),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        LoginScreen(fromNav: false),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign in',
                                style: TextStyle(
                                  color: context.palette.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ))
        ]),
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
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Create your account',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: StepProgressIndicator(
                            totalSteps: 3,
                            currentStep: 2,
                            selectedColor: AppColors.primary,
                            unselectedColor: AppColors.border,
                            roundedEdges: const Radius.circular(6),
                            size: 6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Step 2 of 3 — tell us a bit about yourself',
                      style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 28),
                    Form(
                      key: _formKey,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal info',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 16),
                            WebFormRow(children: [
                              AppTextField(
                                label: 'First name',
                                hint: 'Enter first name',
                                validator: (value) => value!.trim().isEmpty
                                    ? 'First name is required'
                                    : null,
                                onSaved: (v) => firstName = v,
                              ),
                              AppTextField(
                                label: 'Last name',
                                hint: 'Enter last name',
                                validator: (value) => value!.trim().isEmpty
                                    ? 'Last name is required'
                                    : null,
                                onSaved: (v) => lastName = v,
                              ),
                            ]),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Phone',
                              hint: 'Enter phone number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value!.trim().isEmpty) {
                                  return 'Phone number is required';
                                } else if (value.length < 11) {
                                  return 'Invalid phone number';
                                }
                                return null;
                              },
                              onSaved: (v) => phone = v,
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Account details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Email',
                              hint: 'Enter email',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value!.trim().isEmpty) {
                                  return 'Email is required';
                                } else if (!value.contains('@')) {
                                  return 'Invalid email address';
                                }
                                return null;
                              },
                              onSaved: (v) => email = v,
                            ),
                            const SizedBox(height: 16),
                            WebFormRow(children: [
                              _webStateDropdown(),
                              if (cities.isNotEmpty) _webCityDropdown(),
                            ]),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Password',
                              hint: 'Enter password',
                              icon: Icons.lock_outline,
                              obscureText: showPassword,
                              suffix: GestureDetector(
                                onTap: () =>
                                    setState(() => showPassword = !showPassword),
                                child: Icon(
                                  showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              validator: (value) => value!.trim().isEmpty
                                  ? 'Password is required'
                                  : null,
                              onSaved: (v) => pwd = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    MiaButton(
                      text: 'Create Account',
                      isEnabled: !_isLoading,
                      onPressed: submitForm,
                      prefix: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: AppColors.textGrey, fontSize: 13.5),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (ctx) => LoginScreen(fromNav: false),
                              ),
                            ),
                            child: Text(
                              'Sign in',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
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

  Widget _webStateDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedState == 'State' ? null : selectedState,
      decoration: const InputDecoration(labelText: 'State'),
      hint: const Text('Choose state'),
      items: states
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => selectedState = value);
        getCities(value);
      },
    );
  }

  Widget _webCityDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCity == 'Choose City' ? null : selectedCity,
      decoration: const InputDecoration(labelText: 'City'),
      hint: const Text('Choose city'),
      items: cities
          .map((c) => DropdownMenuItem(value: c as String, child: Text(c)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => selectedCity = value);
      },
    );
  }
}
