import 'package:eafind/models/house_type_model.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// The "Property type" field on the listing form: shows the chosen type
/// with its icon, and opens a sheet of icon tiles grouped by kind.
class PropertyTypeField extends StatelessWidget {
  final String? value;
  final List<String> types;
  final ValueChanged<String> onChanged;

  const PropertyTypeField({
    Key? key,
    required this.value,
    required this.types,
    required this.onChanged,
  }) : super(key: key);

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PropertyTypeSheet(types: types, selected: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chosen = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Property type',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: p.textDark)),
        const SizedBox(height: 8),
        Material(
          color: chosen ? p.accent.withValues(alpha: 0.08) : p.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _open(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: chosen ? p.accent.withValues(alpha: 0.5) : p.border,
                  width: chosen ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Container(
                      key: ValueKey(value),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        gradient: chosen
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFC45A06), Color(0xFF161616)],
                              )
                            : null,
                        color: chosen ? null : p.card,
                      ),
                      child: Icon(
                        chosen
                            ? propertyTypeIcon(value!)
                            : Icons.category_outlined,
                        color: chosen ? const Color(0xFFF7821B) : p.textGrey,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chosen
                              ? propertyTypeLabel(value!)
                              : 'Choose property type',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: chosen ? p.textDark : p.textGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          chosen
                              ? propertyTypeHint(value!)
                              : 'House, apartment, land, office…',
                          style: TextStyle(fontSize: 12, color: p.textGrey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chosen ? 'Change' : 'Choose',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: p.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PropertyTypeSheet extends StatelessWidget {
  final List<String> types;
  final String? selected;
  const _PropertyTypeSheet({required this.types, required this.selected});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Group the available types; anything not in a known group goes last.
    final grouped = <String, List<String>>{};
    final placed = <String>{};
    propertyTypeGroups.forEach((group, members) {
      final present = members.where(types.contains).toList();
      if (present.isNotEmpty) grouped[group] = present;
      placed.addAll(present);
    });
    final rest = types.where((t) => !placed.contains(t)).toList();
    if (rest.isNotEmpty) grouped['Other'] = rest;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('What are you listing?',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: p.textDark,
                )),
            const SizedBox(height: 4),
            Text('Pick the type that best matches your property.',
                style: TextStyle(fontSize: 13, color: p.textGrey)),
            for (final entry in grouped.entries) ...[
              const SizedBox(height: 20),
              Text(entry.key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: p.accent,
                  )),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                primary: false,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
                children: [
                  for (final t in entry.value)
                    _TypeTile(
                      type: t,
                      selected: t == selected,
                      onTap: () => Navigator.of(context).pop(t),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final String type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeTile(
      {required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Bedroom types share an icon, so the count goes on a small badge.
    final beds = RegExp(r'^(\d)Bed').firstMatch(type)?.group(1);
    return Material(
      color: selected ? p.primaryFill : p.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? p.primaryFill : p.border),
          ),
          child: Stack(
            children: [
              if (selected)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.check_circle_rounded,
                      size: 18, color: Color(0xFFF7821B)),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? Colors.white.withValues(alpha: 0.14)
                              : p.accent.withValues(alpha: 0.10),
                        ),
                        child: Icon(propertyTypeIcon(type),
                            size: 24,
                            color:
                                selected ? const Color(0xFFF7821B) : p.accent),
                      ),
                      if (beds != null)
                        Positioned(
                          right: -4,
                          bottom: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7821B),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: selected ? p.primaryFill : p.card,
                                  width: 2),
                            ),
                            child: Text(beds,
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1a1a1a))),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    propertyTypeLabel(type),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : p.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    propertyTypeHint(type),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.75)
                          : p.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
