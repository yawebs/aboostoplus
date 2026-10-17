import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/models/new_products_model.dart';
import 'package:eafind/models/products_models.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/marketplace/messages_screen.dart';
import 'package:eafind/screens/marketplace/product_details_screen.dart';
import 'package:eafind/screens/marketplace/upload_product.dart';
import 'package:eafind/screens/marketplace/widget/products_display_widget.dart';
import 'package:eafind/services/providers/marketplace_provider.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../const/constant.dart';
import '../../widgets/product_card.dart';

class MarketHome extends StatefulWidget {
  const MarketHome({Key? key}) : super(key: key);

  @override
  State<MarketHome> createState() => _MarketHomeState();
}

class _MarketHomeState extends State<MarketHome> {
  int _currentSelectedCategory = 0;
  String category = 'all';
  int limit = 10;
  bool _isRefreshing = false;

  // Used by category taps: swaps the whole body for a shimmer while the
  // new category's products load.
  void _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await Future.delayed(Duration(seconds: 1));
    await Provider.of<MarketplaceProvider>(context, listen: false)
        .fetchProducts(category: category, limit: limit, forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
    });
  }

  // Used by RefreshIndicator (pull-to-refresh): the indicator already
  // shows its own spinner while this is pending, so we don't touch
  // _isRefreshing / swap in the shimmer here — that would fight the
  // native pull animation.
  Future<void> _onPullToRefresh() async {
    await Provider.of<MarketplaceProvider>(context, listen: false)
        .fetchProducts(category: category, limit: limit, forceRefresh: true);
  }

  @override
  void initState() {
    super.initState();
    // No-op if the app-launch fetch already populated the provider.
    Provider.of<MarketplaceProvider>(context, listen: false)
        .fetchProducts(category: category, limit: limit);
  }

  static const _categories = [
    _MarketCategory(Icons.all_inclusive, 'All', 'all'),
    _MarketCategory(Icons.tv, 'Electronics', 'Electronics'),
    _MarketCategory(Icons.bed, 'Beds', 'Beds'),
    _MarketCategory(Icons.kitchen, 'Utensils', 'Utensils'),
    _MarketCategory(Icons.device_hub, 'Gadgets', 'Gadgets'),
  ];

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    UserModel? currentUser = context.read<UsermodelProvider>().getUserModel();
    final marketplaceProvider = context.watch<MarketplaceProvider>();
    return Scaffold(
        // A soft, near-white neutral instead of a flat mid-gray.
        // This is what lets the white product cards + shadows actually
        // read as "elevated" instead of blending into the page.
        backgroundColor: context.palette.page,
        appBar: AppBar(
          toolbarHeight: 120,
          backgroundColor: black,
          automaticallyImplyActions: false,
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              searchWidget(),
            ],
          ),
          title: Text(
            'Marketplace',
            style: TextStyle(
                color: white, fontSize: 25, fontWeight: FontWeight.bold),
          ),
          actions: [
            GestureDetector(
              onTap: () => goTo(context, UploadProduct(), false),
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: _IconBtn(
                  icon: Icons.add,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => goTo(
                  context,
                  MessagesScreen(
                      currentUserId: currentUser!.id,
                      currentUserName: currentUser.firstName,
                      currentUserImage: currentUser.profileImage),
                  false),
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: _IconBtn(
                  icon: Icons.message,
                  badge: '4',
                ),
              ),
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _onPullToRefresh,
          color: context.palette.accent,
          backgroundColor: context.palette.paper,
          child: ListView(
            // Required so pull-to-refresh still triggers even when the
            // category bar + products don't fill the screen height.
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Category bar: rounded bottom corners so it reads as a
              // distinct "shelf" hanging off the black appbar, rather than
              // an abrupt black rectangle sitting on gray.
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: black,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentSelectedCategory = 1;
                              category = 'all';
                            });
                            _refreshData();
                          },
                          child: CategoryItem(
                            categoryIcon: Icons.all_inclusive,
                            categoryName: 'All',
                            isActive:
                                _currentSelectedCategory == 1 ? true : false,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentSelectedCategory = 2;
                              category = 'Electronics';
                            });
                            _refreshData();
                            debugPrint(
                                'CurrentIndex is $_currentSelectedCategory');
                          },
                          child: CategoryItem(
                            categoryIcon: Icons.tv,
                            categoryName: 'Electronics',
                            isActive:
                                _currentSelectedCategory == 2 ? true : false,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentSelectedCategory = 3;
                              category = 'Beds';
                            });
                            _refreshData();
                          },
                          child: CategoryItem(
                            categoryIcon: Icons.bed,
                            categoryName: 'Beds',
                            isActive:
                                _currentSelectedCategory == 3 ? true : false,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentSelectedCategory = 4;
                              category = 'Utensils';
                            });
                            _refreshData();
                          },
                          child: CategoryItem(
                            categoryIcon: Icons.kitchen,
                            categoryName: 'Utensils',
                            isActive:
                                _currentSelectedCategory == 4 ? true : false,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentSelectedCategory = 5;
                              category = 'Gadgets';
                            });
                            _refreshData();
                          },
                          child: CategoryItem(
                            categoryIcon: Icons.device_hub,
                            categoryName: 'Gadgets',
                            isActive:
                                _currentSelectedCategory == 5 ? true : false,
                          ),
                        ),
                      ]),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _isRefreshing
                    ? appShimmerLoading(context)
                    : _buildProductsSection(marketplaceProvider),
              ),
            ],
          ),
        ));
  }

  Widget _buildProductsSection(MarketplaceProvider marketplaceProvider) {
    if (marketplaceProvider.isLoading && marketplaceProvider.products.isEmpty) {
      return listLoader();
    }
    if (marketplaceProvider.error != null &&
        marketplaceProvider.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            'Something went wrong. Pull down to try again.',
            style: TextStyle(color: context.palette.inkMuted),
          ),
        ),
      );
    }
    List<NewProductsModel> products = marketplaceProvider.products;
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: const Center(child: Text('No Products Found')),
      );
    }
    return ProductsDisplayWidget(products: products);
  }

  Widget _buildWeb(BuildContext context) {
    UserModel? currentUser = context.read<UsermodelProvider>().getUserModel();
    final marketplaceProvider = context.watch<MarketplaceProvider>();
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: RefreshIndicator(
          onRefresh: _onPullToRefresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Marketplace',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        child: TextField(
                          readOnly: true,
                          onTap: () => showSearchSheetProducts(context),
                          decoration: const InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _webIconButton(
                        Icons.add,
                        () => goTo(context, UploadProduct(), false),
                      ),
                      const SizedBox(width: 10),
                      _webIconButton(
                        Icons.mail_outline_rounded,
                        () => goTo(
                            context,
                            MessagesScreen(
                                currentUserId: currentUser!.id,
                                currentUserName: currentUser.firstName,
                                currentUserImage: currentUser.profileImage),
                            false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories.map((c) {
                      final selected = category == c.value;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => category = c.value);
                            _refreshData();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(c.icon,
                                    size: 16,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textDark),
                                const SizedBox(width: 6),
                                Text(
                                  c.name,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  _isRefreshing
                      ? Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary)),
                        )
                      : marketplaceProvider.isLoading &&
                              marketplaceProvider.products.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(48),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary)),
                            )
                          : marketplaceProvider.error != null &&
                                  marketplaceProvider.products.isEmpty
                              ? const EmptyState(
                                  icon: Icons.error_outline,
                                  title: 'Something went wrong',
                                  message: 'Pull down to try again',
                                )
                              : marketplaceProvider.products.isEmpty
                                  ? const EmptyState(
                                      icon: Icons.shopping_bag_outlined,
                                      title: 'No products found',
                                    )
                                  : ProductsDisplayWidget(
                                      products: marketplaceProvider.products,
                                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webIconButton(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textDark, size: 20),
        ),
      ),
    );
  }

  Widget searchWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: GestureDetector(
                  onTap: () => showSearchSheetProducts(context),
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: grey300, width: 1),
                        borderRadius: appRadius(15.0)),
                    child: TextFormField(
                      // controller: controller,
                      // onChanged: (value) {
                      //   if (controller!.text
                      //       .trim()
                      //       .toString()
                      //       .isEmpty) {
                      //    // clearAuto();
                      //   }
                      // }
                      enabled: false,
                      onSaved: (value) {
                        setState(() {
                          // keyword = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Propertice..',
                        isDense: true,
                        hintStyle: TextStyle(
                          color: white,
                          fontSize: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: context.palette.paper,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: context.palette.accent,
                            width: 1.5,
                          ),
                        ),
                        prefixIcon: Container(
                          padding: EdgeInsets.only(top: 15),
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            color: white,
                          ),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            // if (controller!.text.isNotEmpty) {
                            //   searchPost(posts,
                            //       controller!.text.toString());
                            // }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.palette.paper,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.search,
                              color: context.palette.accent,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

class _MarketCategory {
  final IconData icon;
  final String name;
  final String value;
  const _MarketCategory(this.icon, this.name, this.value);
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String? badge;

  const _IconBtn({required this.icon, this.badge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.palette.card,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: context.palette.ink),
        ),
        if (badge != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
