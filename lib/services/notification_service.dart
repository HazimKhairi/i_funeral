import 'dart:isolate';
import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enums.dart';
import '../main.dart';

class NotificationService {
  static ReceivedAction? initialAction;
  static ReceivePort? receivePort;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Awesome Notifications
  static Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        // Notification channel for new death cases
        NotificationChannel(
          channelKey: 'new_case_channel',
          channelName: 'New Death Cases',
          channelDescription: 'Notifications for new death case requests',
          defaultColor: const Color(0xFF2E8B57),
          ledColor: const Color(0xFF2E8B57),
          playSound: true,
          onlyAlertOnce: false,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Private,
          enableVibration: true,
          enableLights: true,
          groupAlertBehavior: GroupAlertBehavior.Children,
        ),
        
        // General notifications channel
        NotificationChannel(
          channelKey: 'general_channel',
          channelName: 'General Notifications',
          channelDescription: 'General app notifications',
          defaultColor: const Color(0xFF33B5E5),
          ledColor: const Color(0xFF33B5E5),
          playSound: true,
          onlyAlertOnce: false,
          importance: NotificationImportance.Default,
          defaultPrivacy: NotificationPrivacy.Private,
        ),
      ],
      debug: true,
    );

    // Get initial notification action
    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
    
    // Initialize isolate receive port
    await initializeIsolateReceivePort();
  }

  /// Initialize isolate receive port for background notifications
  static Future<void> initializeIsolateReceivePort() async {
    receivePort = ReceivePort('Notification action port in main isolate')
      ..listen((silentData) => onActionReceivedImplementationMethod(silentData));

    IsolateNameServer.registerPortWithName(
        receivePort!.sendPort, 'notification_action_port');
  }

  /// Start listening to notification events
  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  /// Handle notification action received
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      // Handle background actions
      print('Notification action received: ${receivedAction.payload}');
    } else {
      // Handle foreground actions
      if (receivePort == null) {
        print('onActionReceivedMethod called inside parallel isolate.');
        SendPort? sendPort =
            IsolateNameServer.lookupPortByName('notification_action_port');

        if (sendPort != null) {
          print('Redirecting execution to main isolate process.');
          sendPort.send(receivedAction);
          return;
        }
      }

      return onActionReceivedImplementationMethod(receivedAction);
    }
  }

  /// Implementation method for handling notification actions
  static Future<void> onActionReceivedImplementationMethod(
      ReceivedAction receivedAction) async {
    
    // Handle different notification types
    if (receivedAction.payload != null) {
      final payload = receivedAction.payload!;
      
      // Handle new case notification
      if (payload['type'] == 'new_case') {
        // Navigate to staff home if user is staff
        MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/staff-home',
          (route) => route.isFirst,
        );
      }
    }
  }

  /// Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await displayNotificationRationale();
    }
    return isAllowed;
  }

  /// Display notification permission dialog
  static Future<bool> displayNotificationRationale() async {
    bool userAuthorized = false;
    BuildContext? context = MyApp.navigatorKey.currentContext;
    
    if (context != null) {
      await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Color(0xFF2E8B57),
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Enable Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Allow I-Funeral to send you notifications about new death case requests and important updates.',
              style: TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 16,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text(
                  'Not Now',
                  style: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E8B57).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () async {
                    userAuthorized = true;
                    Navigator.of(ctx).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
    
    return userAuthorized && await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  /// MAIN METHOD: Notify all staff about new death case
  static Future<void> notifyStaffNewCase({
    required String caseName,
    required String caseId,
    required ServiceType serviceType,
  }) async {
    try {
      print('🔔 Sending notification for new case: $caseName');

      // Check notification permissions
      bool isAllowed = await requestNotificationPermissions();
      if (!isAllowed) {
        print('❌ Notification permission denied');
        return;
      }

      // Create notification for new death case
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'new_case_channel',
          title: '🚨 New Death Case Request',
          body: 'New application for $caseName (${serviceType.displayName})',
          bigPicture: 'asset://assets/images/logo.png',
          largeIcon: 'asset://assets/images/logo.png',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Social,
          wakeUpScreen: true,
          fullScreenIntent: true,
          autoDismissible: false,
          backgroundColor: const Color(0xFF2E8B57),
          payload: {
            'type': 'new_case',
            'caseId': caseId,
            'caseName': caseName,
            'serviceType': serviceType.value,
          },
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
            isDangerousOption: false,
          ),
        ],
      );

      // Save notification to Firestore for all staff
      await _saveNotificationToFirestore(
        title: 'New Death Case Request',
        body: 'New application for $caseName (${serviceType.displayName})',
        data: {
          'type': 'new_case',
          'caseId': caseId,
          'caseName': caseName,
          'serviceType': serviceType.value,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        userType: UserType.staff,
      );

      print('✅ Notification sent successfully for case: $caseName');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  /// Save notification to Firestore for persistence
  static Future<void> _saveNotificationToFirestore({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    required UserType userType,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'data': data,
        'userType': userType.value,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'targetAudience': 'all_staff', // Indicate this is for all staff
      });
      
      print('📝 Notification saved to Firestore: $title');
    } catch (e) {
      print('❌ Error saving notification to Firestore: $e');
    }
  }

  /// Send case status update notification
  static Future<void> notifyCaseStatusUpdate({
    required String caseName,
    required String caseId,
    required CaseStatus status,
    required String recipientUserId,
  }) async {
    try {
      bool isAllowed = await requestNotificationPermissions();
      if (!isAllowed) return;

      String statusText = '';
      String emoji = '';
      Color notificationColor = const Color(0xFF33B5E5);

      switch (status) {
        case CaseStatus.accepted:
          statusText = 'accepted';
          emoji = '✅';
          notificationColor = const Color(0xFF00C851);
          break;
        case CaseStatus.declined:
          statusText = 'declined';
          emoji = '❌';
          notificationColor = const Color(0xFFFF4444);
          break;
        case CaseStatus.completed:
          statusText = 'completed';
          emoji = '🎉';
          notificationColor = const Color(0xFF33B5E5);
          break;
        default:
          return;
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'general_channel',
          title: '$emoji Case $statusText',
          body: 'Your request for $caseName has been $statusText',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Status,
          backgroundColor: notificationColor,
          payload: {
            'type': 'status_update',
            'caseId': caseId,
            'caseName': caseName,
            'status': status.value,
          },
        ),
      );

      print('✅ Status update notification sent for case: $caseName');
    } catch (e) {
      print('❌ Error sending status update notification: $e');
    }
  }

  /// Send test notification
  static Future<void> sendTestNotification({
    required String title,
    required String body,
  }) async {
    try {
      bool isAllowed = await requestNotificationPermissions();
      if (!isAllowed) return;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'general_channel',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Message,
          payload: {
            'type': 'test',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        ),
      );

      print('✅ Test notification sent successfully');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    print('🗑️ All notifications cancelled');
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int notificationId) async {
    await AwesomeNotifications().cancel(notificationId);
    print('🗑️ Notification $notificationId cancelled');
  }

  /// Get notification history from Firestore
  static Stream<List<Map<String, dynamic>>> getNotificationHistory(UserType userType) {
    return _firestore
        .collection('notifications')
        .where('userType', isEqualTo: userType.value)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }
}