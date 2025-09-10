import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'models/enums.dart';

class TestNotificationWidget extends StatefulWidget {
  const TestNotificationWidget({super.key});

  @override
  State<TestNotificationWidget> createState() => _TestNotificationWidgetState();
}

class _TestNotificationWidgetState extends State<TestNotificationWidget> {
  String _notificationStatus = 'Ready to test!';

  // Test REAL system notification
  Future<void> _showRealNotification() async {
    try {
      NotificationService.showTestNotification(
        title: 'Test Notification',
        body: 'This is a test notification',
        userType: UserType.client,
      );
      setState(() {
        _notificationStatus = 'Real notification sent! Check top of screen 📱';
      });
    } catch (e) {
      setState(() {
        _notificationStatus = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF50C878), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔔 REAL NOTIFICATION TEST',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF50C878),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _notificationStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRealNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50C878),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.notifications_active),
              label: const Text(
                'Show Real System Notification',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          const SizedBox(height: 15),
          
          const Text(
            '⚠️ This will appear at the top like real notifications',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFF6B6B),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}