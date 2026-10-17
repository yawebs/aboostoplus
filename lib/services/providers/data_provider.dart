import 'package:eafind/models/house_type_model.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/services/db_services.dart';
import 'package:flutter/material.dart';

class DataProvider extends ChangeNotifier {
  List<PropertyModel> properties = [];
  List<PropertyModel> featuredProperties = [];

  bool hasFetchedProperties = false;
  bool hasFetchedFeatured = false;
  bool isLoadingProperties = false;
  bool isLoadingFeatured = false;

  String _fetchedPropertyType = '';

  // Per-category caches (Hall, Land, Office Space, Property Sales, ...)
  // used by the category tab screens - keyed so each category is only
  // ever fetched once, instead of on every rebuild.
  Map<String, List<PropertyModel>> categoryProperties = {};
  final Set<String> _loadingCategories = {};

  bool isCategoryLoading(String category) =>
      _loadingCategories.contains(category);

  Future<void> fetchCategoryProperties(String category,
      {bool forceRefresh = false}) async {
    if (_loadingCategories.contains(category)) return;
    if (categoryProperties.containsKey(category) && !forceRefresh) return;
    _loadingCategories.add(category);
    notifyListeners();
    try {
      // Must query by `category` (what the upload forms store). Sending it
      // as `propertyType` hits the houses-only feed query on the server
      // (is_house = 1), which never returns lands, halls, etc.
      categoryProperties[category] =
          await DbServices.getPropertiesByCategories(category, 50);
    } finally {
      _loadingCategories.remove(category);
      notifyListeners();
    }
  }

  // Featured row on the home screen, per stored category ('Land', 'Hall',
  // ...) - backs the property type dropdown when it's set to anything other
  // than Houses. Queries by `category`, which is what the upload forms
  // write, so it matches listings like lands (stored with is_house = 3)
  // that the main houses feed never returns.
  Map<String, List<PropertyModel>> featuredByCategory = {};
  final Set<String> _loadingFeaturedCategories = {};

  bool isFeaturedCategoryLoading(String category) =>
      _loadingFeaturedCategories.contains(category);

  Future<void> fetchFeaturedByCategory(String category,
      {int limit = 20, bool forceRefresh = false}) async {
    if (_loadingFeaturedCategories.contains(category)) return;
    if (featuredByCategory.containsKey(category) && !forceRefresh) return;
    _loadingFeaturedCategories.add(category);
    notifyListeners();
    try {
      featuredByCategory[category] =
          await DbServices.getPropertiesByCategories(category, limit);
    } finally {
      _loadingFeaturedCategories.remove(category);
      notifyListeners();
    }
  }

  Map<String, dynamic> _signupData = {};
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get getSignupData => _signupData;
  setSignupData(Map<String, dynamic> data) {
    _signupData = data;
    notifyListeners();
  }

  addNewEntryToFormatData(Map<String, dynamic> data) {
    _signupData.addAll(data);
    notifyListeners();
  }

  // Fetches the main property feed once and caches it. Safe to call
  // repeatedly (e.g. from every HomeScreen.initState) - it only hits the
  // network the first time, when the property type changes, or when
  // forceRefresh is passed (pagination, pull-to-refresh, filter change).
  Future<void> fetchProperties(
    BuildContext context, {
    required propertyType,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    if (isLoadingProperties) return;
    if (hasFetchedProperties &&
        !forceRefresh &&
        propertyType == _fetchedPropertyType) {
      return;
    }
    isLoadingProperties = true;
    notifyListeners();
    try {
      properties = await DbServices.getProperties(propertyType, limit, context);
      _fetchedPropertyType = propertyType;
      hasFetchedProperties = true;
    } finally {
      isLoadingProperties = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeaturedProperties({
    propertyType = 'Duplex',
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    if (isLoadingFeatured) return;
    if (hasFetchedFeatured && !forceRefresh) return;
    isLoadingFeatured = true;
    notifyListeners();
    try {
      featuredProperties =
          await DbServices.getPropertiesByCategories(propertyType, limit);
      hasFetchedFeatured = true;
    } finally {
      isLoadingFeatured = false;
      notifyListeners();
    }
  }

  List<PropertyModel> serviceApartments = [];
  bool hasFetchedServiceApartments = false;
  bool _isLoadingServiceApartments = false;

  // Deliberately doesn't notifyListeners() before the await: this is kicked
  // off from initState(), and notifying a provider that sits above the
  // caller mid-build throws "setState() or markNeedsBuild() called during
  // build".
  Future<void> fetchServiceApartments({bool forceRefresh = false}) async {
    if (_isLoadingServiceApartments) return;
    if (hasFetchedServiceApartments && !forceRefresh) return;
    _isLoadingServiceApartments = true;
    try {
      serviceApartments =
          await DbServices.getPropertiesByCategories(kServiceApartment, 20);
      hasFetchedServiceApartments = true;
    } finally {
      _isLoadingServiceApartments = false;
      notifyListeners();
    }
  }

  setProperties(List<PropertyModel> prty) {
    properties = prty;
    hasFetchedProperties = true;
    notifyListeners();
  }

  List<PropertyModel> getData() {
    return properties;
  }
}
