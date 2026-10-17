import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/services/providers/saved_homes_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Heart toggle for saving a listing. Pops when tapped; asks guests to log in.
//   onImage: true  -> frosted dark circle for use over photos
//   onImage: false -> plain icon for light surfaces (e.g. card headers)
class SaveButton extends StatefulWidget {
  final PropertyModel property;
  final bool onImage;
  final double size;
  const SaveButton({
    Key? key,
    required this.property,
    this.onImage = true,
    this.size = 34,
  }) : super(key: key);

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _toggle(SavedHomesProvider saved) async {
    if (!saved.hasUser) {
      showToast('Log in to save homes');
      goTo(context, const LoginScreen(fromNav: false), false);
      return;
    }
    _pop.forward(from: 0);
    final nowSaved = await saved.toggle(widget.property);
    if (!mounted) return;
    if (nowSaved == true) {
      showToast('Saved to your homes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedHomesProvider>();
    final isSaved = saved.isSaved(widget.property);
    const red = Color(0xFFE5484D);
    final iconColor = isSaved
        ? red
        : (widget.onImage ? Colors.white : Colors.grey.shade600);

    final icon = AnimatedBuilder(
      animation: _pop,
      builder: (_, child) {
        // Quick overshoot: 1 -> 1.35 -> 1
        final t = _pop.value;
        final scale = t == 0 ? 1.0 : 1 + 0.35 * (t < 0.4 ? t / 0.4 : (1 - t) / 0.6);
        return Transform.scale(scale: scale, child: child);
      },
      child: Icon(
        isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: iconColor,
        size: widget.size * 0.56,
      ),
    );

    return Semantics(
      button: true,
      label: isSaved ? 'Remove from saved homes' : 'Save home',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggle(saved),
        child: widget.onImage
            ? Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Center(child: icon),
              )
            : SizedBox(
                width: widget.size,
                height: widget.size,
                child: Center(child: icon),
              ),
      ),
    );
  }
}
