import 'dart:io';

import 'package:eafind/const/constant.dart';
import 'package:eafind/models/house_type_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/services/service_providers_service.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/utility/states_data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// "List your service" - for movers, cleaners, painters etc. Separate from
// the marketplace upload; saved via service-providers.php.
class ListServiceScreen extends StatefulWidget {
  final String? initialCategory;
  const ListServiceScreen({Key? key, this.initialCategory}) : super(key: key);

  @override
  State<ListServiceScreen> createState() => _ListServiceScreenState();
}

class _ListServiceScreenState extends State<ListServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _areas = TextEditingController();
  final _price = TextEditingController();
  late final TextEditingController _phone;
  String? _category;
  String? _state;
  final List<XFile> _photos = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final me = context.read<UsermodelProvider>().getUserModel();
    _phone = TextEditingController(text: me?.phone ?? '');
    _category = widget.initialCategory;
    final st = me?.state ?? '';
    _state = allStatesAndCities.any((s) => s.state == st) ? st : null;
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _areas, _price, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addPhotos() async {
    try {
      final picked = await ImagePicker().pickMultiImage(
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 80,
      );
      if (picked.isEmpty || !mounted) return;
      setState(() {
        for (final p in picked) {
          if (_photos.length < 4) _photos.add(p);
        }
      });
      if (picked.length + _photos.length > 4) showToast('Up to 4 photos');
    } catch (_) {
      showToast('Could not open your gallery');
    }
  }

  Future<void> _submit() async {
    if (_category == null) {
      showToast('Choose your service type');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_state == null) {
      showToast('Choose the state you work in');
      return;
    }
    if (_photos.isEmpty) {
      showToast('Add at least one photo of your work');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final result = await ServiceProvidersService.create(
      businessName: _name.text.trim(),
      category: _category!,
      description: _description.text.trim(),
      state: _state!,
      areas: _areas.text.trim(),
      phone: _phone.text.trim(),
      startingPrice: num.tryParse(_price.text.replaceAll(',', '').trim()),
      photos: _photos,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.ok) {
      successSnackBar('Your service is live', context);
      Navigator.pop(context, true);
    } else {
      showErrorSnackbar(result.error!, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: palette.page,
        appBar: AppBar(
          backgroundColor: palette.page,
          elevation: 0,
          iconTheme: IconThemeData(color: palette.ink),
          title: Text('List your service',
              style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700)),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            children: [
              _intro(palette),
              _section(palette, 'SERVICE TYPE'),
              _categoryPicker(palette),
              _section(palette, 'YOUR BUSINESS'),
              _field(palette,
                  controller: _name,
                  label: 'Business name',
                  icon: Icons.storefront_rounded,
                  validator: (v) => (v ?? '').trim().length < 2
                      ? 'Enter your business name'
                      : null),
              const SizedBox(height: 14),
              _field(palette,
                  controller: _description,
                  label: 'What you offer',
                  hint:
                      'e.g. Truck + 3 loaders, packing materials, same-day moves across Port Harcourt',
                  icon: Icons.description_rounded,
                  maxLines: 4,
                  validator: (v) => (v ?? '').trim().length < 20
                      ? 'Describe your service in at least 20 characters'
                      : null),
              const SizedBox(height: 14),
              _field(palette,
                  controller: _price,
                  label: 'Starting price (₦, optional)',
                  icon: Icons.payments_rounded,
                  keyboard: TextInputType.number),
              _section(palette, 'WHERE YOU WORK'),
              DropdownButtonFormField<String>(
                initialValue: _state,
                isExpanded: true,
                dropdownColor: palette.paper,
                style: TextStyle(color: palette.ink, fontSize: 15),
                decoration: _decoration(palette, 'State', Icons.map_rounded),
                items: [
                  for (final s in allStatesAndCities)
                    DropdownMenuItem(value: s.state, child: Text(s.state)),
                ],
                onChanged: (v) => setState(() => _state = v),
              ),
              const SizedBox(height: 14),
              _field(palette,
                  controller: _areas,
                  label: 'Areas you cover',
                  hint: 'e.g. Rumuokoro, Woji, GRA, Trans Amadi',
                  icon: Icons.location_on_rounded,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'List the areas you cover' : null),
              const SizedBox(height: 14),
              _field(palette,
                  controller: _phone,
                  label: 'Business phone',
                  icon: Icons.phone_rounded,
                  keyboard: TextInputType.phone,
                  validator: (v) =>
                      (v ?? '').replaceAll(RegExp(r'[^0-9]'), '').length < 10
                          ? 'Enter a valid phone number'
                          : null),
              _section(palette, 'PHOTOS OF YOUR WORK (UP TO 4)'),
              _photoGrid(palette),
              const SizedBox(height: 26),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primaryFill,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        palette.primaryFill.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.rocket_launch_rounded, size: 18),
                  label: Text(_saving ? 'Publishing…' : 'Publish my service',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _intro(AppPalette palette) {
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.4)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [palette.primaryFill, deep]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.handyman_rounded, color: Color(0xFFF5C76A), size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Get jobs from people moving home',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    'Customers request quotes and chat with you directly in the app.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.5,
                        height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(AppPalette palette, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: palette.inkMuted)),
      );

  Widget _categoryPicker(AppPalette palette) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in homeServiceTypes)
          Builder(builder: (_) {
            final info = homeServiceInfo[type]!;
            final selected = _category == type;
            return GestureDetector(
              onTap: () => setState(() => _category = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? info.color : palette.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: selected ? info.color : palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(info.icon,
                        size: 16, color: selected ? Colors.white : info.color),
                    const SizedBox(width: 6),
                    Text(type,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : palette.ink,
                        )),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _photoGrid(AppPalette palette) {
    final tiles = <Widget>[
      for (var i = 0; i < _photos.length; i++)
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox.expand(
                child: kIsWeb
                    ? Image.network(_photos[i].path, fit: BoxFit.cover)
                    : Image.file(File(_photos[i].path), fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _photos.removeAt(i)),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      if (_photos.length < 4)
        GestureDetector(
          onTap: _addPhotos,
          child: Container(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: palette.accent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_rounded,
                    color: palette.accent, size: 26),
                const SizedBox(height: 4),
                Text('Add',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.accent)),
              ],
            ),
          ),
        ),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    );
  }

  InputDecoration _decoration(AppPalette palette, String label, IconData icon,
          {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        hintMaxLines: 2,
        filled: true,
        fillColor: palette.card,
        alignLabelWithHint: true,
        prefixIcon: Icon(icon, size: 19, color: palette.accent),
        labelStyle: TextStyle(color: palette.inkSoft),
        hintStyle: TextStyle(color: palette.inkMuted, fontSize: 13),
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

  Widget _field(
    AppPalette palette, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        textCapitalization: keyboard == null
            ? TextCapitalization.sentences
            : TextCapitalization.none,
        style: TextStyle(color: palette.ink, fontSize: 15),
        decoration: _decoration(palette, label, icon, hint: hint),
      );
}
