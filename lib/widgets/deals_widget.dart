import 'package:eafind/theme/app_palette.dart';

import 'package:eafind/auths/auth_service.dart';
import 'package:eafind/models/chat_item_ref.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/refresh_deal_provider.dart';
import 'package:eafind/screens/house_details_screen.dart';
import 'package:eafind/screens/marketplace/chat_screen.dart';
import 'package:eafind/services/db_services.dart';
import 'package:flutter/material.dart';
import 'package:eafind/screens/services/moving_services_screen.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../const/constant.dart';
import '../providers/usermodel_provider.dart';
import 'change_status_widget.dart';

// Inspection "ticket": property + status, the booked date/time, then the
// other party (the client on an agent's dashboard, the agent on a
// customer's) with chat/call shortcuts.
class DealsWidget extends StatefulWidget {
  final dynamic data;
  // Colour behind the card - the ticket's side notches are painted in it.
  // Defaults to palette.surface (the dashboards' background).
  final Color? backgroundColor;
  const DealsWidget({Key? key, required this.data, this.backgroundColor})
      : super(key: key);

  @override
  State<DealsWidget> createState() => _DealsWidgetState();
}

class _DealsWidgetState extends State<DealsWidget> {
  PropertyModel? property;
  bool isLoading = true;
  UserModel? me;
  // The other party on this deal: the client if I'm the agent, else the agent.
  UserModel? counterpart;
  bool isDialing = false;

  bool get _iAmAgent =>
      me != null && me!.id == widget.data['agent_id'].toString();

  String get _status => (widget.data['dealStatus'] ?? 'Active').toString();

  bool get _isOpen => _status != 'Completed' && _status != 'Cancelled';

  @override
  void initState() {
    super.initState();
    me = Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    _load();
  }

  Future<void> _load() async {
    final otherId = _iAmAgent
        ? widget.data['customer_id'].toString()
        : widget.data['agent_id'].toString();
    final results = await Future.wait([
      DbServices.getSingleProperty(widget.data['property_id']),
      _fetchUser(otherId),
    ]);
    if (!mounted) return;
    setState(() {
      property = results[0] as PropertyModel?;
      counterpart = results[1] as UserModel?;
      isLoading = false;
    });
  }

  Future<UserModel?> _fetchUser(String id) async {
    try {
      final result = await AuthService.getUserById(id);
      final data = result?.data;
      if (data is Map && data['data'] is Map) {
        return UserModel.fromDoc(Map<String, dynamic>.from(data['data']));
      }
    } catch (e) {
      debugPrint('Deal party lookup failed: $e');
    }
    return null;
  }

  Future<void> _call() async {
    final phone = (counterpart?.phone ?? '').toString().trim();
    if (phone.isEmpty) {
      showToast('No phone number available');
      return;
    }
    setState(() => isDialing = true);
    await FlutterPhoneDirectCaller.callNumber('+234$phone');
    if (mounted) setState(() => isDialing = false);
  }

  void _chat() {
    final other = counterpart;
    if (me == null || other == null) return;
    goTo(
      context,
      ChatScreen(
        currentUserId: me!.id,
        receiverId: other.id,
        senderName: me!.firstName,
        senderImage: me!.profileImage,
        item: property == null ? null : ChatItemRef.fromProperty(property!),
      ),
      false,
    );
  }

  void _manage() {
    Provider.of<RefreshDealProvider>(context, listen: false)
        .setDealId(widget.data['id']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeStatusWidget(
        property: property,
        dealId: widget.data['id'],
        deal: Map<String, dynamic>.from(widget.data),
      ),
    );
  }

  // Stored as DateFormat.yMEd() ("Wed, 10/7/2026") + "08:52 AM".
  DateTime? get _when {
    try {
      final day = DateFormat.yMEd().parse(widget.data['inspection_date']);
      final time = DateFormat('hh:mm a').parse(widget.data['inspection_time']);
      return DateTime(day.year, day.month, day.day, time.hour, time.minute);
    } catch (_) {
      return null;
    }
  }

  String _relative(DateTime when) {
    final now = DateTime.now();
    final days = DateTime(when.year, when.month, when.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days == -1) return 'Yesterday';
    if (days > 1) return 'In $days days';
    return '${-days} days ago';
  }

  _StatusStyle _statusStyle() {
    switch (_status) {
      case 'Completed':
        return _StatusStyle(
            const Color(0xFF2E9E5B), Icons.check_circle_rounded, 'Completed');
      case 'Cancelled':
        return _StatusStyle(
            const Color(0xFFD64545), Icons.cancel_rounded, 'Cancelled');
      default:
        final when = _when;
        final overdue = when != null && when.isBefore(DateTime.now());
        return overdue
            ? _StatusStyle(const Color(0xFFE8A93B),
                Icons.pending_actions_rounded, 'Awaiting update')
            : _StatusStyle(context.palette.accent,
                Icons.event_available_rounded, 'Upcoming');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (isLoading) return _skeleton(palette);
    // property is null when the listing was deleted after booking - the
    // deal still exists, so show it from its own saved details.

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: property == null
              ? null
              : () => goTo(
                    context,
                    HouseDetailsScreen(
                        property: property!, isPreviewOnly: true),
                    false,
                  ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.border),
              boxShadow: [
                BoxShadow(
                  color: palette.cardShadow,
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _topSection(palette),
                _Perforation(
                    color: palette.border,
                    notch: widget.backgroundColor ?? palette.surface),
                _bottomSection(palette),
                // After a completed inspection, the customer is likely about
                // to move - offer movers/cleaners for the new area.
                if (_status == 'Completed' && !_iAmAgent) _movingPrompt(palette),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topSection(AppPalette palette) {
    final p = property;
    final status = _statusStyle();
    final when = _when;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: p == null || p.images.isEmpty || p.isVideo == 1
                      ? Container(
                          color: palette.tile,
                          child: Icon(Icons.home_work_outlined,
                              color: palette.inkMuted),
                        )
                      : Image.network(
                          p.images[0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: palette.tile,
                            child: Icon(Icons.home_work_outlined,
                                color: palette.inkMuted),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.data['property_title'] ??
                              p?.title ??
                              'Inspection')
                          .toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 13, color: palette.inkMuted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            p == null
                                ? 'Listing removed by the owner'
                                : '${p.category} · ${p.community}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 12, color: palette.inkSoft),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, size: 12, color: status.color),
                          const SizedBox(width: 4),
                          Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: status.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isOpen)
                IconButton(
                  tooltip: 'Update status',
                  visualDensity: VisualDensity.compact,
                  onPressed: _manage,
                  icon: Icon(Icons.more_horiz_rounded, color: palette.inkSoft),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Date block: calendar tile + time + how far away it is.
          Row(
            children: [
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: palette.primaryFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      when == null
                          ? '--'
                          : DateFormat('MMM').format(when).toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      when == null ? '--' : '${when.day}',
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      when == null
                          ? widget.data['inspection_date'].toString()
                          : DateFormat('EEEE, MMM d').format(when),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: palette.inkMuted),
                        const SizedBox(width: 4),
                        Text(
                          widget.data['inspection_time'].toString(),
                          style:
                              TextStyle(fontSize: 12, color: palette.inkSoft),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (when != null && _isOpen)
                Text(
                  _relative(when),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _movingPrompt(AppPalette palette) {
    final area = [property?.community, property?.city]
        .map((e) => (e ?? '').toString().trim())
        .where((e) => e.isNotEmpty && e != 'Unknown')
        .join(', ');
    return InkWell(
      onTap: () => goTo(
        context,
        MovingServicesScreen(movingTo: area.isEmpty ? null : area),
        false,
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
        decoration: BoxDecoration(
          color: palette.primaryFill.withValues(alpha: 0.08),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(20)),
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            Icon(Icons.local_shipping_rounded, color: palette.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Moving soon? Get quotes from movers & cleaners',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.inkMuted),
          ],
        ),
      ),
    );
  }

  Widget _bottomSection(AppPalette palette) {
    final other = counterpart;
    final role = _iAmAgent ? 'Client' : (property?.userType ?? 'Agent');
    final name = other == null
        ? (_iAmAgent
            ? (widget.data['customer_name'] ?? 'Client').toString()
            : (property?.userName ?? 'Agent'))
        : '${other.firstName} ${other.lastName}'.trim();
    final image = (other?.profileImage ?? '').toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: palette.tile,
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? Icon(Icons.person_rounded, size: 18, color: palette.inkMuted)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(fontSize: 11, color: palette.inkMuted),
                ),
              ],
            ),
          ),
          if (other != null) ...[
            _roundAction(palette, Icons.chat_bubble_rounded, _chat,
                filled: false),
            const SizedBox(width: 6),
            _roundAction(palette, Icons.call_rounded, _call,
                filled: true, loading: isDialing),
          ],
        ],
      ),
    );
  }

  Widget _roundAction(AppPalette palette, IconData icon, VoidCallback onTap,
      {required bool filled, bool loading = false}) {
    return Material(
      color: filled
          ? palette.primaryFill
          : palette.primaryFill.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: filled ? Colors.white : palette.accent),
                  )
                : Icon(icon,
                    size: 18, color: filled ? Colors.white : palette.accent),
          ),
        ),
      ),
    );
  }

  // Card-shaped placeholder, the same height as a real card, so the list
  // doesn't jump (the old 3x3 grid skeleton was far taller than a card).
  Widget _skeleton(AppPalette palette) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: palette.tile,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                bar(58, 58),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(150, 12),
                    const SizedBox(height: 8),
                    bar(100, 10),
                    const SizedBox(height: 8),
                    bar(70, 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                bar(48, 44),
                const SizedBox(width: 12),
                bar(120, 12),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                bar(32, 32),
                const SizedBox(width: 10),
                bar(110, 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color color;
  final IconData icon;
  final String label;
  const _StatusStyle(this.color, this.icon, this.label);
}

// Dashed tear line with half-circle notches on each edge, like a ticket stub.
class _Perforation extends StatelessWidget {
  final Color color;
  final Color notch;
  const _Perforation({required this.color, required this.notch});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        children: [
          _halfCircle(left: true),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              const dash = 5.0, gap = 4.0;
              final n = (c.maxWidth / (dash + gap)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  n,
                  (_) => Container(width: dash, height: 1.2, color: color),
                ),
              );
            }),
          ),
          _halfCircle(left: false),
        ],
      ),
    );
  }

  Widget _halfCircle({required bool left}) {
    return Container(
      width: 8,
      height: 16,
      decoration: BoxDecoration(
        color: notch,
        borderRadius: left
            ? const BorderRadius.horizontal(right: Radius.circular(8))
            : const BorderRadius.horizontal(left: Radius.circular(8)),
      ),
    );
  }
}
