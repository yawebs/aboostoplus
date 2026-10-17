import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

part 'update_sheet.dart';

// Prompts users to update when a newer build is published.
// Driven by lib/call/app-version.php - see the instructions at its top.
//   build < min_build    -> blocking "Update required" screen
//   build < latest_build -> dismissible "Update available" sheet,
//                           re-shown 3 days after "Later"
class UpdateChecker {
  static const _snoozeKey = 'update_prompt_snoozed';
  static const _snooze = Duration(days: 3);
  static bool _checkedThisLaunch = false;

  // TEMPORARY - design preview only. While true, the "Update available"
  // sheet shows on every launch regardless of versions/snooze/server.
  // Set back to false before releasing!
  static const bool _previewForTesting = false;

  static Future<void> check(BuildContext context) async {
    if (kIsWeb || _checkedThisLaunch) return;
    _checkedThisLaunch = true;
    if (_previewForTesting) {
      await _showPreview(context);
      return;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final response = await Dio()
          .get(endPoint('app-version.php'))
          .timeout(const Duration(seconds: 10));
      final raw = response.data;
      if (raw is! Map) return;
      final cfg = _forThisPlatform(raw);

      final latest = int.tryParse('${cfg['latest_build']}') ?? 0;
      final minimum = int.tryParse('${cfg['min_build']}') ?? 0;
      // latest_build 0 = this platform isn't configured yet: never prompt.
      if (latest <= 0 || currentBuild >= latest) return;

      final update = _UpdateInfo(
        title: (cfg['title'] ?? 'A new update is available').toString(),
        version: (cfg['latest_version'] ?? '').toString(),
        currentVersion: info.version,
        notes: [
          for (final n in (cfg['notes'] is List ? cfg['notes'] as List : []))
            n.toString(),
        ],
        storeUrl: (cfg['store_url'] ?? '').toString(),
      );

      if (!context.mounted) return;
      if (currentBuild < minimum) {
        await _showRequired(context, update);
        return;
      }

      // Optional update: respect a recent "Later" for this same build.
      final prefs = await SharedPreferences.getInstance();
      final snoozed = prefs.getString(_snoozeKey);
      if (snoozed != null) {
        final parts = snoozed.split('|');
        final snoozedBuild = int.tryParse(parts.first) ?? 0;
        final until = DateTime.tryParse(parts.length > 1 ? parts[1] : '');
        if (snoozedBuild == latest &&
            until != null &&
            DateTime.now().isBefore(until)) {
          return;
        }
      }
      if (!context.mounted) return;
      final later = await _showOptional(context, update);
      if (later == true) {
        await prefs.setString(_snoozeKey,
            '$latest|${DateTime.now().add(_snooze).toIso8601String()}');
      }
    } catch (e) {
      // Never block the app because the version check failed.
      debugPrint('Update check skipped: $e');
    }
  }

  // TEMPORARY - used by _previewForTesting. Uses the server's title/notes
  // when app-version.php is reachable, else sample text.
  static Future<void> _showPreview(BuildContext context) async {
    String version = '';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    Map cfg = {};
    try {
      final r = await Dio()
          .get(endPoint('app-version.php'))
          .timeout(const Duration(seconds: 6));
      if (r.data is Map) cfg = _forThisPlatform(r.data as Map);
    } catch (_) {}
    final notes = cfg['notes'] is List
        ? [for (final n in cfg['notes'] as List) n.toString()]
        : [
            'Redesigned chats, inspections and home feed',
            'AI insights about the area around every listing',
            'Faster loading and bug fixes',
          ];
    final update = _UpdateInfo(
      title: (cfg['title'] ?? 'A fresh update is here').toString(),
      version: '${cfg['latest_version'] ?? ''}'.isEmpty
          ? '99.0.0'
          : cfg['latest_version'].toString(),
      currentVersion: version,
      notes: notes,
      storeUrl: (cfg['store_url'] ?? '').toString(),
    );
    if (!context.mounted) return;
    await _showOptional(context, update);
  }

  // Android and iOS have independent version/build numbers, so the server
  // config has a block per platform under `platforms`. Shared keys (title,
  // notes) fall through from the top level. Older server configs without
  // `platforms` are read as before.
  static Map _forThisPlatform(Map raw) {
    final key = Platform.isIOS ? 'ios' : 'android';
    final platforms = raw['platforms'];
    if (platforms is Map && platforms[key] is Map) {
      return {...raw, ...(platforms[key] as Map)};
    }
    return {
      ...raw,
      'store_url': Platform.isIOS ? raw['ios_url'] : raw['android_url'],
    };
  }

  static Future<void> _openStore(_UpdateInfo u) async {
    final url = u.storeUrl.isNotEmpty
        ? u.storeUrl
        : 'https://play.google.com/store/apps/details?id=com.aboostoplus.app';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // Returns true when the user tapped "Later".
  static Future<bool?> _showOptional(BuildContext context, _UpdateInfo u) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpdateSheet(
        info: u,
        required: false,
        onUpdate: () {
          Navigator.pop(ctx, false);
          _openStore(u);
        },
        onLater: () => Navigator.pop(ctx, true),
      ),
    );
  }

  static Future<void> _showRequired(BuildContext context, _UpdateInfo u) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: context.palette.page,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _UpdateSheet(
                    info: u,
                    required: true,
                    // Stays on this screen: returning from the store
                    // without updating shows it again.
                    onUpdate: () => _openStore(u),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateInfo {
  final String title;
  final String version;
  final String currentVersion;
  final List<String> notes;
  final String storeUrl;
  const _UpdateInfo({
    required this.title,
    required this.version,
    required this.currentVersion,
    required this.notes,
    required this.storeUrl,
  });
}
