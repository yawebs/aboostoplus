import 'package:eafind/theme/app_palette.dart';
import 'dart:convert';
import 'package:eafind/auths/auth_service.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart'; // Imports your active conversation file

class MessagesScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserImage;

  const MessagesScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserImage,
  }) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

enum _Filter { all, awaitingReply }

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String _query = '';
  _Filter _filter = _Filter.all;
  final TextEditingController _searchController = TextEditingController();

  // Partner profiles looked up by the app, for servers still returning the
  // old "Chat Partner <id>" placeholder (and the sender's own photo).
  final Map<String, UserModel> _partnerCache = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardConversations() async {
    final url = endPoint(
        'fetch_conversation.php?current_user_id=${widget.currentUserId}');
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          final list = [
            for (final c in decoded['data'] as List)
              Map<String, dynamic>.from(c),
          ];
          if (!mounted) return;
          setState(() {
            _conversations = list;
            _isLoading = false;
          });
          _resolveMissingPartners(list);
          return;
        }
      }
    } catch (e) {
      debugPrint("Error loading conversation dashboard list: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  bool _needsLookup(Map<String, dynamic> chat) {
    final name = (chat['name'] ?? '').toString();
    // Old server responses: placeholder name, and no user_type field.
    return name.isEmpty ||
        name.startsWith('Chat Partner') ||
        name.startsWith('User ') ||
        !chat.containsKey('user_type');
  }

  Future<void> _resolveMissingPartners(List<Map<String, dynamic>> list) async {
    final ids = {
      for (final c in list)
        if (_needsLookup(c) &&
            !_partnerCache.containsKey(c['partner_id'].toString()))
          c['partner_id'].toString(),
    };
    if (ids.isEmpty) return;
    await Future.wait(ids.map((id) async {
      try {
        final result = await AuthService.getUserById(id);
        final data = result?.data;
        if (data is Map && data['data'] is Map) {
          _partnerCache[id] =
              UserModel.fromDoc(Map<String, dynamic>.from(data['data']));
        }
      } catch (_) {}
    }));
    if (mounted) setState(() {});
  }

  // ---------- Per-conversation display values ----------

  UserModel? _cached(Map<String, dynamic> c) =>
      _partnerCache[c['partner_id'].toString()];

  String _name(Map<String, dynamic> c) {
    final cached = _cached(c);
    if (cached != null) {
      final full = '${cached.firstName} ${cached.lastName}'.trim();
      if (full.isNotEmpty) return full;
    }
    final name = (c['name'] ?? '').toString();
    if (name.isEmpty || name.startsWith('Chat Partner')) return 'Aboostoplus user';
    return name;
  }

  String _image(Map<String, dynamic> c) {
    final cached = _cached(c);
    if (cached != null) return (cached.profileImage ?? '').toString();
    // Old responses put the *sender's* photo here - mine when I sent last.
    if (_needsLookup(c) && _fromMe(c)) return '';
    return (c['profile_image'] ?? '').toString();
  }

  String _role(Map<String, dynamic> c) =>
      (_cached(c)?.userType ?? c['user_type'] ?? '').toString();

  bool _fromMe(Map<String, dynamic> c) {
    if (c['last_from_me'] is bool) return c['last_from_me'] as bool;
    return (c['last_message'] ?? '').toString().startsWith('You: ');
  }

  String _preview(Map<String, dynamic> c) {
    if (c['message'] != null) return c['message'].toString();
    final raw = (c['last_message'] ?? '').toString();
    return raw.startsWith('You: ') ? raw.substring(5) : raw;
  }

  // "10:24 AM" today, "Yesterday", weekday this week, else "07 Oct".
  String _when(Map<String, dynamic> c) {
    final ts = DateTime.tryParse((c['timestamp'] ?? '').toString());
    if (ts == null) return (c['date'] ?? '').toString();
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(ts.year, ts.month, ts.day))
        .inDays;
    if (days == 0) return DateFormat('h:mm a').format(ts);
    if (days == 1) return 'Yesterday';
    if (days < 7) return DateFormat('EEE').format(ts);
    return DateFormat('dd MMM').format(ts);
  }

  bool _awaitingReply(Map<String, dynamic> c) => c['is_unread'] == true;

  List<Map<String, dynamic>> get _visible {
    final q = _query.trim().toLowerCase();
    return _conversations.where((c) {
      if (_filter == _Filter.awaitingReply && !_awaitingReply(c)) return false;
      if (q.isEmpty) return true;
      return _name(c).toLowerCase().contains(q) ||
          _preview(c).toLowerCase().contains(q) ||
          (c['item_title'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  void _open(Map<String, dynamic> chat) {
    final UserModel? me =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUserId: widget.currentUserId,
          receiverId: chat['partner_id'].toString(),
          senderImage: me?.profileImage ?? widget.currentUserImage,
          senderName: me?.firstName ?? widget.currentUserName,
        ),
      ),
    ).then((_) => _loadDashboardConversations()); // Refresh list when returning
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.page,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            _searchAndFilters(context),
            const SizedBox(height: 8),
            Expanded(child: _listArea(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: context.palette.surface,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: context.palette.page,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppShadows.card,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context),
                    _searchAndFilters(context),
                    const SizedBox(height: 8),
                    Expanded(child: _listArea(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final palette = context.palette;
    final count = _conversations.length;
    final awaiting = _conversations.where(_awaitingReply).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => goBack(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: palette.ink),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: palette.ink,
                  ),
                ),
                if (!_isLoading)
                  Text(
                    count == 0
                        ? 'No conversations yet'
                        : awaiting > 0
                            ? '$count conversations · $awaiting awaiting your reply'
                            : '$count conversation${count == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12.5, color: palette.inkSoft),
                  ),
              ],
            ),
          ),
          _Avatar(
            image: widget.currentUserImage,
            name: widget.currentUserName,
            radius: 21,
            ring: palette.accent,
          ),
        ],
      ),
    );
  }

  Widget _searchAndFilters(BuildContext context) {
    final palette = context.palette;
    final awaiting = _conversations.where(_awaitingReply).length;
    Widget chip(String label, _Filter f, {int? count}) {
      final selected = _filter == f;
      return GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? palette.primaryFill : palette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? palette.primaryFill : palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : palette.ink,
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : palette.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: palette.ink, fontSize: 14.5),
            decoration: InputDecoration(
              hintText: 'Search people, messages or listings',
              hintStyle: TextStyle(color: palette.inkMuted, fontSize: 14),
              filled: true,
              fillColor: palette.card,
              isDense: true,
              prefixIcon: Icon(Icons.search_rounded, color: palette.inkMuted),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: palette.inkMuted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: palette.accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              chip('All', _Filter.all),
              const SizedBox(width: 8),
              chip('Awaiting reply', _Filter.awaitingReply, count: awaiting),
            ],
          ),
        ],
      ),
    );
  }

  Widget _listArea(BuildContext context) {
    final palette = context.palette;
    if (_isLoading) {
      return ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.only(top: 8),
        itemBuilder: (_, __) => const _TileSkeleton(),
      );
    }
    final items = _visible;
    return RefreshIndicator(
      color: palette.accent,
      onRefresh: _loadDashboardConversations,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _emptyState(
                  context,
                  searching: _query.isNotEmpty || _filter != _Filter.all,
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  0, 4, 0, 16 + MediaQuery.of(context).padding.bottom),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final c = items[index];
                return ConversationTile(
                  name: _name(c),
                  subtext: _preview(c),
                  date: _when(c),
                  image: _image(c),
                  isUnread: _awaitingReply(c),
                  fromMe: _fromMe(c),
                  role: _role(c),
                  itemTitle: (c['item_title'] ?? '').toString(),
                  itemImage: (c['item_image'] ?? '').toString(),
                  onTap: () => _open(c),
                );
              },
            ),
    );
  }

  Widget _emptyState(BuildContext context, {required bool searching}) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 70, 32, 0),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                palette.primaryFill.withValues(alpha: 0.18),
                palette.primaryFill.withValues(alpha: 0.05),
              ]),
            ),
            child: Icon(
              searching ? Icons.search_off_rounded : Icons.forum_outlined,
              size: 40,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            searching ? 'No matching conversations' : 'No messages yet',
            style: TextStyle(
              color: palette.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Try another name or clear the filter.'
                : 'Message an agent or seller from any listing - your conversations will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.inkSoft, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class ConversationTile extends StatelessWidget {
  final String name;
  final String subtext;
  final String date;
  final String image;
  final bool isUnread;
  final bool fromMe;
  final String role;
  final String itemTitle;
  final String itemImage;
  final VoidCallback onTap;

  const ConversationTile({
    Key? key,
    required this.name,
    required this.subtext,
    required this.date,
    required this.image,
    required this.isUnread,
    required this.onTap,
    this.fromMe = false,
    this.role = '',
    this.itemTitle = '',
    this.itemImage = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _Avatar(
                image: image,
                name: name,
                radius: 26,
                ring: isUnread ? palette.accent : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isUnread ? FontWeight.w800 : FontWeight.w600,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        if (role.isNotEmpty && role != 'User') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color:
                                  palette.primaryFill.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: palette.accent,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: isUnread ? palette.accent : palette.inkMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Sent by me: a double tick instead of a "You:" prefix.
                        if (fromMe) ...[
                          Icon(Icons.done_all_rounded,
                              size: 15, color: palette.accent),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            subtext,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnread ? palette.ink : palette.inkSoft,
                              fontWeight:
                                  isUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: palette.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // The listing being discussed, when the server sends it.
                    if (itemTitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: itemImage.isEmpty
                                  ? Container(
                                      color: palette.tile,
                                      child: Icon(Icons.home_outlined,
                                          size: 12, color: palette.inkMuted),
                                    )
                                  : Image.network(itemImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(color: palette.tile)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              itemTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: palette.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

// Photo avatar that falls back to the person's initial (instead of a broken
// network image) when there's no photo.
class _Avatar extends StatelessWidget {
  final String image;
  final String name;
  final double radius;
  final Color? ring;
  const _Avatar(
      {required this.image,
      required this.name,
      required this.radius,
      this.ring});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: palette.primaryFill.withValues(alpha: 0.14),
      backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
      onBackgroundImageError: image.isNotEmpty ? (_, __) {} : null,
      child: image.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            )
          : null,
    );
    if (ring == null) return avatar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring!, width: 2),
      ),
      child: avatar,
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: palette.tile,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(radius: 26, backgroundColor: palette.tile),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(140, 13),
              const SizedBox(height: 8),
              bar(200, 11),
            ],
          ),
        ],
      ),
    );
  }
}
