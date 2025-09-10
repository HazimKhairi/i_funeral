import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../models/death_case_model.dart';
import '../services/auth_service.dart';
import '../services/death_case_service.dart';

class WarisHomeScreen extends StatefulWidget {
  const WarisHomeScreen({super.key});

  @override
  State<WarisHomeScreen> createState() => _WarisHomeScreenState();
}

class _WarisHomeScreenState extends State<WarisHomeScreen> {
  final _authService = AuthService();
  final _deathCaseService = DeathCaseService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUserData();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToServiceForm(ServiceType serviceType) {
    Navigator.pushNamed(
      context,
      '/death-case-form',
      arguments: {
        'serviceType': serviceType,
        'currentUser': _currentUser,
      },
    );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 40),
                    _buildServicesSection(),
                    const SizedBox(height: 40),
                    _buildRecentCasesSection(),
                  ],
                ),
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
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
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
                  'Waris Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${_currentUser?.name ?? 'Heir'}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the required services for the deceased',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFFB0B0B0),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        
        // Full Service Card
        _buildServiceCard(
          title: 'Full Service',
          subtitle: 'Complete service including management and delivery',
          icon: Icons.home_work_rounded,
          color: const Color(0xFF4A90E2),
          serviceType: ServiceType.fullService,
        ),
        
        const SizedBox(height: 16),
        
        // Delivery Only Card
        _buildServiceCard(
          title: 'Delivery Only',
          subtitle: 'Corpse delivery service only',
          icon: Icons.local_shipping_rounded,
          color: const Color(0xFF50C878),
          serviceType: ServiceType.deliveryOnly,
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required ServiceType serviceType,
  }) {
    return GestureDetector(
      onTap: () => _navigateToServiceForm(serviceType),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B0B0),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCasesSection() {
    if (_currentUser == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Applications',
              style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16),
        
        StreamBuilder<List<DeathCaseModel>>(
          stream: _deathCaseService.getWarisDeathCases(_currentUser!.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final cases = snapshot.data!.take(3).toList();
            return Column(
              children: cases.map((deathCase) => 
                _buildCaseCard(deathCase)
              ).toList(),
            );
          },
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
            Icons.folder_open_rounded,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
            Text(
            'No applications yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
            ),
            const SizedBox(height: 8),
            Text(
            'Your applications will be displayed here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard(DeathCaseModel deathCase) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(deathCase.status.value).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deathCase.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(deathCase.status.value).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
  deathCase.status.value == 'pending' ? 'Waiting' :
  deathCase.status.value == 'accepted' ? 'Accepted' :
  deathCase.status.value == 'declined' ? 'Rejected' : 'Completed',
  style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: _getStatusColor(deathCase.status.value),
  ),
),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            deathCase.serviceType.value == 'fullService'
                ? 'Full Service'
                : 'Delivery Only',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB0B0B0),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA500);
      case 'accepted':
        return const Color(0xFF50C878);
      case 'declined':
        return const Color(0xFFFF6B6B);
      case 'completed':
        return const Color(0xFF4A90E2);
      default:
        return const Color(0xFFB0B0B0);
  }
  }
}