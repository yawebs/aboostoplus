import 'package:cached_network_image/cached_network_image.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/screens/house_details_screen.dart';
import 'package:eafind/services/providers/saved_homes_provider.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/widgets/save_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// The user's saved ("hearted") listings, newest first. Un-hearting a home
// removes it from the list immediately.
class SavedHomesScreen extends StatefulWidget {
  const SavedHomesScreen({Key? key}) : super(key: key);

  @override
  State<SavedHomesScreen> createState() => _SavedHomesScreenState();
}

class _SavedHomesScreenState extends State<SavedHomesScreen> {
  List<PropertyModel>? _homes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<SavedHomesProvider>().fetchSaved();
    if (mounted) setState(() => _homes = list);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final saved = context.watch<SavedHomesProvider>();
    // Hide homes un-hearted while this screen is open.
    final visible = _homes?.where(saved.isSaved).toList();

    return Scaffold(
      backgroundColor: palette.page,
      appBar: AppBar(
        backgroundColor: palette.page,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.ink),
        title: Text(
          'Saved homes',
          style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
        ),
      ),
      body: !saved.hasUser
          ? _empty(palette, 'Log in to see your saved homes',
              'Tap the heart on any listing to keep it here.')
          : visible == null
              ? Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: palette.accent),
                )
              : RefreshIndicator(
                  color: palette.accent,
                  onRefresh: _load,
                  child: visible.isEmpty
                      ? ListView(children: [
                          _empty(palette, 'No saved homes yet',
                              'Tap the ♡ on any listing to save it for later and compare.'),
                        ])
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 8, 16,
                              24 + MediaQuery.of(context).padding.bottom),
                          itemCount: visible.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => i == 0
                              ? Text(
                                  '${visible.length} saved home${visible.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                      fontSize: 13, color: palette.inkSoft),
                                )
                              : _SavedCard(property: visible[i - 1]),
                        ),
                ),
    );
  }

  Widget _empty(AppPalette palette, String title, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 90, 36, 0),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE5484D).withValues(alpha: 0.10),
            ),
            child: const Icon(Icons.favorite_rounded,
                size: 42, color: Color(0xFFE5484D)),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: palette.ink)),
          const SizedBox(height: 6),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: palette.inkSoft)),
        ],
      ),
    );
  }
}

class _SavedCard extends StatelessWidget {
  final PropertyModel property;
  const _SavedCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final p = property;
    final amount = num.tryParse(p.amount.toString().replaceAll(',', '')) ?? 0;
    final location = [p.community, p.city]
        .map((e) => (e ?? '').toString().trim())
        .where((e) => e.isNotEmpty && e != 'Unknown')
        .join(', ');

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => goTo(context, HouseDetailsScreen(property: p), false),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: p.images.isEmpty || p.isVideo == 1
                      ? Container(
                          color: palette.tile,
                          child: Icon(Icons.home_work_outlined,
                              color: palette.inkMuted),
                        )
                      : CachedNetworkImage(
                          imageUrl: p.images[0],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: palette.tile),
                          errorWidget: (_, __, ___) =>
                              Container(color: palette.tile),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.title.isNotEmpty ? p.title : p.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: palette.inkMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: palette.inkSoft),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '₦${NumberFormat('#,##0').format(amount)}${p.priceSuffix}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: palette.ink,
                      ),
                    ),
                  ],
                ),
              ),
              SaveButton(property: p, onImage: false, size: 42),
            ],
          ),
        ),
      ),
    );
  }
}
