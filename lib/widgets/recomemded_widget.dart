import 'package:eafind/theme/app_palette.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/screens/all_reels_video_screen.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/widgets/reactions_widget.dart';
import 'package:eafind/widgets/recomended_videos.dart';
import 'package:eafind/widgets/video_display_widget.dart';
import 'package:eafind/widgets/view_photo_widget.dart';
import 'package:flutter/material.dart';
import 'package:eafind/widgets/save_button.dart';
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../const/constant.dart';
import '../models/user_model.dart';
import '../providers/usermodel_provider.dart';
import 'agent_account_profile.dart';

class RecommendedWidget extends StatefulWidget {
  final List<PropertyModel> properties;
  RecommendedWidget({Key? key, required this.properties}) : super(key: key);

  @override
  State<RecommendedWidget> createState() => _RecommendedWidgetState();
}

class _RecommendedWidgetState extends State<RecommendedWidget> {
  ScrollController scrollController = ScrollController();
  UserModel? activeUser;

  getActiveUser() async {
    UserModel? _user =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    setState(() {
      activeUser = _user;
    });
  }

  inititState() {
    super.initState();
    getActiveUser();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.properties.length,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      primary: false,
      controller: scrollController,
      itemBuilder: ((context, index) {
        if (widget.properties.length > 3) {
          if (index == 4) {
            return Container(
              height: 390,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: black,
                borderRadius: appRadius(10.0),
                border: Border.all(color: context.palette.paper, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.video_collection,
                                color: white,
                              ),
                              w10(),
                              Text(
                                'Videos',
                                style: TextStyle(
                                    color: white, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                          GestureDetector(
                            onTap: () => goTo(
                                context,
                                RecommendedVideos(
                                    properties: widget.properties),
                                false),
                            child: Row(
                              children: [
                                Text(
                                  'See all',
                                  style: TextStyle(
                                      color: white,
                                      fontWeight: FontWeight.bold),
                                ),
                                w5(),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: grey,
                                  size: 14,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    h10(),
                    Container(
                      height: 300,
                      child:
                          AllReelsVideoScreen(allProperties: widget.properties),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return imagePropertyCard(index, activeUser);
          }
        } else {
          return imagePropertyCard(index, activeUser);
        }
      }),
    );
  }

  Widget imagePropertyCard(index, activeUser) {
    final PropertyModel property = widget.properties[index];
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      decoration: BoxDecoration(
        color: p.raised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.raisedBorder),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AgentAccountProfile(property: property)),
              SaveButton(property: property, onImage: false, size: 40),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.more_horiz_rounded, color: p.textGrey),
                onPressed: () {
                  final UserModel? userModel =
                      Provider.of<UsermodelProvider>(context, listen: false)
                          .getUserModel();
                  if (userModel == null) {
                    goTo(context, LoginScreen(fromNav: true), false);
                  } else {
                    showReportModal(property, context);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (property.isHouse == 0)
            _TextPoster(property: property)
          else if (property.isVideo == 1) ...[
            _PriceLine(property: property),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: VideoDisplayWidget(property: property),
            ),
          ] else
            _PropertyGallery(
              property: property,
              onOpen: () => viewPhotoDialog(property.images, property),
            ),
          if (property.isHouse != 0) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AutoSizeText(
                property.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.ink, fontSize: 14, height: 1.35),
              ),
            ),
            const SizedBox(height: 10),
            _FeatureChips(property: property),
          ],
          const SizedBox(height: 6),
          ReactionsWidget(property: property),
        ],
      ),
    );
  }

  viewPhotoDialog(images, property) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (ctx) {
          return ViewPhotoWidget(
            images: images,
            propertyModel: property,
          );
        });
  }
}

/// Swipeable photo hero with a "stacked prints" edge, a glass counter,
/// category badge, and the price/location set over a gradient scrim.
class _PropertyGallery extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback onOpen;
  const _PropertyGallery({required this.property, required this.onOpen});

  @override
  State<_PropertyGallery> createState() => _PropertyGalleryState();
}

class _PropertyGalleryState extends State<_PropertyGallery> {
  final PageController _pager = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final property = widget.property;
    final images = property.images;
    final count = images.length;
    final stacked = count > 1;
    final badge =
        (property.title.isNotEmpty ? property.title : property.category)
            .toUpperCase();

    return LayoutBuilder(builder: (context, c) {
      final heroH = c.maxWidth * 0.86;
      return SizedBox(
        height: heroH + (stacked ? 14 : 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Two prints peeking out underneath when there's more than one
            // photo, like a small stack of photographs.
            if (stacked) ...[
              _deckLayer(heroH, inset: 28, drop: 14, color: p.chip),
              _deckLayer(heroH, inset: 14, drop: 7, color: p.tile),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: heroH,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    count == 0
                        ? Container(
                            color: p.tile,
                            child: Icon(Icons.home_work_outlined,
                                size: 48, color: p.textLight),
                          )
                        : PageView.builder(
                            controller: _pager,
                            itemCount: count,
                            onPageChanged: (i) => setState(() => _page = i),
                            itemBuilder: (context, i) => GestureDetector(
                              onTap: widget.onOpen,
                              child: CachedNetworkImage(
                                imageUrl: images[i],
                                memCacheWidth: 900,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: p.tile),
                                errorWidget: (_, __, ___) => Container(
                                  color: p.tile,
                                  child: Icon(Icons.broken_image_outlined,
                                      color: p.textLight),
                                ),
                              ),
                            ),
                          ),
                    // Scrim so the badge and price stay readable on any photo.
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 0.22, 0.55, 1.0],
                            colors: [
                              Color(0x59000000),
                              Color(0x00000000),
                              Color(0x00000000),
                              Color(0xCC000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (badge.isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _GlassPill(
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    if (count > 1)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _GlassPill(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_outlined,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                '${_page + 1}/$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: IgnorePointer(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: _overlayPrice(property)),
                            if (count > 1) _dots(count),
                          ],
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
    });
  }

  Widget _overlayPrice(PropertyModel property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (property.location.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: Color(0xFFF7821B)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  property.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '₦${NumberFormat().format(property.amount)}',
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            if (property.priceSuffix.isNotEmpty)
              TextSpan(
                text: property.priceSuffix,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF7821B),
                ),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _deckLayer(double heroH,
      {required double inset, required double drop, required Color color}) {
    return Positioned(
      left: inset,
      right: inset,
      top: drop,
      height: heroH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }

  // Elongated active dot; caps at 5 dots so long galleries stay tidy.
  Widget _dots(int count) {
    final shown = count > 5 ? 5 : count;
    final active =
        count > 5 ? (_page * (shown - 1) / (count - 1)).round() : _page;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(shown, (i) {
          final on = i == active;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(left: 4),
            width: on ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: on ? const Color(0xFFF7821B) : const Color(0x8CFFFFFF),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Price + location for video posts, where the player can't carry an overlay.
class _PriceLine extends StatelessWidget {
  final PropertyModel property;
  const _PriceLine({required this.property});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(
            text: '₦${NumberFormat().format(property.amount)}',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: p.accent,
            ),
          ),
          if (property.priceSuffix.isNotEmpty)
            TextSpan(
              text: property.priceSuffix,
              style: TextStyle(fontSize: 12.5, color: p.textGrey),
            ),
        ])),
        const SizedBox(width: 12),
        if (property.location.isNotEmpty)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: p.accent),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(property.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.textGrey, fontSize: 12.5)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Beds / baths / category as small tinted chips.
class _FeatureChips extends StatelessWidget {
  final PropertyModel property;
  const _FeatureChips({required this.property});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rooms = property.rooms;
    final baths = property.bathrooms;
    final chips = <MapEntry<IconData, String>>[
      if (rooms > 0)
        MapEntry(Icons.bed_rounded, '$rooms bed${rooms == 1 ? '' : 's'}'),
      if (baths > 0)
        MapEntry(Icons.bathtub_outlined, '$baths bath${baths == 1 ? '' : 's'}'),
      if (property.category.isNotEmpty)
        MapEntry(Icons.sell_outlined, property.category),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final chip in chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(chip.key, size: 15, color: p.accent),
                const SizedBox(width: 5),
                Text(chip.value,
                    style: TextStyle(
                        color: p.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Text-only posts: the post colour as a diagonal gradient poster with an
/// oversized quote mark, and the price pinned underneath.
class _TextPoster extends StatelessWidget {
  final PropertyModel property;
  const _TextPoster({required this.property});

  @override
  Widget build(BuildContext context) {
    final base = postColors[property.colorCode];
    final hsl = HSLColor.fromColor(base);
    final deep =
        hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
    final Color fg = getTextColor(property.colorCode);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, deep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('“',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 64,
                height: 0.9,
                color: fg.withValues(alpha: 0.35),
              )),
          Text(
            property.description,
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '₦${NumberFormat().format(property.amount)}${property.priceSuffix}',
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
