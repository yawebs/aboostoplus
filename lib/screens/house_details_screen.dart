import 'package:eafind/widgets/verified_badge.dart';
import 'package:eafind/theme/app_palette.dart';
import 'dart:convert';

import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/payment_sheet.dart';
import 'package:eafind/widgets/review_list.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:eafind/widgets/video_player_controlls_widget.dart';
import 'package:eafind/widgets/view_photo_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:eafind/widgets/save_button.dart';
import 'package:eafind/widgets/area_insights_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../const/constant.dart';
import '../models/house_type_model.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';

import '../widgets/video_display_widget.dart';

class HouseDetailsScreen extends StatefulWidget {
  final PropertyModel property;
  final isPreviewOnly;
  const HouseDetailsScreen(
      {Key? key, required this.property, this.isPreviewOnly})
      : super(key: key);

  @override
  State<HouseDetailsScreen> createState() => _HouseDetailsScreenState();
}

class _HouseDetailsScreenState extends State<HouseDetailsScreen> {
  String currentDetailsShowing = 'Other Fees';
  var currentUser = FirebaseAuth.instance.currentUser;
  UserModel? user;
  bool isLoading = false;

  final PageController _imageController = PageController();
  int _currentImage = 0;

  showPaymentInfoModal() {
    showModalBottomSheet(
        backgroundColor: context.palette.paper,
        context: context,
        // Size to the sheet's content instead of the default 9/16 cap.
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return Paymentsheet(
            property: widget.property,
            userCustomer: user!,
          );
        });
  }

  getUser() async {
    UserModel? _user = context.read<UsermodelProvider>().getUserModel();
    if (_user == null) {
      goTo(context, LoginScreen(fromNav: false), false);
    }
    setState(() {
      user = _user;
    });
  }

  @override
  void initState() {
    super.initState();
    getUser();
    // Area info now comes from AreaInsightsCard (area-insights.php). The old
    // fetchAreaInfo() test call to ai_services.php returned a 500 on every
    // open and its result was never displayed.
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.page,
      extendBodyBehindAppBar: true,
      appBar: detailsAppBar(),
      // bottomNavigationBar (not bottomSheet) so the page reserves the
      // bar's space instead of the bar floating over the content.
      bottomNavigationBar: widget.isPreviewOnly == true ? null : bookingBar(),
      body: isLoading
          ? appSearchLoader(context.palette.accent, 50.0)
          : ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                widget.property.isVideo == 1
                    ? VideoDisplayWidget(property: widget.property)
                    : houseImageWidget(),
                Container(
                  decoration: BoxDecoration(
                    color: context.palette.card,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  // The booking bar now reserves its own space, so this only
                  // needs normal breathing room (was 100 to clear the bar);
                  // previews have no bar, so add the system inset there.
                  padding: EdgeInsets.fromLTRB(
                      18,
                      22,
                      18,
                      widget.isPreviewOnly == true
                          ? 24 + MediaQuery.of(context).padding.bottom
                          : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleAndPriceRow(),
                      const SizedBox(height: 6),
                      locationRow(),
                      const SizedBox(height: 18),
                      featuresRow(),
                      if (widget.property.isServiceApartment)
                        amenitiesSection(),
                      AreaInsightsCard(property: widget.property),
                      const SizedBox(height: 22),
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.palette.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 12),
                      tabBarRow(),
                      const SizedBox(height: 16),
                      tabContent(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Reuses titleAndPriceRow()/locationRow()/featuresRow()/tabBarRow()/
  // tabContent()/agentWidget() below unchanged — those are already
  // theme-agnostic presentational helpers, so only the surrounding
  // layout (single scrolling column vs. gallery + sticky detail panel)
  // differs on web.
  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _webBackButton(context),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final gallery = widget.property.isVideo == 1
                                  ? SizedBox(
                                      height: 420,
                                      child: VideoDisplayWidget(
                                          property: widget.property),
                                    )
                                  : _webGallery();
                              final details = AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    titleAndPriceRow(),
                                    const SizedBox(height: 6),
                                    locationRow(),
                                    const SizedBox(height: 18),
                                    featuresRow(),
                                    if (widget.property.isServiceApartment)
                                      amenitiesSection(),
                                    AreaInsightsCard(
                                        property: widget.property),
                                    const SizedBox(height: 22),
                                    Text(
                                      'Details',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    tabBarRow(),
                                    const SizedBox(height: 16),
                                    tabContent(),
                                    const SizedBox(height: 22),
                                    const Divider(),
                                    const SizedBox(height: 12),
                                    agentWidget(),
                                    if (widget.isPreviewOnly != true) ...[
                                      const SizedBox(height: 20),
                                      MiaButton(
                                        text: 'Book Inspection',
                                        prefix: const Icon(Icons.calendar_month,
                                            color: Colors.white, size: 18),
                                        onPressed: () {
                                          if (user == null) {
                                            goTo(
                                                context,
                                                LoginScreen(fromNav: true),
                                                false);
                                          } else {
                                            showPaymentInfoModal();
                                          }
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              );
                              if (!AppBreakpoints.isWide(
                                  constraints.maxWidth)) {
                                return Column(
                                  children: [
                                    gallery,
                                    const SizedBox(height: 24),
                                    details,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: gallery),
                                  const SizedBox(width: 28),
                                  Expanded(flex: 2, child: details),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _webBackButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => goBack(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textDark),
            const SizedBox(width: 6),
            Text('Back',
                style: TextStyle(
                    color: AppColors.textDark, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _webGallery() {
    final images = widget.property.images;
    return GestureDetector(
      onTap: () => goTo(
          context,
          ViewPhotoWidget(images: images, propertyModel: widget.property),
          false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 460,
          child: Stack(
            fit: StackFit.expand,
            children: [
              images.isEmpty
                  ? Container(color: AppColors.surface)
                  : PageView.builder(
                      controller: _imageController,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _currentImage = i),
                      itemBuilder: (ctx, index) {
                        return Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, stack, err) => Container(
                            color: AppColors.surface,
                            child:
                                const Center(child: Icon(Icons.broken_image)),
                          ),
                        );
                      },
                    ),
              if (images.length > 1)
                Positioned(
                  bottom: 18,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (i) {
                      final active = i == _currentImage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              if (images.length > 1)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentImage + 1}/${images.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Header pieces ----------

  Widget titleAndPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.property.category,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: context.palette.inkSoft,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.palette.primaryFill.withOpacity(0.12),
            borderRadius: appRadius(20.0),
          ),
          child: Text(
            '₦${NumberFormat().format(widget.property.amount)}${widget.property.priceSuffix}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: context.palette.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget locationRow() {
    return Row(
      children: [
        Icon(Icons.location_on, color: grey, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.property.location,
            style: TextStyle(color: grey, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  bool get _isLand => widget.property.category == 'Land';

  Widget featuresRow() {
    // Land has no rooms; its plots/size/title show under "Land details".
    if (_isLand) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: houseFeatursWidget(
              'Bedrooms', widget.property.rooms.toString(), Icons.bed_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: houseFeatursWidget('Bathrooms',
              widget.property.bathrooms.toString(), Icons.bathtub_outlined),
        ),
      ],
    );
  }

  Widget amenitiesSection() {
    final amenities = widget.property.requirements.whereType<String>().toList();
    if (amenities.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Row(
          children: [
            Text(
              _isLand ? 'Land details' : 'Amenities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.palette.inkSoft,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${amenities.length}',
              style: TextStyle(color: grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: amenities
              .map((a) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.palette.tile,
                      borderRadius: appRadius(14.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                context.palette.primaryFill.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(serviceApartmentAmenityIcon(a),
                              color: context.palette.accent, size: 15),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          a,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget houseFeatursWidget(String title, String number, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: context.palette.tile,
        borderRadius: appRadius(14.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.palette.primaryFill.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.palette.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                title,
                style: TextStyle(color: grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Tabs ----------

  Widget tabBarRow() {
    return Row(
      children: [
        houseDetails('Overview'),
        const SizedBox(width: 8),
        houseDetails('Reviews'),
        const SizedBox(width: 8),
        houseDetails('Other Fees'),
      ],
    );
  }

  Widget houseDetails(String label) {
    final bool selected = currentDetailsShowing == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentDetailsShowing = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.palette.primaryFill : context.palette.chip,
          borderRadius: appRadius(24.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? white : grey,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget tabContent() {
    if (currentDetailsShowing == 'Reviews') {
      return ReviewList(property: widget.property);
    }
    if (currentDetailsShowing == 'Other Fees') {
      return feesBreakdown();
    }
    return Text(
      widget.property.description,
      style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 14),
    );
  }

  // ---------- Other fees: upfront cost breakdown ----------

  String _naira(num v) => '₦${NumberFormat('#,##0').format(v)}';

  // Rent/price + agent fee (a % of it) + caution + legal, with a stacked bar
  // showing how the upfront total splits, and the total at the bottom.
  Widget feesBreakdown() {
    final palette = context.palette;
    final p = widget.property;
    final rent = num.tryParse(p.amount.toString().replaceAll(',', '')) ?? 0;
    final agentPct = p.agentFee;
    final agentAmount = rent * agentPct / 100;
    final caution = p.cautionFee;
    final legal = p.legalFee;
    final total = rent + agentAmount + caution + legal;

    const rentColor = Color(0xFFC45A06);
    const agentColor = Color(0xFFF7821B);
    const cautionColor = Color(0xFF2E9E8F);
    const legalColor = Color(0xFF4A78C2);

    final rentLabel = p.isServiceApartment
        ? 'Price per night'
        : (p.category == 'Land' || p.category == 'Property Sales')
            ? 'Asking price'
            : 'Rent';

    // Segments of the share bar (amount, colour), in display order.
    final List<num> partAmounts = [rent, agentAmount, caution, legal];
    const partColors = [rentColor, agentColor, cautionColor, legalColor];

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: palette.primaryFill.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt_long_rounded,
                      size: 18, color: palette.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upfront cost breakdown',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: palette.ink)),
                      Text('What you pay to secure this property',
                          style:
                              TextStyle(fontSize: 12, color: palette.inkSoft)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stacked share bar.
          if (total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      for (var i = 0; i < partAmounts.length; i++)
                        if (partAmounts[i] > 0)
                          Expanded(
                            flex: ((partAmounts[i] / total) * 1000)
                                .round()
                                .clamp(1, 1000),
                            child: Container(
                              color: partColors[i],
                              margin: const EdgeInsets.only(right: 2),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          _feeLine(
            color: rentColor,
            icon: Icons.home_rounded,
            label: rentLabel,
            hint:
                'The listed ${p.priceSuffix.isEmpty ? 'price' : 'nightly price'}',
            value: _naira(rent),
          ),
          _feeLine(
            color: agentColor,
            icon: Icons.badge_rounded,
            label: 'Agent fee',
            hint: agentPct > 0
                ? '$agentPct% of the ${rentLabel.toLowerCase()}'
                : 'No agent commission',
            value: agentPct > 0 ? _naira(agentAmount) : null,
            badge: agentPct > 0 ? '$agentPct%' : null,
          ),
          _feeLine(
            color: cautionColor,
            icon: Icons.shield_rounded,
            label: 'Caution fee',
            hint: 'Security deposit, refundable at move-out',
            value: caution > 0 ? _naira(caution) : null,
            badge: caution > 0 ? 'Refundable' : null,
          ),
          _feeLine(
            color: legalColor,
            icon: Icons.gavel_rounded,
            label: 'Legal fee',
            hint: 'Agreement & documentation',
            value: legal > 0 ? _naira(legal) : null,
          ),
          // Total.
          Container(
            margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  palette.primaryFill,
                  Color.lerp(palette.primaryFill, Colors.black, 0.3)!,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated total upfront',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                          'Confirm final amounts with the ${p.userType.toLowerCase()}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  _naira(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeLine({
    required Color color,
    required IconData icon,
    required String label,
    required String hint,
    required String? value,
    String? badge,
  }) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: palette.ink)),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(badge,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(hint,
                    style: TextStyle(fontSize: 11.5, color: palette.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value ?? 'None',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: value == null ? const Color(0xFF2E9E5B) : palette.ink,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Image gallery ----------

  Widget houseImageWidget() {
    final images = widget.property.images;
    return GestureDetector(
      onTap: () => goTo(
          context,
          ViewPhotoWidget(images: images, propertyModel: widget.property),
          false),
      child: SizedBox(
        height: 600,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _imageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _currentImage = i),
              itemBuilder: (ctx, index) {
                return Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, stack, err) => Container(
                    color: context.palette.surfaceAlt,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                );
              },
            ),
            // subtle gradient so the app bar icons stay legible
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    final active = i == _currentImage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? context.palette.paper
                            : context.palette.paper.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            if (images.length > 1)
              Positioned(
                top: 60,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: appRadius(12.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentImage + 1}/${images.length}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- App bar ----------

  AppBar detailsAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, top: 8),
        child: GestureDetector(
          onTap: () => goBack(context),
          child: circleIconButton(Icons.arrow_back_ios_new, size: 16),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
              ],
            ),
            child: SaveButton(
                property: widget.property, onImage: false, size: 38),
          ),
        ),
      ],
      centerTitle: true,
    );
  }

  Widget circleIconButton(IconData icon, {double size = 18}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Icon(icon, color: context.palette.inkSoft, size: size),
    );
  }

  // ---------- Bottom booking bar ----------

  // No fixed height: it used to be a fixed 80px with the safe-area inset
  // taken *inside* it, so on phones with on-screen nav buttons (~48px) the
  // agent row and button were crushed or hidden behind them. Now the bar
  // sizes to its content and grows by the system inset, while its
  // background still runs down to the screen edge.
  Widget bookingBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          // Fixed content height: agentWidget's Column expands to whatever
          // height it's offered, and a bottomNavigationBar is offered the
          // whole screen. Only the SafeArea inset is added on top of this.
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: width(context) / 2, child: agentWidget()),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (user == null) {
                        goTo(context, LoginScreen(fromNav: true), false);
                      } else {
                        showPaymentInfoModal();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: context.palette.primaryFill,
                        borderRadius: appRadius(14.0),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.calendar_month,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Book Inspection',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget agentWidget() {
    UserModel? propertyOwner;
    if (widget.property.propertyOwner != null &&
        widget.property.propertyOwner != '') {
      propertyOwner =
          UserModel.fromDoc2(json.decode(widget.property.propertyOwner!));
    }

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              border: Border.all(width: 1.5, color: context.palette.border),
              shape: BoxShape.circle),
          child: ClipOval(
              child: (widget.property.propertyOwner == null ||
                      widget.property.propertyOwner == '')
                  ? Image.asset(
                      imageRounte(name: 'avatar.png'),
                      cacheHeight: 84,
                      cacheWidth: 84,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      propertyOwner!.profileImage!,
                      fit: BoxFit.cover,
                    )),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.property.userName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: context.palette.inkSoft,
                    fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Text(
                    widget.property.userType,
                    style: TextStyle(color: grey, fontSize: 12),
                  ),
                  VerifiedBadge(
                      userId: widget.property.ownerId, size: 13, gap: 3),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
