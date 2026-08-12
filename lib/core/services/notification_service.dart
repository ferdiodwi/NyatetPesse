import 'dart:async';
import 'package:flutter/services.dart';

class NotificationData {
  final String packageName;
  final String title;
  final String text;
  final DateTime postTime;

  NotificationData({
    required this.packageName,
    required this.title,
    required this.text,
    required this.postTime,
  });

  factory NotificationData.fromMap(Map<dynamic, dynamic> map) {
    return NotificationData(
      packageName: map['packageName'] ?? '',
      title: map['title'] ?? '',
      text: map['text'] ?? '',
      postTime: DateTime.fromMillisecondsSinceEpoch(map['postTime'] ?? 0),
    );
  }
}

class NotificationService {
  static const MethodChannel _methodChannel = MethodChannel('com.example.nyatet_pesse/notification_method');
  static const EventChannel _eventChannel = EventChannel('com.example.nyatet_pesse/notification_event');

  // Check if permission is granted
  static Future<bool> isPermissionGranted() async {
    try {
      final bool isEnabled = await _methodChannel.invokeMethod('isNotificationListenerEnabled');
      return isEnabled;
    } on PlatformException {
      return false;
    }
  }

  // Open settings to grant permission
  static Future<void> openSettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationSettings');
    } on PlatformException {
      // Ignore
    }
  }

  // Stream of notifications
  static Stream<NotificationData> get notificationStream {
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      return NotificationData.fromMap(event as Map<dynamic, dynamic>);
    });
  }
}
