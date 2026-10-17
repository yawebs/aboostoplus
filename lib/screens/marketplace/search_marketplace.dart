import 'package:eafind/theme/app_palette.dart';
import 'package:dio/dio.dart';
import 'package:eafind/models/new_products_model.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/screens/marketplace/widget/products_display_widget.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/product_card.dart';
import 'package:eafind/widgets/recomemded_widget.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../const/constant.dart';

class SearchMarketplace extends StatefulWidget {
  const SearchMarketplace({Key? key}) : super(key: key);

  @override
  State<SearchMarketplace> createState() => _SearchMarketplaceState();
}

class _SearchMarketplaceState extends State<SearchMarketplace> {
  TextEditingController searchController = TextEditingController();
  List<NewProductsModel> searchProperties = [];
  bool _isSearching = false;
  Future<void> searchProperty(String keyword) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      setState(() {
        searchProperties.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final formData = FormData.fromMap({
        'search_product_keyword': trimmedKeyword,
      });

      final response = await Dio().post(
        endPoint('search-property.php'),
        data: formData,
      );

      // Ignore stale responses: only apply if the text field
      // still matches what we searched for.
      if (searchController.text.trim() != trimmedKeyword) {
        return;
      }

      if (response.data['status'] == 'Success') {
        final List<dynamic> data = response.data['data'] ?? [];
        final results =
            data.map((item) => NewProductsModel.fromJson(item)).toList();

        if (!mounted) return;
        setState(() {
          searchProperties = results;
        });
      } else {
        if (!mounted) return;
        setState(() {
          searchProperties.clear();
        });
      }
    } on DioException catch (e) {
      if (searchController.text.trim() == trimmedKeyword) {
        showToast('Unable to search product');
      }
      debugPrint('Error searching product: ${e.message}');
    } catch (e) {
      if (searchController.text.trim() == trimmedKeyword) {
        showToast('Unable to search product');
      }
      debugPrint('Unexpected error searching product: $e');
    } finally {
      if (mounted && searchController.text.trim() == trimmedKeyword) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        body: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(
              height: 40,
            ),
            searchWidget(),
            Divider(
              color: grey,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'Recent ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            ProductsDisplayWidget(products: searchProperties)
          ],
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search products',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: searchController,
                      onChanged: (value) {
                        if (value.trim().isEmpty) {
                          setState(() => searchProperties = []);
                        } else {
                          searchProperty(value);
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      )
                    else if (searchProperties.isEmpty)
                      const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Search for a product',
                        message: 'Results will appear here',
                      )
                    else
                      ProductsDisplayWidget(products: searchProperties),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget searchWidget() {
    return Container(
      height: 100,
      width: width(context),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: GestureDetector(
              onTap: () => goBack(context),
              child: Icon(
                Icons.arrow_back_ios,
                color: context.palette.ink,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Container(
                height: 50,
                child: TextFormField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: searchController,
                  onChanged: (value) {
                    if (value.toString().isEmpty) {
                      setState(() {
                        searchProperties = [];
                      });
                    } else {
                      searchProperty(value);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Products...',
                    isDense: true,
                    hintStyle: TextStyle(
                      color: grey,
                      fontSize: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: context.palette.accent,
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
                        color: context.palette.accent,
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
                          color: context.palette.primaryFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.search,
                          color: white,
                          size: 25,
                        ),
                      ),
                    ),
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
