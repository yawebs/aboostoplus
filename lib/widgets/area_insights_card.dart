import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:flutter/material.dart';

// AI-generated neighbourhood briefing for a listing's area (electricity,
// security, roads, water, flooding, transport, landmarks, pros/cons).
// Generated server-side by area-insights.php and cached per area.
class AreaInsightsCard extends StatefulWidget {
  final String community;
  final String city;
  final String state;
  // What the user is looking for - tunes the AI's perspective.
  final String category;

  // For a listing's area (house details screen).
  AreaInsightsCard({Key? key, required PropertyModel property})
      : community = (property.community ?? '').toString(),
        city = (property.city ?? '').toString(),
        state = property.location,
        category = property.category,
        super(key: key);

  // For any area (standalone Explore an area screen).
  const AreaInsightsCard.forArea({
    Key? key,
    required this.community,
    required this.city,
    required this.state,
    this.category = 'home to rent or buy',
  }) : super(key: key);

  @override
  State<AreaInsightsCard> createState() => _AreaInsightsCardState();
}

class _AreaInsightsCardState extends State<AreaInsightsCard> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _failed = false;
  bool _expanded = false;

  // Results cached for this app session, so reopening a listing in the
  // same area doesn't refetch.
  static final Map<String, Map<String, dynamic>> _sessionCache = {};

  String get _areaKey =>
      '${widget.community}|${widget.city}|${widget.state}'.toLowerCase();

  String get _areaLabel {
    return [widget.community, widget.city]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != 'Unknown')
        .join(', ');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = _sessionCache[_areaKey];
    if (cached != null) {
      setState(() {
        _data = cached;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final response = await Dio().post(
        endPoint('area-insights.php'),
        data: FormData.fromMap({
          'community': widget.community,
          'city': widget.city,
          'state': widget.state,
          'category': widget.category,
        }),
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      );
      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final data = Map<String, dynamic>.from(body['data']);
        _sessionCache[_areaKey] = data;
        if (!mounted) return;
        setState(() {
          _data = data;
          _loading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Area insights failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primaryFill.withValues(alpha: 0.10),
            palette.card,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(palette),
            const SizedBox(height: 14),
            if (_loading)
              _loadingState(palette)
            else if (_failed || _data == null)
              _errorState(palette)
            else
              _content(palette, _data!),
          ],
        ),
      ),
    );
  }

  Widget _header(AppPalette palette) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              palette.primaryFill,
              const Color(0xFFF7821B),
            ]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI area insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: palette.ink,
                ),
              ),
              if (_areaLabel.isNotEmpty)
                Text(
                  _areaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: palette.inkSoft),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: palette.primaryFill.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'BETA',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: palette.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadingState(AppPalette palette) {
    Widget bar(double widthFactor) => FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: 11,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: palette.tile,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: palette.accent),
            ),
            const SizedBox(width: 8),
            Text(
              'Analysing the neighbourhood…',
              style: TextStyle(fontSize: 12.5, color: palette.inkSoft),
            ),
          ],
        ),
        const SizedBox(height: 12),
        bar(1),
        bar(0.9),
        bar(0.6),
      ],
    );
  }

  Widget _errorState(AppPalette palette) {
    return Row(
      children: [
        Icon(Icons.cloud_off_rounded, size: 18, color: palette.inkMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "Couldn't load insights for this area right now.",
            style: TextStyle(fontSize: 12.5, color: palette.inkSoft),
          ),
        ),
        TextButton(onPressed: _load, child: const Text('Retry')),
      ],
    );
  }

  List<Map<String, dynamic>> _list(dynamic v) => v is List
      ? [
          for (final e in v)
            if (e is Map) Map<String, dynamic>.from(e)
        ]
      : [];

  List<String> _strings(dynamic v) => v is List
      ? [
          for (final e in v)
            if (e.toString().trim().isNotEmpty) e.toString()
        ]
      : [];

  Widget _content(AppPalette palette, Map<String, dynamic> d) {
    final factors = _list(d['factors']);
    final landmarks = _list(d['landmarks']);
    final goodFor = _strings(d['good_for']);
    final watchOut = _strings(d['watch_out']);
    final tips = _strings(d['tips']);
    final headline = (d['headline'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headline.isNotEmpty) ...[
          Text(
            headline,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          (d['overview'] ?? '').toString(),
          style: TextStyle(fontSize: 13.5, height: 1.5, color: palette.inkSoft),
        ),
        if (factors.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Two-column grid of factor tiles.
          LayoutBuilder(builder: (context, c) {
            final tileWidth = (c.maxWidth - 10) / 2;
            final visible =
                _expanded ? factors : factors.take(4).toList(growable: false);
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final f in visible)
                  SizedBox(width: tileWidth, child: _factorTile(palette, f)),
              ],
            );
          }),
        ],
        // Always visible (not behind "see more") - fibre is a deciding
        // factor for a lot of renters.
        if (d['mtn_fiberx'] is Map) ...[
          const SizedBox(height: 12),
          _fiberXStrip(palette, Map<String, dynamic>.from(d['mtn_fiberx'])),
        ],
        if (_expanded) ...[
          if (landmarks.isNotEmpty) ...[
            const SizedBox(height: 18),
            _subheading(palette, 'Nearby landmarks'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in landmarks) _landmarkChip(palette, l),
              ],
            ),
          ],
          if (goodFor.isNotEmpty) ...[
            const SizedBox(height: 18),
            _bulletGroup(palette, 'Great for', goodFor,
                Icons.thumb_up_alt_rounded, const Color(0xFF2E9E5B)),
          ],
          if (watchOut.isNotEmpty) ...[
            const SizedBox(height: 14),
            _bulletGroup(palette, 'Watch out for', watchOut,
                Icons.warning_amber_rounded, const Color(0xFFF7821B)),
          ],
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 14),
            _bulletGroup(palette, 'Tips before you commit', tips,
                Icons.lightbulb_rounded, palette.accent),
          ],
        ],
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: palette.accent,
            ),
            label: Text(
              _expanded ? 'Show less' : 'See landmarks, pros & tips',
              style:
                  TextStyle(color: palette.accent, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 13, color: palette.inkMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'AI-generated from general knowledge of the area and may be '
                'out of date. Always verify on an inspection.',
                style: TextStyle(
                    fontSize: 11, height: 1.4, color: palette.inkMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static const Map<String, IconData> _factorIcons = {
    'power': Icons.bolt_rounded,
    'internet': Icons.wifi_rounded,
    'security': Icons.shield_rounded,
    'roads': Icons.add_road_rounded,
    'water': Icons.water_drop_rounded,
    'flooding': Icons.flood_rounded,
    'transport': Icons.directions_bus_rounded,
  };

  Color _scoreColor(int score) {
    if (score >= 4) return const Color(0xFF2E9E5B);
    if (score == 3) return const Color(0xFFF7821B);
    return const Color(0xFFD64545);
  }

  Widget _factorTile(AppPalette palette, Map<String, dynamic> f) {
    final raw = f['score'];
    final score = raw is num ? raw.round().clamp(1, 5) : null;
    final color = score == null ? palette.inkMuted : _scoreColor(score);
    final icon = _factorIcons[f['key']] ?? Icons.insights_rounded;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (f['label'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 5-segment meter; empty with "No data" when the AI wasn't sure.
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: i < 5 ? 3 : 0),
                    decoration: BoxDecoration(
                      color: score != null && i <= score ? color : palette.tile,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            score == null ? 'No reliable data' : '$score / 5',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (f['summary'] ?? '').toString(),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(fontSize: 11.5, height: 1.4, color: palette.inkSoft),
          ),
        ],
      ),
    );
  }

  // MTN FiberX availability, in MTN's yellow, with an honest status label.
  Widget _fiberXStrip(AppPalette palette, Map<String, dynamic> fx) {
    const mtnYellow = Color(0xFFFFCB05);
    final status = (fx['status'] ?? 'unknown').toString().toLowerCase();
    final summary = (fx['summary'] ?? '').toString();

    final String label;
    final Color color;
    final IconData icon;
    switch (status) {
      case 'available':
        label = 'Available';
        color = const Color(0xFF2E9E5B);
        icon = Icons.check_circle_rounded;
        break;
      case 'likely':
        label = 'Likely available';
        color = const Color(0xFF3A86E0);
        icon = Icons.wifi_rounded;
        break;
      case 'unlikely':
        label = 'Unlikely';
        color = const Color(0xFFD64545);
        icon = Icons.wifi_off_rounded;
        break;
      default:
        label = 'Not confirmed';
        color = palette.inkMuted;
        icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mtnYellow.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mtnYellow.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: mtnYellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.router_rounded,
                size: 22, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MTN FiberX',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: color),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: TextStyle(
                        fontSize: 12, height: 1.4, color: palette.inkSoft),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Fibre coverage varies street by street - confirm with MTN '
                  'for this exact address.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.35,
                    color: palette.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subheading(AppPalette palette, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: palette.ink,
        ),
      );

  static const Map<String, IconData> _landmarkIcons = {
    'school': Icons.school_rounded,
    'hospital': Icons.local_hospital_rounded,
    'market': Icons.storefront_rounded,
    'mall': Icons.local_mall_rounded,
    'worship': Icons.church_rounded,
    'park': Icons.park_rounded,
    'bank': Icons.account_balance_rounded,
    'government': Icons.account_balance_outlined,
    'transport': Icons.directions_bus_rounded,
  };

  Widget _landmarkChip(AppPalette palette, Map<String, dynamic> l) {
    final icon = _landmarkIcons[l['type']] ?? Icons.place_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              (l['name'] ?? '').toString(),
              style: TextStyle(fontSize: 12, color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletGroup(AppPalette palette, String title, List<String> items,
      IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            _subheading(palette, title),
          ],
        ),
        const SizedBox(height: 6),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 7, right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                        fontSize: 12.5, height: 1.45, color: palette.inkSoft),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
