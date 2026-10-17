import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/services/new_auth_service.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/utility/states_data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../const/constant.dart';
import '../../models/user_model.dart';

// Edit the signed-in user's profile: photo, name, phone, address and
// location. Saved through update-profile.php (authenticated by the user's
// login token), then the in-app user is refreshed so every screen updates.
class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String? _state;
  String? _city;
  XFile? _newPhoto;
  bool _saving = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _user = context.read<UsermodelProvider>().getUserModel();
    final u = _user;
    if (u != null) {
      _first.text = u.firstName;
      _last.text = u.lastName;
      _phone.text = u.phone;
      _address.text = u.address;
      _state = _stateNames.contains(u.state) ? u.state : null;
      _city = _citiesFor(_state).contains(u.city) ? u.city : null;
    }
    for (final c in [_first, _last, _phone, _address]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _stateNames => [for (final s in allStatesAndCities) s.state];

  List<String> _citiesFor(String? state) {
    if (state == null) return [];
    for (final s in allStatesAndCities) {
      if (s.state == state) return s.areas.cast<String>();
    }
    return [];
  }

  bool get _dirty {
    final u = _user;
    if (u == null) return false;
    return _newPhoto != null ||
        _first.text.trim() != u.firstName ||
        _last.text.trim() != u.lastName ||
        _phone.text.trim() != u.phone ||
        _address.text.trim() != u.address ||
        (_state ?? '') != u.state ||
        (_city ?? '') != u.city;
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final palette = ctx.palette;
        Widget option(IconData icon, String label, ImageSource s) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: palette.primaryFill.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: palette.accent),
              ),
              title: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: palette.ink)),
              onTap: () => Navigator.pop(ctx, s),
            );
        return Container(
          decoration: BoxDecoration(
            color: palette.paper,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Profile photo',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: palette.ink)),
                  const SizedBox(height: 8),
                  if (!kIsWeb)
                    option(Icons.photo_camera_rounded, 'Take a photo',
                        ImageSource.camera),
                  option(Icons.photo_library_rounded, 'Choose from gallery',
                      ImageSource.gallery),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (picked != null && mounted) setState(() => _newPhoto = picked);
    } catch (e) {
      showToast(
          'Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}');
    }
  }

  Future<void> _save() async {
    final u = _user;
    if (u == null || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final token = await NewAuthService.instance.getToken();
      if (token == null) {
        showErrorSnackbar(
            'Please log in again to update your profile', context);
        return;
      }
      final form = FormData.fromMap({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'state': _state ?? '',
        'city': _city ?? '',
        if (_newPhoto != null)
          'profileImage': MultipartFile.fromBytes(
            await _newPhoto!.readAsBytes(),
            filename: _newPhoto!.name,
          ),
      });
      final res = await Dio().post(
        endPoint('update-profile.php'),
        data: form,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true, // read our JSON error messages
        ),
      );
      final body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final d = Map<String, dynamic>.from(body['data']);
        final updated = UserModel(
          id: u.id,
          firstName: (d['firstname'] ?? _first.text.trim()).toString(),
          lastName: (d['lastname'] ?? _last.text.trim()).toString(),
          email: u.email,
          createdAt: u.createdAt,
          profileImage: d['profileImage'] ?? u.profileImage,
          phone: (d['phone'] ?? _phone.text.trim()).toString(),
          userType: u.userType,
          address: (d['uAddress'] ?? _address.text.trim()).toString(),
          state: (d['uState'] ?? _state ?? '').toString(),
          city: (d['city'] ?? _city ?? '').toString(),
          userName: (d['firstname'] ?? u.userName).toString(),
          notificationToken: u.notificationToken,
          uid: u.uid,
          leadId: u.leadId,
          password: u.password,
          accountStatus: u.accountStatus,
        );
        if (!mounted) return;
        context.read<UsermodelProvider>().setUserModel(updated);
        setState(() {
          _user = updated;
          _newPhoto = null;
        });
        successSnackBar('Profile updated', context);
      } else {
        final msg = body is Map && body['message'] != null
            ? body['message'].toString()
            : res.statusCode == 404
                ? 'Profile editing is not available yet. Please try again later.'
                : 'Could not update your profile';
        if (mounted) showErrorSnackbar(msg, context);
      }
    } catch (e) {
      debugPrint('update-profile failed: $e');
      if (mounted) {
        showErrorSnackbar(
            'Could not reach the server. Check your connection.', context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final u = _user;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: palette.page,
        body: u == null
            ? Center(
                child: Text('Log in to edit your profile',
                    style: TextStyle(color: palette.inkSoft)))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _header(palette, u),
                              Form(
                                key: _formKey,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 8, 18, 24),
                                  child: _fields(palette, u),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _saveBar(palette),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _header(AppPalette palette, UserModel u) {
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.45)!;
    final current = (u.profileImage ?? '').toString();
    final ImageProvider? photo = _newPhoto != null
        ? (kIsWeb
            ? NetworkImage(_newPhoto!.path)
            : FileImage(File(_newPhoto!.path)) as ImageProvider)
        : (current.isNotEmpty ? NetworkImage(current) : null);
    final initial =
        u.firstName.trim().isEmpty ? '?' : u.firstName.trim()[0].toUpperCase();

    return SizedBox(
      height: 270 + MediaQuery.of(context).padding.top,
      child: Stack(
        children: [
          // Gradient band
          Container(
            height: 200 + MediaQuery.of(context).padding.top,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.primaryFill, deep],
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => goBack(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text('Edit profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          // Avatar overlapping the band
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _saving ? null : _pickPhoto,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.page,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor:
                              palette.primaryFill.withValues(alpha: 0.15),
                          backgroundImage: photo,
                          onBackgroundImageError:
                              photo != null ? (_, __) {} : null,
                          child: photo == null
                              ? Text(initial,
                                  style: TextStyle(
                                      fontSize: 44,
                                      fontWeight: FontWeight.w800,
                                      color: palette.accent))
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 6,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [
                              Color(0xFFF5C76A),
                              Color(0xFFE8A93B),
                            ]),
                            border: Border.all(color: palette.page, width: 3),
                          ),
                          child: const Icon(Icons.photo_camera_rounded,
                              size: 18, color: Color(0xFF3F224F)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _newPhoto != null
                      ? 'New photo selected'
                      : 'Tap to change photo',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _newPhoto != null ? palette.accent : palette.inkMuted,
                    fontWeight:
                        _newPhoto != null ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fields(AppPalette palette, UserModel u) {
    String? required(String? v, String label) =>
        (v == null || v.trim().isEmpty) ? 'Enter your $label' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: palette.primaryFill.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded,
                    size: 14, color: palette.accent),
                const SizedBox(width: 6),
                Text('${u.userType} account',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.accent)),
              ],
            ),
          ),
        ),
        _section(palette, 'PERSONAL DETAILS'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _input(palette,
                  controller: _first,
                  label: 'First name',
                  icon: Icons.person_rounded,
                  validator: (v) => required(v, 'first name')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _input(palette,
                  controller: _last,
                  label: 'Last name',
                  icon: Icons.badge_rounded,
                  validator: (v) => required(v, 'last name')),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _input(palette,
            controller: _phone,
            label: 'Phone number',
            icon: Icons.phone_rounded,
            keyboard: TextInputType.phone, validator: (v) {
          final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.isEmpty) return null;
          return digits.length < 10 ? 'Enter a valid phone number' : null;
        }),
        const SizedBox(height: 14),
        // Email is the login id - shown but not editable here.
        _input(palette,
            initial: u.email,
            label: 'Email',
            icon: Icons.mail_rounded,
            readOnly: true,
            helper: 'Your email is your login, so it can\'t be changed here.'),
        _section(palette, 'LOCATION'),
        _input(palette,
            controller: _address,
            label: 'Address',
            icon: Icons.home_rounded,
            maxLines: 2),
        const SizedBox(height: 14),
        _dropdown(
          palette,
          label: 'State',
          icon: Icons.map_rounded,
          value: _state,
          items: _stateNames,
          onChanged: (v) => setState(() {
            _state = v;
            _city = null;
          }),
        ),
        const SizedBox(height: 14),
        _dropdown(
          palette,
          key: ValueKey(_state),
          label: _state == null ? 'City (pick a state first)' : 'City / LGA',
          icon: Icons.location_city_rounded,
          value: _city,
          items: _citiesFor(_state),
          onChanged: _state == null ? null : (v) => setState(() => _city = v),
        ),
      ],
    );
  }

  Widget _section(AppPalette palette, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
        child: Text(text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: palette.inkMuted,
            )),
      );

  InputDecoration _decoration(AppPalette palette, String label, IconData icon,
          {bool readOnly = false, String? helper}) =>
      InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        filled: true,
        fillColor: readOnly ? palette.tile : palette.card,
        prefixIcon: Icon(icon, size: 19, color: palette.accent),
        suffixIcon: readOnly
            ? Icon(Icons.lock_rounded, size: 16, color: palette.inkMuted)
            : null,
        labelStyle: TextStyle(color: palette.inkSoft),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD64545)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD64545), width: 1.5),
        ),
      );

  Widget _input(
    AppPalette palette, {
    TextEditingController? controller,
    String? initial,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    bool readOnly = false,
    String? helper,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initial : null,
      readOnly: readOnly,
      keyboardType: keyboard,
      validator: validator,
      maxLines: maxLines,
      enabled: !_saving || readOnly,
      textCapitalization: keyboard == null && !readOnly
          ? TextCapitalization.words
          : TextCapitalization.none,
      style: TextStyle(
          color: readOnly ? palette.inkSoft : palette.ink, fontSize: 15),
      decoration:
          _decoration(palette, label, icon, readOnly: readOnly, helper: helper),
    );
  }

  Widget _dropdown(
    AppPalette palette, {
    Key? key,
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: value,
      isExpanded: true,
      dropdownColor: palette.paper,
      style: TextStyle(color: palette.ink, fontSize: 15),
      decoration: _decoration(palette, label, icon),
      items: [
        for (final i in items) DropdownMenuItem(value: i, child: Text(i)),
      ],
      onChanged: _saving ? null : onChanged,
    );
  }

  Widget _saveBar(AppPalette palette) {
    final enabled = _dirty && !_saving;
    return Container(
      padding: EdgeInsets.fromLTRB(
          18, 12, 18, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: enabled ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.primaryFill,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                palette.primaryFill.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white),
                )
              : Text(
                  _dirty ? 'Save changes' : 'No changes yet',
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
