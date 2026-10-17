import 'package:eafind/theme/app_palette.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/screens/all_reels_video_screen.dart';
import 'package:flutter/material.dart';
import 'package:eafind/widgets/save_button.dart';
import 'package:intl/intl.dart';

import '../const/constant.dart';
import '../screens/house_details_screen.dart';
import '../screens/view_story_screen.dart';

// Featured property card: a full-bleed photo with a dark gradient rising from
// the bottom, so the title, location, price and room counts sit on the image
// itself instead of in a flat grey strip.
class HouseWidgetProfile extends StatelessWidget {
  final PropertyModel property;
  const HouseWidgetProfile({Key? key, required this.property})
      : super(key: key);

  static const _gold = Color(0xFFF7821B);
  static const _cardWidth = 210.0;
  static const _cardHeight = 260.0;

  @override
  Widget build(BuildContext context) {
    if (property.isVideo == 1) {
      return Container(
        height: _cardHeight,
        width: _cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        // A single video inside the featured row: don't let its own
        // horizontal list capture the row's swipe.
        child: AllReelsVideoScreen(
          allProperties: [property],
          physics: const NeverScrollableScrollPhysics(),
        ),
      );
    }

    final palette = context.palette;
    return GestureDetector(
      onTap: () =>
          goTo(context, HouseDetailsScreen(property: property), false),
      child: Container(
        height: _cardHeight,
        width: _cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: palette.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _photo(context),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.3, 0.55, 1.0],
                    colors: [
                      Color(0x66000000),
                      Colors.transparent,
                      Color(0x33000000),
                      Color(0xE6000000),
                    ],
                  ),
                ),
              ),
              Positioned(top: 10, left: 10, child: _featuredBadge()),
              Positioned(
                top: 6,
                right: 6,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: SaveButton(property: property, size: 30),
                    ),
                    _glassButton(
                      icon: Icons.more_horiz_rounded,
                      onTap: () => showReportModal(property, context),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _details(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photo(BuildContext context) {
    if (property.images.isEmpty) {
      return Container(
        color: context.palette.tile,
        child: Icon(Icons.home_work_outlined,
            size: 40, color: context.palette.inkMuted),
      );
    }
    return CachedNetworkImage(
      imageUrl: property.images[0],
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: context.palette.tile,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.palette.accent,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: context.palette.tile,
        child: Icon(Icons.broken_image_outlined,
            color: context.palette.inkMuted),
      ),
    );
  }

  Widget _featuredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDB813), _gold],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star_rounded, size: 12, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'FEATURED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _details(BuildContext context) {
    final location = [property.community, property.city]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (property.category.isNotEmpty)
              Flexible(child: _categoryTag(property.category)),
            const Spacer(),
            if (property.images.length > 1) _photoCount(context),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          property.title.isNotEmpty ? property.title : property.category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (location.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 12, color: Colors.white70),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(child: _priceTag(context)),
            const SizedBox(width: 6),
            if (property.rooms > 0) _spec(Icons.bed_rounded, property.rooms),
            if (property.bathrooms > 0) ...[
              const SizedBox(width: 4),
              _spec(Icons.bathtub_rounded, property.bathrooms),
            ],
          ],
        ),
      ],
    );
  }

  Widget _categoryTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _photoCount(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          goTo(context, ViewStoryScreen(images: property.images), false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_rounded,
                size: 11, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              '${property.images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.palette.primaryFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '₦${NumberFormat.compact().format(property.amount)}${property.priceSuffix}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _spec(IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
