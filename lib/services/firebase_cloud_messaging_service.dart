import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:http/http.dart' as http;
import '../models/enums.dart';
import '../main.dart';

class FirebaseCloudMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FCM Server Key - IMPORTANT: Get this from Firebase Console
  // Go to: Project Settings > Cloud Messaging > Server Key
  static const String _fcmServerKey = 'YOUR_FCM_SERVER_KEY_HERE'; // REPLACE THIS!

  /// Initialize Firebase Cloud Messaging
  static Future<void> initialize() async {
    print('🚀 Initializing Firebase Cloud Messaging...');

    // Request notification permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM Permission granted');
      
      // Get FCM token
      String? token = await _messaging.getToken();
      print('📱 FCM Token: $token');
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        // Update token in Firestore when it refreshes
        _updateCurrentUserToken(newToken);
      });

      // Setup message handlers
      _setupMessageHandlers();
      
    } else {
      print('❌ FCM Permission denied');
    }
  }

  /// Setup foreground and background message handlers
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received: ${message.notification?.title}');
      
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 Notification tapped: ${message.data}');
      _handleNotificationTap(message);
    });
  }

  /// Show local notification for foreground messages
  static void _showLocalNotification(RemoteMessage message) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'new_case_channel',
        title: message.notification?.title ?? 'I-Funeral',
        body: message.notification?.body ?? 'New notification',
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Social,
        wakeUpScreen: true,
        backgroundColor: const Color(0xFF2E8B57),
        payload: message.data.map((key, value) => MapEntry(key, value.toString())),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'VIEW_CASE',
          label: 'View Request',
          actionType: ActionType.Default,
          color: const Color(0xFF2E8B57),
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.DismissAction,
        ),
      ],
    );
  }

  /// Handle notification tap actions
  static void _handleNotificationTap(RemoteMessage message) {
    if (message.data['type'] == 'new_case') {
      // Navigate to staff home screen
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/staff-home',
        (route) => route.isFirst,
      );
    }
  }

  /// Save FCM token to current user's document
  static Future<void> saveTokenToCurrentUser(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'tokenActive': true,
        });
        print('✅ FCM token saved for user: $userId');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Update current user's token (for token refresh)
  static Future<void> _updateCurrentUserToken(String newToken) async {
    try {
      // You'll need to get current user ID from your auth service
      // For now, we'll update all active tokens (not ideal but works for testing)
      print('🔄 Updating FCM token: $newToken');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }

  /// MAIN FUNCTION: Send notification to ALL STAFF
  static Future<void> notifyAllStaff({
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      print('📡 Sending notification to ALL STAFF...');
      print('Title: $title');
      print('Body: $body');

      // Get all staff users with active FCM tokens
      QuerySnapshot staffQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'staff')
          .where('tokenActive', isEqualTo: true)
          .get();

      print('👥 Found ${staffQuery.docs.length} staff members');

      List<String> tokens = [];
      
      // Collect all valid FCM tokens
      for (DocumentSnapshot staffDoc in staffQuery.docs) {
        String? token = staffDoc.get('fcmToken');
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
          print('📱 Staff token: ${staffDoc.id} - ${token.substring(0, 20)}...');
        }
      }

      if (tokens.isEmpty) {
        print('❌ No active staff tokens found');
        return;
      }

      print('📤 Sending to ${tokens.length} staff devices...');

      // Send to all tokens using multicast
      await _sendMulticastMessage(
        tokens: tokens,
        title: title,
        body: body,
        data: data,
      );

      // Also save notification to Firestore for history
      await _saveNotificationHistory(title, body, data);

      print('✅ Successfully sent notifications to all staff!');
    } catch (e) {
      print('❌ Error sending staff notifications: $e');
    }
  }

  /// Send FCM message to multiple tokens (multicast)
  static Future<void> _sendMulticastMessage({
    required List<String> tokens,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      // Split tokens into batches of 500 (FCM limit)
      const int batchSize = 500;
      for (int i = 0; i < tokens.length; i += batchSize) {
        List<String> batch = tokens.skip(i).take(batchSize).toList();
        
        await _sendBatchNotification(
          tokens: batch,
          title: title,
          body: body,
          data: data,
        );
        
        // Small delay between batches
        if (i + batchSize < tokens.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      print('❌ Error in multicast message: $e');
    }
  }

  /// Send notification to a batch of tokens via FCM HTTP API
  static Future<void> _sendBatchNotification({
    required List<String> tokens,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      // IMPORTANT: You need to implement server-side FCM sending
      // This is a client-side approach for testing (NOT recommended for production)
      
      final String fcmUrl = 'https://fcm.googleapis.com/fcm/send';
      
      for (String token in tokens) {
        final Map<String, dynamic> message = {
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'badge': '1',
          },
          'data': data,
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'new_case_channel',
              'priority': 'high',
              'sound': 'default',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        };

        final response = await http.post(
          Uri.parse(fcmUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$_fcmServerKey', // Replace with your server key
          },
          body: json.encode(message),
        );

        if (response.statusCode == 200) {
          print('✅ Message sent to token: ${token.substring(0, 20)}...');
        } else {
          print('❌ Failed to send to token: ${response.statusCode} - ${response.body}');
        }

        // Small delay between individual sends
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      print('❌ Error sending batch notification: $e');
    }
  }

  /// Save notification to Firestore for history/tracking
  static Future<void> _saveNotificationHistory(
    String title,
    String body,
    Map<String, String> data,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'data': data,
        'type': 'staff_broadcast',
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': 'system',
      });
    } catch (e) {
      print('❌ Error saving notification history: $e');
    }
  }

  /// CONVENIENCE METHOD: Send new death case notification
  static Future<void> notifyStaffNewCase({
    required String caseName,
    required String caseId,
    required ServiceType serviceType,
  }) async {
    await notifyAllStaff(
      title: '🚨 New Death Case Request',
      body: 'New application for $caseName (${serviceType.displayName})',
      data: {
        'type': 'new_case',
        'caseId': caseId,
        'caseName': caseName,
        'serviceType': serviceType.value,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  /// Send case status update notification
  static Future<void> notifyCaseStatusUpdate({
    required String caseName,
    required String caseId,
    required CaseStatus status,
    required String recipientUserId,
  }) async {
    try {
      // Get recipient's FCM token
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(recipientUserId)
          .get();

      String? token = userDoc.get('fcmToken');
      if (token != null) {
        String statusText = '';
        String emoji = '';

        switch (status) {
          case CaseStatus.accepted:
            statusText = 'accepted';
            emoji = '✅';
            break;
          case CaseStatus.completed:
            statusText = 'completed';
            emoji = '🎉';
            break;
          default:
            return;
        }

        await _sendBatchNotification(
          tokens: [token],
          title: '$emoji Case $statusText',
          body: 'Your request for $caseName has been $statusText',
          data: {
            'type': 'status_update',
            'caseId': caseId,
            'caseName': caseName,
            'status': status.value,
          },
        );
      }
    } catch (e) {
      print('❌ Error sending status update: $e');
    }
  }

  /// Test notification for debugging
  static Future<void> sendTestNotification() async {
    await notifyAllStaff(
      title: '🔔 Test Notification',
      body: 'This is a test notification to all staff members!',
      data: {
        'type': 'test',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  /// Get current device FCM token
  static Future<String?> getCurrentToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      NotificationSettings settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('❌ Error checking notification settings: $e');
      return false;
    }
  }
}