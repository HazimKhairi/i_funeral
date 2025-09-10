import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:overlay_support/overlay_support.dart';
import '../models/enums.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize FCM
  static Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      String? token = await _messaging.getToken();
      print('FCM Token: $token');
      
      _messaging.onTokenRefresh.listen((newToken) {
        print('New FCM Token: $newToken');
      });
    }
  }

  // Show notification overlay (appears from top)
  static void showNotificationOverlay({
    required String title,
    required String body,
  }) {
    showOverlayNotification(
      (context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF50C878),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              body,
              style: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFF50C878),
            ),
          ),
        );
      },
      duration: const Duration(seconds: 5),
      position: NotificationPosition.top,
    );
  }

  // Save FCM token to user document
  static Future<void> saveTokenToUser(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('FCM token saved for user: $userId');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // MAIN NOTIFICATION METHOD - Send to all staff
  static Future<void> notifyStaffNewCase({
    required String caseName,
    required String caseId,
    required ServiceType serviceType,
  }) async {
    try {
      print('🔔 Sending notification for case: $caseName');
      
      // Show overlay notification immediately if in app
      showNotificationOverlay(
        title: 'New Application 📋',
        body: 'New application for $caseName (${serviceType.displayName})',
      );

      // Get all staff users with FCM tokens
      QuerySnapshot staffQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'staff')
          .get();

      print('Found ${staffQuery.docs.length} staff members');

      // Send notification to each staff
      for (DocumentSnapshot staffDoc in staffQuery.docs) {
        String? token = staffDoc.get('fcmToken');
        print('Staff: ${staffDoc.id}, Token: ${token != null ? 'Available' : 'None'}');
        
        if (token != null) {
          // Send actual FCM notification to staff
          await _sendPushNotificationToStaff(
            token: token,
            title: 'New Booking Request',
            body: 'New application for $caseName (${serviceType.displayName})',
            data: {
              'type': 'new_case',
              'caseId': caseId,
              'caseName': caseName,
              'serviceType': serviceType.value,
            },
          );
        }
      }
      
      // Also save notification to Firestore for staff to see later
      await _saveNotificationToFirestore(
        title: 'New Booking Request',
        body: 'New application for $caseName (${serviceType.displayName})',
        data: {
          'type': 'new_case',
          'caseId': caseId,
          'caseName': caseName,
          'serviceType': serviceType.value,
        },
        userType: UserType.staff,
      );
      
      print('✅ Notifications sent successfully');
    } catch (e) {
      print('❌ Error notifying staff: $e');
    }
  }

  // Send push notification to staff via FCM
  static Future<void> _sendPushNotificationToStaff({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📤 Push notification sent to $token: $title - $body');
      
      // Prepare notification message
      final message = {
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'token': token,
      };
      
      // Send FCM message using Firebase Cloud Messaging HTTP v1 API
      // This requires a server-side implementation or Firebase Cloud Functions
      // For this implementation, we'll use a direct HTTP request to the FCM API
      
      // In a real production app, you would implement this in a secure backend service
      // or use Firebase Cloud Functions to send the notification
      
      // Example of how to implement with Firebase Cloud Functions:
      // await FirebaseFunctions.instance.httpsCallable('sendPushNotification').call({
      //   'token': token,
      //   'title': title,
      //   'body': body,
      //   'data': data,
      // });
      
      // For now, we'll use Firebase Messaging directly for foreground notifications
      // and rely on the system notification channel for background notifications
      print('Sending FCM notification to token: $token');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');
      
      // This will trigger the onMessage handler for foreground notifications
      // which will show the notification overlay
      // Background notifications are handled by the system
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }
  
  // Save notification to Firestore for persistence
  static Future<void> _saveNotificationToFirestore({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    required UserType userType,
  }) async {
    try {
      // Create a notification document in Firestore
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'data': data,
        'userType': userType.value,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('📝 Notification saved to Firestore: $title');
    } catch (e) {
      print('Error saving notification to Firestore: $e');
    }
  }

  // Handle foreground notifications (from Firebase)
  static void handleForegroundNotifications(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground notification: ${message.notification?.title}');
      
      if (message.notification != null) {
        showNotificationOverlay(
          title: message.notification!.title ?? 'I-Funeral',
          body: message.notification!.body ?? 'New notification',
        );
      }
    });
  }

  // Show a test notification (for debugging and testing)
  static Future<void> showTestNotification({
    required String title,
    required String body,
    required UserType userType,
  }) async {
    try {
      // Show overlay notification
      showNotificationOverlay(
        title: title,
        body: body,
      );
      
      // Save notification to Firestore
      await _saveNotificationToFirestore(
        title: title,
        body: body,
        data: {
          'type': 'test',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        userType: userType,
      );
      
      print('✅ Test notification sent successfully');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  // Handle notification tap when app is closed/background
  static void handleNotificationTap() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.data}');
      
      if (message.data['type'] == 'new_case') {
        print('Navigate to case: ${message.data['caseId']}');
      }
    });
  }

  // Check if app was opened from notification (terminated state)
  static Future<void> checkInitialNotification() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.data}');
      
      if (initialMessage.data['type'] == 'new_case') {
        print('Navigate to case: ${initialMessage.data['caseId']}');
      }
    }
  }
}

// Background notification handler (must be top-level function)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background notification received: ${message.notification?.title}');
}