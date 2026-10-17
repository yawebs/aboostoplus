import 'dart:math' as math;

import 'package:eafind/models/house_type_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-launch tour of Aboostoplus's features. Each slide has its own animated
/// illustration; the background colour flows between slides as you swipe.
/// Shown once (see [FeatureTour.shouldShow]); Skip or Get started calls [onDone].
class FeatureTour extends StatefulWidget {
  final VoidCallback onDone;
  const FeatureTour({Key? key, required this.onDone}) : super(key: key);

  static const _prefKey = 'seen_feature_tour_v1';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefKey) ?? false);
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  @override
  State<FeatureTour> createState() => _FeatureTourState();
}

const _plum = Color(0xFF3F224F);
const _plum2 = Color(0xFF6A3D7A);
const _gold = Color(0xFFF5C76A);
const _amber = Color(0xFFE8A93B);
const _red = Color(0xFFE5484D);
const _green = Color(0xFF2FBF71);
const _blue = Color(0xFF3A86E0);

typedef _ArtBuilder = Widget Function(double t, double loop);

class _Slide {
  final String kicker;
  final String title;
  final String highlight;
  final String body;
  final Color top;
  final Color bottom;
  final _ArtBuilder art;
  const _Slide(this.kicker, this.title, this.highlight, this.body, this.top, this.bottom, this.art);
}

final List<_Slide> _slides = [
  _Slide('WELCOME TO ABOOSTOPLUS', 'Find your next home', 'without the wahala.',
      'Homes, land and service apartments, with everything you need to decide in one place.',
      const Color(0xFF4A2560), const Color(0xFF1A0D22), (t, l) => _WelcomeArt(t: t, loop: l)),
  _Slide('EXPLORE ANY NEIGHBOURHOOD', 'Know the area', 'before you move.',
      'AI Area Insights scores power, flooding, security, roads and more for any neighbourhood in Nigeria.',
      const Color(0xFF173A63), const Color(0xFF0D1626), (t, l) => _AreaArt(t: t, loop: l)),
  _Slide('VERIFIED AGENTS', 'Look for the', 'blue tick.',
      'Agents prove who they are with a government ID and a selfie, checked by our team.',
      const Color(0xFF1C3D6E), const Color(0xFF0E1A2E), (t, l) => _VerifiedArt(t: t, loop: l)),
  _Slide('NO SURPRISE FEES', 'Every fee upfront,', 'then talk price.',
      'See rent, agent, caution and legal fees before you inspect. Chat with the agent and book an inspection in the app.',
      const Color(0xFF5A2A3C), const Color(0xFF1E0D16), (t, l) => _FeesArt(t: t, loop: l)),
  _Slide('MOVING SOON?', 'Book help for', 'moving day.',
      'Movers, cleaners, painters, solar, plumbing, electrical and fumigation. Request a quote and agree a price in chat.',
      const Color(0xFF17483F), const Color(0xFF0B1F1B), (t, l) => _ServicesArt(t: t, loop: l)),
  _Slide('SAVED HOMES & ALERTS', 'Never miss', 'the right home.',
      'Save homes you love and turn on search alerts. We’ll tell you the moment a match is listed.',
      const Color(0xFF4A2560), const Color(0xFF1A0D22), (t, l) => _AlertsArt(t: t, loop: l)),
];

class _FeatureTourState extends State<FeatureTour> with TickerProviderStateMixin {
  final _pages = PageController();
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    _intro.forward(from: 0);
  }

  Future<void> _finish() async {
    await FeatureTour.markSeen();
    widget.onDone();
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _pages.nextPage(duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
    }
  }

  double get _page => _pages.hasClients && _pages.position.haveDimensions ? (_pages.page ?? 0) : _index.toDouble();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF120A18),
        body: AnimatedBuilder(
          animation: Listenable.merge([_pages, _loop]),
          builder: (context, _) {
            final page = _page;
            final i = page.floor().clamp(0, _slides.length - 1);
            final j = (i + 1).clamp(0, _slides.length - 1);
            final f = page - i;
            final top = Color.lerp(_slides[i].top, _slides[j].top, f)!;
            final bottom = Color.lerp(_slides[i].bottom, _slides[j].bottom, f)!;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
              ),
              child: Stack(
                children: [
                  ..._blobs(_loop.value),
                  SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          children: [
                            _topBar(),
                            Expanded(
                              child: PageView.builder(
                                controller: _pages,
                                itemCount: _slides.length,
                                onPageChanged: _onPageChanged,
                                itemBuilder: (context, n) => _slidePage(n, page),
                              ),
                            ),
                            _bottomBar(page),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _blobs(double loop) {
    final a = loop * 2 * math.pi;
    return [
      Positioned(
        left: -80 + 40 * math.sin(a),
        top: 80 + 30 * math.cos(a),
        child: _blob(260, Colors.white.withValues(alpha: .06)),
      ),
      Positioned(
        right: -100 + 30 * math.cos(a),
        bottom: 160 + 40 * math.sin(a),
        child: _blob(300, _gold.withValues(alpha: .08)),
      ),
    ];
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])),
      );

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 14, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
            child: Image.asset('assets/images/logo-icon.png', width: 26, height: 26),
          ),
          const SizedBox(width: 10),
          const Text('Aboostoplus', style: TextStyle(fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const Spacer(),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _isLast ? 0 : 1,
            child: TextButton(
              onPressed: _isLast ? null : _finish,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: .12),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
              child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slidePage(int n, double page) {
    final s = _slides[n];
    final delta = n - page; // -1..1 while swiping
    final t = n == _index ? Curves.linear.transform(_intro.value) : 1.0;
    final textIn = n == _index ? Curves.easeOutCubic.transform(((_intro.value - .15) / .5).clamp(0.0, 1.0)) : 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Opacity(
              opacity: (1 - delta.abs()).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(delta * 140, 0),
                child: Center(child: s.art(t, _loop.value)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Transform.translate(
            offset: Offset(delta * 40, (1 - textIn) * 26),
            child: Opacity(
              opacity: textIn * (1 - delta.abs()).clamp(0.0, 1.0),
              child: Column(
                children: [
                  Text(s.kicker,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12.5, letterSpacing: 2.6, color: _gold, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${s.title}\n'),
                      TextSpan(text: s.highlight, style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: _gold)),
                    ]),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Fraunces', fontSize: 31, height: 1.12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(s.body,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.5, color: Colors.white.withValues(alpha: .78))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _bottomBar(double page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 14, 26, 22),
      child: Row(
        children: [
          Row(
            children: List.generate(_slides.length, (n) {
              final closeness = (1 - (page - n).abs()).clamp(0.0, 1.0);
              return Container(
                margin: const EdgeInsets.only(right: 6),
                width: 8 + 20 * closeness,
                height: 8,
                decoration: BoxDecoration(
                  color: Color.lerp(Colors.white.withValues(alpha: .28), _gold, closeness),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _next,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              height: 58,
              width: _isLast ? 172 : 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_gold, _amber]),
                borderRadius: BorderRadius.circular(29),
                boxShadow: [BoxShadow(color: _amber.withValues(alpha: .45), blurRadius: 22, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(29),
                child: Center(
                  child: _isLast
                      ? const FittedBox(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('Get started', style: TextStyle(color: _plum, fontWeight: FontWeight.w800, fontSize: 16)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: _plum),
                          ]),
                        )
                      : const Icon(Icons.arrow_forward_rounded, color: _plum, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── helpers ─────────────────────────

double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
double _out(double x) => 1 - math.pow(1 - x, 3).toDouble();
double _back(double x) {
  const c = 1.9;
  return 1 + (c + 1) * math.pow(x - 1, 3) + c * math.pow(x - 1, 2);
}

Widget _pop(double k, Widget child) => Opacity(opacity: k.clamp(0.0, 1.0), child: Transform.scale(scale: _back(k), child: child));
Widget _rise(double k, Widget child, [double dy = 24]) =>
    Opacity(opacity: k, child: Transform.translate(offset: Offset(0, (1 - _out(k)) * dy), child: child));

BoxDecoration _card([double r = 22]) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 30, offset: const Offset(0, 14))],
    );

// ───────────────────────── illustrations ─────────────────────────

class _WelcomeArt extends StatelessWidget {
  final double t, loop;
  const _WelcomeArt({required this.t, required this.loop});

  static const _icons = [
    [Icons.travel_explore_rounded, _gold],
    [Icons.verified_rounded, _blue],
    [Icons.receipt_long_rounded, _amber],
    [Icons.chat_bubble_rounded, _green],
    [Icons.local_shipping_rounded, Color(0xFFD9578A)],
    [Icons.favorite_rounded, _red],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final r = math.min(c.maxWidth, c.maxHeight) * .38;
      final logo = _back(_seg(t, 0, .45));
      return SizedBox(
        width: r * 2 + 80,
        height: r * 2 + 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: r * 2,
              height: r * 2,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .12), width: 1.5)),
            ),
            Container(
              width: r * 1.3,
              height: r * 1.3,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold.withValues(alpha: .18), width: 1.5)),
            ),
            for (var n = 0; n < _icons.length; n++)
              Builder(builder: (_) {
                final a = n / _icons.length * 2 * math.pi + loop * 2 * math.pi;
                final k = _seg(t, .25 + n * .08, .6 + n * .08);
                final rr = r * _out(k);
                return Transform.translate(
                  offset: Offset(math.cos(a) * rr, math.sin(a) * rr),
                  child: _pop(k, Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: (_icons[n][1] as Color).withValues(alpha: .5), blurRadius: 18)],
                    ),
                    child: Icon(_icons[n][0] as IconData, color: _icons[n][1] as Color, size: 26),
                  )),
                );
              }),
            Opacity(
              opacity: _seg(t, 0, .2),
              child: Transform.scale(
                scale: logo * (1 + .03 * math.sin(loop * 2 * math.pi * 3)),
                child: Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: _gold.withValues(alpha: .45), blurRadius: 40, spreadRadius: 4)],
                  ),
                  child: Image.asset('assets/images/logo-icon.png'),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _AreaArt extends StatelessWidget {
  final double t, loop;
  const _AreaArt({required this.t, required this.loop});

  static const _rows = [
    [Icons.bolt_rounded, 'Electricity', 3, _amber],
    [Icons.flood_rounded, 'Flood safety', 2, _red],
    [Icons.shield_rounded, 'Security', 3, _amber],
    [Icons.add_road_rounded, 'Roads', 3, _amber],
    [Icons.wifi_rounded, 'Internet', 4, _green],
  ];

  @override
  Widget build(BuildContext context) {
    final bounce = -6 * math.sin(loop * 2 * math.pi * 3).abs();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pop(_seg(t, 0, .25), Transform.translate(
          offset: Offset(0, bounce),
          child: const Icon(Icons.location_on_rounded, color: _gold, size: 46, shadows: [Shadow(color: Colors.black54, blurRadius: 12)]),
        )),
        const SizedBox(height: 6),
        _rise(_seg(t, .05, .35), Container(
          width: 320,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: _card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [_plum2, _amber]), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('AI area insights', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1D1424))),
                    Text('Woji, Port Harcourt', style: TextStyle(fontSize: 12, color: Color(0xFF7D7088))),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              for (var n = 0; n < _rows.length; n++)
                Builder(builder: (_) {
                  final k = _out(_seg(t, .3 + n * .1, .7 + n * .1));
                  final score = _rows[n][2] as int;
                  final col = _rows[n][3] as Color;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      SizedBox(width: 24, child: Icon(_rows[n][0] as IconData, size: 17, color: col)),
                      SizedBox(width: 92, child: Text(_rows[n][1] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF3A2E44)))),
                      Expanded(
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(color: const Color(0xFFF0E9F4), borderRadius: BorderRadius.circular(5)),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: score / 5 * k,
                            child: Container(decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(5))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Opacity(opacity: k, child: Text('$score/5', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: col))),
                    ]),
                  );
                }),
            ],
          ),
        )),
      ],
    );
  }
}

class _VerifiedArt extends StatelessWidget {
  final double t, loop;
  const _VerifiedArt({required this.t, required this.loop});

  @override
  Widget build(BuildContext context) {
    final badge = _seg(t, .35, .65);
    final pulse = (loop * 3) % 1;
    return _rise(_seg(t, 0, .3), Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: _card(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_plum2, _plum])),
                alignment: Alignment.center,
                child: const Text('C', style: TextStyle(fontFamily: 'Fraunces', fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              Positioned(
                right: -22,
                bottom: -10,
                child: Stack(alignment: Alignment.center, children: [
                  if (badge >= 1)
                    Container(
                      width: 40 + 34 * pulse,
                      height: 40 + 34 * pulse,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _blue.withValues(alpha: (1 - pulse) * .7), width: 3)),
                    ),
                  _pop(badge, Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(Icons.verified_rounded, color: _blue, size: 38),
                  )),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Chidi Okafor', style: TextStyle(fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1D1424))),
          Opacity(
            opacity: badge,
            child: const Text('Verified agent · Port Harcourt', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _blue)),
          ),
          const SizedBox(height: 16),
          for (var n = 0; n < 3; n++)
            _rise(_seg(t, .55 + n * .12, .85 + n * .12), Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFEFF5FD), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: _green, size: 20),
                const SizedBox(width: 10),
                Text(const ['Government ID checked', 'Selfie matched', 'Reviewed by Aboostoplus'][n],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2B3A4E))),
              ]),
            ), 14),
        ],
      ),
    ));
  }
}

class _FeesArt extends StatelessWidget {
  final double t, loop;
  const _FeesArt({required this.t, required this.loop});

  @override
  Widget build(BuildContext context) {
    final rows = const [
      ['Rent', '₦2,500,000'],
      ['Agent fee · 10%', '₦250,000'],
      ['Caution (refundable)', '₦250,000'],
      ['Legal fee', '₦100,000'],
    ];
    return SizedBox(
      width: 330,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _rise(_seg(t, 0, .3), Container(
            margin: const EdgeInsets.only(right: 24, bottom: 70),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: _card(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Upfront cost breakdown', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1D1424))),
                const SizedBox(height: 10),
                for (var n = 0; n < rows.length; n++)
                  _rise(_seg(t, .2 + n * .1, .45 + n * .1), Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Expanded(child: Text(rows[n][0], style: TextStyle(fontSize: 13.5, color: n == 1 ? _plum2 : const Color(0xFF5A4F62), fontWeight: n == 1 ? FontWeight.w800 : FontWeight.w500))),
                      Text(rows[n][1], style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1D1424))),
                    ]),
                  ), 10),
                const Divider(height: 18),
                _rise(_seg(t, .6, .8), const Row(children: [
                  Expanded(child: Text('Estimated total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _plum))),
                  Text('₦3,100,000', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _plum)),
                ]), 8),
              ],
            ),
          )),
          Positioned(
            right: 0,
            bottom: 26,
            child: _rise(_seg(t, .7, .9), _bubble('Can we do 10% agent fee?', true), 20),
          ),
          Positioned(
            left: 8,
            bottom: -16,
            child: _rise(_seg(t, .85, 1), _bubble('Deal! Inspection on Saturday?', false), 20),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, bool me) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: me ? _plum : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(me ? 18 : 4),
            bottomRight: Radius.circular(me ? 4 : 18),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Text(text, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: me ? Colors.white : const Color(0xFF1D1424))),
      );
}

class _ServicesArt extends StatelessWidget {
  final double t, loop;
  const _ServicesArt({required this.t, required this.loop});

  @override
  Widget build(BuildContext context) {
    final names = homeServiceTypes;
    return LayoutBuilder(builder: (context, c) {
      final w = math.min(c.maxWidth, 340.0);
      return SizedBox(
        width: w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var n = 0; n < names.length; n++)
                  Builder(builder: (_) {
                    final info = homeServiceInfo[names[n]]!;
                    return _pop(_seg(t, .05 + n * .08, .4 + n * .08), Container(
                      width: (w - 20) / 3,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                      decoration: _card(18),
                      child: Column(children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: info.color, borderRadius: BorderRadius.circular(13)),
                          child: Icon(info.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(height: 7),
                        Text(names[n],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 11.5, height: 1.15, fontWeight: FontWeight.w700, color: Color(0xFF1D1424))),
                      ]),
                    ));
                  }),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 46,
              child: Stack(children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Container(height: 3, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .25), borderRadius: BorderRadius.circular(2))),
                ),
                Positioned(
                  left: -50 + (w + 60) * loop,
                  bottom: 8,
                  child: Transform.translate(
                    offset: Offset(0, -2 * math.sin(loop * 2 * math.pi * 12).abs()),
                    child: const Icon(Icons.local_shipping_rounded, color: _gold, size: 38),
                  ),
                ),
              ]),
            ),
          ],
        ),
      );
    });
  }
}

class _AlertsArt extends StatelessWidget {
  final double t, loop;
  const _AlertsArt({required this.t, required this.loop});

  @override
  Widget build(BuildContext context) {
    final beat = 1 + .14 * math.pow(math.sin(loop * 2 * math.pi * 2).abs(), 6);
    final drop = _seg(t, .45, .75);
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: drop,
            child: Transform.translate(
              offset: Offset(0, -60 * (1 - _back(drop))),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .96),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _plum, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.notifications_active_rounded, color: _gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Aboostoplus · now', style: TextStyle(fontSize: 11.5, color: Color(0xFF7D7088))),
                      Text('3 new homes match “2-bed in Woji”', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1D1424))),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var n = 0; n < 2; n++)
                Expanded(
                  child: _rise(_seg(t, n * .15, .35 + n * .15), Container(
                    margin: EdgeInsets.only(right: n == 0 ? 10 : 0),
                    decoration: _card(18),
                    clipBehavior: Clip.antiAlias,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Stack(children: [
                        Container(
                          height: 92,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: n == 0 ? const [Color(0xFFE2C9A0), Color(0xFFB98B57)] : const [Color(0xFFB9C7D6), Color(0xFF6E86A0)]),
                          ),
                          child: Icon(n == 0 ? Icons.house_rounded : Icons.apartment_rounded, color: Colors.white.withValues(alpha: .9), size: 54),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Transform.scale(
                            scale: n == 0 ? beat : 1,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Icon(n == 0 ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _red, size: 18),
                            ),
                          ),
                        ),
                      ]),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n == 0 ? 'Duplex · Woji' : 'Flat · Rumuodara',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1D1424))),
                          Text(n == 0 ? '₦5M / yr' : '₦2.5M / yr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _plum2)),
                        ]),
                      ),
                    ]),
                  )),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
