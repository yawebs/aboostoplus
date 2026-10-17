import 'package:eafind/models/house_type_model.dart';
import 'package:eafind/models/property_filter.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/utility/states_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Opens the filter sheet seeded with [current]; resolves to the new filter,
// or null if the user closed it without applying.
Future<PropertyFilter?> showAdvancedFilterSheet(
    BuildContext context, PropertyFilter current) {
  return showModalBottomSheet<PropertyFilter>(
    context: context,
    isScrollControlled: true,
    // Keeps the sheet below the status bar / notch instead of letting a
    // tall, scroll-controlled sheet slide up underneath it.
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AdvancedFilterSheet(initial: current),
  );
}

class AdvancedFilterSheet extends StatefulWidget {
  final PropertyFilter initial;
  const AdvancedFilterSheet({Key? key, required this.initial})
      : super(key: key);

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  // Price slider stops: non-linear so both a ₦50k room and a ₦50M land
  // are reachable. The first stop means "no minimum", the last "no maximum".
  static const List<int> _priceSteps = [
    0, 20000, 50000, 100000, 200000, 500000, 1000000, 2000000, //
    5000000, 10000000, 20000000, 50000000, 100000000,
  ];
  static const List<int> _countOptions = [0, 1, 2, 3, 4, 5];

  late PropertyFilter _filter;
  late TextEditingController _communityController;

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
    _communityController = TextEditingController(text: _filter.community);
  }

  @override
  void dispose() {
    _communityController.dispose();
    super.dispose();
  }

  int _stepIndex(int? price, {required bool isMax}) {
    if (price == null) return isMax ? _priceSteps.length - 1 : 0;
    final i = _priceSteps.indexWhere((s) => s >= price);
    return i == -1 ? _priceSteps.length - 1 : i;
  }

  String _naira(int value) => '₦${NumberFormat.compact().format(value)}';

  List<String> get _cities {
    if (_filter.state == null) return [];
    for (final s in allStatesAndCities) {
      if (s.state == _filter.state) return s.areas.cast<String>();
    }
    return [];
  }

  void _reset() {
    setState(() => _filter = PropertyFilter.empty);
    _communityController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final media = MediaQuery.of(context);
    // bottom: false - the apply bar pads itself for the home indicator so
    // its background still reaches the screen edge.
    return SafeArea(
      bottom: false,
      child: FractionallySizedBox(
        // Fraction of the safe area, not the raw screen height, so the
        // header can never sit under the status bar.
        heightFactor: 0.94,
        child: Container(
          decoration: BoxDecoration(
            color: palette.paper,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _header(palette),
              Divider(height: 1, color: palette.border),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                      16, 8, 16, 24 + media.viewInsets.bottom),
                  children: [
                    _section(
                        'Sort by', Icons.swap_vert_rounded, _sortRow(palette)),
                    _section('Property type', Icons.home_work_rounded,
                        _categoryWrap(palette)),
                    _section('Price range', Icons.payments_rounded,
                        _priceSlider(palette)),
                    _section(
                        'Bedrooms',
                        Icons.bed_rounded,
                        _countRow(palette, _filter.minRooms,
                            (v) => _filter = _filter.copyWith(minRooms: v))),
                    _section(
                        'Bathrooms',
                        Icons.bathtub_rounded,
                        _countRow(
                            palette,
                            _filter.minBathrooms,
                            (v) =>
                                _filter = _filter.copyWith(minBathrooms: v))),
                    _section('Location', Icons.location_on_rounded,
                        _locationFields(palette)),
                    _section('Listing media', Icons.perm_media_rounded,
                        _mediaRow(palette)),
                  ],
                ),
              ),
              _applyBar(palette, media.padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: palette.inkMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close_rounded, color: palette.ink),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Filters',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: _filter.isActive || _filter.sort != SortOption.newest
                    ? _reset
                    : null,
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _filter.isActive || _filter.sort != SortOption.newest
                        ? palette.accent
                        : palette.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget child) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: palette.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // Selectable pill shared by every chip group in the sheet.
  Widget _pill(
    AppPalette palette, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? palette.primaryFill : palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? palette.primaryFill : palette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 15, color: selected ? Colors.white : palette.accent),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortRow(AppPalette palette) {
    const labels = {
      SortOption.newest: 'Newest',
      SortOption.priceLowHigh: 'Price: low to high',
      SortOption.priceHighLow: 'Price: high to low',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SortOption.values
          .map((s) => _pill(
                palette,
                label: labels[s]!,
                selected: _filter.sort == s,
                onTap: () =>
                    setState(() => _filter = _filter.copyWith(sort: s)),
              ))
          .toList(),
    );
  }

  static IconData _categoryIcon(String type) {
    switch (type) {
      case 'Land':
        return Icons.landscape_rounded;
      case 'Office Space':
        return Icons.business_center_rounded;
      case 'Hall':
        return Icons.celebration_rounded;
      case 'Property Sales':
        return Icons.location_city_rounded;
      case kServiceApartment:
        return Icons.apartment_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  Widget _categoryWrap(AppPalette palette) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: houseTypes.map((h) {
        final selected = _filter.categories.contains(h.type);
        return _pill(
          palette,
          label: h.type,
          icon: _categoryIcon(h.type),
          selected: selected,
          onTap: () => setState(() {
            final next = Set<String>.from(_filter.categories);
            selected ? next.remove(h.type) : next.add(h.type);
            _filter = _filter.copyWith(categories: next);
          }),
        );
      }).toList(),
    );
  }

  Widget _priceSlider(AppPalette palette) {
    final lo = _stepIndex(_filter.minPrice, isMax: false);
    final hi = _stepIndex(_filter.maxPrice, isMax: true);
    final last = _priceSteps.length - 1;
    Widget box(String caption, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caption,
                    style: TextStyle(fontSize: 11, color: palette.inkSoft)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    )),
              ],
            ),
          ),
        );
    return Column(
      children: [
        Row(
          children: [
            box('Minimum', lo == 0 ? 'No min' : _naira(_priceSteps[lo])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('—', style: TextStyle(color: palette.inkMuted)),
            ),
            box('Maximum', hi == last ? 'No max' : _naira(_priceSteps[hi])),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: palette.primaryFill,
            inactiveTrackColor: palette.border,
            thumbColor: palette.primaryFill,
            overlayColor: palette.primaryFill.withValues(alpha: 0.12),
            showValueIndicator: ShowValueIndicator.never,
            tickMarkShape: SliderTickMarkShape.noTickMark,
          ),
          child: RangeSlider(
            min: 0,
            max: last.toDouble(),
            divisions: last,
            values: RangeValues(lo.toDouble(), hi.toDouble()),
            onChanged: (v) => setState(() {
              final newLo = v.start.round();
              final newHi = v.end.round();
              _filter = _filter.copyWith(
                minPrice: () => newLo == 0 ? null : _priceSteps[newLo],
                maxPrice: () => newHi == last ? null : _priceSteps[newHi],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _countRow(
      AppPalette palette, int value, void Function(int) onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _countOptions
          .map((n) => _pill(
                palette,
                label: n == 0 ? 'Any' : '$n+',
                selected: value == n,
                onTap: () => setState(() => onChanged(n)),
              ))
          .toList(),
    );
  }

  InputDecoration _fieldDecoration(AppPalette palette, String hint,
          {IconData? icon}) =>
      InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: palette.card,
        prefixIcon:
            icon == null ? null : Icon(icon, size: 18, color: palette.accent),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      );

  Widget _locationFields(AppPalette palette) {
    final cities = _cities;
    final textStyle = TextStyle(fontSize: 14, color: palette.ink);
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _filter.state,
          isExpanded: true,
          dropdownColor: palette.paper,
          style: textStyle,
          decoration:
              _fieldDecoration(palette, 'Any state', icon: Icons.map_rounded),
          items: [
            DropdownMenuItem<String>(value: null, child: Text('Any state')),
            ...allStatesAndCities.map(
                (s) => DropdownMenuItem(value: s.state, child: Text(s.state))),
          ],
          onChanged: (v) => setState(() => _filter = _filter.copyWith(
                state: () => v,
                city: () => null,
              )),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          // Keyed on state so the field resets when the state changes.
          key: ValueKey(_filter.state),
          value: cities.contains(_filter.city) ? _filter.city : null,
          isExpanded: true,
          dropdownColor: palette.paper,
          style: textStyle,
          decoration: _fieldDecoration(palette,
              _filter.state == null ? 'Pick a state first' : 'Any city',
              icon: Icons.location_city_rounded),
          items: [
            DropdownMenuItem<String>(value: null, child: Text('Any city')),
            ...cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
          ],
          onChanged: _filter.state == null
              ? null
              : (v) =>
                  setState(() => _filter = _filter.copyWith(city: () => v)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _communityController,
          textCapitalization: TextCapitalization.words,
          style: textStyle,
          decoration: _fieldDecoration(palette, 'Community (e.g. Rumuokoro)',
              icon: Icons.signpost_rounded),
          onChanged: (v) =>
              setState(() => _filter = _filter.copyWith(community: v)),
        ),
      ],
    );
  }

  Widget _mediaRow(AppPalette palette) {
    Widget pill(MediaFilter m, String label, IconData icon) => _pill(
          palette,
          label: label,
          icon: icon,
          selected: _filter.media == m,
          onTap: () => setState(() => _filter = _filter.copyWith(media: m)),
        );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        pill(MediaFilter.any, 'Any', Icons.all_inclusive_rounded),
        pill(MediaFilter.photos, 'Photos', Icons.photo_library_rounded),
        pill(MediaFilter.videos, 'Video tours', Icons.videocam_rounded),
      ],
    );
  }

  Widget _applyBar(AppPalette palette, double bottomInset) {
    final count = _filter.activeCount;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: palette.paper,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.primaryFill,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.search_rounded),
          label: Text(
            count == 0
                ? 'Show results'
                : 'Show results · $count filter${count == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          onPressed: () => Navigator.pop(
            context,
            _filter.copyWith(community: _communityController.text.trim()),
          ),
        ),
      ),
    );
  }
}
