import 'package:flutter/material.dart';

// The app's neutral colors (page/card surfaces, text, borders) as a
// ThemeExtension, so they flip between light and dark with the ambient
// Theme. Reading them via `context.palette` registers a dependency on the
// Theme, which is what makes every screen - including ones already pushed
// on the Navigator - restyle itself when the theme changes.
//
// Only the mobile app ever switches to the dark palette (see AppTheme /
// main.dart); web keeps a light-only theme with no extension attached, and
// `context.palette` falls back to [AppPalette.light] there.
//
// Light values are identical to the constants they replaced
// (AppColors.* and the constant.dart globals white/black/lightGrey), so
// light mode looks exactly as it did before.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.cardBg,
    required this.card,
    required this.page,
    required this.tile,
    required this.chip,
    required this.raised,
    required this.raisedBorder,
    required this.raisedElevation,
    required this.textDark,
    required this.textGrey,
    required this.textLight,
    required this.border,
    required this.cardShadow,
    required this.paper,
    required this.paperAlt,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.accent,
    required this.primaryFill,
  });

  // Mirrors AppColors.
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color cardBg;
  // Raised white surfaces (cards, tiles, chips) that sat on a tinted page.
  final Color card;
  // Tinted page background, and the inset tile / chip fills that sit on it.
  final Color page;
  final Color tile;
  final Color chip;
  // Listing cards that float above the page. In dark mode a black shadow
  // alone is invisible, so they also get a lighter fill and a hairline border.
  final Color raised;
  final Color raisedBorder;
  final double raisedElevation;
  final Color textDark;
  final Color textGrey;
  final Color textLight;
  final Color border;
  final Color cardShadow;

  // Mirrors the legacy constant.dart globals: `white` (a lavender page/card
  // surface), `lightGrey`, and `black` / Colors.black87 / Colors.black54
  // when used as text or icon colors.
  final Color paper;
  final Color paperAlt;
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;

  // The brand purple when it's used as a text/icon/border color on a
  // surface (it needs to be lighter on dark surfaces), and when it's used
  // as a solid fill behind white content.
  final Color accent;
  final Color primaryFill;

  // Card() styling for a raised listing card.
  RoundedRectangleBorder get raisedShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: raisedBorder),
      );

  Color get paperOp => paper.withValues(alpha: .9);

  static const light = AppPalette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F6FA),
    surfaceAlt: Color(0xFFEFEFF6),
    cardBg: Color(0xFFF7F8FC),
    card: Color(0xFFFFFFFF),
    page: Color(0xFFF7F7F9),
    tile: Color(0xFFF7F7F9),
    chip: Color(0xFFF1F1F3),
    raised: Color(0xE6E6E6FA),
    raisedBorder: Color(0x00000000),
    raisedElevation: 1,
    textDark: Color(0xFF0D0D0D),
    textGrey: Color(0xFF8A8A8A),
    textLight: Color(0xFFBBBBBB),
    border: Color(0xFFE8E8E8),
    cardShadow: Color(0x1F3F224F),
    paper: Color(0xFFE6E6FA),
    paperAlt: Color(0xFFEEF3F3),
    ink: Color(0xFF000000),
    inkSoft: Color(0xDD000000),
    inkMuted: Color(0x8A000000),
    accent: Color(0xFF3F224F),
    primaryFill: Color(0xFF3F224F),
  );

  static const dark = AppPalette(
    background: Color(0xFF15111B),
    surface: Color(0xFF1D1824),
    surfaceAlt: Color(0xFF261F2F),
    cardBg: Color(0xFF211A29),
    card: Color(0xFF211A29),
    page: Color(0xFF15111B),
    tile: Color(0xFF2A2333),
    chip: Color(0xFF322A3D),
    raised: Color(0xFF2B2336),
    raisedBorder: Color(0x33CBA6DE),
    raisedElevation: 10,
    textDark: Color(0xFFF2EFF5),
    textGrey: Color(0xFFA79DB2),
    textLight: Color(0xFF6E647A),
    border: Color(0xFF332B3F),
    cardShadow: Color(0x66000000),
    paper: Color(0xFF1D1824),
    paperAlt: Color(0xFF261F2F),
    ink: Color(0xFFF2EFF5),
    inkSoft: Color(0xE6F2EFF5),
    inkMuted: Color(0x99F2EFF5),
    accent: Color(0xFFCBA6DE),
    primaryFill: Color(0xFF6A3D7A),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? cardBg,
    Color? card,
    Color? page,
    Color? tile,
    Color? chip,
    Color? raised,
    Color? raisedBorder,
    double? raisedElevation,
    Color? textDark,
    Color? textGrey,
    Color? textLight,
    Color? border,
    Color? cardShadow,
    Color? paper,
    Color? paperAlt,
    Color? ink,
    Color? inkSoft,
    Color? inkMuted,
    Color? accent,
    Color? primaryFill,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      cardBg: cardBg ?? this.cardBg,
      card: card ?? this.card,
      page: page ?? this.page,
      tile: tile ?? this.tile,
      chip: chip ?? this.chip,
      raised: raised ?? this.raised,
      raisedBorder: raisedBorder ?? this.raisedBorder,
      raisedElevation: raisedElevation ?? this.raisedElevation,
      textDark: textDark ?? this.textDark,
      textGrey: textGrey ?? this.textGrey,
      textLight: textLight ?? this.textLight,
      border: border ?? this.border,
      cardShadow: cardShadow ?? this.cardShadow,
      paper: paper ?? this.paper,
      paperAlt: paperAlt ?? this.paperAlt,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkMuted: inkMuted ?? this.inkMuted,
      accent: accent ?? this.accent,
      primaryFill: primaryFill ?? this.primaryFill,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      cardBg: l(cardBg, other.cardBg),
      card: l(card, other.card),
      page: l(page, other.page),
      tile: l(tile, other.tile),
      chip: l(chip, other.chip),
      raised: l(raised, other.raised),
      raisedBorder: l(raisedBorder, other.raisedBorder),
      raisedElevation: raisedElevation + (other.raisedElevation - raisedElevation) * t,
      textDark: l(textDark, other.textDark),
      textGrey: l(textGrey, other.textGrey),
      textLight: l(textLight, other.textLight),
      border: l(border, other.border),
      cardShadow: l(cardShadow, other.cardShadow),
      paper: l(paper, other.paper),
      paperAlt: l(paperAlt, other.paperAlt),
      ink: l(ink, other.ink),
      inkSoft: l(inkSoft, other.inkSoft),
      inkMuted: l(inkMuted, other.inkMuted),
      accent: l(accent, other.accent),
      primaryFill: l(primaryFill, other.primaryFill),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
