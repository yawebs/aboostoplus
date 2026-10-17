import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_filter.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/utility/states_data.dart';
import 'package:eafind/widgets/area_insights_card.dart';
import 'package:eafind/widgets/search_sheet.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Standalone "Explore an area": pick any neighbourhood and get the same AI
// briefing shown on listings (electricity, security, roads, water, flooding,
// internet & MTN FiberX, landmarks, pros/cons, tips).
class ExploreAreaScreen extends StatefulWidget {
  const ExploreAreaScreen({Key? key}) : super(key: key);

  @override
  State<ExploreAreaScreen> createState() => _ExploreAreaScreenState();
}

class _Area {
  final String community;
  final String city;
  final String state;
  const _Area(this.community, this.city, this.state);

  String get label => [community, city]
      .where((e) => e.trim().isNotEmpty)
      .join(', ');
  String get encoded => '$community|$city|$state';
  static _Area? decode(String s) {
    final p = s.split('|');
    return p.length == 3 ? _Area(p[0], p[1], p[2]) : null;
  }

  @override
  bool operator ==(Object o) => o is _Area && o.encoded == encoded;
  @override
  int get hashCode => encoded.hashCode;
}

class _ExploreAreaScreenState extends State<ExploreAreaScreen> {
  static const _recentKey = 'explore_recent_areas';

  // Popular picks - names match lib/utility/states_data.dart exactly.
  static const _popular = [
    _Area('Lekki Phase 1', 'Eti Osa', 'Lagos State'),
    _Area('Woji', 'Obio/Akpor', 'Rivers State'),
    _Area('Gwarinpa', 'Abuja Municipal Area Council', 'Federal Capital Territory'),
    _Area('Ikeja GRA', 'Ikeja', 'Lagos State'),
    _Area('Rumuokoro', 'Obio/Akpor', 'Rivers State'),
    _Area('GRA Phase 2', 'Port Harcourt', 'Rivers State'),
    _Area('Independence Layout', 'Enugu North', 'Enugu State'),
    _Area('Bodija', 'Ibadan North', 'Oyo State'),
  ];

  final _community = TextEditingController();
  final _scroll = ScrollController();
  final _resultKey = GlobalKey();
  String? _state;
  String? _city;
  _Area? _area; // the area currently shown
  List<_Area> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _community.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_recentKey) ?? [];
      if (!mounted) return;
      setState(() => _recent = list.map(_Area.decode).whereType<_Area>().toList());
    } catch (_) {}
  }

  Future<void> _remember(_Area a) async {
    final next = [a, ..._recent.where((x) => x != a)].take(5).toList();
    setState(() => _recent = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentKey, next.map((e) => e.encoded).toList());
    } catch (_) {}
  }

  List<String> get _cities {
    for (final s in allStatesAndCities) {
      if (s.state == _state) return s.areas.cast<String>();
    }
    return [];
  }

  void _explore([_Area? preset]) {
    FocusScope.of(context).unfocus();
    if (preset != null) {
      _state = preset.state;
      _city = _cities.contains(preset.city) ? preset.city : null;
      _community.text = preset.community;
    }
    final community = _community.text.trim();
    if (_state == null) {
      showToast('Choose a state');
      return;
    }
    if (community.isEmpty && _city == null) {
      showToast('Enter a neighbourhood or choose a city');
      return;
    }
    final area = _Area(community, _city ?? '', _state!);
    setState(() => _area = area);
    _remember(area);
    // Scroll the result into view once it's laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic);
      }
    });
  }

  void _seeHomes(_Area a) {
    goTo(
      context,
      SearchSheet(
        initialFilter: PropertyFilter(
          state: a.state,
          city: a.city.isEmpty ? null : a.city,
          community: a.community,
        ),
      ),
      false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: palette.page,
        body: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(child: _hero(palette)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _form(palette),
              ),
            ),
            if (_area == null) ...[
              if (_recent.isNotEmpty)
                SliverToBoxAdapter(
                    child: _chips(palette, 'RECENT', _recent, Icons.history_rounded)),
              SliverToBoxAdapter(
                  child: _chips(palette, 'POPULAR AREAS', _popular,
                      Icons.trending_up_rounded)),
            ] else
              SliverToBoxAdapter(
                child: Padding(
                  key: _resultKey,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Keyed by area so a new search reloads the card.
                      AreaInsightsCard.forArea(
                        key: ValueKey(_area!.encoded),
                        community: _area!.community,
                        city: _area!.city,
                        state: _area!.state,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _seeHomes(_area!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.primaryFill,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.home_work_rounded, size: 19),
                          label: Text(
                            'See homes in ${_area!.community.isNotEmpty ? _area!.community : _area!.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() {
                          _area = null;
                          _community.clear();
                        }),
                        child: const Text('Explore another area'),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(height: 30 + MediaQuery.of(context).padding.bottom),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(AppPalette palette) {
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.45)!;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 6, 16, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primaryFill, deep],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () => goBack(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFDB813), Color(0xFFF7821B)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF161616), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Explore any neighbourhood',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Ask our AI about electricity, security, flooding, internet and MTN FiberX, before you move.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13.5,
                height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in const [
                '⚡ Power',
                '🛡️ Security',
                '🌧️ Flooding',
                '📶 Internet',
                '📍 Landmarks',
              ])
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(t,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(AppPalette palette, String label, IconData icon,
          {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: palette.card,
        prefixIcon: Icon(icon, size: 19, color: palette.accent),
        labelStyle: TextStyle(color: palette.inkSoft),
        hintStyle: TextStyle(color: palette.inkMuted, fontSize: 13.5),
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
      );

  Widget _form(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('state-$_state'),
          initialValue: _state,
          isExpanded: true,
          dropdownColor: palette.paper,
          style: TextStyle(color: palette.ink, fontSize: 15),
          decoration: _decoration(palette, 'State', Icons.map_rounded),
          items: [
            for (final s in allStatesAndCities)
              DropdownMenuItem(value: s.state, child: Text(s.state)),
          ],
          onChanged: (v) => setState(() {
            _state = v;
            _city = null;
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('city-$_state-$_city'),
          initialValue: _city,
          isExpanded: true,
          dropdownColor: palette.paper,
          style: TextStyle(color: palette.ink, fontSize: 15),
          decoration: _decoration(
              palette,
              _state == null ? 'City / LGA (pick a state first)' : 'City / LGA',
              Icons.location_city_rounded),
          items: [
            for (final c in _cities) DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged:
              _state == null ? null : (v) => setState(() => _city = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _community,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _explore(),
          style: TextStyle(color: palette.ink, fontSize: 15),
          decoration: _decoration(palette, 'Neighbourhood',
              Icons.signpost_rounded,
              hint: 'e.g. Woji, Lekki Phase 1, Gwarinpa'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _explore,
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primaryFill,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 19),
            label: const Text('Get AI insights',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _chips(
      AppPalette palette, String title, List<_Area> areas, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: palette.inkMuted),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: palette.inkMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in areas)
                ActionChip(
                  avatar: Icon(Icons.place_rounded,
                      size: 16, color: palette.accent),
                  label: Text(a.label),
                  labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.ink),
                  backgroundColor: palette.card,
                  side: BorderSide(color: palette.border),
                  shape: const StadiumBorder(),
                  onPressed: () => _explore(a),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
