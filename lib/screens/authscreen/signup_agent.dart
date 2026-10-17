import 'package:eafind/theme/app_palette.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:eafind/auths/auth_service.dart';
import 'package:eafind/models/states_model.dart';
import 'package:eafind/screens/authscreen/setup_agent_profile.dart';
import 'package:eafind/services/permision_handler_service.dart';
import 'package:eafind/services/push_notification_service.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/utility/states_data.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shortid/shortid.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import '../../const/constant.dart';
import '../../services/providers/data_provider.dart';
import 'login_screen.dart';

class SignAgent extends StatefulWidget {
  const SignAgent({Key? key}) : super(key: key);

  @override
  State<SignAgent> createState() => _SignAgentState();
}

class _SignAgentState extends State<SignAgent> {
  final _formKey = GlobalKey<FormState>();
  bool showPassword = true;
  String selectedUserType = 'Account Type';
  List<String> userTypes = [
    'Agent',
    'Landlord',
    'Lead',
    'Freelancer',
  ];
  List<String> states = [];
  List<dynamic> cities = [];
  String selectedState = 'State';
  String selectedCity = 'Choose City';
  var firstName, lastName, residentialAddress, email, password, phone, leadUId;
  bool isLoading = false;

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
    if (selectedUserType == 'Account Type') {
      showErrorSnackbar('Please Choose Account type', context);
    } else if (selectedState == 'State') {
      showErrorSnackbar('Choose State', context);
    } else if (selectedCity == 'Choose City') {
      showErrorSnackbar('Choose City', context);
    } else {
      if (_formKey.currentState!.validate()) {
        setState(() {
          isLoading = true;
          _formKey.currentState!.save();
        });
        String? deviceId = await PushNotificationService.getDeviceToken();

        print(deviceId);
        Map<String, dynamic> data = {
          'auth_user': 'Agent',
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
          'email': email,
          'lead_uid': leadUId ?? '',
          'unique_id': shortid.generate(),
          'phone': phone,
          'address': residentialAddress,
          'state': selectedState,
          'city': selectedCity,
          'user_type': selectedUserType,
          'notification_id': deviceId ?? '',
        };
        Provider.of<DataProvider>(context, listen: false).setSignupData(data);
        // await AuthService().signupUserEndpoint(data);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => const SetupAgentProfile(),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getStates();
  }

  // Small helper so every "section" (Personal / Contact) gets the same
  // icon + label + spacing treatment instead of ad-hoc Text widgets.
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

  // Card wrapper: replaces the bare `formWrapperContainer` with a
  // bordered, softly-shadowed surface so each section reads as a
  // distinct grouped card, matching the login screen's form card.
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
                onTap: isLoading ? null : (() => submitForm()),
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
                    child: isLoading
                        ? LoadingAnimationWidget.fallingDot(
                            color: white, size: 32)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Next',
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
      body: ListView(shrinkWrap: true, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            'Create An Account',
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
        Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 110),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(Icons.person_outline, 'Personal Info'),
                  _sectionCard(
                    child: Column(
                      children: [
                        accountTypeDropdown(),
                        const SizedBox(height: 10),
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
                              if (value!.isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              firstName = newValue;
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
                              if (value!.isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              lastName = newValue;
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
                          title: 'Residential Address',
                          context: context,
                          child: TextFormField(
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10),
                              label: Text('Enter address'),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Address is required';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              residentialAddress = newValue;
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
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
                              if (value!.isEmpty) {
                                return 'Email is required';
                              } else if (!value.contains('@')) {
                                return 'Invalid email address';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (newValue) {
                              email = newValue!.trim().toLowerCase();
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        formContainer(
                          title: 'Phone',
                          context: context,
                          child: TextFormField(
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10),
                              label: Text('Enter Phone'),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Phone is required';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              phone = newValue;
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        formContainer(
                          title: 'Lead UID',
                          context: context,
                          child: TextFormField(
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10),
                              label: Text('Enter Lead UID (Optional)'),
                            ),
                            keyboardType: TextInputType.text,
                            onSaved: (newValue) {
                              leadUId = newValue;
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        stateDropdown(),
                        const SizedBox(height: 10),
                        cities.isEmpty
                            ? const SizedBox.shrink()
                            : cityDropdown(),
                        if (cities.isNotEmpty) const SizedBox(height: 10),
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
                                  // "closed eye" state, and the open eye
                                  // once revealed (the original had these
                                  // swapped).
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
                              if (value!.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              password = newValue;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(color: grey, fontSize: 13.5),
                        ),
                        GestureDetector(
                          onTap: () {
                            goTo(
                                context,
                                LoginScreen(
                                  fromNav: false,
                                ),
                                false);
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
                ],
              ),
            ))
      ]),
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
                          'Create an agent account',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 28,
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
                            DropdownButtonFormField<String>(
                              value: selectedUserType == 'Account Type'
                                  ? null
                                  : selectedUserType,
                              decoration:
                                  const InputDecoration(labelText: 'Account type'),
                              hint: const Text('Choose account type'),
                              items: userTypes
                                  .map((t) =>
                                      DropdownMenuItem(value: t, child: Text(t)))
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => selectedUserType = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            WebFormRow(children: [
                              AppTextField(
                                label: 'First name',
                                hint: 'Enter first name',
                                validator: (v) => v!.isEmpty
                                    ? 'First name is required'
                                    : null,
                                onSaved: (v) => firstName = v,
                              ),
                              AppTextField(
                                label: 'Last name',
                                hint: 'Enter last name',
                                validator: (v) =>
                                    v!.isEmpty ? 'Last name is required' : null,
                                onSaved: (v) => lastName = v,
                              ),
                            ]),
                            const SizedBox(height: 28),
                            const Text(
                              'Contact data',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Residential Address',
                              hint: 'Enter address',
                              icon: Icons.home_outlined,
                              validator: (v) =>
                                  v!.isEmpty ? 'Address is required' : null,
                              onSaved: (v) => residentialAddress = v,
                            ),
                            const SizedBox(height: 16),
                            WebFormRow(children: [
                              AppTextField(
                                label: 'Email',
                                hint: 'Enter email',
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v!.isEmpty) return 'Email is required';
                                  if (!v.contains('@')) {
                                    return 'Invalid email address';
                                  }
                                  return null;
                                },
                                onSaved: (v) => email = v!.trim().toLowerCase(),
                              ),
                              AppTextField(
                                label: 'Phone',
                                hint: 'Enter phone',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (v) =>
                                    v!.isEmpty ? 'Phone is required' : null,
                                onSaved: (v) => phone = v,
                              ),
                            ]),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Lead UID (optional)',
                              hint: 'Enter lead UID',
                              icon: Icons.badge_outlined,
                              onSaved: (v) => leadUId = v,
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
                              validator: (v) =>
                                  v!.isEmpty ? 'Password is required' : null,
                              onSaved: (v) => password = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    MiaButton(
                      text: 'Next',
                      isEnabled: !isLoading,
                      onPressed: submitForm,
                      prefix: isLoading
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
                            onTap: () => goTo(
                                context, LoginScreen(fromNav: false), false),
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
      items:
          states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
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

  Widget stateDropdown() {
    return formContainer(
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
    );
  }

  Widget cityDropdown() {
    return formContainer(
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
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      selectedCity,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.palette.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            items: cities
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
                borderRadius: BorderRadius.circular(10),
                color: context.palette.paper,
              ),
              elevation: 8,
            ),
          ),
        ),
      ),
    );
  }

  Widget accountTypeDropdown() {
    return formContainer(
      title: 'Account Type',
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
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      selectedUserType,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.palette.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            items: userTypes
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
                selectedUserType = value as String;
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
              maxHeight: 150,
              padding: null,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
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
