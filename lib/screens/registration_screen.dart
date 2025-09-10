import 'package:flutter/material.dart';
import '../models/enums.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  void _navigateToAuth(BuildContext context, UserType userType) {
    Navigator.pushNamed(
      context,
      '/auth',
      arguments: userType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Header Section
              _buildHeader(),
              
              const SizedBox(height: 80),
              
              // Selection Cards
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSelectionCard(
                      context: context,
                        title: 'Waris',
                        subtitle: 'Register as waris to request services',
                      icon: Icons.family_restroom_rounded,
                      userType: UserType.waris,
                      color: const Color(0xFF4A90E2),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildSelectionCard(
                      context: context,
                      title: 'Staff',
                        subtitle: 'Register as staff to provide services',
                      icon: Icons.work_rounded,
                      userType: UserType.staff,
                      color: const Color(0xFF50C878),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A90E2).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
            'Welcome',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
            'Choose your registration category',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFFB0B0B0),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required UserType userType,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _navigateToAuth(context, userType),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                size: 30,
                color: color,
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B0B0),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}