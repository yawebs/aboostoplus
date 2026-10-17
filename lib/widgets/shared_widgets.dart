import 'package:eafind/theme/app_palette.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';

class MiaButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final Widget? prefix;

  const MiaButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.prefix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? primaryColor : const Color(0xFFBCAEA8),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: isEnabled ? 2 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefix != null) ...[prefix!, const SizedBox(width: 8)],
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BackHeader extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;

  const BackHeader({Key? key, this.title, this.actions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Row(
            children: [
              Icon(Icons.chevron_left, color: white, size: 24),
              Text(
                title ?? 'Back',
                style: TextStyle(
                  color: white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (actions != null) ...actions!,
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const SectionTitle({Key? key, required this.text, this.style})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ??
          TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: white,
          ),
    );
  }
}

class FollowButton extends StatefulWidget {
  final bool initialFollowing;

  const FollowButton({Key? key, this.initialFollowing = false})
      : super(key: key);

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  late bool _following;

  @override
  void initState() {
    super.initState();
    _following = widget.initialFollowing;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _following = !_following),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _following ? context.palette.primaryFill : Colors.transparent,
          border: Border.all(color: context.palette.accent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _following ? 'Following' : 'Follow',
          style: TextStyle(
            color: _following ? Colors.white : context.palette.accent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;
  const TagChip({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: context.palette.textGrey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class NetworkImageWidget extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const NetworkImageWidget({
    Key? key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget img = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: context.palette.surface,
        child: Icon(Icons.image, color: context.palette.textLight),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: context.palette.surface,
          child: Center(
            child: CircularProgressIndicator(
              color: context.palette.accent,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}

// --- Web-only building blocks -------------------------------------------
// Everything below is net-new and only ever used from a screen's kIsWeb
// web-layout branch. Nothing here is referenced by any existing mobile
// build path, so adding these carries no risk to the mobile app.

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const AppCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.palette.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}

class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  const StatTile({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.palette.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: context.palette.textGrey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.palette.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: context.palette.textLight),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.palette.textDark,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.palette.textGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final String? hint;
  final String? label;
  final IconData? icon;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    Key? key,
    this.hint,
    this.label,
    this.icon,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.suffix,
    this.keyboardType,
    this.maxLines = 1,
    this.inputFormatters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.palette.textDark,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          onSaved: onSaved,
          maxLines: obscureText ? 1 : maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                icon != null ? Icon(icon, color: context.palette.textGrey, size: 20) : null,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

// Lays fields side-by-side once the available width clears
// [breakpoint], otherwise stacks them — used to make signup/edit-profile
// style forms (first/last name, state/city, etc.) responsive without
// each screen re-implementing the same LayoutBuilder logic.
class WebFormRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double breakpoint;

  const WebFormRow({
    Key? key,
    required this.children,
    this.spacing = 16,
    this.breakpoint = 420,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (children.length == 1 || constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const GradientHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// Describes one destination in the web app shell's nav (sidebar / rail /
// drawer, depending on viewport width).
class WebNavItem {
  final IconData icon;
  final String label;
  const WebNavItem({required this.icon, required this.label});
}

// Responsive app shell for the web build: a drawer+top-bar on narrow
// windows, a compact icon rail on tablet-width windows, and a full
// extended sidebar on desktop-width windows — all driven by the same
// `screens`/`currentIndex` state the mobile bottom-nav shell already
// tracks, so no navigation/state logic is duplicated.
class ResponsiveWebShell extends StatelessWidget {
  final List<WebNavItem> items;
  final List<Widget> screens;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String brandLabel;

  const ResponsiveWebShell({
    Key? key,
    required this.items,
    required this.screens,
    required this.currentIndex,
    required this.onTap,
    this.brandLabel = 'Aboostoplus',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (AppBreakpoints.isNarrow(width)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            brandLabel,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        drawer: Drawer(
          backgroundColor: AppColors.background,
          width: 280,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration:
                      const BoxDecoration(gradient: AppColors.heroGradient),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.home_work_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        brandLabel,
                        style: const TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _SidebarItem(
                            item: items[i],
                            selected: i == currentIndex,
                            extended: true,
                            light: false,
                            onTap: () {
                              Navigator.pop(context);
                              onTap(i);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: screens[currentIndex],
      );
    }

    final extended = AppBreakpoints.isWide(width);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(
            extended: extended,
            brandLabel: brandLabel,
            items: items,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          Expanded(child: screens[currentIndex]),
        ],
      ),
    );
  }
}

// The persistent desktop/tablet sidebar: a full-bleed brand-gradient
// panel (instead of a plain surface-colored NavigationRail) with the
// active item rendered as a floating white pill lifted off the
// gradient via a soft shadow — the same "elevated card on a colored
// rail" pattern used by most modern dashboard products.
class _Sidebar extends StatelessWidget {
  final bool extended;
  final String brandLabel;
  final List<WebNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _Sidebar({
    required this.extended,
    required this.brandLabel,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: extended ? 240 : 92,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        boxShadow: [
          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(6, 0)),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: 28, horizontal: extended ? 24 : 0),
              child: extended
                  ? Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.home_work_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            brandLabel,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.home_work_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: extended ? 14 : 14),
                children: [
                  for (var i = 0; i < items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _SidebarItem(
                        item: items[i],
                        selected: i == currentIndex,
                        extended: extended,
                        light: true,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Container(
                width: extended ? 40 : 32,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A single nav destination. `light: true` renders for the gradient
// sidebar (white pill when selected, translucent hover state);
// `light: false` renders for the narrow-width Drawer's plain
// background (tinted pill instead of white, since that surface is
// already light).
class _SidebarItem extends StatefulWidget {
  final WebNavItem item;
  final bool selected;
  final bool extended;
  final bool light;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.extended,
    required this.light,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (widget.light) {
      bg = widget.selected
          ? Colors.white
          : (_hovering ? Colors.white.withOpacity(.14) : Colors.transparent);
      fg = widget.selected ? AppColors.primary : Colors.white;
    } else {
      bg = widget.selected
          ? AppColors.primaryLight
          : (_hovering ? context.palette.surface : Colors.transparent);
      fg = widget.selected ? AppColors.primary : AppColors.textDark;
    }

    final content = widget.extended
        ? Row(
            children: [
              Icon(widget.item.icon, color: fg, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.item.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          )
        : Tooltip(
            message: widget.item.label,
            child: Center(child: Icon(widget.item.icon, color: fg, size: 22)),
          );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.extended
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 13)
              : const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.selected && widget.light
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(.18),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: content,
        ),
      ),
    );
  }
}

// Responsive property grid + card for the web browsing screens (home,
// explore, category tabs). Column count adapts to the available width
// via SliverGridDelegateWithMaxCrossAxisExtent rather than a fixed count,
// so it works unchanged from a narrow browser window up to a wide desktop
// one.
class WebPropertyGrid extends StatelessWidget {
  final List<PropertyModel> properties;
  final ValueChanged<PropertyModel> onTap;
  final double maxCardWidth;

  const WebPropertyGrid({
    Key? key,
    required this.properties,
    required this.onTap,
    this.maxCardWidth = 280,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: properties.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCardWidth,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final property = properties[index];
        return WebPropertyCard(
          property: property,
          onTap: () => onTap(property),
        );
      },
    );
  }
}

class WebPropertyCard extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback onTap;

  const WebPropertyCard({Key? key, required this.property, required this.onTap})
      : super(key: key);

  @override
  State<WebPropertyCard> createState() => _WebPropertyCardState();
}

class _WebPropertyCardState extends State<WebPropertyCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _hovering ? AppShadows.card : const [],
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    property.images.isEmpty
                        ? Container(color: AppColors.surface)
                        : property.isVideo == 1
                            ? _WebVideoThumb(url: property.images[0])
                            : CachedNetworkImage(
                                imageUrl: property.images[0],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.surface,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surface,
                                  child: Icon(Icons.image_not_supported,
                                      color: AppColors.textLight),
                                ),
                              ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          property.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 13, color: AppColors.textGrey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textGrey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₦${NumberFormat().format(property.amount)}${property.priceSuffix}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A static (non-autoplaying) video thumbnail for grid cards: initializes
// just far enough to show the first frame, then stays paused — so video
// listings get a real preview image instead of CachedNetworkImage trying
// (and failing) to load a video file as a still image.
class _WebVideoThumb extends StatefulWidget {
  final String url;
  const _WebVideoThumb({required this.url});

  @override
  State<_WebVideoThumb> createState() => _WebVideoThumbState();
}

class _WebVideoThumbState extends State<_WebVideoThumb> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize();
      await controller.setVolume(0);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else if (_failed)
            const Center(
              child: Icon(Icons.videocam_off_outlined, color: Colors.white54),
            )
          else
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              ),
            ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}
