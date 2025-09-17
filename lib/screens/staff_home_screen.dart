import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../models/death_case_model.dart';
import '../services/auth_service.dart';
import '../services/death_case_service.dart';
import '../services/firebase_cloud_messaging_service.dart';
import '../theme/app_colors.dart';
import '../test_notification.dart';
class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _deathCaseService = DeathCaseService();
  UserModel? _currentUser;
  bool _isLoading = true;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
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
      
      // Ensure FCM token is saved for this staff member
      if (user != null && user.userType == UserType.staff) {
        await FirebaseCloudMessagingService.saveTokenToCurrentUser(user.id);
        print('✅ Staff FCM token updated: ${user.email}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Error loading current user: $e');
    }
  }

  // Show FCM Test Dialog
  void _showFCMTestDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: const FCMTestWidget(),
      ),
    );
  }

  Future<void> _handleAcceptCase(String caseId) async {
    try {
      await _deathCaseService.acceptDeathCase(caseId, _currentUser!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request has been accepted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: ${e.toString()}'),
            backgroundColor: AppColors.error,
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
            content: Text('Request declined. Other staff can still accept this request.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline request: ${e.toString()}'),
            backgroundColor: AppColors.error,
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
            content: Text('Case has been marked as completed'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete case: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _showDeclineConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: AppColors.warning,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Decline Request',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to decline this request?',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Other staff members can still accept this request.',
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Decline',
              style: TextStyle(
                color: AppColors.error,
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
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Check if current staff has declined this case
  bool _hasCurrentStaffDeclined(DeathCaseModel deathCase) {
    if (_currentUser == null) return false;
    return deathCase.declinedByStaff.contains(_currentUser!.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
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
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.highlight,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.work_rounded,
              color: AppColors.textPrimary,
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
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Staff Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // FCM Test notification button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.error,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                IconButton(
                  onPressed: _showFCMTestDialog,
                  icon: const Icon(
                    Icons.cloud_sync,
                    color: AppColors.error,
                    size: 20,
                  ),
                  tooltip: 'Test FCM - All Staff Notifications',
                ),
                // FCM indicator badge
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _signOut,
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.textPrimary,
              ),
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.accent,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_active, size: 20),
                SizedBox(width: 8),
                Text('All Requests'),
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
          Text(
            'Welcome, ${_currentUser?.name ?? 'Staff Member'}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All pending requests - accept the ones you can handle',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 30),
          
          StreamBuilder<List<DeathCaseModel>>(
            stream: _deathCaseService.getPendingDeathCases(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
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
            'My Request History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Requests that you have accepted',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 30),
          
          StreamBuilder<List<DeathCaseModel>>(
            stream: _deathCaseService.getStaffHandledCases(_currentUser!.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
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
    final hasDeclined = _hasCurrentStaffDeclined(deathCase);
    final declineCount = deathCase.declinedByStaff.length;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDeclined 
              ? AppColors.error.withOpacity(0.5)
              : AppColors.warning.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasDeclined 
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: hasDeclined ? AppColors.error : AppColors.warning,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hasDeclined ? 'DECLINED BY YOU' : 'NEW REQUEST',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      deathCase.serviceType == ServiceType.fullService 
                          ? Icons.home_work_rounded 
                          : Icons.local_shipping_rounded,
                      color: hasDeclined ? AppColors.error : AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      deathCase.serviceType == ServiceType.fullService 
                          ? 'Full Service' 
                          : 'Delivery Only',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hasDeclined ? AppColors.error : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                
                // Show decline status if applicable
                if (hasDeclined) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          color: AppColors.info,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            declineCount > 1
                                ? 'Waiting for other staff to accept ($declineCount staff declined)'
                                : 'Waiting for other staff to accept (You declined)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.info,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: hasDeclined 
                              ? AppColors.textPrimary.withOpacity(0.7)
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${deathCase.age} years old',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
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
                  value: deathCase.gender == Gender.lelaki ? 'Male' : 'Female',
                  isDeclined: hasDeclined,
                ),
                
                const SizedBox(height: 12),
                
                _buildDetailRow(
                  icon: Icons.medical_information_rounded,
                  label: 'Cause of Death',
                  value: deathCase.causeOfDeath,
                  isDeclined: hasDeclined,
                ),
                
                const SizedBox(height: 12),
                
                _buildDetailRow(
                  icon: Icons.location_on_rounded,
                  label: 'Address',
                  value: deathCase.address,
                  isDeclined: hasDeclined,
                ),
                
                if (deathCase.deliveryLocation != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.local_shipping_rounded,
                    label: 'Delivery Location',
                    value: deathCase.deliveryLocation!,
                    isDeclined: hasDeclined,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                _buildDetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Request Time',
                  value: _formatDateTime(deathCase.createdAt),
                  isDeclined: hasDeclined,
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                if (hasDeclined) ...[
                  // Show info that this staff declined
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.error,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You declined this request',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                              Text(
                                'Other staff members can still accept it',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Show accept/decline buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _handleDeclineCase(deathCase.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            label: const Text(
                              'Decline',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _handleAcceptCase(deathCase.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.textPrimary,
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
                      ),
                    ],
                  ),
                ],
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(deathCase.status).withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getStatusColor(deathCase.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCaseStatusDisplayName(deathCase.status).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
                  deathCase.serviceType == ServiceType.fullService 
                      ? 'Full Service' 
                      : 'Delivery Only',
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${deathCase.age} years old',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildDetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Accepted On',
                  value: deathCase.acceptedAt != null 
                      ? _formatDateTime(deathCase.acceptedAt!)
                      : 'N/A',
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
                
                // Complete button for accepted cases
                if (deathCase.status == CaseStatus.accepted) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.info.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _handleCompleteCase(deathCase.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: AppColors.textPrimary,
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
    bool isDeclined = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDeclined 
                ? AppColors.textMuted.withOpacity(0.5)
                : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDeclined 
                      ? AppColors.textMuted.withOpacity(0.6)
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isDeclined 
                      ? AppColors.textPrimary.withOpacity(0.6)
                      : AppColors.textPrimary,
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 48,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Pending Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New requests will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted.withOpacity(0.7),
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Requests you accept will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted.withOpacity(0.7),
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary.withOpacity(0.7),
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
        return 'Declined';
      case CaseStatus.completed:
        return 'Completed';
    }
  }

  Color _getStatusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.pending:
        return AppColors.warning;
      case CaseStatus.accepted:
        return AppColors.success;
      case CaseStatus.declined:
        return AppColors.error;
      case CaseStatus.completed:
        return AppColors.info;
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