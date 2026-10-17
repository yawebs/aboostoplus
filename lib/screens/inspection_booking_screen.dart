import 'package:eafind/theme/app_palette.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/models/chat_item_ref.dart';
import 'package:eafind/providers/navigation_provider.dart';
import 'package:eafind/screens/marketplace/chat_screen.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auths/auth_service.dart';
import '../models/user_model.dart';

class InspectionBookingScreen extends StatefulWidget {
  final PropertyModel property;
  final int amount;
  final UserModel userCustomer;
  final transactionRef;
  const InspectionBookingScreen({
    Key? key,
    required this.property,
    required this.amount,
    required this.userCustomer,
    required this.transactionRef,
  }) : super(key: key);

  @override
  State<InspectionBookingScreen> createState() =>
      _InspectionBookingScreenState();
}

class _InspectionBookingScreenState extends State<InspectionBookingScreen> {
  bool _isLoading = false;
  UserModel? agentData;
  DateTime? _dateTime;
  bool isDialing = false;

  // The listing owner is who the user inspects with, chats with and calls.
  // ownerId is always set on a listing; the owner snapshot may be missing.
  String get _agentId => widget.property.ownerId;

  bool get _isOwnListing => widget.userCustomer.id == _agentId;

  void _openChat() {
    if (_isOwnListing) {
      showToast('This is your own listing');
      return;
    }
    final when = _dateTime == null
        ? ''
        : ' on ${DateFormat.yMMMEd().format(_dateTime!)} at '
            '${DateFormat('h:mm a').format(_dateTime!)}';
    goTo(
      context,
      ChatScreen(
        currentUserId: widget.userCustomer.id,
        receiverId: _agentId,
        senderName: widget.userCustomer.firstName,
        senderImage: widget.userCustomer.profileImage,
        item: ChatItemRef.fromProperty(widget.property),
        initialMessage: 'Hi, I would like to inspect '
            '"${widget.property.title}"$when. Is that time okay for you?',
      ),
      false,
    );
  }

  _callNumber() async {
    final phone = agentData?.phone.toString() ?? '';
    if (phone.trim().isEmpty) {
      showToast('No phone number for this agent - send a message instead');
      return;
    }
    setState(() {
      isDialing = true;
    });
    String number = '+234$phone'; //set the number here
    bool? res = await FlutterPhoneDirectCaller.callNumber(number);
    setState(() {
      isDialing = false;
    });
    debugPrint('dialer is $res');
  }

  addAppointment() async {
    try {
      setState(() {
        _isLoading = true;
      });
      FormData formData = FormData.fromMap(
        {
          'payment_ref': widget.transactionRef,
          'amount': widget.amount,
          'agentId': widget.property.ownerId,
          'customerId': widget.userCustomer.id,
          'inspection_date': DateFormat.yMEd().format(_dateTime!),
          'inspection_time': DateFormat('hh:mm a').format(_dateTime!),
          'customer_name': widget.userCustomer.userName,
          'property_id': widget.property.id,
          'property_title': widget.property.title,
          'new_deal': 1,
        },
      );
      var response =
          await Dio().post(endPoint('add-deals.php'), data: formData);
      setState(() {
        _isLoading = false;
      });
      Provider.of<NavigationProvider>(context, listen: false).setScreen(4);
      showToast('Inspection Successfully Scheduled');
      goTo(context, const BottomNavHome(), false);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint(e.toString());
    }
  }

  pickDate() async {
    DateTime? dateTime = await showOmniDateTimePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1600).subtract(const Duration(days: 3652)),
      lastDate: DateTime.now().add(
        const Duration(days: 3652),
      ),
      is24HourMode: false,
      isShowSeconds: false,
      minutesInterval: 1,
      secondsInterval: 1,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: const BoxConstraints(
        maxWidth: 350,
        maxHeight: 650,
      ),
      theme: ThemeData.dark(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(
            Tween(
              begin: 0,
              end: 1,
            ),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      selectableDayPredicate: (dateTime) {
        // Disable 25th Feb 2023
        if (dateTime == DateTime(2023, 2, 25)) {
          return false;
        } else {
          return true;
        }
      },
    );
    setState(() {
      _dateTime = dateTime;
    });
  }

  // getAgent() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //   try {
  //     var result = await AuthService.getUserById(widget.property.ownerId);
  //     debugPrint('This is the result fetching agent: ${result}');
  //     UserModel? aUser = UserModel.fromDoc(result['data']);
  //     setState(() {
  //       agentData = aUser;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     debugPrint('This is the result fetching agent: ${e.toString()}');
  //   }
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Was decoded only as a local inside build(), leaving this field null -
    // so the Call button (and the whole web layout) crashed on agentData!.
    try {
      final raw = widget.property.propertyOwner;
      if (raw != null && raw.toString().isNotEmpty) {
        agentData = UserModel.fromDoc2(json.decode(raw));
      }
    } catch (e) {
      debugPrint('Could not read listing owner: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Theme(
      data: AppTheme.of(context),
      child: Scaffold(
        backgroundColor: context.palette.surface,
        appBar: AppBar(
          backgroundColor: context.palette.background,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => goBack(context),
            child: Icon(Icons.arrow_back_ios_new,
                color: context.palette.textDark, size: 18),
          ),
          title: Text(
            'Book Inspection',
            style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: context.palette.textDark),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: context.palette.accent))
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                children: [
                  _propertySummary(),
                  const SizedBox(height: 14),
                  _agentCard(),
                  const SizedBox(height: 14),
                  _scheduleCard(),
                  const SizedBox(height: 14),
                  _verifyCard(),
                ],
              ),
        bottomNavigationBar: _isLoading ? null : _confirmBar(),
      ),
    );
  }

  Widget _propertySummary() {
    final hasImage = widget.property.images.isNotEmpty;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: hasImage
                  ? Image.network(
                      widget.property.images[0],
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                          color: context.palette.surface,
                          child: Icon(Icons.home_outlined,
                              color: context.palette.textGrey)),
                    )
                  : Container(
                      color: context.palette.surface,
                      child: Icon(Icons.home_outlined,
                          color: context.palette.textGrey)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.property.category,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.palette.accent,
                      letterSpacing: 0.4),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.property.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  '₦${NumberFormat().format(widget.property.amount)}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _agentCard() {
    final agent = agentData;
    final hasImage =
        agent != null && (agent.profileImage ?? '').toString().isNotEmpty;
    final name = (agent?.userName.toString().trim().isNotEmpty ?? false)
        ? agent!.userName
        : widget.property.userName;
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.palette.border)),
            child: ClipOval(
              child: hasImage
                  ? Image.network(agent.profileImage, fit: BoxFit.cover)
                  : Image.asset(imageRounte(name: 'avatar.png'),
                      fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.palette.textDark,
                      fontSize: 15)),
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: AppColors.success, size: 15),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined,
                  color: context.palette.textGrey, size: 15),
              const SizedBox(width: 4),
              Text(widget.property.community,
                  style: TextStyle(
                      color: context.palette.textGrey, fontSize: 12.5)),
            ],
          ),
          if (!_isOwnListing) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _agentAction(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Message',
                    filled: true,
                    onTap: _openChat,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _agentAction(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    filled: false,
                    loading: isDialing,
                    onTap: _callNumber,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Hidden buttons used to leave no clue why - say so instead.
            const SizedBox(height: 14),
            _ownListingNotice(),
          ],
        ],
      ),
    );
  }

  Widget _agentAction({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    final palette = context.palette;
    final fg = filled ? Colors.white : palette.accent;
    return Material(
      color: filled ? palette.primaryFill : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: filled
            ? BorderSide.none
            : BorderSide(color: palette.accent.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: loading ? null : onTap,
        child: SizedBox(
          height: 46,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: fg),
                      const SizedBox(width: 8),
                      Text(label,
                          style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _scheduleCard() {
    final chosen = _dateTime != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inspection date & time',
            style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.palette.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            chosen
                ? 'The agent still needs to confirm this works for them.'
                : 'Choose when you would like to inspect this property.',
            style: TextStyle(fontSize: 12.5, color: context.palette.textGrey),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: pickDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: chosen
                    ? context.palette.primaryFill.withOpacity(0.06)
                    : context.palette.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: chosen
                        ? context.palette.accent.withOpacity(0.3)
                        : context.palette.border),
              ),
              child: chosen
                  ? Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: context.palette.primaryFill,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.event_available_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(DateFormat.yMMMEd().format(_dateTime!),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: context.palette.textDark,
                                      fontSize: 14)),
                              Text(DateFormat('hh:mm a').format(_dateTime!),
                                  style: TextStyle(
                                      color: context.palette.textGrey,
                                      fontSize: 12.5)),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_outlined,
                            color: context.palette.accent, size: 18),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color:
                                  context.palette.primaryFill.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: Icon(Icons.calendar_month_outlined,
                              color: context.palette.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Tap to choose date & time',
                              style: TextStyle(
                                  color: context.palette.textDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: context.palette.textGrey),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Shown instead of Message/Call when the logged-in user posted this
  // listing - you can't chat with or call yourself.
  Widget _ownListingNotice() {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.primaryFill.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: palette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is your listing. People interested in it can message '
              'or call you from here.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.35, color: palette.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifyCard() {
    // Nothing to confirm with yourself on your own listing.
    if (_isOwnListing) return const SizedBox.shrink();
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.14),
                shape: BoxShape.circle),
            child: const Icon(Icons.forum_outlined,
                color: Color(0xFFD96A0B), size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Confirm with the agent',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.palette.textDark,
                        fontSize: 13.5)),
                SizedBox(height: 2),
                Text(
                    _dateTime == null
                        ? 'Pick a time, then message the agent to check they are free.'
                        : 'Message the agent - your chosen time is added to the chat for you.',
                    style: TextStyle(
                        color: context.palette.textGrey, fontSize: 12)),
              ],
            ),
          ),
          if (!_isOwnListing) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _openChat,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: context.palette.primaryFill,
                    borderRadius: BorderRadius.circular(24)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('Chat',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _confirmBar() {
    final ready = _dateTime != null;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        child: MiaButton(
          text: ready ? 'Confirm Inspection' : 'Choose a date & time first',
          isEnabled: ready,
          prefix: ready
              ? const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18)
              : null,
          onPressed: () {
            if (_dateTime != null) {
              addAppointment();
            } else {
              showErrorSnackbar(
                  'Please choose inspection date and time', context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: AppCard(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Text(
                              'Book ${widget.property.userType}',
                              style: TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: 1, color: AppColors.border),
                                borderRadius: BorderRadius.circular(38),
                              ),
                              child: ClipOval(
                                child: (agentData?.profileImage ?? '')
                                        .toString()
                                        .isEmpty
                                    ? Image.asset(
                                        imageRounte(name: 'avatar.png'),
                                        fit: BoxFit.cover)
                                    : Image.network(agentData!.profileImage,
                                        fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    agentData?.userName ??
                                        widget.property.userName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark)),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified,
                                    color: AppColors.success, size: 15),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on,
                                    color: AppColors.textGrey, size: 16),
                                const SizedBox(width: 4),
                                Text(widget.property.community,
                                    style: TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 12),
                            Text(
                              'Inspection details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 16),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: pickDate,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.calendar_view_day,
                                      color: Colors.white, size: 34),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Choose inspection date',
                                style: TextStyle(
                                    color: AppColors.textGrey, fontSize: 13)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text('Inspection date',
                                        style: TextStyle(
                                            color: AppColors.textGrey,
                                            fontSize: 12)),
                                    if (_dateTime != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                            DateFormat.yMEd()
                                                .format(_dateTime!),
                                            style: TextStyle(
                                                color: AppColors.textDark,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('Inspection time',
                                        style: TextStyle(
                                            color: AppColors.textGrey,
                                            fontSize: 12)),
                                    if (_dateTime != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                            DateFormat('hh:mm a')
                                                .format(_dateTime!),
                                            style: TextStyle(
                                                color: AppColors.textDark,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (!_isOwnListing)
                              SizedBox(
                                width: 320,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _agentAction(
                                        icon: Icons.chat_bubble_rounded,
                                        label: 'Message',
                                        filled: true,
                                        onTap: _openChat,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _agentAction(
                                        icon: Icons.call_rounded,
                                        label: 'Call',
                                        filled: false,
                                        loading: isDialing,
                                        onTap: _callNumber,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              SizedBox(width: 360, child: _ownListingNotice()),
                            const SizedBox(height: 10),
                            if (!_isOwnListing)
                              Text(
                                'Message or call the agent to confirm the inspection date',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textGrey),
                              ),
                            const SizedBox(height: 24),
                            MiaButton(
                              text: 'Confirm inspection',
                              isEnabled: !_isLoading,
                              onPressed: () {
                                if (_dateTime != null) {
                                  addAppointment();
                                } else {
                                  showErrorSnackbar(
                                      'Please choose inspection date and time',
                                      context);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
