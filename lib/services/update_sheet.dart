part of 'update_checker.dart';

// ---------------------------------------------------------------------------
// Update popup UI: animated dark hero with the app icon, old -> new
// version chips, "what's new" feature cards and a shimmering CTA.
// ---------------------------------------------------------------------------

class _NoteStyle {
  final IconData icon;
  final Color color;
  const _NoteStyle(this.icon, this.color);
}

class _UpdateSheet extends StatefulWidget {
  final _UpdateInfo info;
  final bool required;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;
  const _UpdateSheet({
    required this.info,
    required this.required,
    required this.onUpdate,
    this.onLater,
  });

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet>
    with TickerProviderStateMixin {
  static const _gold = Color(0xFFFDB813);
  static const _goldDeep = Color(0xFFF7821B);

  // Looping: icon glow pulse, sparkle twinkle, arrow nudge, button shimmer.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  // One-shot staggered entrance.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _loop.dispose();
    _intro.dispose();
    super.dispose();
  }

  // Fades + slides [child] in, starting at [start] (0-1) of the intro.
  Widget _stagger(double start, Widget child) {
    final end = (start + 0.45).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - anim.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final required = widget.required;
    final notes = widget.info.notes;
    return Container(
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: required
            ? BorderRadius.circular(30)
            : const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: !required,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _hero(palette),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _stagger(0.25, _versionRow(palette)),
                  const SizedBox(height: 14),
                  _stagger(
                    0.32,
                    Text(
                      required
                          ? 'This version is no longer supported. Update to '
                              'keep finding homes, chatting with agents and '
                              'booking inspections.'
                          : 'A faster, smoother Aboostoplus is ready for you. '
                              'Here is what is waiting:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: palette.inkSoft,
                      ),
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (var i = 0; i < notes.length; i++)
                      _stagger(
                        (0.4 + i * 0.08).clamp(0.0, 0.55),
                        _featureCard(palette, notes[i], i),
                      ),
                  ],
                  const SizedBox(height: 10),
                  _stagger(0.6, _ctaButton(palette)),
                  if (!required && widget.onLater != null)
                    _stagger(
                      0.65,
                      TextButton(
                        onPressed: widget.onLater,
                        child: Text(
                          'Maybe later',
                          style: TextStyle(
                            color: palette.inkMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    _stagger(
                      0.65,
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_clock_rounded,
                                size: 13, color: palette.inkMuted),
                            const SizedBox(width: 6),
                            Text(
                              'Required to continue',
                              style: TextStyle(
                                  fontSize: 11.5, color: palette.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dark gradient stage: rings, twinkling sparkles, and the app icon with
  // a pulsing glow and an orange "NEW" badge.
  Widget _hero(AppPalette palette) {
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.45)!;
    return SizedBox(
      height: 232,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [palette.primaryFill, deep],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (_, __) => CustomPaint(
                painter: _HeroPainter(progress: _loop.value, accent: _gold),
              ),
            ),
          ),
          if (!widget.required)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          Align(
            alignment: const Alignment(0, 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _appIcon(),
                const SizedBox(height: 16),
                _stagger(
                  0.1,
                  Text(
                    widget.required ? 'Time to update' : widget.info.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _stagger(
                  0.15,
                  Text(
                    widget.required
                        ? 'A required update is available'
                        : 'New version available',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appIcon() {
    return AnimatedBuilder(
      animation: _loop,
      builder: (_, child) {
        // 0 -> 1 -> 0 over each loop.
        final pulse = 0.5 - 0.5 * math.cos(_loop.value * 2 * math.pi);
        return Container(
          padding: EdgeInsets.all(6 + 4 * pulse),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.10 + 0.06 * pulse),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.25 + 0.25 * pulse),
                blurRadius: 24 + 16 * pulse,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child:
                Image.asset('assets/images/logo-icon.png', fit: BoxFit.contain),
          ),
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_gold, _goldDeep]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_upward_rounded,
                      size: 11, color: Colors.white),
                  SizedBox(width: 2),
                  Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _versionChip(AppPalette palette, String label, String version,
      {required bool isNew}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: palette.inkMuted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient:
                isNew ? const LinearGradient(colors: [_gold, _goldDeep]) : null,
            color: isNew ? null : palette.tile,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isNew
                ? [
                    BoxShadow(
                      color: _goldDeep.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            'v$version',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isNew ? Colors.white : palette.inkMuted,
              decoration: isNew ? null : TextDecoration.lineThrough,
              decorationColor: palette.inkMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _versionRow(AppPalette palette) {
    if (widget.info.version.isEmpty) {
      return Center(
        child: _versionChip(palette, 'YOUR VERSION', widget.info.currentVersion,
            isNew: false),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _versionChip(palette, 'CURRENT', widget.info.currentVersion,
            isNew: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: AnimatedBuilder(
            animation: _loop,
            builder: (_, child) => Transform.translate(
              offset: Offset(3 * math.sin(_loop.value * 2 * math.pi), 0),
              child: child,
            ),
            child: Icon(Icons.east_rounded, color: palette.accent, size: 20),
          ),
        ),
        _versionChip(palette, 'LATEST', widget.info.version, isNew: true),
      ],
    );
  }

  // Picks an icon/colour from the note's wording.
  _NoteStyle _noteStyle(AppPalette palette, String note, int index) {
    final n = note.toLowerCase();
    if (n.contains(' ai') || n.startsWith('ai') || n.contains('insight')) {
      return const _NoteStyle(Icons.auto_awesome_rounded, Color(0xFFF7821B));
    }
    if (n.contains('chat') || n.contains('message')) {
      return const _NoteStyle(Icons.forum_rounded, Color(0xFF3A86E0));
    }
    if (n.contains('fast') || n.contains('speed') || n.contains('perform')) {
      return const _NoteStyle(Icons.bolt_rounded, _goldDeep);
    }
    if (n.contains('fix') || n.contains('bug') || n.contains('stab')) {
      return const _NoteStyle(Icons.verified_rounded, Color(0xFF2E9E5B));
    }
    if (n.contains('design') || n.contains('look')) {
      return const _NoteStyle(Icons.palette_rounded, Color(0xFFD9578A));
    }
    const fallback = [
      Icons.star_rounded,
      Icons.rocket_launch_rounded,
      Icons.favorite_rounded,
    ];
    return _NoteStyle(fallback[index % fallback.length], palette.accent);
  }

  Widget _featureCard(AppPalette palette, String note, int index) {
    final style = _noteStyle(palette, note, index);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(style.icon, size: 19, color: style.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gradient CTA with a light shimmer sweeping across it.
  Widget _ctaButton(AppPalette palette) {
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.3)!;
    return GestureDetector(
      onTap: widget.onUpdate,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [palette.primaryFill, deep]),
          boxShadow: [
            BoxShadow(
              color: palette.primaryFill.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (_, c) => AnimatedBuilder(
                  animation: _loop,
                  builder: (_, __) {
                    final w = c.maxWidth;
                    return Stack(
                      children: [
                        Positioned(
                          left: -0.4 * w + _loop.value * 1.8 * w,
                          top: 0,
                          bottom: 0,
                          width: w * 0.35,
                          child: Transform(
                            transform: Matrix4.skewX(-0.35),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.white.withValues(alpha: 0),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Update now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Decorative hero background: soft concentric rings behind the icon, corner
// glows, and four-point sparkles that twinkle out of phase.
class _HeroPainter extends CustomPainter {
  final double progress;
  final Color accent;
  _HeroPainter({required this.progress, required this.accent});

  // dx, dy (fractions of size), radius, phase
  static const List<List<double>> _sparkles = [
    [0.12, 0.22, 7.0, 0.0],
    [0.86, 0.18, 9.0, 0.3],
    [0.80, 0.72, 6.0, 0.55],
    [0.18, 0.76, 8.0, 0.8],
    [0.93, 0.46, 5.0, 0.15],
    [0.06, 0.50, 5.0, 0.65],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.36);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      ring.color = Colors.white.withValues(alpha: 0.10 - i * 0.018);
      canvas.drawCircle(center, 52.0 + i * 34, ring);
    }

    final blob = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    blob.color = accent.withValues(alpha: 0.18);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 60, blob);
    blob.color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.95), 70, blob);

    final star = Paint()..style = PaintingStyle.fill;
    for (final s in _sparkles) {
      final t = (progress + s[3]) % 1.0;
      final twinkle = 0.5 - 0.5 * math.cos(t * 2 * math.pi);
      star.color = (s[2] > 7 ? accent : Colors.white)
          .withValues(alpha: 0.25 + 0.65 * twinkle);
      final r = s[2] * (0.6 + 0.4 * twinkle);
      final c = Offset(size.width * s[0], size.height * s[1]);
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(path, star);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPainter old) => old.progress != progress;
}
