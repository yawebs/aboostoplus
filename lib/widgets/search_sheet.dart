import 'dart:async';

import 'package:eafind/theme/app_palette.dart';
import 'package:dio/dio.dart';
import 'package:eafind/models/house_type_model.dart';
import 'package:eafind/models/property_filter.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/screens/house_details_screen.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/advanced_filter_sheet.dart';
import 'package:eafind/widgets/recomemded_widget.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/services/search_alerts_service.dart';
import 'package:intl/intl.dart';

import '../const/constant.dart';

class SearchSheet extends StatefulWidget {
  // Optional search to start with (e.g. opened from a saved search alert).
  final PropertyFilter? initialFilter;
  final String initialKeyword;
  const SearchSheet({Key? key, this.initialFilter, this.initialKeyword = ''})
      : super(key: key);

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  TextEditingController searchController = TextEditingController();
  PropertyFilter _filter = PropertyFilter.empty;
  List<PropertyModel> _rawResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  // Bumped on every search so a slow, older response can't overwrite the
  // results of a newer one.
  int _requestId = 0;

  // Server results narrowed and sorted locally, so the filter is honoured
  // even when the server only did a plain keyword/category lookup.
  List<PropertyModel> get searchProperties => _filter.apply(_rawResults);

  bool get _hasQuery =>
      searchController.text.trim().isNotEmpty || _filter.isActive;

  // Search-alert state for the current query.
  bool _savingAlert = false;
  bool _alertSaved = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null || widget.initialKeyword.isNotEmpty) {
      _filter = widget.initialFilter ?? PropertyFilter.empty;
      searchController.text = widget.initialKeyword;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
    }
  }

  Future<void> _saveAlert() async {
    final user = context.read<UsermodelProvider>().getUserModel();
    if (user == null) {
      showToast('Log in to get search alerts');
      goTo(context, const LoginScreen(fromNav: false), false);
      return;
    }
    setState(() => _savingAlert = true);
    final error = await SearchAlertsService.create(
        user.id, _filter, searchController.text);
    if (!mounted) return;
    setState(() {
      _savingAlert = false;
      _alertSaved = error == null;
    });
    showToast(error ?? "Alert on - we'll notify you about new matches");
  }

  // "Get alerts for this search": shown for any active search/filter, and
  // most useful when there are no results yet.
  Widget _alertCard(AppPalette palette, {required bool noResults}) {
    const gold = Color(0xFFE8A93B);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _alertSaved
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _alertSaved
                      ? 'Alert is on'
                      : noResults
                          ? 'Nothing yet? Get notified.'
                          : 'Get alerts for this search',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _alertSaved
                      ? "We'll notify you when a new listing matches."
                      : _filter.describe(searchController.text),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: palette.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!_alertSaved)
            ElevatedButton(
              onPressed: _savingAlert ? null : _saveAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primaryFill,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _savingAlert
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Turn on'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onKeywordChanged(String _) {
    setState(() {}); // show/hide the clear button immediately
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    final keyword = searchController.text.trim();
    _alertSaved = false; // a changed search is a new potential alert
    if (!_hasQuery) {
      _requestId++;
      setState(() {
        _rawResults = [];
        _isSearching = false;
      });
      return;
    }
    final id = ++_requestId;
    setState(() => _isSearching = true);
    List<PropertyModel> results = [];
    try {
      results = _filter.isActive
          ? await _fetchFiltered(keyword)
          : await _fetchByKeyword(keyword);
    } catch (e) {
      debugPrint('Property search failed: $e');
    }
    if (!mounted || id != _requestId) return;
    setState(() {
      _rawResults = results;
      _isSearching = false;
    });
  }

  List<PropertyModel> _parse(dynamic data) => [
        for (final item in (data as List)) PropertyModel.fromMap(item),
      ];

  Future<List<PropertyModel>> _fetchByKeyword(String keyword) async {
    final response = await Dio().post(endPoint('search-property.php'),
        data: FormData.fromMap({'keyword': keyword}));
    if (response.data['status'] == 'Success') {
      return _parse(response.data['data']);
    }
    return [];
  }

  // Asks the server's `advanced_filter` endpoint first. A server without it
  // answers 'unauthorized' (or runs a plain keyword search), so fall back to
  // gathering candidates by keyword or by category and filtering locally.
  Future<List<PropertyModel>> _fetchFiltered(String keyword) async {
    try {
      final response = await Dio().post(endPoint('search-property.php'),
          data: FormData.fromMap(_filter.toFormFields(keyword)));
      if (response.data is Map && response.data['status'] == 'Success') {
        return _parse(response.data['data']);
      }
    } catch (e) {
      debugPrint('advanced_filter unavailable, filtering locally: $e');
    }
    if (keyword.isNotEmpty) return _fetchByKeyword(keyword);

    final categories = _filter.categories.isNotEmpty
        ? _filter.categories.toList()
        : houseTypes.map((h) => h.type).toList();
    final lists = await Future.wait(
        categories.map((c) => DbServices.getPropertiesByCategories(c, 50)));
    final seen = <String>{};
    return [
      for (final list in lists)
        for (final p in list)
          if (seen.add(p.id.toString())) p,
    ];
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final result = await showAdvancedFilterSheet(context, _filter);
    if (result == null || !mounted) return;
    setState(() => _filter = result);
    _runSearch();
  }

  void _updateFilter(PropertyFilter next) {
    setState(() => _filter = next);
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: palette.paper,
        body: SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 50),
              searchWidget(),
              if (_filter.isActive || _filter.sort != SortOption.newest)
                _activeFilterChips(palette),
              const SizedBox(height: 8),
              Divider(height: 1, color: palette.border),
              _resultsBody(palette),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultsBody(AppPalette palette) {
    if (_isSearching) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child:
              CircularProgressIndicator(strokeWidth: 2, color: palette.accent),
        ),
      );
    }
    if (!_hasQuery) {
      return _message(
        palette,
        Icons.travel_explore_rounded,
        'Find your next place',
        'Search by area, agent or type — or tap the filter button to narrow '
            'by price, rooms and location.',
      );
    }
    final results = searchProperties;
    if (results.isEmpty) {
      return Column(
        children: [
          _alertCard(palette, noResults: true),
          _message(
            palette,
            Icons.search_off_rounded,
            'No properties match',
            _filter.isActive
                ? 'Try removing a filter or widening the price range.'
                : 'Try a different keyword.',
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _alertCard(palette, noResults: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
          child: Text(
            '${results.length} propert${results.length == 1 ? 'y' : 'ies'} found',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: palette.ink,
            ),
          ),
        ),
        RecommendedWidget(properties: results),
      ],
    );
  }

  Widget _message(
      AppPalette palette, IconData icon, String title, String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.primaryFill.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: palette.accent),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              )),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: palette.inkSoft)),
        ],
      ),
    );
  }

  // One removable chip per active filter group, plus "Clear all".
  Widget _activeFilterChips(AppPalette palette) {
    final f = _filter;
    String naira(int v) => '₦${NumberFormat.compact().format(v)}';
    final chips = <MapEntry<String, PropertyFilter>>[
      if (f.categories.isNotEmpty)
        MapEntry(
            f.categories.length == 1
                ? f.categories.first
                : '${f.categories.length} types',
            f.copyWith(categories: {})),
      if (f.minPrice != null || f.maxPrice != null)
        MapEntry(
            f.minPrice == null
                ? 'Up to ${naira(f.maxPrice!)}'
                : f.maxPrice == null
                    ? '${naira(f.minPrice!)}+'
                    : '${naira(f.minPrice!)} – ${naira(f.maxPrice!)}',
            f.copyWith(minPrice: () => null, maxPrice: () => null)),
      if (f.minRooms > 0)
        MapEntry('${f.minRooms}+ beds', f.copyWith(minRooms: 0)),
      if (f.minBathrooms > 0)
        MapEntry('${f.minBathrooms}+ baths', f.copyWith(minBathrooms: 0)),
      if (f.state != null || f.city != null || f.community.trim().isNotEmpty)
        MapEntry(
            [f.community.trim(), f.city, f.state]
                .where((e) => e != null && e.isNotEmpty)
                .join(', '),
            f.copyWith(state: () => null, city: () => null, community: '')),
      if (f.media != MediaFilter.any)
        MapEntry(f.media == MediaFilter.videos ? 'Video tours' : 'Photos',
            f.copyWith(media: MediaFilter.any)),
      if (f.sort != SortOption.newest)
        MapEntry(f.sort == SortOption.priceLowHigh ? 'Price ↑' : 'Price ↓',
            f.copyWith(sort: SortOption.newest)),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(chip.key),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                ),
                backgroundColor: palette.primaryFill.withValues(alpha: 0.1),
                side: BorderSide(color: palette.accent.withValues(alpha: 0.35)),
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.compact,
                deleteIcon: const Icon(Icons.close_rounded, size: 15),
                deleteIconColor: palette.accent,
                onPressed: _openFilters,
                onDeleted: () => _updateFilter(chip.value),
              ),
            ),
          TextButton(
            onPressed: () => _updateFilter(PropertyFilter.empty),
            child: Text('Clear all',
                style: TextStyle(
                    color: palette.inkSoft, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _webFilterButton() {
    final count = _filter.activeCount;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: OutlinedButton.icon(
        onPressed: _openFilters,
        icon: const Icon(Icons.tune_rounded, size: 18),
        label: const Text('Filters'),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    final results = searchProperties;
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => goBack(context),
                            child: const Icon(Icons.arrow_back,
                                color: AppColors.textDark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            textCapitalization: TextCapitalization.sentences,
                            controller: searchController,
                            onChanged: _onKeywordChanged,
                            decoration: const InputDecoration(
                              hintText: 'Search properties...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _webFilterButton(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      )
                    else if (results.isEmpty)
                      EmptyState(
                        icon: Icons.search_off_rounded,
                        title: _hasQuery
                            ? 'No properties match'
                            : 'Search for a property',
                        message: _hasQuery
                            ? 'Try removing a filter or a different keyword'
                            : 'Results will appear here',
                      )
                    else
                      WebPropertyGrid(
                        properties: results,
                        onTap: (p) => goTo(
                            context, HouseDetailsScreen(property: p), false),
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

  Widget searchWidget() {
    final palette = context.palette;
    final count = _filter.activeCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => goBack(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: palette.ink),
          ),
          Expanded(
            child: SizedBox(
              height: 50,
              child: TextFormField(
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                controller: searchController,
                onChanged: _onKeywordChanged,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _runSearch(),
                style: TextStyle(color: palette.ink),
                decoration: InputDecoration(
                  hintText: 'Search area, agent or type…',
                  isDense: true,
                  filled: true,
                  fillColor: palette.card,
                  hintStyle: TextStyle(color: grey, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: palette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: palette.accent, width: 1.5),
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: palette.accent),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: palette.inkMuted),
                          onPressed: () {
                            searchController.clear();
                            _runSearch();
                          },
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter button: filled once any filter is active, with a count
          // badge, so it's obvious results are being narrowed.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _openFilters,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: count > 0 ? palette.primaryFill : palette.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: count > 0 ? palette.primaryFill : palette.border,
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: count > 0 ? Colors.white : palette.accent,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8A93B),
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.paper, width: 2),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
