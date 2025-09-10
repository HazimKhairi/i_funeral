import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../models/death_case_model.dart';
import '../services/auth_service.dart';
import '../services/death_case_service.dart';
import '../services/notification_service.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _deathCaseService = DeathCaseService();
  final _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;
  bool _isLoading = true;
  int _unreadNotifications = 0;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
    _setupNotificationListener();
    
    // Setup notification handling for when app is in foreground
    NotificationService.handleForegroundNotifications(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUserData();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
      
      if (user != null && user.userType == UserType.staff) {
        await NotificationService.saveTokenToUser(user.id);
        _checkUnreadNotifications();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _setupNotificationListener() {
    // Listen for new notifications in Firestore
    _firestore
        .collection('notifications')
        .where('userType', isEqualTo: 'staff')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _unreadNotifications = snapshot.docs.length;
        });
      }
    });
  }
  
  void _testNotification() {
    // Show a test notification
    NotificationService.showTestNotification(
      title: 'Test Notification',
      body: 'This is a test notification for staff',
      userType: UserType.staff,
    );
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent'),
        backgroundColor: Color(0xFF50C878),
      ),
    );
  }
  
  Future<void> _checkUnreadNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userType', isEqualTo: 'staff')
          .where('read', isEqualTo: false)
          .get();
      
      if (mounted) {
        setState(() {
          _unreadNotifications = snapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error checking unread notifications: $e');
    }
  }

  Future<void> _handleAcceptCase(String caseId) async {
    try {
      await _deathCaseService.acceptDeathCase(caseId, _currentUser!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application has been accepted'),
            backgroundColor: Color(0xFF50C878),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept application: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeclineCase(String caseId) async {
    final confirmed = await _showDeclineConfirmation();
    if (!confirmed) return;

    try {
      await _deathCaseService.declineDeathCase(caseId, _currentUser!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application has been rejected'),
            backgroundColor: Color(0xFFFF6B6B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject application: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCompleteCase(String caseId) async {
    try {
      await _deathCaseService.completeDeathCase(caseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application has been completed'),
            backgroundColor: Color(0xFF4A90E2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete application: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeclineConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Color(0xFFFF6B6B),
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Reject Application',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to reject this application?',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reject',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/loading',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showNotifications() async {
    // Get notifications from Firestore
    final notificationsSnapshot = await _firestore
        .collection('notifications')
        .where('userType', isEqualTo: 'staff')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    
    if (!mounted) return;
    
    // Mark notifications as read
    for (final doc in notificationsSnapshot.docs) {
      if (doc['read'] == false) {
        await _firestore.collection('notifications').doc(doc.id).update({
          'read': true
        });
      }
    }
    
    // Reset unread count
    setState(() {
      _unreadNotifications = 0;
    });
    
    // Show notifications in a modal bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D44),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Color(0xFF50C878),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF3F3F5F)),
                Expanded(
                  child: notificationsSnapshot.docs.isEmpty
                      ? const Center(
                          child: Text(
                            'No notifications yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: notificationsSnapshot.docs.length,
                          itemBuilder: (context, index) {
                            final notification = notificationsSnapshot.docs[index];
                            final data = notification.data();
                            final notificationData = data['data'] as Map<String, dynamic>?;
                            final timestamp = data['createdAt'] as Timestamp?;
                            final formattedTime = timestamp != null
                                ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                                : 'Just now';
                            
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF50C878).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.book_online,
                                  color: Color(0xFF50C878),
                                ),
                              ),
                              title: Text(
                                data['title'] ?? 'New Notification',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['body'] ?? '',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedTime,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Navigate to case details if available
                                if (notificationData != null && 
                                    notificationData['type'] == 'new_case' && 
                                    notificationData['caseId'] != null) {
                                  Navigator.pop(context); // Close bottom sheet
                                  // Navigate to case details
                                  // You can implement this navigation based on your app's routing
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF50C878)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingCasesTab(),
                  _buildMyHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF50C878),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.work_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'I-Funeral',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Staff Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: _showNotifications,
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF50C878),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFFB0B0B0),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_active, size: 20),
                SizedBox(width: 8),
                Text('New Applications'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 20),
                SizedBox(width: 8),
                Text('My History'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCasesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Welcome, ${_currentUser?.name ?? 'Staff'}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Test notification button
              ElevatedButton.icon(
                onPressed: _testNotification,
                icon: const Icon(Icons.notifications_active, size: 16),
                label: const Text('Test Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF50C878),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'There are new applications waiting for your action',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFB0B0B0),
            ),
          ),
          const SizedBox(height: 30),
          
          StreamBuilder<List<DeathCaseModel>>(
            stream: _deathCaseService.getPendingDeathCases(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF50C878)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState();
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final pendingCases = snapshot.data!;
              return Column(
                children: pendingCases.map((deathCase) => 
                  _buildPendingCaseCard(deathCase)
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyHistoryTab() {
    if (_currentUser == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Application History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Applications you have accepted',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFB0B0B0),
            ),
          ),
          const SizedBox(height: 30),
          
          StreamBuilder<List<DeathCaseModel>>(
            stream: _deathCaseService.getStaffHandledCases(_currentUser!.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF50C878)),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyHistoryState();
              }

              final handledCases = snapshot.data!;
              return Column(
                children: handledCases.map((deathCase) => 
                  _buildHistoryCaseCard(deathCase)
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCaseCard(DeathCaseModel deathCase) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFA500).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA500).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA500),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  deathCase.serviceType == ServiceType.fullService 
                      ? Icons.home_work_rounded 
                      : Icons.local_shipping_rounded,
                  color: const Color(0xFFFFA500),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  deathCase.serviceType.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFA500),
                  ),
                ),
              ],
            ),
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Age
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deathCase.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${deathCase.age} years',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Details Grid
                _buildDetailRow(
                  icon: deathCase.gender == Gender.lelaki 
                      ? Icons.male_rounded 
                      : Icons.female_rounded,
                  label: 'Gender',
                  value: deathCase.gender.displayName,
                ),
                
                const SizedBox(height: 12),
                
                _buildDetailRow(
                  icon: Icons.medical_information_rounded,
                  label: 'Cause of Death',
                  value: deathCase.causeOfDeath,
                ),
                
                const SizedBox(height: 12),
                
                _buildDetailRow(
                  icon: Icons.location_on_rounded,
                  label: 'Address',
                  value: deathCase.address,
                ),
                
                if (deathCase.deliveryLocation != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.local_shipping_rounded,
                    label: 'Delivery Location',
                    value: deathCase.deliveryLocation!,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                _buildDetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Application Time',
                  value: _formatDateTime(deathCase.createdAt),
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleDeclineCase(deathCase.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text(
                          'Reject',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAcceptCase(deathCase.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF50C878),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text(
                          'Accept',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCaseCard(DeathCaseModel deathCase) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(deathCase.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getStatusColor(deathCase.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(deathCase.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCaseStatusDisplayName(deathCase.status).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  deathCase.serviceType == ServiceType.fullService 
                      ? Icons.home_work_rounded 
                      : Icons.local_shipping_rounded,
                  color: _getStatusColor(deathCase.status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  deathCase.serviceType.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(deathCase.status),
                  ),
                ),
              ],
            ),
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Age
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deathCase.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${deathCase.age} tahun',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildDetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Accepted on',
                  value: deathCase.acceptedAt != null 
                      ? _formatDateTime(deathCase.acceptedAt!)
                      : 'N/A',
                ),
                
                const SizedBox(height: 12),
                
                _buildDetailRow(
                  icon: Icons.location_on_rounded,
                  label: 'Alamat',
                  value: deathCase.address,
                ),
                
                if (deathCase.deliveryLocation != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.local_shipping_rounded,
                    label: 'Lokasi Penghantaran',
                    value: deathCase.deliveryLocation!,
                  ),
                ],
                
                // Complete button for accepted cases
                if (deathCase.status == CaseStatus.accepted) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleCompleteCase(deathCase.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.done_all_rounded, size: 20),
                      label: const Text(
                        'Mark as Completed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFFB0B0B0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB0B0B0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No New Applications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New applications will be displayed here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Applications you have accepted will be displayed here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Color(0xFFFF6B6B),
          ),
          const SizedBox(height: 20),
          const Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getCaseStatusDisplayName(CaseStatus status) {
    switch (status) {
      case CaseStatus.pending:
        return 'Pending';
      case CaseStatus.accepted:
        return 'Accepted';
      case CaseStatus.declined:
        return 'Rejected';
      case CaseStatus.completed:
        return 'Completed';
    }
  }

  Color _getStatusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.pending:
        return const Color(0xFFFFA500);
      case CaseStatus.accepted:
        return const Color(0xFF50C878);
      case CaseStatus.declined:
        return const Color(0xFFFF6B6B);
      case CaseStatus.completed:
        return const Color(0xFF4A90E2);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}