import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

enum _NetStatus { online, offline, poor, restored }

// Wraps the app (via MaterialApp.builder) and floats a status card in from
// the top whenever the device has no connectivity, or is connected to a
// network that can't actually reach the internet ("poor" - e.g. a wifi
// captive portal or a dead mobile connection). When the connection comes
// back it briefly confirms "Back online" before sliding away.
class NetworkStatusBanner extends StatefulWidget {
  final Widget child;
  const NetworkStatusBanner({Key? key, required this.child}) : super(key: key);

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  static const _offlineColor = Color(0xFFE5484D);
  static const _poorColor = Color(0xFFF5A524);
  static const _restoredColor = Color(0xFF30A46C);

  _NetStatus _status = _NetStatus.online;
  bool _retrying = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pollTimer;
  Timer? _restoreTimer;

  @override
  void initState() {
    super.initState();
    _checkNow();
    _subscription =
        Connectivity().onConnectivityChanged.listen((_) => _checkNow());
    // Catches the "connected to wifi/data but no real internet" case,
    // which a connectivity-change event alone never surfaces.
    _pollTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _checkNow());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pollTimer?.cancel();
    _restoreTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkNow() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      _setStatus(_NetStatus.offline);
      return;
    }
    final reachable = await _hasRealInternet();
    _setStatus(reachable ? _NetStatus.online : _NetStatus.poor);
  }

  Future<bool> _hasRealInternet() async {
    // Browsers already gate outgoing requests on real connectivity, so the
    // connectivity_plus check above is enough on web - dart:io's
    // InternetAddress.lookup isn't available there anyway.
    if (kIsWeb) return true;
    try {
      final lookup = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _setStatus(_NetStatus next) {
    if (!mounted) return;
    if (next == _NetStatus.online) {
      // Already fine, or already showing the "back online" confirmation
      // (its own timer takes us to online).
      if (_status == _NetStatus.online || _status == _NetStatus.restored) {
        return;
      }
      setState(() => _status = _NetStatus.restored);
      _restoreTimer?.cancel();
      _restoreTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && _status == _NetStatus.restored) {
          setState(() => _status = _NetStatus.online);
        }
      });
      return;
    }
    _restoreTimer?.cancel();
    if (_status == next) return;
    setState(() => _status = next);
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    // Keeps the spinner visible long enough to read as feedback even when
    // the check fails instantly.
    await Future.wait([
      _checkNow(),
      Future.delayed(const Duration(milliseconds: 600)),
    ]);
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _status != _NetStatus.online;
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: IgnorePointer(
              ignoring: !visible,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                offset: visible ? Offset.zero : const Offset(0, -1.5),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: visible ? 1 : 0,
                  // Sits above the Navigator, so there's no Material
                  // ancestor - without this the text picks up the default
                  // yellow double underline.
                  child: Material(
                    type: MaterialType.transparency,
                    child: _banner(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _banner() {
    final Color accent;
    final IconData icon;
    final String title;
    final String subtitle;
    switch (_status) {
      case _NetStatus.offline:
        accent = _offlineColor;
        icon = Icons.wifi_off_rounded;
        title = 'No internet connection';
        subtitle = 'Check your Wi-Fi or mobile data and try again';
        break;
      case _NetStatus.poor:
        accent = _poorColor;
        icon = Icons.network_check_rounded;
        title = 'Weak network connection';
        subtitle = 'Some content may load slowly or not at all';
        break;
      case _NetStatus.restored:
      case _NetStatus.online:
        accent = _restoredColor;
        icon = Icons.check_rounded;
        title = 'Back online';
        subtitle = 'Your connection has been restored';
        break;
    }
    final showRetry =
        _status == _NetStatus.offline || _status == _NetStatus.poor;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          if (showRetry) ...[
            const SizedBox(width: 8),
            _retryButton(accent),
          ],
        ],
      ),
    );
  }

  Widget _retryButton(Color accent) {
    return GestureDetector(
      onTap: _retry,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: _retrying
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: accent),
                )
              : Text(
                  'Retry',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
        ),
      ),
    );
  }
}
