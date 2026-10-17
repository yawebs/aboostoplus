import 'package:eafind/theme/app_palette.dart';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/widgets/reactions_widget.dart';
import 'package:eafind/widgets/report_options_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ViewPhotoWidget extends StatefulWidget {
  final List images;
  final PropertyModel propertyModel;
  const ViewPhotoWidget(
      {Key? key, required this.images, required this.propertyModel})
      : super(key: key);

  @override
  State<ViewPhotoWidget> createState() => _ViewPhotoWidgetState();
}

class _ViewPhotoWidgetState extends State<ViewPhotoWidget> {
  final CarouselSliderController _sliderController = CarouselSliderController();
  int currentSlide = 0;
  int currentIndex = 0;
  showReportModal() {
    showModalBottomSheet(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
        ),
        context: context,
        builder: (ctx) {
          return ReportOptionsSheet(property: widget.propertyModel);
        });
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            CarouselSlider.builder(
              carouselController: _sliderController,
              options: CarouselOptions(
                height: double.infinity,
                viewportFraction: 1.0,
                initialPage: 0,
                reverse: false,
                autoPlay: false,
                enlargeCenterPage: false,
                scrollDirection: Axis.horizontal,
                onPageChanged: ((index, reason) {
                  setState(() {
                    currentIndex = index;
                  });
                }),
              ),
              itemCount: widget.images.length,
              itemBuilder: (ctx, itemIndex, pageViewIndex) {
                return Image.network(
                  widget.images[itemIndex],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  ),
                );
              },
            ),
            // scrims so the floating chrome stays legible over any photo
            _scrim(alignment: Alignment.topCenter, height: 150),
            _scrim(alignment: Alignment.bottomCenter, height: 230),

            // tap-the-edge navigation (WhatsApp-status style) - sits below
            // the chrome below so those buttons/filmstrip still win taps
            // inside their own bounds; swiping still works since a plain
            // tap and a horizontal drag are different gestures and the
            // CarouselSlider's PageView keeps its own recognizer.
            if (widget.images.length > 1) ...[
              _tapNavZone(isNext: false),
              _tapNavZone(isNext: true),
            ],

            // top chrome: story-style progress + close/more
            Positioned(
              top: topInset + 12,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  _galleryProgress(),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _glassIconButton(Icons.close,
                          onTap: () => goBack(context)),
                      Text(
                        '${currentIndex + 1} of ${widget.images.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _glassIconButton(Icons.more_vert,
                          onTap: () => showReportModal()),
                    ],
                  ),
                ],
              ),
            ),

            // bottom chrome: filmstrip + glass reactions bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.images.length > 1) _filmstrip(),
                  _glassActionBar(bottomInset),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scrim({required Alignment alignment, required double height}) {
    final atTop = alignment == Alignment.topCenter;
    return Positioned(
      top: atTop ? 0 : null,
      bottom: atTop ? null : 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: atTop ? Alignment.topCenter : Alignment.bottomCenter,
              end: atTop ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(atTop ? 0.5 : 0.55),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tapNavZone({required bool isNext}) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: isNext ? null : 0,
      right: isNext ? 0 : null,
      width: MediaQuery.of(context).size.width * 0.35,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _goToImage(currentIndex + (isNext ? 1 : -1)),
      ),
    );
  }

  void _goToImage(int index) {
    if (index < 0 || index >= widget.images.length) return;
    _sliderController.animateToPage(index);
  }

  Widget _galleryProgress() {
    if (widget.images.length <= 1) return const SizedBox.shrink();
    return Row(
      children: List.generate(widget.images.length, (i) {
        final filled = i <= currentIndex;
        return Expanded(
          child: Container(
            height: 2.5,
            margin: EdgeInsets.only(
                right: i == widget.images.length - 1 ? 0 : 4),
            decoration: BoxDecoration(
              color: filled ? context.palette.card : Colors.white.withOpacity(0.32),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _glassIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.26)),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
        ),
      ),
    );
  }

  Widget _filmstrip() {
    return Container(
      height: 58,
      margin: const EdgeInsets.only(bottom: 14),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (ctx, index) {
          final active = index == currentIndex;
          return GestureDetector(
            onTap: () => _sliderController.animateToPage(index),
            child: Container(
              width: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: active
                    ? Border.all(color: const Color(0xFFE8A93B), width: 2)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Opacity(
                  opacity: active ? 1 : 0.55,
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        Container(color: Colors.grey.shade800),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _glassActionBar(double bottomInset) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0A12).withOpacity(0.62),
            border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.12))),
          ),
          padding: EdgeInsets.fromLTRB(18, 16, 18, bottomInset + 16),
          child: ReactionsWidget(
            property: widget.propertyModel,
            showWhite: true,
            filledDetailsButton: true,
          ),
        ),
      ),
    );
  }

  // A full-bleed viewer stretched across a wide desktop browser looks
  // wrong, so it's centered as a lightbox-style panel instead.
  Widget _buildWeb(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: black,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Property gallery',
                              style: TextStyle(
                                color: grey,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: showReportModal,
                                    child: Icon(Icons.more_vert, color: grey),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => goBack(context),
                                    child: Icon(Icons.close, color: white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      CarouselSlider.builder(
                        carouselController: _sliderController,
                        options: CarouselOptions(
                          height: 460,
                          viewportFraction: 1.0,
                          initialPage: 0,
                          enlargeCenterPage: true,
                          onPageChanged: ((index, reason) {
                            setState(() => currentIndex = index);
                          }),
                        ),
                        itemCount: widget.images.length,
                        itemBuilder: (ctx, itemIndex, pageViewIndex) {
                          return SizedBox(
                            width: double.infinity,
                            child: Image.network(
                              widget.images[itemIndex],
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          );
                        },
                      ),
                      if (widget.images.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.images
                              .asMap()
                              .entries
                              .map((e) => GestureDetector(
                                    onTap: () {
                                      setState(() => currentSlide = e.key);
                                      _sliderController.animateToPage(e.key);
                                    },
                                    child: Container(
                                      width: 8.0,
                                      height: 8.0,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 5),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: grey),
                                        shape: BoxShape.circle,
                                        color: currentIndex == e.key
                                            ? white
                                            : transparent,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      Container(
                        color: lightGrey,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        height: 50,
                        child: ReactionsWidget(property: widget.propertyModel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
