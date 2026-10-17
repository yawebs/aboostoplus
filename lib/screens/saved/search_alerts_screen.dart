import 'package:eafind/const/constant.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/services/search_alerts_service.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/widgets/search_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Manage saved searches: pause/resume with the switch, swipe to delete, tap
// to run the search again.
class SearchAlertsScreen extends StatefulWidget {
  const SearchAlertsScreen({Key? key}) : super(key: key);

  @override
  State<SearchAlertsScreen> createState() => _SearchAlertsScreenState();
}

class _SearchAlertsScreenState extends State<SearchAlertsScreen> {
  List<SearchAlert>? _alerts;
  bool _failed = false;

  String? get _userId =>
      context.read<UsermodelProvider>().getUserModel()?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _userId;
    if (uid == null) {
      setState(() => _alerts = []);
      return;
    }
    final list = await SearchAlertsService.list(uid);
    if (!mounted) return;
    setState(() {
      _failed = list == null;
      _alerts = list ?? [];
    });
  }

  Future<void> _toggle(SearchAlert a) async {
    final uid = _userId;
    if (uid == null) return;
    final active = await SearchAlertsService.toggle(uid, a.id);
    if (!mounted || active == null) return;
    setState(() {
      _alerts = [
        for (final x in _alerts!)
          x.id == a.id
              ? SearchAlert(
                  id: x.id,
                  label: x.label,
                  filter: x.filter,
                  keyword: x.keyword,
                  active: active,
                  createdAt: x.createdAt)
              : x,
      ];
    });
  }

  Future<void> _delete(SearchAlert a) async {
    final uid = _userId;
    if (uid == null) return;
    setState(() => _alerts = _alerts!.where((x) => x.id != a.id).toList());
    final ok = await SearchAlertsService.delete(uid, a.id);
    if (!ok && mounted) {
      showToast('Could not delete the alert');
      _load();
    }
  }

  void _run(SearchAlert a) {
    goTo(
      context,
      SearchSheet(initialFilter: a.filter, initialKeyword: a.keyword),
      false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final alerts = _alerts;
    return Scaffold(
      backgroundColor: palette.page,
      appBar: AppBar(
        backgroundColor: palette.page,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.ink),
        title: Text('Search alerts',
            style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.primaryFill,
        foregroundColor: Colors.white,
        onPressed: () => goTo(context, const SearchSheet(), false),
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('New alert'),
      ),
      body: alerts == null
          ? Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: palette.accent))
          : RefreshIndicator(
              color: palette.accent,
              onRefresh: _load,
              child: alerts.isEmpty
                  ? ListView(children: [_empty(palette)])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: alerts.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => i == 0
                          ? Text(
                              'Swipe left to delete · ${alerts.length}/10 alerts',
                              style: TextStyle(
                                  fontSize: 12.5, color: palette.inkSoft),
                            )
                          : _tile(palette, alerts[i - 1]),
                    ),
            ),
    );
  }

  Widget _tile(AppPalette palette, SearchAlert a) {
    const gold = Color(0xFFF7821B);
    return Dismissible(
      key: ValueKey(a.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(a),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFD64545),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Material(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _run(a),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (a.active ? gold : palette.inkMuted)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    a.active
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_paused_rounded,
                    color: a.active ? gold : palette.inkMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: a.active ? palette.ink : palette.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        a.active
                            ? 'Notifying you about new matches'
                            : 'Paused',
                        style: TextStyle(fontSize: 12, color: palette.inkSoft),
                      ),
                      if (a.createdAt != null)
                        Text(
                          'Created ${DateFormat('d MMM yyyy').format(a.createdAt!)}',
                          style: TextStyle(
                              fontSize: 11, color: palette.inkMuted),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: a.active,
                  activeThumbColor: palette.primaryFill,
                  onChanged: (_) => _toggle(a),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(AppPalette palette) {
    const gold = Color(0xFFF7821B);
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 80, 36, 0),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gold.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                size: 42, color: gold),
          ),
          const SizedBox(height: 18),
          Text(
            _failed
                ? "Couldn't load your alerts"
                : _userId == null
                    ? 'Log in to use search alerts'
                    : 'Never miss the right home',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: palette.ink),
          ),
          const SizedBox(height: 6),
          Text(
            _failed
                ? 'Pull down to try again.'
                : 'Search or filter for what you want, then tap "Turn on" on '
                    'the alert card. We\'ll notify you the moment a matching '
                    'home is listed.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5, height: 1.45, color: palette.inkSoft),
          ),
        ],
      ),
    );
  }
}
