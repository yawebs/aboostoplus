import 'package:eafind/services/verification_service.dart';
import 'package:flutter/material.dart';

// The verified tick. Renders NOTHING unless the server says this user passed
// agent verification (users.is_verified) - never shown by user type alone.
class VerifiedBadge extends StatelessWidget {
  final String userId;
  final double size;
  final Color? color;
  // Space before the tick when it shows (so callers don't leave a gap
  // after the name when it doesn't).
  final double gap;
  // Shows "Verified" next to the tick.
  final bool withLabel;

  const VerifiedBadge({
    Key? key,
    required this.userId,
    this.size = 15,
    this.color,
    this.gap = 4,
    this.withLabel = false,
  }) : super(key: key);

  static const blue = Color(0xFF1D9BF0);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: VerifiedUsers.instance.changes,
      builder: (context, _, __) {
        final verified = VerifiedUsers.instance.isVerified(userId) == true;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, a) =>
              ScaleTransition(scale: a, child: child),
          child: verified
              ? Padding(
                  key: const ValueKey('v'),
                  padding: EdgeInsets.only(left: gap),
                  child: Tooltip(
                    message: 'Verified agent - ID checked by Aboostoplus',
                    child: withLabel ? _pill() : _tick(),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('n')),
        );
      },
    );
  }

  Widget _tick() =>
      Icon(Icons.verified_rounded, size: size, color: color ?? blue);

  Widget _pill() {
    final c = color ?? blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: size - 2, color: c),
          const SizedBox(width: 3),
          Text('Verified',
              style: TextStyle(
                  fontSize: size - 4,
                  fontWeight: FontWeight.w700,
                  color: c)),
        ],
      ),
    );
  }
}
