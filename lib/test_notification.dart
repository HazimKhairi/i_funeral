import 'package:flutter/material.dart';
import 'services/firebase_cloud_messaging_service.dart';
import 'services/auth_service.dart';
import 'models/enums.dart';
import 'models/user_model.dart';
import 'theme/app_colors.dart';

class FCMTestWidget extends StatefulWidget {
  const FCMTestWidget({super.key});

  @override
  State<FCMTestWidget> createState() => _FCMTestWidgetState();
}

class _FCMTestWidgetState extends State<FCMTestWidget> {
  final _authService = AuthService();
  String _testStatus = 'Ready to test Firebase Cloud Messaging!';
  bool _isLoading = false;
  List<UserModel> _activeStaff = [];

  @override
  void initState() {
    super.initState();
    _loadActiveStaff();
  }

  Future<void> _loadActiveStaff() async {
    try {
      final staff = await _authService.getAllActiveStaff();
      setState(() {
        _activeStaff = staff;
      });
    } catch (e) {
      print('Error loading active staff: $e');
    }
  }

  Future<void> _testFCMToAllStaff() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Sending FCM notification to ALL STAFF...';
    });

    try {
      // Reload active staff to get latest count
      await _loadActiveStaff();

      if (_activeStaff.isEmpty) {
        setState(() {
          _testStatus = '''❌ NO ACTIVE STAFF FOUND

Possible issues:
• No staff members have logged in recently
• FCM tokens not saved properly
• Check Firestore users collection

Please ensure staff@gmail.com and staff2@gmail.com 
have logged into the app recently.''';
        });
        return;
      }

      // Send test notification to all staff
      await FirebaseCloudMessagingService.sendTestNotification();

      setState(() {
        _testStatus = '''✅ FCM NOTIFICATION SENT TO ALL STAFF!

📊 Notification Details:
• Recipients: ${_activeStaff.length} staff members
• Method: Firebase Cloud Messaging
• Delivery: Cross-device real-time

👥 Active Staff:
${_activeStaff.map((staff) => '• ${staff.email}').join('\n')}

📱 ALL STAFF should receive notification now!
🔔 Check notification panels on all devices.

This proves the FCM system works for real death cases!''';
      });
    } catch (e) {
      setState(() {
        _testStatus = '''❌ ERROR SENDING FCM NOTIFICATION

Error: $e

🔧 Troubleshooting:
1. Check FCM server key in firebase_cloud_messaging_service.dart
2. Verify internet connection
3. Ensure Firebase project is configured
4. Check console logs for detailed error messages

Please fix the error and try again.''';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testNewCaseNotification() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Simulating new death case submission...';
    });

    try {
      await _loadActiveStaff();

      if (_activeStaff.isEmpty) {
        setState(() {
          _testStatus = '''❌ Cannot test: No active staff found.
          
Ensure staff@gmail.com and staff2@gmail.com are logged in.''';
        });
        return;
      }

      // Test realistic death case notification
      final testCases = [
        {'name': 'Ahmad bin Abdullah', 'service': ServiceType.fullService},
        {'name': 'Siti Aminah binti Hassan', 'service': ServiceType.deliveryOnly},
        {'name': 'Mohd Rizal bin Omar', 'service': ServiceType.fullService},
      ];

      final testCase = testCases[DateTime.now().millisecond % testCases.length];

      await FirebaseCloudMessagingService.notifyStaffNewCase(
        caseName: testCase['name'] as String,
        caseId: 'FCM_TEST_${DateTime.now().millisecondsSinceEpoch}',
        serviceType: testCase['service'] as ServiceType,
      );

      setState(() {
        _testStatus = '''🚨 NEW DEATH CASE NOTIFICATION SENT!

📋 Test Case Details:
• Name: ${testCase['name']}
• Service: ${(testCase['service'] as ServiceType).displayName}
• Method: Firebase Cloud Messaging
• Recipients: ${_activeStaff.length} staff members

👥 Notified Staff:
${_activeStaff.map((staff) => '• ${staff.email}').join('\n')}

📱 This is EXACTLY what happens when waris submit real death case!
🔔 ALL STAFF should receive "🚨 New Death Case Request" notification!

Perfect for testing cross-device notification system!''';
      });
    } catch (e) {
      setState(() {
        _testStatus = 'ERROR: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkFCMStatus() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Checking FCM system status...';
    });

    try {
      // Check current user's token
      String? currentToken = await FirebaseCloudMessagingService.getCurrentToken();
      bool notificationsEnabled = await FirebaseCloudMessagingService.areNotificationsEnabled();
      
      await _loadActiveStaff();

      setState(() {
        _testStatus = '''🔍 FCM SYSTEM STATUS

📱 Current Device:
• FCM Token: ${currentToken != null ? '✅ Available (${currentToken.substring(0, 20)}...)' : '❌ Not available'}
• Notifications: ${notificationsEnabled ? '✅ Enabled' : '❌ Disabled'}

👥 Active Staff in Database:
${_activeStaff.isNotEmpty ? _activeStaff.map((staff) => '''• ${staff.email}
  - Token: ${staff.fcmToken != null ? '✅ Available' : '❌ Missing'}
  - Last Update: ${staff.fcmToken != null ? 'Recent' : 'Never'}''').join('\n') : '❌ No active staff found'}

📊 System Summary:
• Total Active Staff: ${_activeStaff.length}
• FCM Ready: ${_activeStaff.where((s) => s.fcmToken != null).length}/${_activeStaff.length}
• Ready for Testing: ${_activeStaff.length >= 2 ? '✅ YES' : '❌ Need 2+ staff'}

${_activeStaff.length < 2 ? '''
🔧 To test properly:
1. Login as staff@gmail.com on one device
2. Login as staff2@gmail.com on another device  
3. Both should appear in active staff list above
''' : '✅ Ready to test cross-device notifications!'}''';
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Error checking FCM status: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_sync,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FIREBASE CLOUD MESSAGING TEST',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      Text(
                        'Test ALL STAFF notifications',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Status Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textMuted.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'FCM Test Status',
                        style: TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _testStatus,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_isLoading) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
              ),
              const SizedBox(width: 16),
              const Text(
                'Processing...',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Test Buttons
            Column(
              children: [
                // Check FCM Status
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.info.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkFCMStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.health_and_safety, size: 22),
                    label: const Text(
                      'Check FCM System Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Test New Case Notification (PRIMARY TEST)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warning.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testNewCaseNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.notification_add, size: 24),
                    label: const Text(
                      'Test New Death Case Alert',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Simple FCM Test
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testFCMToAllStaff,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.send, size: 22),
                    label: const Text(
                      'Send Test FCM to All Staff',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.rocket_launch,
                        color: AppColors.error,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Firebase Cloud Messaging',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Tests cross-device notification delivery\n'
                    '• Ensures ALL STAFF receive death case alerts\n'
                    '• Verifies staff@gmail.com AND staff2@gmail.com get notified\n'
                    '• Uses Firebase Cloud Messaging for real-time delivery\n'
                    '• Perfect for testing before production deployment',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}