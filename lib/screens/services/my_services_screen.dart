import 'package:cached_network_image/cached_network_image.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/house_type_model.dart';
import 'package:eafind/screens/services/list_service_screen.dart';
import 'package:eafind/services/service_providers_service.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:flutter/material.dart';

// A provider's own service listings: see them, add another, remove one.
class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({Key? key}) : super(key: key);

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  List<ServiceProvider>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await ServiceProvidersService.mine();
    if (!mounted) return;
    setState(() {
      _items = r.data ?? [];
      _error = r.error;
    });
  }

  Future<void> _add() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ListServiceScreen()),
    );
    if (added == true) _load();
  }

  Future<void> _remove(ServiceProvider s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this service?'),
        content: Text('"${s.businessName}" will no longer be shown to customers.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove',
                  style: TextStyle(color: Color(0xFFD64545)))),
        ],
      ),
    );
    if (ok != true) return;
    final r = await ServiceProvidersService.delete(s.id);
    if (!mounted) return;
    if (r.ok) {
      setState(() => _items = _items!.where((x) => x.id != s.id).toList());
      showToast('Service removed');
    } else {
      showErrorSnackbar(r.error!, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final items = _items;
    return Scaffold(
      backgroundColor: palette.page,
      appBar: AppBar(
        backgroundColor: palette.page,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.ink),
        title: Text('My services',
            style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.primaryFill,
        foregroundColor: Colors.white,
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('List a service'),
      ),
      body: items == null
          ? Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: palette.accent))
          : RefreshIndicator(
              color: palette.accent,
              onRefresh: _load,
              child: items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(36, 90, 36, 0),
                      children: [
                        Icon(Icons.handyman_rounded,
                            size: 56, color: palette.inkMuted),
                        const SizedBox(height: 14),
                        Text(
                            _error != null
                                ? _error!
                                : 'You haven\'t listed a service yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: palette.ink)),
                        const SizedBox(height: 6),
                        Text(
                            'Movers, cleaners, painters, electricians and more get requests from people moving home.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: palette.inkSoft)),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _tile(palette, items[i]),
                    ),
            ),
    );
  }

  Widget _tile(AppPalette palette, ServiceProvider s) {
    final info = homeServiceInfo[s.category];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: s.images.isEmpty
                  ? Container(color: palette.tile)
                  : CachedNetworkImage(imageUrl: s.images.first, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(info?.icon ?? Icons.handyman_rounded,
                        size: 13, color: info?.color ?? palette.accent),
                    const SizedBox(width: 4),
                    Text(s.category,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: info?.color ?? palette.accent)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(s.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink)),
                Text(s.areas,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: palette.inkSoft)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => _remove(s),
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFD64545)),
          ),
        ],
      ),
    );
  }
}
