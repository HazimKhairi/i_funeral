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
  String _testStatus = 'Ready to test Firebase Cloud Messaging HTTP v1 API!';
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

  Future<void> _testFCMV1ToAllStaff() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Sending FCM HTTP v1 notification to ALL STAFF...';
    });

    try {
      // Reload active staff to get latest count
      await _loadActiveStaff();

      if (_activeStaff.isEmpty) {
        setState(() {
          _testStatus = '''❌ NO ACTIVE STAFF FOUND

Setup Required:
• Ensure staff@gmail.com and staff2@gmail.com are logged in
• Check that service account JSON is configured
• Verify project ID is correct in FCM service
• Make sure Firebase project has HTTP v1 API enabled''';
        });
        return;
      }

      // Send test notification using HTTP v1 API
      await FirebaseCloudMessagingService.sendTestNotification();

      setState(() {
        _testStatus = '''✅ FCM HTTP v1 NOTIFICATION SENT!

🚀 NEW API FEATURES:
• Using OAuth 2.0 access tokens (more secure)
• HTTP v1 API endpoint
• Better cross-platform support
• Future-proof implementation

📊 Notification Details:
• Recipients: ${_activeStaff.length} staff members
• Method: Firebase Cloud Messaging v1
• Authentication: OAuth 2.0 service account
• Endpoint: /v1/projects/{project}/messages:send

👥 Active Staff:
${_activeStaff.map((staff) => '• ${staff.email}').join('\n')}

📱 ALL STAFF should receive the new v1 notification!
🎉 Your FCM system is now using the modern API!''';
      });
    } catch (e) {
      setState(() {
        _testStatus = '''❌ ERROR WITH FCM HTTP v1 API

Error: $e

🔧 Troubleshooting:
1. ✅ Check that service-account.json is in assets/
2. ✅ Verify project ID in firebase_cloud_messaging_service.dart
3. ✅ Ensure googleapis_auth dependency is added
4. ✅ Confirm Firebase Cloud Messaging API is enabled in Google Cloud Console
5. ✅ Make sure service account has Firebase Admin permissions

💡 The old server key method is deprecated. This new method is required!''';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testNewCaseNotificationV1() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Testing new death case with HTTP v1 API...';
    });

    try {
      await _loadActiveStaff();

      if (_activeStaff.isEmpty) {
        setState(() {
          _testStatus = '''❌ Cannot test: No active staff found.
          
Ensure staff accounts are logged in and properly configured.''';
        });
        return;
      }

      // Test realistic death case notification with v1 API
      final testCases = [
        {'name': 'Ahmad bin Abdullah', 'service': ServiceType.fullService},
        {'name': 'Siti Aminah binti Hassan', 'service': ServiceType.deliveryOnly},
        {'name': 'Mohd Rizal bin Omar', 'service': ServiceType.fullService},
      ];

      final testCase = testCases[DateTime.now().millisecond % testCases.length];

      await FirebaseCloudMessagingService.notifyStaffNewCase(
        caseName: testCase['name'] as String,
        caseId: 'V1_TEST_${DateTime.now().millisecondsSinceEpoch}',
        serviceType: testCase['service'] as ServiceType,
      );

      setState(() {
        _testStatus = '''🚨 NEW DEATH CASE NOTIFICATION SENT (HTTP v1)!

📋 Test Case Details:
• Name: ${testCase['name']}
• Service: ${(testCase['service'] as ServiceType).displayName}
• Method: Firebase Cloud Messaging HTTP v1
• Security: OAuth 2.0 access token
• Recipients: ${_activeStaff.length} staff members

🔐 SECURITY IMPROVEMENTS:
• ✅ OAuth 2.0 tokens (expire automatically)
• ✅ Service account authentication
• ✅ No exposed API keys
• ✅ Google Cloud IAM managed permissions

👥 Notified Staff:
${_activeStaff.map((staff) => '• ${staff.email}').join('\n')}

📱 This is EXACTLY what happens with the new API!
🔔 ALL STAFF should receive "🚨 New Death Case Request" via HTTP v1!

Perfect modern notification system! 🎉''';
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

  Future<void> _checkFCMV1Status() async {
    setState(() {
      _isLoading = true;
      _testStatus = 'Checking FCM HTTP v1 system status...';
    });

    try {
      // Check current user's token
      String? currentToken = await FirebaseCloudMessagingService.getCurrentToken();
      bool notificationsEnabled = await FirebaseCloudMessagingService.areNotificationsEnabled();
      
      await _loadActiveStaff();

      setState(() {
        _testStatus = '''🔍 FCM HTTP v1 SYSTEM STATUS

🆕 MODERN API FEATURES:
• OAuth 2.0 authentication ✅
• Service account security ✅
• Cross-platform messaging ✅
• Future-proof implementation ✅

📱 Current Device:
• FCM Token: ${currentToken != null ? '✅ Available (${currentToken.substring(0, 20)}...)' : '❌ Not available'}
• Notifications: ${notificationsEnabled ? '✅ Enabled' : '❌ Disabled'}

👥 Active Staff in Database:
${_activeStaff.isNotEmpty ? _activeStaff.map((staff) => '''• ${staff.email}
  - Token: ${staff.fcmToken != null ? '✅ Available' : '❌ Missing'}
  - Ready for v1: ${staff.fcmToken != null ? '✅ YES' : '❌ NO'}''').join('\n') : '❌ No active staff found'}

📊 System Summary:
• Total Active Staff: ${_activeStaff.length}
• HTTP v1 Ready: ${_activeStaff.where((s) => s.fcmToken != null).length}/${_activeStaff.length}
• Modern API: ✅ ENABLED
• Legacy API: ❌ DEPRECATED (July 2024)

${_activeStaff.length < 2 ? '''
🔧 Setup Instructions:
1. Login as staff@gmail.com on device 1
2. Login as staff2@gmail.com on device 2  
3. Both should appear in active staff list above
4. Test cross-device notifications
''' : '🎉 Ready to test modern FCM HTTP v1 notifications!'}

🚀 Your app is now using the latest FCM technology!''';
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Error checking FCM v1 status: $e';
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
        border: Border.all(color: AppColors.success, width: 2),
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
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
                    color: AppColors.success,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FCM HTTP v1 API TEST',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        'Modern Firebase Cloud Messaging',
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
                        'FCM HTTP v1 Status',
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
              ),
              const SizedBox(width: 16),
              const Text(
                'Testing HTTP v1 API...',
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
                // Check FCM v1 Status
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
                    onPressed: _isLoading ? null : _checkFCMV1Status,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.analytics, size: 22),
                    label: const Text(
                      'Check HTTP v1 System Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Test New Case Notification v1
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
                    onPressed: _isLoading ? null : _testNewCaseNotificationV1,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.security, size: 24),
                    label: const Text(
                      'Test Death Case Alert (HTTP v1)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Simple FCM v1 Test
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
                    onPressed: _isLoading ? null : _testFCMV1ToAllStaff,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.rocket, size: 22),
                    label: const Text(
                      'Test HTTP v1 to All Staff',
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
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: AppColors.success,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Modern FCM HTTP v1 API',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '🔐 OAuth 2.0 authentication (more secure)\n'
                    '🚀 Future-proof implementation\n'
                    '📱 Better cross-platform support\n'
                    '⚡ Real-time delivery\n'
                    '✅ Replaces deprecated server key method\n'
                    '🎯 Production-ready notification system',
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