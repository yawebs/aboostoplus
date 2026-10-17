import 'package:cached_network_image/cached_network_image.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/house_type_model.dart';
import 'package:eafind/screens/services/list_service_screen.dart';
import 'package:eafind/screens/services/moving_services_screen.dart';
import 'package:eafind/services/service_providers_service.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Home-feed "Book a service" section: category shortcuts plus a carousel of
// the newest providers, each with a Book button (quote request -> chat).
class HomeServicesSection extends StatefulWidget {
  const HomeServicesSection({Key? key}) : super(key: key);

  @override
  State<HomeServicesSection> createState() => _HomeServicesSectionState();
}

class _HomeServicesSectionState extends State<HomeServicesSection> {
  // Kept for the app session so scrolling the feed (which rebuilds this
  // section) doesn't refetch.
  static List<ServiceProvider>? _cache;
  List<ServiceProvider>? _providers = _cache;

  @override
  void initState() {
    super.initState();
    if (_cache == null) _load();
  }

  Future<void> _load() async {
    final r = await ServiceProvidersService.featured();
    if (!mounted) return;
    setState(() => _providers = _cache = r.data ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final providers = _providers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.primaryFill.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.handyman_rounded,
                    size: 16, color: palette.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Book a service',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: palette.accent)),
                    Text('Movers, cleaners & handymen near you',
                        style: TextStyle(fontSize: 12, color: palette.inkSoft)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    goTo(context, const MovingServicesScreen(), false),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('See all',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.accent)),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: palette.accent),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Category shortcuts
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            itemCount: homeServiceTypes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final type = homeServiceTypes[i];
              final info = homeServiceInfo[type]!;
              return GestureDetector(
                onTap: () => goTo(
                    context, ServiceProvidersScreen(category: type), false),
                child: SizedBox(
                  width: 74,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: info.color.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: info.color.withValues(alpha: 0.25)),
                        ),
                        child: Icon(info.icon, color: info.color, size: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _shortName(type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: palette.ink),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Newest providers
        if (providers == null)
          const SizedBox(
            height: 60,
            child: Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else if (providers.isEmpty)
          _emptyCta(palette)
        else
          SizedBox(
            height: 262,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
              itemCount: providers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _ProviderTile(provider: providers[i]),
            ),
          ),
      ],
    );
  }

  static String _shortName(String type) => const {
        'Moving & Haulage': 'Movers',
        'Power & Solar': 'Power',
      }[type] ??
      type;

  Widget _emptyCta(AppPalette palette) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.primaryFill.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.storefront_rounded, color: palette.accent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Providers are joining soon. Run a moving, cleaning or repair business? List it here.',
              style: TextStyle(fontSize: 12.5, height: 1.35, color: palette.ink),
            ),
          ),
          TextButton(
            onPressed: () => goTo(context, const ListServiceScreen(), false),
            child: const Text('List it'),
          ),
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final ServiceProvider provider;
  const _ProviderTile({required this.provider});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final p = provider;
    final info = homeServiceInfo[p.category];
    return GestureDetector(
      onTap: () => goTo(
          context, ServiceProvidersScreen(category: p.category), false),
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  p.images.isEmpty
                      ? Container(
                          color: (info?.color ?? palette.accent)
                              .withValues(alpha: 0.12),
                          child: Icon(info?.icon ?? Icons.handyman_rounded,
                              size: 36, color: info?.color ?? palette.accent),
                        )
                      : CachedNetworkImage(
                          imageUrl: p.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: palette.tile),
                          errorWidget: (_, __, ___) =>
                              Container(color: palette.tile),
                        ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(info?.icon ?? Icons.handyman_rounded,
                              size: 12, color: info?.color ?? palette.accent),
                          const SizedBox(width: 4),
                          Text(p.category,
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2A2A2A))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: palette.ink)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 12, color: palette.inkMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(p.areas,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.5, color: palette.inkSoft)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.startingPrice != null && p.startingPrice! > 0
                              ? 'From ₦${NumberFormat.compact().format(p.startingPrice)}'
                              : 'Get a quote',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.accent),
                        ),
                      ),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => showQuoteRequestSheet(context, p),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.primaryFill,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Book',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
