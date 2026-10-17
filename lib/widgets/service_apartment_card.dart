import 'package:eafind/theme/app_palette.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eafind/models/house_type_model.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/screens/house_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:eafind/widgets/save_button.dart';
import 'package:intl/intl.dart';

import '../const/constant.dart';

// Hotel-style stay card for the home screen's Service Apartments carousel:
// big photo with a frosted nightly-price tag, amenity icons, room counts
// and a "Book a stay" button. Fills the width it's given.
class ServiceApartmentCard extends StatelessWidget {
  final PropertyModel property;
  const ServiceApartmentCard({Key? key, required this.property})
      : super(key: key);

  // Kept for callers that size cards themselves.
  static const double width = 270;

  static const _gold = Color(0xFFF7821B);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final amenities = property.requirements.whereType<String>().toList();
    final shown = amenities.take(4).toList();
    final extra = amenities.length - shown.length;
    final location = [property.community, property.city]
        .map((e) => (e ?? '').toString().trim())
        .where((e) => e.isNotEmpty && e != 'Unknown')
        .join(', ');

    return GestureDetector(
      onTap: () => goTo(context, HouseDetailsScreen(property: property), false),
      child: Container(
        margin: const EdgeInsets.fromLTRB(6, 4, 6, 12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _photo(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title.isNotEmpty
                        ? property.title
                        : 'Service apartment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 13, color: palette.inkMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location.isEmpty ? property.location : location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: palette.inkSoft),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _spec(
                          context,
                          Icons.king_bed_rounded,
                          property.rooms == 0
                              ? 'Studio'
                              : '${property.rooms} bed'),
                      const SizedBox(width: 6),
                      _spec(context, Icons.bathtub_rounded,
                          '${property.bathrooms} bath'),
                      const Spacer(),
                      // Amenity icons, overlapping like an avatar stack.
                      SizedBox(
                        height: 28,
                        width: shown.isEmpty
                            ? 0
                            : 28.0 +
                                (shown.length - 1 + (extra > 0 ? 1 : 0)) * 18,
                        child: Stack(
                          children: [
                            for (var i = 0; i < shown.length; i++)
                              Positioned(
                                left: i * 18.0,
                                child: _amenityDot(context,
                                    icon:
                                        serviceApartmentAmenityIcon(shown[i])),
                              ),
                            if (extra > 0)
                              Positioned(
                                left: shown.length * 18.0,
                                child: _amenityDot(context, label: '+$extra'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: [
                        palette.primaryFill,
                        Color.lerp(palette.primaryFill, Colors.black, 0.3)!,
                      ]),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.nights_stay_rounded,
                              size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Book a stay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photo(BuildContext context) {
    final palette = context.palette;
    final hasImage = property.isVideo != 1 && property.images.isNotEmpty;
    final amount = num.tryParse(property.amount.toString()) ?? 0;
    Widget fallback() => Container(
          color: palette.tile,
          child: Icon(
            property.isVideo == 1
                ? Icons.videocam_outlined
                : Icons.apartment_rounded,
            size: 40,
            color: palette.inkMuted,
          ),
        );
    return Stack(
      fit: StackFit.expand,
      children: [
        hasImage
            ? CachedNetworkImage(
                imageUrl: property.images[0],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: palette.tile),
                errorWidget: (_, __, ___) => fallback(),
              )
            : fallback(),
        // Bottom fade so the price tag reads on any photo.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.45, 1],
              colors: [Colors.transparent, Color(0x99000000)],
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.room_service_rounded, size: 12, color: _gold),
                SizedBox(width: 4),
                Text(
                  'Fully serviced',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: SaveButton(property: property, size: 36),
        ),
        if (property.images.length > 1 && property.isVideo != 1)
          Positioned(
            bottom: 14,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_rounded,
                      size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${property.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Frosted nightly price tag.
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '₦${NumberFormat('#,##0').format(amount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: ' / night',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _spec(BuildContext context, IconData icon, String label) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: palette.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amenityDot(BuildContext context, {IconData? icon, String? label}) {
    final palette = context.palette;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: palette.primaryFill.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: palette.card, width: 2),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 13, color: palette.accent)
            : Text(
                label ?? '',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: palette.accent,
                ),
              ),
      ),
    );
  }
}
