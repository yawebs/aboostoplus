import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/utility/custom_toast.dart';
import 'package:eafind/widgets/currency_formatter.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:eafind/widgets/percentage_formatter.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/states_model.dart';
import '../utility/states_data.dart';

/// "Sell land" listing form.
///
/// Land is stored like any other property (upload-house.php, category
/// "Land", is_house 3). The land-specific facts — plots, plot size, use,
/// title document, survey plan, condition — are saved as the listing's
/// `requirements` list, which the details screen shows as chips under
/// "Land details".
class LandUploadScreen extends StatefulWidget {
  const LandUploadScreen({Key? key}) : super(key: key);

  @override
  State<LandUploadScreen> createState() => _LandUploadScreenState();
}

class _LandUploadScreenState extends State<LandUploadScreen> {
  static const _plotSizes = [
    '50 × 100 ft',
    '60 × 120 ft',
    '100 × 100 ft',
    'Other'
  ];
  static const _landUses = [
    'Residential',
    'Commercial',
    'Mixed use',
    'Agricultural',
    'Industrial',
  ];
  static const _titleDocs = [
    'C of O',
    "Governor's Consent",
    'Deed of Assignment',
    'Gazette',
    'Registered Survey',
    'Excision',
    'Family Receipt',
  ];
  static const _conditions = [
    'Dry land',
    'Fenced',
    'Gated estate',
    'Good road access',
    'Electricity nearby',
    'Corner piece',
    'Needs sand-filling',
  ];
  static const _minPhotos = 4;
  static const _maxPhotos = 8;

  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _plotsCtrl = TextEditingController();
  final _pricePerPlotCtrl = TextEditingController();

  UserModel? _user;

  String? _headline, _description, _community, _customSize;
  String _legalFee = '0', _agentFee = '0';
  String? _plotSize;
  String? _landUse;
  String? _titleDoc;
  bool? _hasSurveyPlan;
  bool _negotiable = false;
  bool _declared = false;
  final Set<String> _selectedConditions = {};

  String? _state, _city;
  List<String> _cities = [];

  int _mediaMode = 0; // 0 = photos, 1 = video
  List<File> _images = [];
  File? _video;

  bool _uploading = false;
  String _uploadStep = '';

  @override
  void initState() {
    super.initState();
    _user = context.read<UsermodelProvider>().getUserModel();
    _plotsCtrl.addListener(() => setState(() {}));
    _pricePerPlotCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _plotsCtrl.dispose();
    _pricePerPlotCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Derived values

  int get _plots => int.tryParse(_plotsCtrl.text.trim()) ?? 0;

  double _money(String formatted) =>
      double.tryParse(formatted.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  double get _pricePerPlot => _money(_pricePerPlotCtrl.text);

  double get _total => _plots * _pricePerPlot;

  String get _sizeLabel =>
      _plotSize == 'Other' ? (_customSize ?? '').trim() : (_plotSize ?? '');

  // ---------------------------------------------------------------------------
  // Media

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      limit: _maxPhotos,
    );
    if (picked.isEmpty) return;
    setState(() {
      _images = [
        ..._images,
        ...picked.map((x) => File(x.path)),
      ].take(_maxPhotos).toList();
    });
    if (_images.length < _minPhotos) {
      _toast('Add at least $_minPhotos photos of the land.');
    }
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _video = File(picked.path));
  }

  // ---------------------------------------------------------------------------
  // Submit

  void _toast(String message) => CustomToast.show(context,
      title: 'Check your listing', message: message, type: ToastType.error);

  /// Returns the first problem with the parts of the form that aren't plain
  /// text fields, or null when everything required is filled in.
  String? _missing() {
    if (_plotSize == null) return 'Choose the plot size.';
    if (_landUse == null) return 'Choose what the land can be used for.';
    if (_titleDoc == null) return 'Choose the title document for this land.';
    if (_hasSurveyPlan == null)
      return 'Say whether a survey plan is available.';
    if (_state == null) return 'Choose the state.';
    if (_city == null) return 'Choose the city.';
    if (_mediaMode == 0 && _images.length < _minPhotos) {
      return 'Add at least $_minPhotos photos of the land.';
    }
    if (_mediaMode == 1 && _video == null) return 'Choose a video of the land.';
    if (!_declared) return 'Confirm the declaration at the bottom of the form.';
    return null;
  }

  Future<void> _submit() async {
    final fieldsOk = _formKey.currentState!.validate();
    final problem = _missing();
    if (!fieldsOk || problem != null) {
      _toast(problem ?? 'Some required fields are empty.');
      return;
    }
    _formKey.currentState!.save();
    if (_user == null) {
      _toast('Please sign in again before listing land.');
      return;
    }

    setState(() {
      _uploading = true;
      _uploadStep = _mediaMode == 0
          ? 'Uploading ${_images.length} photos…'
          : 'Uploading video…';
    });

    try {
      final files = <MultipartFile>[];
      for (final f in _mediaMode == 0 ? _images : [_video!]) {
        final name = f.path.split(Platform.pathSeparator).last;
        files.add(MultipartFile.fromBytes(await f.readAsBytes(),
            filename: name, contentType: MediaType('image', name)));
      }
      final mediaRes = await Dio().post(endPoint('upload-images.php'),
          data: FormData.fromMap({'files[]': files, 'upload_images': true}));
      if (mediaRes.data['status'] != true) {
        throw Exception('media upload rejected');
      }
      final mediaUrls = mediaRes.data['imagePath'];

      setState(() => _uploadStep = 'Publishing listing…');

      final details = <String>[
        '$_plots plot${_plots == 1 ? '' : 's'}',
        if (_sizeLabel.isNotEmpty) '$_sizeLabel per plot',
        _landUse!,
        _titleDoc!,
        _hasSurveyPlan! ? 'Survey plan available' : 'No survey plan yet',
        ..._selectedConditions,
        if (_negotiable) 'Price negotiable',
      ];

      final res = await Dio().post(
        endPoint('upload-house.php'),
        data: FormData.fromMap({
          'upload_house': true,
          'title': _headline,
          'description': _description,
          'category': 'Land',
          'ownerId': _user!.id,
          'location': _state,
          'amount': _total,
          'userType': _user!.userType,
          'rooms': 0,
          'bathrooms': 0,
          'imageUrls': json.encode(mediaUrls),
          'requirements': json.encode(details),
          'userName': _user!.firstName,
          'community': _community,
          'color_code': 0,
          'tagged_userId': '',
          'is_house': 3,
          'property_plot': _plots,
          'hCity': _city,
          'cautionFee': 0,
          'legalFee': _money(_legalFee),
          'agentFee': int.tryParse(_agentFee.replaceAll('%', '')) ?? 0,
          'isVideo': _mediaMode,
          'propertyOwnerData': json.encode(_user!.toJson()),
        }),
      );
      if (res.data is Map && res.data['status'] == false) {
        throw Exception(res.data['message']);
      }

      if (!mounted) return;
      CustomToast.show(context,
          title: 'Land listed', message: 'Your land is now live on Aboostoplus.');
      goTo(context, const BottomNavHome(), false);
    } catch (e) {
      debugPrint('Land upload failed: $e');
      if (!mounted) return;
      setState(() => _uploading = false);
      CustomToast.show(context,
          title: 'Upload failed',
          message: 'We could not publish your land. Check your connection '
              'and try again.',
          type: ToastType.error);
    }
  }

  // ---------------------------------------------------------------------------
  // UI

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.of(context),
      child: PopScope(
        canPop: !_uploading,
        child: Scaffold(
          backgroundColor: context.palette.surface,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(),
                Expanded(child: _uploading ? _busy() : _form()),
              ],
            ),
          ),
          bottomNavigationBar: _uploading ? null : _publishBar(),
        ),
      ),
    );
  }

  Widget _form() {
    final p = context.palette;
    return Form(
      key: _formKey,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        children: [
          _section(
            icon: Icons.edit_note_rounded,
            title: 'About the land',
            children: [
              AppTextField(
                label: 'Listing headline',
                hint: 'e.g. 4 plots of dry land at Rumuodara',
                validator: _required('Add a headline'),
                onSaved: (v) => _headline = v!.trim(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                hint: 'Access road, neighbourhood, what buyers should know',
                maxLines: 4,
                validator: _required('Add a description'),
                onSaved: (v) => _description = v!.trim(),
              ),
            ],
          ),
          _section(
            icon: Icons.straighten_rounded,
            title: 'Size & use',
            children: [
              AppTextField(
                label: 'Number of plots',
                hint: 'e.g. 4',
                controller: _plotsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                    ? 'Enter how many plots'
                    : null,
              ),
              const SizedBox(height: 16),
              _label('Size of each plot'),
              _choiceChips(
                options: _plotSizes,
                selected: _plotSize,
                onSelect: (v) => setState(() => _plotSize = v),
              ),
              if (_plotSize == 'Other') ...[
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Plot size',
                  hint: 'e.g. 600 sqm',
                  validator: _required('Enter the plot size'),
                  onSaved: (v) => _customSize = v,
                  onChanged: (v) => _customSize = v,
                ),
              ],
              const SizedBox(height: 16),
              _label('Land use'),
              _choiceChips(
                options: _landUses,
                selected: _landUse,
                onSelect: (v) => setState(() => _landUse = v),
              ),
            ],
          ),
          _section(
            icon: Icons.verified_outlined,
            title: 'Documents',
            subtitle:
                'Buyers filter by title, so pick the strongest one you hold.',
            children: [
              _label('Title document'),
              _choiceChips(
                options: _titleDocs,
                selected: _titleDoc,
                onSelect: (v) => setState(() => _titleDoc = v),
              ),
              const SizedBox(height: 16),
              _label('Survey plan available?'),
              _choiceChips(
                options: const ['Yes', 'No'],
                selected: _hasSurveyPlan == null
                    ? null
                    : (_hasSurveyPlan! ? 'Yes' : 'No'),
                onSelect: (v) => setState(() => _hasSurveyPlan = v == 'Yes'),
              ),
            ],
          ),
          _section(
            icon: Icons.landscape_outlined,
            title: 'Condition',
            subtitle: 'Optional — select all that apply.',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _conditions.map((c) {
                  final on = _selectedConditions.contains(c);
                  return _chip(
                    label: c,
                    selected: on,
                    onTap: () => setState(() => on
                        ? _selectedConditions.remove(c)
                        : _selectedConditions.add(c)),
                  );
                }).toList(),
              ),
            ],
          ),
          _section(
            icon: Icons.payments_outlined,
            title: 'Price',
            children: [
              AppTextField(
                label: 'Price per plot (₦)',
                hint: 'e.g. 3,500,000',
                controller: _pricePerPlotCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                validator: (v) =>
                    _money(v ?? '') <= 0 ? 'Enter the price per plot' : null,
              ),
              const SizedBox(height: 12),
              _totalPanel(),
              const SizedBox(height: 16),
              WebFormRow(children: [
                AppTextField(
                  label: 'Legal fee (₦)',
                  hint: '0 if none',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  onSaved: (v) => _legalFee = (v ?? '').isEmpty ? '0' : v!,
                ),
                AppTextField(
                  label: 'Agent fee (%)',
                  hint: '0 if none',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    PercentageInputFormatter(),
                  ],
                  onSaved: (v) => _agentFee = (v ?? '').isEmpty ? '0' : v!,
                ),
              ]),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _negotiable,
                activeThumbColor: p.accent,
                onChanged: (v) => setState(() => _negotiable = v),
                title: Text('Price is negotiable',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.textDark)),
              ),
            ],
          ),
          _section(
            icon: Icons.place_outlined,
            title: 'Location',
            children: [
              _dropdown(
                label: 'State',
                hint: 'Choose state',
                value: _state,
                items: allStatesAndCities.map((s) => s.state).toList(),
                onChanged: (v) => setState(() {
                  _state = v;
                  _city = null;
                  _cities = allStatesAndCities
                      .firstWhere((s) => s.state == v,
                          orElse: () => StatesModel(state: v!, areas: []))
                      .areas
                      .cast<String>();
                }),
              ),
              if (_state != null) ...[
                const SizedBox(height: 16),
                _dropdown(
                  label: 'City',
                  hint: 'Choose city',
                  value: _city,
                  items: _cities,
                  onChanged: (v) => setState(() => _city = v),
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                label: 'Community / area',
                hint: 'e.g. Rumuodara',
                validator: _required('Enter the community'),
                onSaved: (v) => _community = v!.trim(),
              ),
            ],
          ),
          _section(
            icon: Icons.photo_library_outlined,
            title: 'Photos or video',
            subtitle:
                'Add $_minPhotos–$_maxPhotos clear photos of the land, or one walkthrough video.',
            children: [_mediaPicker()],
          ),
          _declaration(),
        ],
      ),
    );
  }

  // --- building blocks -------------------------------------------------------

  FormFieldValidator<String> _required(String message) =>
      (v) => (v ?? '').trim().isEmpty ? message : null;

  Widget _section({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: p.accent),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textDark)),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12.5, color: p.textGrey, height: 1.4)),
            ],
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textDark)),
      );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? p.primaryFill : p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? p.primaryFill : p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : p.textDark,
                )),
          ],
        ),
      ),
    );
  }

  Widget _choiceChips({
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((o) => _chip(
              label: o, selected: selected == o, onTap: () => onSelect(o)))
          .toList(),
    );
  }

  Widget _dropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(hint, style: TextStyle(color: p.textLight)),
              dropdownColor: p.card,
              items: items
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// Live "plots × price = total" panel, so sellers see the listed price
  /// before they publish.
  Widget _totalPanel() {
    final p = context.palette;
    final fmt = NumberFormat('#,##0');
    final ready = _plots > 0 && _pricePerPlot > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: ready
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6A3D7A), Color(0xFF3F224F)],
              )
            : null,
        color: ready ? null : p.surface,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LISTED PRICE',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                    color: ready ? const Color(0xFFE8A93B) : p.textGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ready ? '₦${fmt.format(_total)}' : 'Enter plots and price',
                  style: TextStyle(
                    fontFamily: ready ? 'Fraunces' : null,
                    fontSize: ready ? 24 : 14,
                    fontWeight: FontWeight.w600,
                    color: ready ? Colors.white : p.textLight,
                  ),
                ),
              ],
            ),
          ),
          if (ready)
            Text(
              '$_plots × ₦${fmt.format(_pricePerPlot)}',
              style: const TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _mediaPicker() {
    final p = context.palette;
    final isVideo = _mediaMode == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final mode in const [0, 1])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mediaMode = mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _mediaMode == mode ? p.primaryFill : null,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        mode == 0 ? 'Photos' : 'Video',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _mediaMode == mode ? Colors.white : p.textGrey,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: isVideo ? _pickVideo : _pickImages,
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.accent.withValues(alpha: 0.35)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    isVideo
                        ? Icons.video_call_outlined
                        : Icons.add_photo_alternate_outlined,
                    color: p.accent,
                    size: 28),
                const SizedBox(height: 6),
                Text(
                  isVideo
                      ? (_video == null
                          ? 'Choose a video'
                          : 'Video selected — tap to change')
                      : (_images.isEmpty
                          ? 'Choose photos'
                          : '${_images.length} of $_maxPhotos photos — tap to add more'),
                  style:
                      TextStyle(color: p.textDark, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        if (!isVideo && _images.isNotEmpty) ...[
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            itemCount: _images.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 110,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_images[i], fit: BoxFit.cover),
                  if (i == 0)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8A93B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Cover',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF241428))),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _declaration() {
    final p = context.palette;
    return GestureDetector(
      onTap: () => setState(() => _declared = !_declared),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _declared ? p.accent : p.border,
              width: _declared ? 1.5 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _declared,
              activeColor: p.primaryFill,
              visualDensity: VisualDensity.compact,
              onChanged: (v) => setState(() => _declared = v ?? false),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'I confirm I own this land or am authorised to sell it, and '
                  'that the title document listed above is genuine.',
                  style:
                      TextStyle(fontSize: 13, height: 1.45, color: p.textDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Same header family as the property and marketplace upload screens,
  // labelled for land so sellers know exactly which form they're in.
  Widget _header() {
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
                    if (_uploading) return;
                    Navigator.of(context).canPop()
                        ? Navigator.of(context).pop()
                        : goTo(context, const BottomNavHome(), false);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
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
                        'LAND SALE',
                        style: TextStyle(
                          color: Color(0xFFE8A93B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sell Your Land',
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

  Widget _headerBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Transform.rotate(angle: (1 - value) * -0.5, child: child),
      ),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFE8A93B),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8A93B).withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.terrain_rounded,
            color: Color(0xFF241428), size: 22),
      ),
    );
  }

  Widget _busy() {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: AppCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: p.accent),
              const SizedBox(height: 16),
              Text('Please keep this screen open',
                  style: TextStyle(
                      color: p.textDark, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_uploadStep, style: TextStyle(color: p.textGrey)),
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
          text: 'List Land for Sale',
          prefix:
              const Icon(Icons.terrain_rounded, color: Colors.white, size: 18),
          onPressed: _submit,
        ),
      ),
    );
  }
}
