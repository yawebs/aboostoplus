import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_filter.dart';
import 'package:flutter/foundation.dart';

class SearchAlert {
  final int id;
  final String label;
  final PropertyFilter filter;
  final String keyword;
  final bool active;
  final DateTime? createdAt;

  const SearchAlert({
    required this.id,
    required this.label,
    required this.filter,
    required this.keyword,
    required this.active,
    this.createdAt,
  });

  factory SearchAlert.fromJson(Map<String, dynamic> j) {
    final f = j['filters'] is Map
        ? Map<String, dynamic>.from(j['filters'])
        : <String, dynamic>{};
    return SearchAlert(
      id: int.tryParse('${j['id']}') ?? 0,
      label: (j['label'] ?? '').toString(),
      filter: PropertyFilter.fromAlertJson(f),
      keyword: (f['keyword'] ?? '').toString(),
      active: j['active'] == true,
      createdAt: DateTime.tryParse('${j['created_at']}'),
    );
  }
}

// Saved searches that push a notification when a matching listing is
// uploaded (matching runs server-side in search_alerts_lib.php).
class SearchAlertsService {
  // Set when the last call reached the server but it couldn't handle it
  // (e.g. endpoint not deployed -> 404 page), as opposed to no connection.
  static bool _serverProblem = false;

  static Future<Map?> _post(Map<String, dynamic> fields) async {
    _serverProblem = false;
    try {
      final res = await Dio()
          .post(endPoint('search-alerts.php'), data: FormData.fromMap(fields))
          .timeout(const Duration(seconds: 15));
      if (res.data is Map) return res.data as Map;
      _serverProblem = true; // got HTML/text instead of JSON
      return null;
    } on DioException catch (e) {
      debugPrint('search-alerts failed: $e');
      _serverProblem = e.response != null; // server answered with an error
      return null;
    } catch (e) {
      debugPrint('search-alerts failed: $e');
      return null;
    }
  }

  static Future<List<SearchAlert>?> list(String userId) async {
    final data = await _post({'action': 'list', 'user_id': userId});
    if (data == null || data['status'] != true) return null;
    return [
      for (final a in (data['data'] as List))
        SearchAlert.fromJson(Map<String, dynamic>.from(a)),
    ];
  }

  // Returns null on success, else a message to show.
  static Future<String?> create(
      String userId, PropertyFilter filter, String keyword) async {
    final data = await _post({
      'action': 'create',
      'user_id': userId,
      'label': filter.describe(keyword),
      'filters': jsonEncode(filter.toAlertJson(keyword)),
    });
    if (data == null) {
      return _serverProblem
          ? 'Search alerts are not available right now. Please try again later.'
          : 'Could not save the alert. Check your connection.';
    }
    if (data['status'] != true) {
      return (data['message'] ?? 'Could not save the alert').toString();
    }
    return null;
  }

  static Future<bool> delete(String userId, int id) async {
    final data = await _post({'action': 'delete', 'user_id': userId, 'id': id});
    return data?['status'] == true;
  }

  static Future<bool?> toggle(String userId, int id) async {
    final data = await _post({'action': 'toggle', 'user_id': userId, 'id': id});
    if (data?['status'] != true) return null;
    return data!['active'] == true;
  }
}
