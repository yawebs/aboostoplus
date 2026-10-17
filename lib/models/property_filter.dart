import 'package:eafind/models/property_model.dart';

enum MediaFilter { any, photos, videos }

enum SortOption { newest, priceLowHigh, priceHighLow }

// Every field is optional: an empty filter matches everything. Used both to
// build the server `advanced_filter` request and to filter/sort locally, so
// results stay correct even against a server that ignores some fields.
class PropertyFilter {
  final Set<String> categories;
  final String? state;
  final String? city;
  final String community;
  final int? minPrice;
  final int? maxPrice;
  final int minRooms;
  final int minBathrooms;
  final MediaFilter media;
  final SortOption sort;

  const PropertyFilter({
    this.categories = const {},
    this.state,
    this.city,
    this.community = '',
    this.minPrice,
    this.maxPrice,
    this.minRooms = 0,
    this.minBathrooms = 0,
    this.media = MediaFilter.any,
    this.sort = SortOption.newest,
  });

  static const empty = PropertyFilter();

  // Number of active filter groups, shown as the badge on the filter button.
  // Sort isn't counted: it orders results rather than narrowing them.
  int get activeCount =>
      (categories.isNotEmpty ? 1 : 0) +
      (state != null || city != null || community.trim().isNotEmpty ? 1 : 0) +
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (minRooms > 0 ? 1 : 0) +
      (minBathrooms > 0 ? 1 : 0) +
      (media != MediaFilter.any ? 1 : 0);

  bool get isActive => activeCount > 0;

  static num _amount(PropertyModel p) =>
      num.tryParse(p.amount.toString().replaceAll(',', '')) ?? 0;

  bool matches(PropertyModel p) {
    if (categories.isNotEmpty && !categories.contains(p.category)) {
      return false;
    }
    if (state != null && p.location != state) return false;
    if (city != null && p.city.toString() != city) return false;
    final c = community.trim().toLowerCase();
    if (c.isNotEmpty && !p.community.toString().toLowerCase().contains(c)) {
      return false;
    }
    final amount = _amount(p);
    if (minPrice != null && amount < minPrice!) return false;
    if (maxPrice != null && amount > maxPrice!) return false;
    if (p.rooms < minRooms) return false;
    if (p.bathrooms < minBathrooms) return false;
    if (media == MediaFilter.photos && p.isVideo == 1) return false;
    if (media == MediaFilter.videos && p.isVideo != 1) return false;
    return true;
  }

  List<PropertyModel> apply(List<PropertyModel> properties) {
    final result = properties.where(matches).toList();
    switch (sort) {
      case SortOption.newest:
        result.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
        break;
      case SortOption.priceLowHigh:
        result.sort((a, b) => _amount(a).compareTo(_amount(b)));
        break;
      case SortOption.priceHighLow:
        result.sort((a, b) => _amount(b).compareTo(_amount(a)));
        break;
    }
    return result;
  }

  // Fields for search-property.php's `advanced_filter` branch; anything
  // unset is simply left out.
  Map<String, dynamic> toFormFields(String keyword) => {
        'advanced_filter': 1,
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        if (categories.isNotEmpty) 'categories': categories.join('|'),
        if (state != null) 'state': state,
        if (city != null) 'city': city,
        if (community.trim().isNotEmpty) 'community': community.trim(),
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (minRooms > 0) 'minRooms': minRooms,
        if (minBathrooms > 0) 'minBathrooms': minBathrooms,
        if (media != MediaFilter.any)
          'media': media == MediaFilter.videos ? 'videos' : 'photos',
        'sort': sort.name,
      };

  // Stored with a search alert (search-alerts.php) and matched server-side
  // against new uploads (search_alerts_lib.php) - keep the field names in sync.
  Map<String, dynamic> toAlertJson(String keyword) => {
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        if (categories.isNotEmpty) 'categories': categories.toList(),
        if (state != null) 'state': state,
        if (city != null) 'city': city,
        if (community.trim().isNotEmpty) 'community': community.trim(),
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (minRooms > 0) 'minRooms': minRooms,
        if (minBathrooms > 0) 'minBathrooms': minBathrooms,
      };

  static PropertyFilter fromAlertJson(Map<String, dynamic> j) {
    int? asInt(dynamic v) => v == null ? null : int.tryParse(v.toString());
    return PropertyFilter(
      categories: {
        for (final c in (j['categories'] is List ? j['categories'] as List : []))
          c.toString(),
      },
      state: j['state']?.toString(),
      city: j['city']?.toString(),
      community: (j['community'] ?? '').toString(),
      minPrice: asInt(j['minPrice']),
      maxPrice: asInt(j['maxPrice']),
      minRooms: asInt(j['minRooms']) ?? 0,
      minBathrooms: asInt(j['minBathrooms']) ?? 0,
    );
  }

  // Short human label, e.g. "2Bed-Room · ₦500K–₦1.5M · Rumuokoro".
  String describe(String keyword) {
    String naira(int v) {
      if (v >= 1000000) {
        final m = v / 1000000;
        return '₦${m == m.roundToDouble() ? m.toInt() : m.toStringAsFixed(1)}M';
      }
      if (v >= 1000) return '₦${(v / 1000).round()}K';
      return '₦$v';
    }

    final parts = <String>[
      if (keyword.trim().isNotEmpty) '"${keyword.trim()}"',
      if (categories.isNotEmpty)
        categories.length <= 2
            ? categories.join(', ')
            : '${categories.length} property types',
      if (minRooms > 0) '$minRooms+ beds',
      if (minPrice != null && maxPrice != null)
        '${naira(minPrice!)}–${naira(maxPrice!)}'
      else if (maxPrice != null)
        'Up to ${naira(maxPrice!)}'
      else if (minPrice != null)
        '${naira(minPrice!)}+',
      if (community.trim().isNotEmpty)
        community.trim()
      else if (city != null)
        city!
      else if (state != null)
        state!,
    ];
    return parts.isEmpty ? 'All new listings' : parts.join(' · ');
  }

  PropertyFilter copyWith({
    Set<String>? categories,
    String? Function()? state,
    String? Function()? city,
    String? community,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    int? minRooms,
    int? minBathrooms,
    MediaFilter? media,
    SortOption? sort,
  }) =>
      PropertyFilter(
        categories: categories ?? this.categories,
        state: state != null ? state() : this.state,
        city: city != null ? city() : this.city,
        community: community ?? this.community,
        minPrice: minPrice != null ? minPrice() : this.minPrice,
        maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
        minRooms: minRooms ?? this.minRooms,
        minBathrooms: minBathrooms ?? this.minBathrooms,
        media: media ?? this.media,
        sort: sort ?? this.sort,
      );
}
