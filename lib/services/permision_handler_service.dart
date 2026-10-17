import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Request Notification Permission
  static Future<void> requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.status;

    if (status.isDenied) {
      status = await Permission.notification.request();
    }

    if (status.isPermanentlyDenied) {
      // Direct user to device system settings
      await openAppSettings();
    }
    debugPrint('Requested Notification Permission is $status');
  }

  // Request Location Permission
  static Future<void> requestLocationPermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.status;

    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isPermanentlyDenied) {
      // Direct user to device system settings
      await openAppSettings();
    }
  }
}
