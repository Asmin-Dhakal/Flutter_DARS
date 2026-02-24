import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServices {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Static instance for background notifications
  static final FlutterLocalNotificationsPlugin _backgroundNotificationPlugin =
      FlutterLocalNotificationsPlugin();

  // Define a constant channel
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  // Order updates channel
  static const AndroidNotificationChannel orderUpdatesChannel =
      AndroidNotificationChannel(
        'order_updates_channel',
        'Order Updates',
        description: 'Notifications for order creation and status changes',
        importance: Importance.high,
      );

  void initLocalNotifications(
    BuildContext context,
    RemoteMessage message,
  ) async {
    var androidInitializationSettings = const AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    var iosInitializationSettings = const DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('Notification tapped with payload: $payload');
          // Notify listeners about the tap - they can handle navigation
        }
      },
    );

    // Also initialize the background plugin
    await _backgroundNotificationPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap in background
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('Background notification tapped with payload: $payload');
        }
      },
    );

    // Create the notification channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Create order updates channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(orderUpdatesChannel);

    // Also create channel for background plugin
    await _backgroundNotificationPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Also create order updates channel for background plugin
    await _backgroundNotificationPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(orderUpdatesChannel);
  }

  void firebaseInit() {
    FirebaseMessaging.onMessage.listen((message) {
      print(message.notification!.title);
      print(message.notification!.body);
      showNotification(message);
    });
  }

  // Static method to show notification in background
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.max,
          ticker: 'ticker',
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await _backgroundNotificationPlugin.show(
      id: message.hashCode,
      title: message.notification!.title.toString(),
      body: message.notification!.body.toString(),
      notificationDetails: notificationDetails,
    );
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.max,
          ticker: 'ticker',
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
        id: 0,
        title: message.notification!.title.toString(),
        body: message.notification!.body.toString(),
        notificationDetails: notificationDetails,
      );
    });
  }

  void requestNotificationPersmissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User Granted Permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User Granted Provisional Permission');
    } else {
      AppSettings.openAppSettings();
      print('User Declined or Has Not Accepted Permission');
    }
  }

  Future<String?> getDeviceToken() async {
    String? token = await _firebaseMessaging.getToken();

    // Save token to Firestore when we get it
    if (token != null) {
      await _saveDeviceTokenToFirestore(token);
    }

    return token;
  }

  /// Save device token to Firestore so Cloud Functions can send notifications
  Future<void> _saveDeviceTokenToFirestore(String token) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Use token as document ID to avoid duplicates
      await firestore.collection('deviceTokens').doc(token).set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Device token saved to Firestore');
    } catch (e) {
      debugPrint('⚠️ Failed to save device token to Firestore: $e');
    }
  }

  /// Listen for token refresh and save new token to Firestore
  void isTokenRefresh() async {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 Device token refreshed');
      _saveDeviceTokenToFirestore(newToken);
    });
  }

  /// Remove device token from Firestore when user logs out
  Future<void> removeDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('deviceTokens')
            .doc(token)
            .delete();
        debugPrint('✅ Device token removed from Firestore');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to remove device token: $e');
    }
  }

  /// Handle messages received while app is in background or terminated
  void handleBackgroundMessage() {
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  }

  /// Static method that handles background messages
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    debugPrint(
      '🔔 Background message received: ${message.notification?.title}',
    );
    debugPrint('📦 Data: ${message.data}');

    // Show local notification even when app is in background
    await showBackgroundNotification(message);
  }

  void handleMessage(BuildContext context, RemoteMessage message) {
    debugPrint('💬 Message received in foreground');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
  }

  // Getter to access the local notifications plugin
  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin =>
      _flutterLocalNotificationsPlugin;
}
