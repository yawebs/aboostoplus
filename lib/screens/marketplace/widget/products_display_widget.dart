import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/models/new_products_model.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../const/constant.dart';
import '../../../widgets/product_card.dart';
import 'featured_product_card.dart';

class ProductsDisplayWidget extends StatefulWidget {
  final List<NewProductsModel> products;
  const ProductsDisplayWidget({Key? key, required this.products})
      : super(key: key);

  @override
  State<ProductsDisplayWidget> createState() => _ProductsDisplayWidgetState();
}

class _ProductsDisplayWidgetState extends State<ProductsDisplayWidget> {
  static const double _horizontalPadding = 14.0;
  static const int _featuredCount = 3;

  @override
  Widget build(BuildContext context) {
    // Featured rail gets the first few items; the grid shows the rest so
    // the same product never appears twice on the same screen.
    final featured = widget.products.take(_featuredCount).toList();
    final remaining = widget.products.length > _featuredCount
        ? widget.products.skip(_featuredCount).toList()
        : <NewProductsModel>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile keeps its fixed 2-column grid unchanged; the web build
        // adds more columns as the window widens instead of staying
        // stuck at 2 on a desktop-size viewport.
        final crossAxisCount = kIsWeb
            ? (AppBreakpoints.isWide(constraints.maxWidth)
                ? 4
                : AppBreakpoints.isMedium(constraints.maxWidth)
                    ? 3
                    : 2)
            : 2;
        const spacing = 12.0;
        // Ratio tuned to the current card's natural height (image + price
        // + name + location block) rather than a hardcoded pixel height,
        // so it won't overflow if card content grows.
        const aspectRatio = 0.7;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (featured.isNotEmpty) ...[
                FeaturedProductsSection(
                  title: 'Featured Products',
                  products: featured,
                  onSeeAll: () {
                    // TODO: navigate to a full featured-products screen
                  },
                ),
                h20(),
              ],
              if (remaining.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalPadding),
                  child: Text(
                    'All Products',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.palette.inkSoft,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalPadding),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: aspectRatio,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    itemCount: remaining.length,
                    itemBuilder: (context, index) {
                      final product = remaining[index];
                      return ProductCard(
                        product: product,
                        index: index,
                      );
                    },
                  ),
                ),
              ] else if (featured.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No Products Found')),
                ),
            ],
          ),
        );
      },
    );
  }
}
