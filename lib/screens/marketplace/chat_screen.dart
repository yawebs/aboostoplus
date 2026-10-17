import 'package:eafind/widgets/verified_badge.dart';
import 'package:eafind/theme/app_palette.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:eafind/auths/auth_service.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/chat_item_ref.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String senderName;
  // Was `dynamic` — that let callers pass null (e.g. a user with no
  // profile photo), which then silently broke the message POST (see
  // _sendMessage). Marked nullable explicitly and normalized at the
  // point of use instead of forcing every call site to guard it.
  final String? senderImage;
  // Optional draft placed in the composer (not sent) - e.g. the inspection
  // screen pre-fills which property the user is asking about.
  final String? initialMessage;
  // The product/property this chat is about, when opened from one. When
  // null (e.g. opened from the Messages list) it's recovered from the
  // conversation's messages instead.
  final ChatItemRef? item;

  const ChatScreen(
      {Key? key,
      required this.currentUserId,
      required this.receiverId,
      required this.senderName,
      required this.senderImage,
      this.initialMessage,
      this.item})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [];
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  UserModel? recieverUserModel;
  bool isLoadingUser = false;
  bool _isLoadingHistory = false;
  bool _isComposing = false;
  final ScrollController _scrollController = ScrollController();

  // Item pinned at the top: the one passed in, else the most recent item
  // referenced in the conversation.
  ChatItemRef? _item;

  void _adoptItemFrom(Map<String, dynamic> msg) {
    final ref = ChatItemRef.fromMessage(msg);
    if (ref != null) _item = ref;
  }

  getUser() async {
    setState(() {
      isLoadingUser = true;
    });
    try {
      Response response = await AuthService.getUserById(widget.receiverId);
      if (response.statusCode == 200) {
        UserModel user = UserModel.fromDoc(response.data['data']);
        setState(() {
          recieverUserModel = user;
          isLoadingUser = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoadingUser = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _fetchChatHistory();
    getUser();
    _initPusher();
    _controller.addListener(() {
      final composing = _controller.text.trim().isNotEmpty;
      if (composing != _isComposing) {
        setState(() => _isComposing = composing);
      }
    });
    // Rebuild so the composer's border highlights while focused.
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    final draft = widget.initialMessage?.trim() ?? '';
    if (draft.isNotEmpty) {
      _controller.text = draft;
      _isComposing = true;
    }
  }

  void _initPusher() async {
    try {
      await pusher.init(
        apiKey: pusherKey,
        cluster: pusherCluster,
        onEvent: (PusherEvent event) {
          if (event.eventName == "new-message") {
            final decodedData = Map<String, dynamic>.from(
                jsonDecode(event.data.toString()));
            // "chat-room" is one shared channel, so only take messages the
            // other person sent to me - otherwise other users' chats leak
            // into this conversation.
            if (decodedData['sender_id'] == widget.receiverId &&
                decodedData['receiver_id'] == widget.currentUserId) {
              if (!mounted) return;
              setState(() {
                _messages.add(decodedData);
                _adoptItemFrom(decodedData);
              });
              _scrollToBottom();
            }
          }
        },
      );
      await pusher.subscribe(channelName: "chat-room");
      await pusher.connect();
    } catch (e) {
      debugPrint("Pusher connection failed: $e");
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String messageText = _controller.text.trim();
    _controller.clear();
    setState(() => _isComposing = false);

    // widget.senderImage can be null (e.g. no profile photo). http.post's
    // body must be Map<String, String> — a null value throws a cast
    // error the instant the http package tries to url-encode the form
    // fields, and that throw happens BEFORE the request leaves the
    // device. The catch block below then swallows it silently: the
    // bubble still renders optimistically (nothing looks obviously
    // wrong in the UI), but send_message.php is never actually hit —
    // meaning the DB insert, the Pusher event, AND the FCM push
    // notification never fire. This is very likely why notifications
    // stopped working after the redesign introduced a caller that can
    // pass a null image.
    final String senderImage = (widget.senderImage ?? '').toString();

    final localMessage = {
      'sender_id': widget.currentUserId,
      'receiver_id': widget.receiverId,
      'message': messageText,
      'sender_name': widget.senderName,
      'sender_image': senderImage,
      'timestamp': DateTime.now().toString(),
      'is_sending': true,
    };

    setState(() {
      _messages.add(localMessage);
    });
    _scrollToBottom();
    await _dispatch(localMessage);
  }

  // Tapping a failed bubble re-sends it in place.
  void _retry(Map<String, dynamic> msg) {
    setState(() {
      msg['failed'] = false;
      msg['is_sending'] = true;
    });
    _dispatch(msg);
  }

  Future<void> _dispatch(Map<String, dynamic> localMessage) async {
    final String messageText = localMessage['message'].toString();
    final String senderImage = localMessage['sender_image'].toString();
    try {
      final response = await http.post(
        Uri.parse(endPoint('send_message.php')),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          'sender_id': widget.currentUserId,
          'receiver_id': widget.receiverId,
          'message': messageText,
          'sender_name': widget.senderName,
          'sender_image': senderImage,
          // Tags the message with the item being discussed so the other
          // side sees it pinned too.
          ...?_item?.toFields(),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          localMessage['is_sending'] = false;
        });
      } else {
        debugPrint(
            "Failed to dispatch message (${response.statusCode}): ${response.body}");
        _handleMessageFailure(localMessage);
      }
    } catch (e, st) {
      // Logging the stack trace too — a silent catch here is exactly
      // what let the null-cast issue above go unnoticed.
      debugPrint("Network error dispatching message: $e\n$st");
      _handleMessageFailure(localMessage);
    }
  }

  Future<void> _fetchChatHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });
    final String rawUrl = endPoint(
        'fetch_messages.php?sender_id=${widget.currentUserId}&receiver_id=${widget.receiverId}');

    try {
      final response = await http
          .get(Uri.parse(rawUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse['status'] == 'success') {
          List<dynamic> historyData = decodedResponse['data'];

          setState(() {
            _messages.addAll(
                historyData.map((msg) => Map<String, dynamic>.from(msg)));
            // Opened without an item (e.g. from the Messages list): pin
            // the latest item the conversation referenced.
            if (widget.item == null) {
              for (final msg in _messages) {
                _adoptItemFrom(msg);
              }
            }
            _isLoadingHistory = false;
          });

          _scrollToBottom();
        } else {
          setState(() => _isLoadingHistory = false);
        }
      } else {
        debugPrint("Failed loading database history logs: ${response.body}");
        setState(() => _isLoadingHistory = false);
      }
    } catch (e) {
      debugPrint("Error pulling background data sync logs: $e");
      setState(() => _isLoadingHistory = false);
    }
  }

  void _handleMessageFailure(Map<String, dynamic> failedMsg) {
    if (!mounted) return;
    setState(() {
      failedMsg['failed'] = true;
      failedMsg['is_sending'] = false;
    });
  }

  // ---------- UI helpers ----------

  DateTime? _parseTime(dynamic timestamp) {
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp.toString());
  }

  String _formatTime(String? timestamp) {
    final dt = _parseTime(timestamp);
    return dt == null ? '' : DateFormat('h:mm a').format(dt);
  }

  // "Today" / "Yesterday" / "Mon, Oct 6" (adds the year if it isn't this one).
  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return d.year == now.year
        ? DateFormat('EEE, MMM d').format(d)
        : DateFormat('MMM d, yyyy').format(d);
  }

  bool _startsNewDay(int index) {
    final current = _parseTime(_messages[index]['timestamp']);
    if (current == null) return false;
    if (index == 0) return true;
    final previous = _parseTime(_messages[index - 1]['timestamp']);
    return previous == null ||
        previous.year != current.year ||
        previous.month != current.month ||
        previous.day != current.day;
  }

  // Groups consecutive messages from the same sender so avatars/spacing
  // only show once per "burst" of messages, like most chat apps.
  bool _isFirstInGroup(int index) {
    if (index == 0 || _startsNewDay(index)) return true;
    return _messages[index]['sender_id'] != _messages[index - 1]['sender_id'];
  }

  bool _isLastInGroup(int index) {
    if (index == _messages.length - 1) return true;
    if (_startsNewDay(index + 1)) return true;
    return _messages[index]['sender_id'] != _messages[index + 1]['sender_id'];
  }

  String get _receiverName {
    final user = recieverUserModel;
    if (user == null) return '';
    final full = '${user.firstName} ${user.lastName}'.trim();
    return full.isNotEmpty ? full : user.userName.toString();
  }

  String get _receiverImage =>
      (recieverUserModel?.profileImage ?? '').toString();

  String get _receiverPhone => (recieverUserModel?.phone ?? '').toString();

  Future<void> _callReceiver() async {
    final phone = _receiverPhone.trim();
    if (phone.isEmpty) return;
    await FlutterPhoneDirectCaller.callNumber('+234$phone');
  }

  // Starter questions on an empty chat, tuned to what's being discussed.
  List<String> get _suggestions {
    final item = _item;
    if (item == null) {
      return ['Hello! 👋', 'Is this still available?', 'Can we talk?'];
    }
    if (item.type == 'property') {
      return [
        'Is this still available?',
        'When can I come for an inspection?',
        'Is the price negotiable?',
      ];
    }
    return [
      'Is this still available?',
      "What's your final price?",
      'Where can I pick it up?',
    ];
  }

  void _useSuggestion(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: context.palette.page,
          body: _chatLayout(context, showStatusBarInset: true),
        ),
      ),
    );
  }

  // Same layout as mobile, framed as a centered panel.
  Widget _buildWeb(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: context.palette.page,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.card,
              ),
              clipBehavior: Clip.antiAlias,
              child: _chatLayout(context, showStatusBarInset: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chatLayout(BuildContext context, {required bool showStatusBarInset}) {
    final hasItem = _item != null;
    return Column(
      children: [
        // Header with the item card floating over its bottom edge.
        Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: hasItem ? 44 : 0),
              child: _buildHeader(context, showStatusBarInset),
            ),
            if (hasItem)
              Positioned(
                left: 14,
                right: 14,
                bottom: 0,
                child: _buildItemCard(_item!),
              ),
          ],
        ),
        Expanded(
          child: CustomPaint(
            painter: _DotPatternPainter(
                color: context.palette.inkMuted.withValues(alpha: 0.10)),
            child: _isLoadingHistory
                ? Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: context.palette.accent),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                        itemCount: _messages.length,
                        controller: _scrollController,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return Column(
                            children: [
                              if (_startsNewDay(index))
                                _buildDayDivider(
                                    _parseTime(msg['timestamp'])!),
                              _buildMessageRow(
                                msg: msg,
                                isMe: msg['sender_id'] == widget.currentUserId,
                                firstInGroup: _isFirstInGroup(index),
                                lastInGroup: _isLastInGroup(index),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool showStatusBarInset) {
    final palette = context.palette;
    final top = showStatusBarInset ? MediaQuery.of(context).padding.top : 0.0;
    final role = (recieverUserModel?.userType ?? '').toString();
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.35)!;

    return Container(
      padding: EdgeInsets.fromLTRB(6, top + 8, 10, _item != null ? 54 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primaryFill, deep],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => goBack(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          // Avatar with a soft ring.
          Hero(
            tag: 'chat-avatar-${widget.receiverId}',
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 21,
                backgroundColor: Colors.white24,
                backgroundImage: _receiverImage.isNotEmpty
                    ? NetworkImage(_receiverImage)
                    : null,
                child: _receiverImage.isEmpty
                    ? Text(
                        _receiverName.isNotEmpty
                            ? _receiverName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isLoadingUser
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _receiverName.isNotEmpty ? _receiverName : 'Chat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (role.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              role,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            VerifiedBadge(
                                userId: widget.receiverId,
                                size: 14,
                                color: const Color(0xFFF5C76A),
                                withLabel: true,
                                gap: 6),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
          if (!kIsWeb && _receiverPhone.trim().isNotEmpty)
            _headerAction(Icons.call_rounded, _callReceiver),
        ],
      ),
    );
  }

  Widget _headerAction(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // Floating card over the header's edge: what this conversation is about.
  Widget _buildItemCard(ChatItemRef item) {
    final palette = context.palette;
    final isProperty = item.type == 'property';
    Widget fallback() => Container(
          color: palette.tile,
          child: Icon(
            isProperty ? Icons.home_work_outlined : Icons.shopping_bag_outlined,
            color: palette.inkMuted,
            size: 22,
          ),
        );
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: item.image.isEmpty
                  ? fallback()
                  : Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => fallback(),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      isProperty
                          ? Icons.home_rounded
                          : item.type == 'service'
                              ? Icons.handyman_rounded
                              : Icons.local_offer_rounded,
                      size: 11,
                      color: palette.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isProperty
                          ? 'PROPERTY'
                          : item.type == 'service'
                              ? 'SERVICE'
                              : 'MARKETPLACE ITEM',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: palette.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ],
            ),
          ),
          // No price tag when there's no price (e.g. a service without a
          // listed starting price).
          if (item.amount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: palette.primaryFill.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${item.type == 'service' ? 'From ' : ''}₦${NumberFormat.compact().format(item.amount)}${item.priceSuffix}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayDivider(DateTime day) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Text(
            _dayLabel(day),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: palette.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final palette = context.palette;
    final name = recieverUserModel?.firstName.toString().trim() ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  palette.primaryFill.withValues(alpha: 0.18),
                  palette.primaryFill.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Icon(Icons.waving_hand_rounded,
                size: 38, color: palette.accent),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name.isEmpty ? 'Start the conversation' : 'Say hello to $name',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Messages are delivered instantly and they get a notification.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.inkSoft, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 22),
        Text(
          'QUICK QUESTIONS',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
            color: palette.inkMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _suggestions
              .map((s) => ActionChip(
                    label: Text(s),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.accent,
                    ),
                    backgroundColor: palette.card,
                    side: BorderSide(
                        color: palette.accent.withValues(alpha: 0.35)),
                    shape: const StadiumBorder(),
                    onPressed: () => _useSuggestion(s),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMessageRow({
    required Map<String, dynamic> msg,
    required bool isMe,
    required bool firstInGroup,
    required bool lastInGroup,
  }) {
    final palette = context.palette;
    final bool failed = msg['failed'] == true;
    final bool sending = msg['is_sending'] == true;
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.2)!;

    // Rounded everywhere except a small "tail" corner on the last bubble of
    // each burst, on the sender's side.
    final radius = BorderRadius.only(
      topLeft: Radius.circular(!isMe && !firstInGroup ? 6 : 20),
      topRight: Radius.circular(isMe && !firstInGroup ? 6 : 20),
      bottomLeft: Radius.circular(!isMe ? (lastInGroup ? 4 : 6) : 20),
      bottomRight: Radius.circular(isMe ? (lastInGroup ? 4 : 6) : 20),
    );

    final textColor = isMe ? Colors.white : palette.ink;
    final metaColor =
        isMe ? Colors.white.withValues(alpha: 0.75) : palette.inkMuted;

    final Widget status = failed
        ? const Icon(Icons.error_rounded, size: 13, color: Color(0xFFFFB4B4))
        : sending
            ? Icon(Icons.schedule_rounded, size: 12, color: metaColor)
            : Icon(Icons.done_all_rounded, size: 14, color: metaColor);

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * (kIsWeb ? 0.5 : 0.74),
      ),
      padding: const EdgeInsets.fromLTRB(14, 9, 12, 7),
      decoration: BoxDecoration(
        gradient: isMe
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.primaryFill, deep],
              )
            : null,
        color: isMe ? null : palette.card,
        borderRadius: radius,
        border: isMe ? null : Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: (isMe ? palette.primaryFill : Colors.black)
                .withValues(alpha: isMe ? 0.22 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(
              (msg['message'] ?? '').toString(),
              style: TextStyle(color: textColor, fontSize: 14.5, height: 1.35),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(msg['timestamp']?.toString()),
                style: TextStyle(fontSize: 10.5, color: metaColor),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                status,
              ],
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(top: firstInGroup ? 8 : 2, bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            SizedBox(
              width: 30,
              child: lastInGroup ? _smallAvatar(msg) : null,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: failed ? () => _retry(msg) : null,
                  child: bubble,
                ),
                if (failed)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 4),
                    child: Text(
                      'Not sent · Tap to retry',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
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

  Widget _smallAvatar(Map<String, dynamic> msg) {
    final fromMsg = (msg['sender_image'] ?? '').toString();
    final image = fromMsg.isNotEmpty ? fromMsg : _receiverImage;
    return CircleAvatar(
      radius: 14,
      backgroundColor: context.palette.tile,
      backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
      child: image.isEmpty
          ? Icon(Icons.person_rounded, size: 16, color: context.palette.inkMuted)
          : null,
    );
  }

  Widget _buildInputBar() {
    final palette = context.palette;
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.25)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      color: palette.page,
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 130),
                padding: const EdgeInsets.only(left: 18, right: 8),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? palette.accent.withValues(alpha: 0.5)
                        : palette.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: palette.ink, fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'Write a message…',
                    hintStyle:
                        TextStyle(color: palette.inkMuted, fontSize: 14.5),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedScale(
              scale: _isComposing ? 1 : 0.88,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isComposing
                      ? LinearGradient(colors: [palette.primaryFill, deep])
                      : null,
                  color: _isComposing ? null : palette.tile,
                  boxShadow: _isComposing
                      ? [
                          BoxShadow(
                            color: palette.primaryFill.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: _isComposing ? Colors.white : palette.inkMuted,
                    size: 21,
                  ),
                  onPressed: _isComposing ? _sendMessage : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    pusher.disconnect();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

// Faint dot grid behind the messages - gives the chat a subtle texture
// instead of a flat fill.
class _DotPatternPainter extends CustomPainter {
  final Color color;
  const _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const gap = 22.0;
    for (double y = gap / 2; y < size.height; y += gap) {
      for (double x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
