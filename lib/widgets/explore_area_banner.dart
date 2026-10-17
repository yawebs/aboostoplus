import 'package:eafind/const/constant.dart';
import 'package:eafind/screens/explore_area/explore_area_screen.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:flutter/material.dart';

// Home-feed banner promoting the standalone AI "Explore an area" feature.
class ExploreAreaBanner extends StatelessWidget {
  const ExploreAreaBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.5)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => goTo(context, const ExploreAreaScreen(), false),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [deep, palette.primaryFill],
              ),
            ),
            child: Stack(
              children: [
                // Soft gold glow in the corner
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFFF5C76A).withValues(alpha: 0.35),
                        const Color(0xFFF5C76A).withValues(alpha: 0),
                      ]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFFF5C76A),
                            Color(0xFFE8A93B),
                          ]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.travel_explore_rounded,
                            color: Color(0xFF3F224F), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Explore any neighbourhood',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5C76A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('AI',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF3F224F))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Light, security, flooding, internet & landmarks for any area, before you move.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
