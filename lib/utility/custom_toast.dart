import 'package:eafind/theme/app_palette.dart';
import 'dart:async';
import 'package:flutter/material.dart';

/// A reusable, custom-styled toast/snackbar widget that matches a
/// "Success" notification card design:
///
///  ┌────────────────────────────────────────────┐
///  │ ✔  Success!                                 │
///  │    Your vehicle document has been uploaded  │
///  │    and saved securely.                      │
///  └────────────────────────────────────────────┘
///
/// Usage:
/// ```dart
/// CustomToast.show(
///   context,
///   title: 'Success!',
///   message: 'Your vehicle document has been uploaded and saved securely.',
/// );
/// ```
///
/// You can also show error/info/warning variants:
/// ```dart
/// CustomToast.show(
///   context,
///   title: 'Something went wrong',
///   message: 'Please try again later.',
///   type: ToastType.error,
/// );
/// ```

enum ToastType { success, error, info, warning }

class _ToastStyle {
  final Color background;
  final Color border;
  final Color iconBackground;
  final Color iconColor;
  final IconData icon;

  const _ToastStyle({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.iconColor,
    required this.icon,
  });
}

class CustomToast {
  static OverlayEntry? _currentEntry;
  static Timer? _currentTimer;

  /// Shows the custom toast at the top of the screen (below the status bar).
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 5),
    ToastPosition position = ToastPosition.top,
  }) {
    // Remove any toast already showing so they don't stack.
    _dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);

    final entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        title: title,
        message: message,
        type: type,
        position: position,
        onDismissed: _dismiss,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _currentTimer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _currentTimer?.cancel();
    _currentTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

enum ToastPosition { top, bottom }

class _ToastOverlay extends StatefulWidget {
  final String title;
  final String message;
  final ToastType type;
  final ToastPosition position;
  final VoidCallback onDismissed;

  const _ToastOverlay({
    required this.title,
    required this.message,
    required this.type,
    required this.position,
    required this.onDismissed,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    final beginOffset = widget.position == ToastPosition.top
        ? const Offset(0, -0.3)
        : const Offset(0, 0.3);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slide = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _ToastStyle _styleFor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const _ToastStyle(
          background: Color(0xFFEAF9EF),
          border: Color(0xFF34C759),
          iconBackground: Colors.transparent,
          iconColor: Color(0xFF34C759),
          icon: Icons.check,
        );
      case ToastType.error:
        return const _ToastStyle(
          background: Color(0xFFFDEDEC),
          border: Color(0xFFE53935),
          iconBackground: Colors.transparent,
          iconColor: Color(0xFFE53935),
          icon: Icons.cancel_sharp,
        );
      case ToastType.warning:
        return const _ToastStyle(
          background: Color(0xFFFFF8E6),
          border: Color(0xFFF5A623),
          iconBackground: Colors.transparent,
          iconColor: Color(0xFFF5A623),
          icon: Icons.error,
        );
      case ToastType.info:
        return const _ToastStyle(
          background: Color(0xFFEAF2FE),
          border: Color(0xFF2F80ED),
          iconBackground: Colors.transparent,
          iconColor: Color(0xFF2F80ED),
          icon: Icons.info,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(widget.type);
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      top: widget.position == ToastPosition.top ? topInset + 12 : null,
      bottom: widget.position == ToastPosition.bottom ? bottomInset + 12 : null,
      left: 16,
      right: 16,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: widget.onDismissed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: style.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: style.border, width: 10),
                      top: BorderSide(color: style.border, width: 1),
                      right: BorderSide(color: style.border, width: 1),
                      bottom: BorderSide(color: style.border, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(style.icon, color: style.iconColor, size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.palette.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF5F6B66),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

/// --- Example usage ---
///
/// void main() => runApp(const MyApp());
///
/// class MyApp extends StatelessWidget {
///   const MyApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         appBar: AppBar(title: const Text('Custom Toast Demo')),
///         body: Center(
///           child: ElevatedButton(
///             onPressed: () {
///               CustomToast.show(
///                 context,
///                 title: 'Success!',
///                 message:
///                     'Your vehicle document has been uploaded and saved securely.',
///               );
///             },
///             child: const Text('Show Toast'),
///           ),
///         ),
///       ),
///     );
///   }
/// }
