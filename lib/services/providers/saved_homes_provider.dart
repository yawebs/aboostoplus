import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:flutter/foundation.dart';

// The signed-in user's saved ("hearted") listings. Holds just the ids so
// every card can show its heart instantly; the full list is fetched on the
// Saved homes screen. Kept in sync with the signed-in user via
// ChangeNotifierProxyProvider in main.dart.
class SavedHomesProvider extends ChangeNotifier {
  String? _userId;
  final Set<int> _ids = {};

  bool get hasUser => _userId != null;
  int get count => _ids.length;

  static int? _idOf(PropertyModel p) => int.tryParse(p.id.toString());

  bool isSaved(PropertyModel p) {
    final id = _idOf(p);
    return id != null && _ids.contains(id);
  }

  // Called whenever the signed-in user changes (login, logout, switch).
  void syncUser(String? userId) {
    final id = (userId == null || userId.isEmpty) ? null : userId;
    if (id == _userId) return;
    _userId = id;
    _ids.clear();
    // Defer: this runs during a provider update/build.
    Future.microtask(() {
      notifyListeners();
      if (id != null) _loadIds();
    });
  }

  Future<Response?> _post(Map<String, dynamic> fields) async {
    try {
      return await Dio()
          .post(endPoint('saved-properties.php'), data: FormData.fromMap(fields))
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('saved-properties failed: $e');
      return null;
    }
  }

  Future<void> _loadIds() async {
    final userId = _userId;
    final res = await _post({'action': 'ids', 'user_id': userId});
    if (userId != _userId) return; // user changed meanwhile
    final data = res?.data;
    if (data is Map && data['status'] == true && data['data'] is List) {
      _ids
        ..clear()
        ..addAll([for (final v in data['data']) int.tryParse('$v') ?? 0]);
      notifyListeners();
    }
  }

  // Optimistic toggle; reverts if the server call fails. Returns the new
  // saved state, or null when nobody is signed in.
  Future<bool?> toggle(PropertyModel p) async {
    final userId = _userId;
    final id = _idOf(p);
    if (userId == null || id == null) return null;
    final wasSaved = _ids.contains(id);
    wasSaved ? _ids.remove(id) : _ids.add(id);
    notifyListeners();

    final res = await _post({
      'action': 'toggle',
      'user_id': userId,
      'property_id': id,
    });
    final data = res?.data;
    if (data is Map && data['status'] == true) {
      final saved = data['saved'] == true;
      saved ? _ids.add(id) : _ids.remove(id);
      notifyListeners();
      return saved;
    }
    // Revert.
    wasSaved ? _ids.add(id) : _ids.remove(id);
    notifyListeners();
    return wasSaved;
  }

  // Full saved listings (newest saved first), for the Saved homes screen.
  Future<List<PropertyModel>> fetchSaved() async {
    if (_userId == null) return [];
    final res = await _post({'action': 'list', 'user_id': _userId});
    final data = res?.data;
    if (data is Map && data['status'] == true && data['data'] is List) {
      final list = <PropertyModel>[];
      for (final row in data['data'] as List) {
        try {
          list.add(PropertyModel.fromMap(row));
        } catch (_) {}
      }
      // Drop ids of listings that no longer exist.
      _ids
        ..clear()
        ..addAll(list.map(_idOf).whereType<int>());
      notifyListeners();
      return list;
    }
    return [];
  }
}
