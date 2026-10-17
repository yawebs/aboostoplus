import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/screens/agents/user_account.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/widgets/verified_badge.dart';
import 'package:flutter/material.dart';

class Reactor {
  final String userId;
  final String name;
  final String image;
  final String userType;
  final bool liked; // false = thumbs down
  const Reactor(this.userId, this.name, this.image, this.userType, this.liked);

  factory Reactor.fromJson(Map j) => Reactor(
        (j['user_id'] ?? '').toString(),
        (j['name'] ?? '').toString(),
        (j['image'] ?? '').toString(),
        (j['user_type'] ?? '').toString(),
        j['reaction'] == 'up',
      );
}

// "Who reacted" sheet for a property (reactions-list.php), with
// All / thumbs-up / thumbs-down tabs. Tapping a person opens their profile.
Future<void> showReactorsSheet(BuildContext context,
    {required int propertyId, bool startOnDislikes = false}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReactorsSheet(
        propertyId: propertyId, startOnDislikes: startOnDislikes),
  );
}

class _ReactorsSheet extends StatefulWidget {
  final int propertyId;
  final bool startOnDislikes;
  const _ReactorsSheet(
      {Key? key, required this.propertyId, required this.startOnDislikes})
      : super(key: key);

  @override
  State<_ReactorsSheet> createState() => _ReactorsSheetState();
}

class _ReactorsSheetState extends State<_ReactorsSheet> {
  static const _likeColor = Color(0xFF3A86E0);
  static const _dislikeColor = Color(0xFFE5484D);

  List<Reactor>? _all;
  String? _error;
  late int _tab = widget.startOnDislikes ? 2 : 0; // 0 all, 1 up, 2 down

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final res = await Dio().post(
        endPoint('reactions-list.php'),
        data: FormData.fromMap({'propertyId': widget.propertyId}),
        options: Options(validateStatus: (_) => true),
      );
      final body = res.data;
      if (body is Map && body['success'] == true) {
        if (!mounted) return;
        setState(() => _all = [
              for (final r in (body['data'] as List? ?? []))
                Reactor.fromJson(r as Map),
            ]);
        return;
      }
      throw Exception(res.statusCode == 404
          ? 'This is not available yet. Please try again later.'
          : 'Could not load reactions');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is Exception && '$e'.startsWith('Exception: ')
          ? '$e'.substring(11)
          : 'Could not load reactions. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final all = _all ?? const <Reactor>[];
    final likes = all.where((r) => r.liked).length;
    final dislikes = all.length - likes;
    final shown = _tab == 0
        ? all
        : all.where((r) => r.liked == (_tab == 1)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: palette.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text('Reactions',
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: palette.ink)),
                  const Spacer(),
                  if (_all != null)
                    Text('${all.length} ${all.length == 1 ? 'person' : 'people'}',
                        style:
                            TextStyle(fontSize: 13, color: palette.inkMuted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _chip(palette, 0, 'All', all.length, null, palette.accent),
                  const SizedBox(width: 8),
                  _chip(palette, 1, null, likes, Icons.thumb_up_rounded,
                      _likeColor),
                  const SizedBox(width: 8),
                  _chip(palette, 2, null, dislikes, Icons.thumb_down_rounded,
                      _dislikeColor),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: palette.border),
            Expanded(child: _body(palette, shown, controller)),
          ],
        ),
      ),
    );
  }

  Widget _body(
      AppPalette palette, List<Reactor> shown, ScrollController controller) {
    if (_error != null) {
      return _message(palette, Icons.cloud_off_rounded, _error!,
          action: TextButton(onPressed: _load, child: const Text('Try again')));
    }
    if (_all == null) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }
    if (shown.isEmpty) {
      return _message(
          palette,
          Icons.sentiment_neutral_rounded,
          _tab == 0
              ? 'No reactions yet'
              : _tab == 1
                  ? 'No thumbs up yet'
                  : 'No thumbs down yet');
    }
    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
          8, 6, 8, 16 + MediaQuery.of(context).padding.bottom),
      itemCount: shown.length,
      itemBuilder: (_, i) => _tile(palette, shown[i]),
    );
  }

  Widget _tile(AppPalette palette, Reactor r) {
    final color = r.liked ? _likeColor : _dislikeColor;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      onTap: r.userId.isEmpty
          ? null
          : () {
              Navigator.pop(context);
              goTo(context, UserAccount(userId: r.userId), false);
            },
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: palette.tile,
            backgroundImage: r.image.isNotEmpty ? NetworkImage(r.image) : null,
            onBackgroundImageError: r.image.isNotEmpty ? (_, __) {} : null,
            child: r.image.isEmpty
                ? Text(r.name.isEmpty ? '?' : r.name[0].toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                        fontSize: 17))
                : null,
          ),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: palette.paper, width: 2),
              ),
              child: Icon(
                  r.liked ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                  size: 10,
                  color: Colors.white),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(r.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: palette.ink)),
          ),
          VerifiedBadge(userId: r.userId, size: 15),
        ],
      ),
      subtitle: r.userType.isEmpty
          ? null
          : Text(r.userType,
              style: TextStyle(fontSize: 12.5, color: palette.inkMuted)),
      trailing: r.userId.isEmpty
          ? null
          : Icon(Icons.chevron_right_rounded, color: palette.inkMuted),
    );
  }

  Widget _chip(AppPalette palette, int index, String? label, int count,
      IconData? icon, Color color) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : palette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? color : palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 15, color: color),
            if (label != null)
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? color : palette.ink)),
            const SizedBox(width: 6),
            Text(_all == null ? '–' : '$count',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? color : palette.inkSoft)),
          ],
        ),
      ),
    );
  }

  Widget _message(AppPalette palette, IconData icon, String text,
          {Widget? action}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: palette.inkMuted),
              const SizedBox(height: 10),
              Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: palette.inkSoft)),
              if (action != null) ...[const SizedBox(height: 6), action],
            ],
          ),
        ),
      );
}
