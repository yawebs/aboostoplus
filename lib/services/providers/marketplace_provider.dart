import 'package:eafind/models/new_products_model.dart';
import 'package:eafind/services/db_services.dart';
import 'package:flutter/material.dart';

class MarketplaceProvider extends ChangeNotifier {
  List<NewProductsModel> products = [];

  bool hasFetched = false;
  bool isLoading = false;
  Object? error;

  String _fetchedCategory = '';

  // Fetches the marketplace product list once and caches it. Safe to call
  // repeatedly (e.g. every time MarketHome mounts) - it only hits the
  // network the first time, when the category changes, or when
  // forceRefresh is passed (category tap, pull-to-refresh).
  Future<void> fetchProducts({
    String category = 'all',
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    if (isLoading) return;
    if (hasFetched && !forceRefresh && category == _fetchedCategory) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      products = await DbServices.getProducts(limit, category);
      _fetchedCategory = category;
      hasFetched = true;
    } catch (e) {
      error = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
