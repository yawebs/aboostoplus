// report_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportResult {
  final bool success;
  final String? caseRef;
  final String? message;
  ReportResult({required this.success, this.caseRef, this.message});
}

class ReportService {
  // Point this at your PHP backend
  static const String baseUrl = 'https://aboostoplus.com/api';

  /// Submits a report for a property (houses.id) or agent (users.uniqueId).
  ///
  /// [userId]   the current user's uniqueId (matches users.uniqueId)
  /// [targetId] must be a STRING either way:
  ///   - property: the house's numeric id, as a string, e.g. '482'
  ///   - agent:    the agent's uniqueId, e.g. 'yr3Qgmvugq'
  Future<ReportResult> submitReport({
    required String userId,
    required String targetType, // 'property' | 'agent'
    required String targetId,
    required String reasonId,
    required String details,
    List<String> evidenceUrls = const [],
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/submit_report.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'target_type': targetType,
              'target_id': targetId,
              'reason_id': reasonId,
              'details': details,
              'evidence_urls': evidenceUrls,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.body.isEmpty) {
        return ReportResult(
          success: false,
          message:
              'Server returned an empty response (HTTP ${res.statusCode}). '
              'Check the PHP error log — likely a fatal error before any output.',
        );
      }

      late final Map<String, dynamic> body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        return ReportResult(
          success: false,
          message: 'Server returned non-JSON (HTTP ${res.statusCode}): '
              '${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}',
        );
      }

      if (res.statusCode == 200 && body['success'] == true) {
        return ReportResult(success: true, caseRef: body['case_ref']);
      }

      // TEMPORARY — folds PHP's debug detail into the visible message
      // so we can see the real cause. Remove the debugSuffix bit once
      // submit_report.php's debug field is removed.
      final debugSuffix = body['debug'] != null ? ' (${body['debug']})' : '';
      return ReportResult(
        success: false,
        message:
            (body['message'] ?? 'Something went wrong. Please try again.') +
                debugSuffix,
      );
    } catch (e) {
      return ReportResult(
        success: false,
        message:
            'Could not reach the server. Check your connection and try again.',
      );
    }
  }
}
