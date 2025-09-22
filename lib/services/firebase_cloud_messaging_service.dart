import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../models/enums.dart';
import '../main.dart';

class FirebaseCloudMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Your Firebase project ID
  static const String _projectId = 'ifuneral';
  
  // FCM v1 API endpoint
  static String get _fcmEndpoint => 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
  
  // OAuth 2.0 scopes for FCM
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging'
  ];

  /// Initialize Firebase Cloud Messaging
  static Future<void> initialize() async {
    print('🚀 Initializing Firebase Cloud Messaging (HTTP v1)...');

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
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/staff-home',
        (route) => route.isFirst,
      );
    }
  }

  /// Get OAuth 2.0 access token from service account
  static Future<String> _getAccessToken() async {
    try {
      // Load service account JSON from assets
      String serviceAccountJson = await rootBundle.loadString('assets/service-account.json');
      Map<String, dynamic> serviceAccount = json.decode(serviceAccountJson);
      
      // Create service account credentials
      var credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      
      // Get access token
      var client = await clientViaServiceAccount(credentials, _scopes);
      var accessToken = client.credentials.accessToken.data;
      
      client.close();
      
      print('✅ Access token obtained: ${accessToken.substring(0, 20)}...');
      return accessToken;
      
    } catch (e) {
      print('❌ Error getting access token: $e');
      throw Exception('Failed to get access token: $e');
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
      print('🔄 Updating FCM token: $newToken');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }

  /// MAIN FUNCTION: Send notification to ALL STAFF using HTTP v1 API
  static Future<void> notifyAllStaff({
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      print('📡 Sending FCM v1 notification to ALL STAFF...');
      print('Title: $title');
      print('Body: $body');

      // Get all staff users with active FCM tokens
      QuerySnapshot staffQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'staff')
          .where('tokenActive', isEqualTo: true)
          .get();

      print('👥 Found ${staffQuery.docs.length} staff members');

      if (staffQuery.docs.isEmpty) {
        print('❌ No active staff tokens found');
        return;
      }

      // Get OAuth 2.0 access token
      String accessToken = await _getAccessToken();

      // Send to each staff member
      int successCount = 0;
      for (DocumentSnapshot staffDoc in staffQuery.docs) {
        String? token = staffDoc.get('fcmToken');
        if (token != null && token.isNotEmpty) {
          bool sent = await _sendMessageToToken(
            token: token,
            title: title,
            body: body,
            data: data,
            accessToken: accessToken,
          );
          if (sent) successCount++;
        }
      }

      // Save notification to Firestore for history
      await _saveNotificationHistory(title, body, data);

      print('✅ Successfully sent notifications to $successCount/${staffQuery.docs.length} staff members!');
      
    } catch (e) {
      print('❌ Error sending staff notifications: $e');
      rethrow;
    }
  }

  /// Send FCM message to a single token using HTTP v1 API
  static Future<bool> _sendMessageToToken({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
    required String accessToken,
  }) async {
    try {
      // Create HTTP v1 message payload with correct structure
      final Map<String, dynamic> message = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data,
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'new_case_channel',
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'icon': 'ic_launcher',
              'color': '#2E8B57',
            },
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
                'alert': {
                  'title': title,
                  'body': body,
                },
                'content-available': 1,
              },
            },
          },
        },
      };

      // Send HTTP request to FCM v1 API
      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        print('✅ Message sent successfully to: ${token.substring(0, 20)}...');
        return true;
      } else {
        print('❌ Failed to send message: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
      
    } catch (e) {
      print('❌ Error sending message to token: $e');
      return false;
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
        'apiVersion': 'v1',
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

  /// Send case status update notification to specific user
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
      if (token != null && token.isNotEmpty) {
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

        // Get access token
        String accessToken = await _getAccessToken();

        // Send notification
        await _sendMessageToToken(
          token: token,
          title: '$emoji Case $statusText',
          body: 'Your request for $caseName has been $statusText',
          data: {
            'type': 'status_update',
            'caseId': caseId,
            'caseName': caseName,
            'status': status.value,
          },
          accessToken: accessToken,
        );
      }
    } catch (e) {
      print('❌ Error sending status update: $e');
    }
  }

  /// Test notification for debugging
  static Future<void> sendTestNotification() async {
    await notifyAllStaff(
      title: '🔔 Test Notification (HTTP v1)',
      body: 'This test uses the new FCM HTTP v1 API!',
      data: {
        'type': 'test',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'api_version': 'v1',
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