import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/services/new_auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ServiceProvider {
  final int id;
  final String ownerId;
  final String businessName;
  final String category;
  final String description;
  final String state;
  final String areas;
  final num? startingPrice;
  final String phone;
  final List<String> images;
  final String ownerName;
  final String ownerImage;
  final DateTime? createdAt;

  const ServiceProvider({
    required this.id,
    required this.ownerId,
    required this.businessName,
    required this.category,
    required this.description,
    required this.state,
    required this.areas,
    required this.startingPrice,
    required this.phone,
    required this.images,
    required this.ownerName,
    required this.ownerImage,
    this.createdAt,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> j) => ServiceProvider(
        id: int.tryParse('${j['id']}') ?? 0,
        ownerId: '${j['owner_id'] ?? ''}',
        businessName: '${j['business_name'] ?? ''}',
        category: '${j['category'] ?? ''}',
        description: '${j['description'] ?? ''}',
        state: '${j['state'] ?? ''}',
        areas: '${j['areas'] ?? ''}',
        startingPrice: num.tryParse('${j['starting_price']}'),
        phone: '${j['phone'] ?? ''}',
        images: [
          for (final i in (j['images'] is List ? j['images'] as List : []))
            '$i',
        ],
        ownerName: '${j['owner_name'] ?? ''}',
        ownerImage: '${j['owner_image'] ?? ''}',
        createdAt: DateTime.tryParse('${j['created_at']}'),
      );
}

// Result of a call: data on success, otherwise a message to show.
class ServiceResult<T> {
  final T? data;
  final String? error;
  const ServiceResult.ok(this.data) : error = null;
  const ServiceResult.fail(this.error) : data = null;
  bool get ok => error == null;
}

// Moving & home service providers (service-providers.php) - separate from
// the marketplace.
class ServiceProvidersService {
  static Future<ServiceResult<Map>> _post(Map<String, dynamic> fields,
      {bool auth = false, List<MultipartFile> photos = const []}) async {
    try {
      final headers = <String, String>{};
      if (auth) {
        final token = await NewAuthService.instance.getToken();
        if (token == null) {
          return const ServiceResult.fail('Please log in again to continue');
        }
        headers['Authorization'] = 'Bearer $token';
      }
      final form = FormData.fromMap(fields);
      // Added one by one under the exact name PHP reads ($_FILES['photos']).
      for (final p in photos) {
        form.files.add(MapEntry('photos[]', p));
      }
      final res = await Dio().post(
        endPoint('service-providers.php'),
        data: form,
        options: Options(headers: headers, validateStatus: (_) => true),
      );
      final body = res.data;
      if (body is Map) {
        if (body['success'] == true) return ServiceResult.ok(body);
        return ServiceResult.fail(
            (body['message'] ?? 'Something went wrong').toString());
      }
      return ServiceResult.fail(res.statusCode == 404
          ? 'Services are not available yet. Please try again later.'
          : 'Something went wrong. Please try again.');
    } catch (e) {
      debugPrint('service-providers failed: $e');
      return const ServiceResult.fail(
          'Could not reach the server. Check your connection.');
    }
  }

  static List<ServiceProvider> _list(Map body) => [
        for (final p in (body['data'] as List? ?? []))
          ServiceProvider.fromJson(Map<String, dynamic>.from(p)),
      ];

  static Future<ServiceResult<List<ServiceProvider>>> byCategory(
      String category) async {
    final r = await _post({'action': 'list', 'category': category});
    return r.ok ? ServiceResult.ok(_list(r.data!)) : ServiceResult.fail(r.error);
  }

  // Newest providers across all categories (home screen section).
  static Future<ServiceResult<List<ServiceProvider>>> featured() async {
    final r = await _post({'action': 'featured'});
    return r.ok ? ServiceResult.ok(_list(r.data!)) : ServiceResult.fail(r.error);
  }

  static Future<ServiceResult<List<ServiceProvider>>> mine() async {
    final r = await _post({'action': 'mine'}, auth: true);
    return r.ok ? ServiceResult.ok(_list(r.data!)) : ServiceResult.fail(r.error);
  }

  static Future<ServiceResult<bool>> delete(int id) async {
    final r = await _post({'action': 'delete', 'id': id}, auth: true);
    return r.ok ? const ServiceResult.ok(true) : ServiceResult.fail(r.error);
  }

  static Future<ServiceResult<ServiceProvider>> create({
    required String businessName,
    required String category,
    required String description,
    required String state,
    required String areas,
    required String phone,
    num? startingPrice,
    required List<XFile> photos,
  }) async {
    final r = await _post({
      'action': 'create',
      'business_name': businessName,
      'category': category,
      'description': description,
      'state': state,
      'areas': areas,
      'phone': phone,
      if (startingPrice != null) 'starting_price': startingPrice.toString(),
    }, auth: true, photos: [
      for (final p in photos)
        MultipartFile.fromBytes(await p.readAsBytes(), filename: p.name),
    ]);
    if (!r.ok) return ServiceResult.fail(r.error);
    return ServiceResult.ok(
        ServiceProvider.fromJson(Map<String, dynamic>.from(r.data!['data'])));
  }
}
