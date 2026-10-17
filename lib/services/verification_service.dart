import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/services/new_auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class IdType {
  final String key;
  final String label;
  final String hint;
  final RegExp pattern;
  final bool hasBack;
  const IdType(this.key, this.label, this.hint, this.pattern,
      {this.hasBack = true});
}

// Must match AV_ID_TYPES in lib/call/verification_lib.php.
final List<IdType> idTypes = [
  IdType('nin', 'NIN slip / card', '11-digit NIN', RegExp(r'^[0-9]{11}$')),
  IdType("drivers_licence", "Driver's licence", 'e.g. ABC12345AA12',
      RegExp(r'^[A-Z0-9]{8,15}$')),
  IdType('passport', 'Int\'l passport', 'e.g. A12345678',
      RegExp(r'^[A-Z]{1,2}[0-9]{7,8}$'),
      hasBack: false),
  IdType('voters_card', "Voter's card", '19-character VIN',
      RegExp(r'^[A-Z0-9]{16,20}$')),
];

IdType? idTypeFor(String key) {
  for (final t in idTypes) {
    if (t.key == key) return t;
  }
  return null;
}

class VerificationSubmission {
  final String status; // pending | approved | rejected
  final String legalName;
  final String businessName;
  final String idType;
  final String idNumberHint;
  final String rejectionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const VerificationSubmission({
    required this.status,
    required this.legalName,
    required this.businessName,
    required this.idType,
    required this.idNumberHint,
    required this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
  });

  factory VerificationSubmission.fromJson(Map json) => VerificationSubmission(
        status: (json['status'] ?? 'pending').toString(),
        legalName: (json['legal_name'] ?? '').toString(),
        businessName: (json['business_name'] ?? '').toString(),
        idType: (json['id_type'] ?? '').toString(),
        idNumberHint: (json['id_number_hint'] ?? '').toString(),
        rejectionReason: (json['rejection_reason'] ?? '').toString(),
        createdAt: DateTime.tryParse('${json['created_at']}'),
        reviewedAt: DateTime.tryParse('${json['reviewed_at']}'),
      );

  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}

class VerificationState {
  final bool isVerified;
  final VerificationSubmission? submission;
  const VerificationState(this.isVerified, this.submission);
}

class VerificationResult<T> {
  final T? data;
  final String? error;
  const VerificationResult.ok(this.data) : error = null;
  const VerificationResult.fail(this.error) : data = null;
  bool get ok => error == null;
}

// Agent identity verification (agent-verification.php). An admin reviews
// each submission; only approval turns on the verified badge.
class VerificationService {
  static Future<VerificationResult<Map>> _post(Map<String, dynamic> fields,
      {bool auth = true, Map<String, XFile?> files = const {}}) async {
    try {
      final headers = <String, String>{};
      if (auth) {
        final token = await NewAuthService.instance.getToken();
        if (token == null) {
          return const VerificationResult.fail(
              'Please log in again to continue');
        }
        headers['Authorization'] = 'Bearer $token';
      }
      final form = FormData.fromMap(fields);
      for (final e in files.entries) {
        final f = e.value;
        if (f == null) continue;
        form.files.add(MapEntry(
            e.key,
            kIsWeb
                ? MultipartFile.fromBytes(await f.readAsBytes(),
                    filename: f.name)
                : await MultipartFile.fromFile(f.path, filename: f.name)));
      }
      final res = await Dio().post(
        endPoint('agent-verification.php'),
        data: form,
        options: Options(
          headers: headers,
          validateStatus: (_) => true,
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      final body = res.data;
      if (body is Map) {
        if (body['success'] == true) return VerificationResult.ok(body);
        return VerificationResult.fail(
            (body['message'] ?? 'Something went wrong').toString());
      }
      return VerificationResult.fail(res.statusCode == 404
          ? 'Verification is not available yet. Please try again later.'
          : 'Something went wrong. Please try again.');
    } catch (e) {
      debugPrint('agent-verification failed: $e');
      return const VerificationResult.fail(
          'Could not reach the server. Check your connection.');
    }
  }

  static Future<VerificationResult<VerificationState>> status() async {
    final r = await _post({'action': 'status'});
    if (!r.ok) return VerificationResult.fail(r.error);
    final sub = r.data!['submission'];
    final state = VerificationState(
      r.data!['is_verified'] == true,
      sub is Map ? VerificationSubmission.fromJson(sub) : null,
    );
    return VerificationResult.ok(state);
  }

  static Future<VerificationResult<VerificationSubmission>> submit({
    required String legalName,
    required String businessName,
    required String officeAddress,
    required String state,
    required String cacNumber,
    required String idType,
    required String idNumber,
    required XFile idFront,
    XFile? idBack,
    required XFile selfie,
  }) async {
    final r = await _post({
      'action': 'submit',
      'legal_name': legalName,
      'business_name': businessName,
      'office_address': officeAddress,
      'state': state,
      'cac_number': cacNumber,
      'id_type': idType,
      'id_number': idNumber,
    }, files: {
      'id_front': idFront,
      'id_back': idBack,
      'selfie': selfie,
    });
    if (!r.ok) return VerificationResult.fail(r.error);
    return VerificationResult.ok(VerificationSubmission.fromJson(
        Map.from(r.data!['submission'] as Map)));
  }
}

// Which users are verified, for the badge. Badges anywhere in the app ask
// for a user id; ids requested in the same frame are looked up in one
// request and cached for the session.
class VerifiedUsers {
  VerifiedUsers._();
  static final VerifiedUsers instance = VerifiedUsers._();

  final Map<String, bool> _known = {};
  final Set<String> _queued = {};
  final Set<String> _inFlight = {};
  Timer? _timer;

  // Bumps whenever new answers arrive, so badges can rebuild.
  final ValueNotifier<int> changes = ValueNotifier(0);

  // true / false when known, null while it's being looked up.
  bool? isVerified(String userId) {
    if (userId.isEmpty) return false;
    final known = _known[userId];
    if (known != null) return known;
    if (!_inFlight.contains(userId)) {
      _queued.add(userId);
      _timer ??= Timer(const Duration(milliseconds: 60), _flush);
    }
    return null;
  }

  // Set when the user's own status is loaded from the server.
  void set(String userId, bool verified) {
    _known[userId] = verified;
    changes.value++;
  }

  // Drop a cached answer so the next badge build asks the server again.
  void forget(String userId) {
    if (_known.remove(userId) != null) changes.value++;
  }

  Future<void> _flush() async {
    _timer = null;
    final ids = _queued.toList();
    _queued.clear();
    if (ids.isEmpty) return;
    _inFlight.addAll(ids);
    final r = await VerificationService._post(
        {'action': 'lookup', 'ids': ids.join(',')},
        auth: false);
    _inFlight.removeAll(ids);
    if (!r.ok) return; // stay unknown; asked again next time a badge builds
    final verified = {
      for (final v in (r.data!['verified'] as List? ?? [])) v.toString()
    };
    for (final id in ids) {
      _known[id] = verified.contains(id);
    }
    changes.value++;
  }
}
