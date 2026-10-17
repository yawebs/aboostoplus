import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/models/chat_item_ref.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/marketplace/chat_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../const/constant.dart';
import '../../models/new_products_model.dart';
import '../../models/products_models.dart';
import '../../models/user_model.dart';
import '../../services/db_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shared_widgets.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// Near-black surface (Material dark-theme convention) instead of pure
// #000000 — pure black leaves no room for elevated surfaces to read as
// "lifted" above the background.
const Color _bgColor = Color(0xFF121212);
// One step lighter than the background — used for cards/sheets that should
// feel elevated (message box) rather than flush with the page.
const Color _surfaceElevated = Color(0xFF1E1E1E);

class ItemDetailsScreen extends StatefulWidget {
  final NewProductsModel product;
  final bool isInfluencer;

  const ItemDetailsScreen({
    Key? key,
    required this.product,
    this.isInfluencer = false,
  }) : super(key: key);

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  int _currentImage = 0;
  int _selectedColor = 0;
  bool _showShareSheet = false;
  bool _descExpanded = false;
  UserModel? _productOwner;
  TextEditingController _controller =
      TextEditingController(text: 'Is this still available?');
  bool _messageSent = false;
  bool _isSendingMessage = false;

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      String messageText = _controller.text;
      _controller.clear();
      UserModel? currentUser = context.read<UsermodelProvider>().getUserModel();
      // 1. Create a local temporary message payload

      // 2. OPTIMISTIC UPDATE: Add to UI immediately so the user sees it instantly
      setState(() {
        _isSendingMessage = true;
      });
      final String senderImage = (currentUser!.profileImage ?? '').toString();
      try {
        // 3. Fire off the network request in the background
        final response = await http.post(
          Uri.parse(endPoint('send_message.php')),
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: {
            'sender_id': currentUser.id,
            'receiver_id': widget.product.ownerData.id,
            'message': messageText,
            'sender_name': currentUser.firstName,
            'sender_image': senderImage,
            // So the seller sees which item this quick message is about.
            ...ChatItemRef.fromProduct(widget.product).toFields(),
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          setState(() {
            _messageSent = true;
            _isSendingMessage = false;
          });
          showToast(
              'Message sent to Seller (${widget.product.ownerData.firstName})');
          // Optional: Update local state to remove any 'is_sending' loading indicators
          // setState(() {
          //   localMessage['is_sending'] = false;
          // });
        } else {
          setState(() {
            _isSendingMessage = false;
          });
          showToast('Unable to send message, try again later');
          print("Failed to dispatch message: ${response.body}");
          // _handleMessageFailure(localMessage);
        }
      } catch (e) {
        showToast('Unable to send message, try again later');
        setState(() {
          _isSendingMessage = false;
        });
        print("Network error dispatching message: $e");
        // _handleMessageFailure(localMessage);
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    UserModel? currentUser = context.read<UsermodelProvider>().getUserModel();
    debugPrint('Product category: ${widget.product.category}');
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App bar
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: BackHeader(
                              title: '${widget.product.name} Details'),
                        ),
                        h20(),
                        // Designer info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: NetworkImageWidget(
                                  url: widget.product.ownerData.profileImage,
                                  width: 44,
                                  height: 44,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product.ownerData.firstName,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: white),
                                  ),
                                  Row(
                                    children: [
                                      TagChip(
                                          label:
                                              widget.product.ownerData.state),
                                      const SizedBox(width: 6),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          widget.product.area,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: context.palette.textGrey,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // _outlineButton('Follow', null),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Image carousel
                        SizedBox(
                          height: 400,
                          child: Stack(
                            children: [
                              PageView.builder(
                                onPageChanged: (i) =>
                                    setState(() => _currentImage = i),
                                itemCount: widget.product.images.length,
                                itemBuilder: (_, i) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: NetworkImageWidget(
                                      url: widget.product.images[i],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              // Pill-style dot indicator: active dot is
                              // wider and tinted with the brand color,
                              // inactive dots use semi-opaque white so
                              // they stay visible against any photo.
                              if (widget.product.images.length > 1)
                                Positioned(
                                  bottom: 16,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      widget.product.images.length,
                                      (i) => AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        width: i == _currentImage ? 18 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: i == _currentImage
                                              ? context.palette.primaryFill
                                              : Colors.white.withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Page indicator

                        // Product info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: white),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _pill(widget.product.category),
                                  const SizedBox(width: 6),
                                  _pill(
                                    '•${widget.product.area}',
                                    underline: true,
                                    location: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _descExpanded = !_descExpanded),
                                child: Text(
                                  widget.product.description,
                                  maxLines: _descExpanded ? null : 4,
                                  overflow: _descExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.palette.textGrey,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Price + Share
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: context.palette.primaryFill,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                        child: Text('₦',
                                            style: tStyle(color: white))),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${NumberFormat().format(double.parse(widget.product.price.toString()))}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _showShareSheet = true),
                                    child: Row(
                                      children: [
                                        Icon(Icons.ios_share,
                                            size: 16, color: white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Share Item',
                                          style: TextStyle(
                                            color: white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Message Seller — a single elevated surface
                              // instead of a Container(border) wrapping a
                              // transparent Card, so there's one clear
                              // "raised panel" instead of two overlapping
                              // shape definitions.
                              widget.product.ownerId == currentUser!.id
                                  ? SizedBox.shrink()
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: _surfaceElevated,
                                        borderRadius: appRadius(12.0),
                                        border: Border.all(
                                          color: grey.withOpacity(.25),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                  widget.product.ownerData
                                                      .profileImage),
                                            ),
                                            title: Text(
                                              '${widget.product.ownerData.firstName} ${widget.product.ownerData.lastName}',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: white),
                                            ),
                                            subtitle: Text(
                                              'Message Seller',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      context.palette.textGrey),
                                            ),
                                            trailing: _messageSent
                                                ? null
                                                : _isSendingMessage
                                                    ? appLoader(20.0)
                                                    : GestureDetector(
                                                        onTap: () =>
                                                            _sendMessage(),
                                                        child: Icon(
                                                          Icons.send,
                                                          size: 16,
                                                          color: white,
                                                        ),
                                                      ),
                                          ),
                                          _messageSent
                                              ? Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 40.0,
                                                      vertical: 10),
                                                  child: appButton(
                                                    label: 'Continue Chat',
                                                    callback: () => goTo(
                                                        context,
                                                        ChatScreen(
                                                            item: ChatItemRef
                                                                .fromProduct(
                                                                    widget
                                                                        .product),
                                                            currentUserId:
                                                                currentUser!.id,
                                                            receiverId: widget
                                                                .product
                                                                .ownerId,
                                                            senderName:
                                                                currentUser
                                                                    .firstName,
                                                            senderImage:
                                                                currentUser
                                                                    .profileImage),
                                                        false),
                                                    color: context
                                                        .palette.primaryFill,
                                                    textColor: white,
                                                  ),
                                                )
                                              : TextField(
                                                  controller: _controller,
                                                  style: tStyle(color: white),
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Is this still available?',
                                                    hintStyle: TextStyle(
                                                        color: Colors.white70),
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .fromLTRB(
                                                            16, 0, 16, 14),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                              h20(),
                              Text('Related Items',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: white)),
                              h10(),
                              FutureBuilder(
                                  future: DbServices.getRelatedProducts(
                                      10,
                                      widget.product.category,
                                      widget.product.id),
                                  builder: (context, asyncSnapshot) {
                                    if (!asyncSnapshot.hasData) {
                                      return listLoader();
                                    }
                                    List<NewProductsModel> products =
                                        asyncSnapshot.data
                                            as List<NewProductsModel>;
                                    if (products.isEmpty) {
                                      return const Center(
                                          child: Text('No Products Found'));
                                    }

                                    return LayoutBuilder(
                                      builder: (context, constraints) {
                                        const crossAxisCount = 2;
                                        const spacing = 12.0;
                                        // Tuned to the current ProductCard's
                                        // natural proportions (image +
                                        // price/name/location block) rather
                                        // than a hardcoded pixel height that
                                        // drifts out of sync with the card.
                                        const aspectRatio = 0.7;

                                        return GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: crossAxisCount,
                                              childAspectRatio: aspectRatio,
                                              crossAxisSpacing: spacing,
                                              mainAxisSpacing: spacing,
                                            ),
                                            itemCount: products.length,
                                            itemBuilder: (context, index) {
                                              final product = products[index];
                                              return ProductCard(
                                                product: product,
                                                index: index,
                                              );
                                            });
                                      },
                                    );
                                  })
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom button — a hairline top border + slightly darker
                // container gives it visual weight as a persistent action
                // bar instead of content just stopping mid-scroll.
                widget.product.ownerData.id == currentUser.id
                    ? SizedBox.shrink()
                    : Container(
                        decoration: BoxDecoration(
                          color: _bgColor,
                          border: Border(
                            top: BorderSide(
                                color: grey.withOpacity(.15), width: 1),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: MiaButton(
                                text: '📞 Contact Seller',
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => goTo(
                                  context,
                                  ChatScreen(
                                    item:
                                        ChatItemRef.fromProduct(widget.product),
                                    currentUserId: currentUser!.id,
                                    receiverId: widget.product.ownerData.id,
                                    senderImage: currentUser.profileImage,
                                    senderName: currentUser.firstName,
                                  ),
                                  false),
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chat_bubble_outline,
                                    color: context.palette.accent, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),

            // Share sheet overlay
            if (_showShareSheet) ...[
              GestureDetector(
                onTap: () => setState(() => _showShareSheet = false),
                child: Container(color: Colors.black54),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _ShareSheet(
                    onClose: () => setState(() => _showShareSheet = false)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Reconciles this screen's existing dark-only mobile palette into the
  // main light AppColors system used by the rest of the web redesign;
  // reuses _pill()/_sendMessage() unchanged since those helpers already
  // read from AppColors rather than the dark _bgColor/_surfaceElevated
  // constants above.
  Widget _buildWeb(BuildContext context) {
    UserModel? currentUser = context.read<UsermodelProvider>().getUserModel();
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => goBack(context),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_ios_new,
                                    size: 16, color: AppColors.textDark),
                                SizedBox(width: 6),
                                Text('Back',
                                    style: TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final gallery = _webGallery();
                            final details =
                                _webDetailsPanel(context, currentUser);
                            if (!AppBreakpoints.isWide(constraints.maxWidth)) {
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
                        const SizedBox(height: 32),
                        const Text(
                          'Related items',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder(
                          future: DbServices.getRelatedProducts(
                              10, widget.product.category, widget.product.id),
                          builder: (context, asyncSnapshot) {
                            if (!asyncSnapshot.hasData) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.primary)),
                              );
                            }
                            List<NewProductsModel> products =
                                asyncSnapshot.data as List<NewProductsModel>;
                            if (products.isEmpty) {
                              return const EmptyState(
                                icon: Icons.shopping_bag_outlined,
                                title: 'No related items found',
                              );
                            }
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 240,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) => ProductCard(
                                product: products[index],
                                index: index,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showShareSheet) ...[
                GestureDetector(
                  onTap: () => setState(() => _showShareSheet = false),
                  child: Container(color: Colors.black54),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _ShareSheet(
                          onClose: () =>
                              setState(() => _showShareSheet = false)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _webGallery() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 440,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PageView.builder(
                onPageChanged: (i) => setState(() => _currentImage = i),
                itemCount: widget.product.images.length,
                itemBuilder: (_, i) => NetworkImageWidget(
                  url: widget.product.images[i],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (widget.product.images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.product.images.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentImage ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _currentImage
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _webDetailsPanel(BuildContext context, UserModel? currentUser) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: NetworkImageWidget(
                  url: widget.product.ownerData.profileImage,
                  width: 44,
                  height: 44,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.ownerData.firstName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    TagChip(label: widget.product.ownerData.state),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.product.name,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _pill(widget.product.category),
              const SizedBox(width: 6),
              _pill('•${widget.product.area}', underline: true, location: true),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Text(
              widget.product.description,
              maxLines: _descExpanded ? null : 4,
              overflow:
                  _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textGrey, height: 1.6),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: const Center(
                    child: Text('₦', style: TextStyle(color: Colors.white))),
              ),
              const SizedBox(width: 10),
              Text(
                NumberFormat()
                    .format(double.parse(widget.product.price.toString())),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _showShareSheet = true),
                  child: const Row(
                    children: [
                      Icon(Icons.ios_share,
                          size: 16, color: AppColors.textDark),
                      SizedBox(width: 4),
                      Text('Share',
                          style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.product.ownerId != currentUser!.id)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(widget.product.ownerData.profileImage),
                    ),
                    title: Text(
                      '${widget.product.ownerData.firstName} ${widget.product.ownerData.lastName}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    subtitle: const Text('Message seller',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    trailing: _messageSent
                        ? null
                        : _isSendingMessage
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.primary))
                            : MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _sendMessage,
                                  child: Icon(Icons.send,
                                      size: 18, color: AppColors.primary),
                                ),
                              ),
                  ),
                  if (_messageSent)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: MiaButton(
                        text: 'Continue chat',
                        onPressed: () => goTo(
                            context,
                            ChatScreen(
                                item: ChatItemRef.fromProduct(widget.product),
                                currentUserId: currentUser.id,
                                receiverId: widget.product.ownerId,
                                senderName: currentUser.firstName,
                                senderImage: currentUser.profileImage),
                            false),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Is this still available?',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (widget.product.ownerData.id != currentUser.id)
            MiaButton(
              text: 'Chat with seller',
              prefix: const Icon(Icons.chat_bubble_outline,
                  color: Colors.white, size: 18),
              onPressed: () => goTo(
                  context,
                  ChatScreen(
                    item: ChatItemRef.fromProduct(widget.product),
                    currentUserId: currentUser.id,
                    receiverId: widget.product.ownerData.id,
                    senderImage: currentUser.profileImage,
                    senderName: currentUser.firstName,
                  ),
                  false),
            ),
        ],
      ),
    );
  }

  Widget _pill(String label, {bool underline = false, bool location = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (location) ...[
            Icon(Icons.location_on, size: 14, color: context.palette.textDark),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textDark,
              decoration: underline ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: context.palette.accent),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final VoidCallback onClose;
  const _ShareSheet({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': Icons.link,
        'label': 'Copy Link',
        'color': const Color(0xFFFF6B1A)
      },
      {
        'icon': Icons.whatshot,
        'label': 'WhatsApp',
        'color': const Color(0xFF25D366)
      },
      {
        'icon': Icons.facebook,
        'label': 'Facebook',
        'color': const Color(0xFF1877F2)
      },
      {
        'icon': Icons.music_note,
        'label': 'TikTok',
        'color': const Color(0xFF000000)
      },
      {
        'icon': Icons.camera_alt,
        'label': 'Instagram',
        'color': const Color(0xFFE4405F)
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share Via',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items
                .map(
                  (item) => Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: item['color'] as Color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.palette.textGrey,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
