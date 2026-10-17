import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/house_details_screen.dart';
import 'package:eafind/screens/marketplace/chat_screen.dart';
import 'package:eafind/screens/marketplace/messages_screen.dart';
import 'package:eafind/screens/verification/agent_verification_screen.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/services/verification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Root navigator, so a notification tap can open a screen from anywhere
// (set on MaterialApp in main.dart).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// Opens the right screen when a push notification is tapped.
//
// Taps can arrive before the app is usable (cold start: user session still
// restoring, home shell not built yet), so the tap is held as "pending" until
// the home shell calls [markReady].
//
// Payload `type` values (sent by the PHP backend):
//   chat          sender_id, sender_name, sender_image -> that conversation
//   search_alert  property_id                          -> the new listing
//   verification  (approved / rejected)                -> verification screen
//   anything else (incl. older chat pushes)            -> Messages list
class NotificationRouter {
  NotificationRouter._();

  static Map<String, dynamic>? _pending;
  static bool _ready = false;

  static void handle(Map<String, dynamic> data) {
    debugPrint('Notification tapped: $data');
    _pending = data;
    _flush();
  }

  // Called by the home shell once the signed-in user is available.
  static void markReady() {
    _ready = true;
    _flush();
  }

  static void _flush() {
    final data = _pending;
    final nav = appNavigatorKey.currentState;
    if (data == null || !_ready || nav == null) return;
    _pending = null;
    _route(nav, data);
  }

  static Future<void> _route(
      NavigatorState nav, Map<String, dynamic> data) async {
    final context = nav.context;
    final me = context.read<UsermodelProvider>().getUserModel();
    if (me == null) return; // signed out: nothing personal to open

    final type = (data['type'] ?? '').toString();
    final push = (Widget screen) =>
        nav.push(MaterialPageRoute(builder: (_) => screen));

    final senderId = (data['sender_id'] ?? '').toString();
    final propertyId = (data['property_id'] ?? '').toString();

    if (type == 'chat' && senderId.isNotEmpty) {
      push(ChatScreen(
        currentUserId: me.id,
        receiverId: senderId,
        senderName: me.firstName,
        senderImage: me.profileImage,
      ));
      return;
    }

    if (type == 'search_alert' && propertyId.isNotEmpty) {
      final PropertyModel? property =
          await DbServices.getSingleProperty(propertyId);
      if (property != null) {
        push(HouseDetailsScreen(property: property));
      } else {
        showToast('That listing is no longer available');
      }
      return;
    }

    if (type == 'verification') {
      VerifiedUsers.instance.forget(me.id); // approval may have just landed
      push(const AgentVerificationScreen());
      return;
    }

    // Anything else (incl. older chat pushes without sender info).
    push(MessagesScreen(
      currentUserId: me.id,
      currentUserName: me.firstName,
      currentUserImage: (me.profileImage ?? '').toString(),
    ));
  }
}
