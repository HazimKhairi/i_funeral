import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_colors.dart';

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
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    
                    _buildHeader(),
                    
                    const SizedBox(height: 80),
                    
                    // Selection Cards Section
                    _buildSelectionSection(context),
                    
                    // Spacer to push content up when keyboard appears
                    const Spacer(),
                    
                    // Footer section
                    _buildFooter(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightGreen.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppColors.highlight,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            size: 40,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Welcome to I-Funeral',
          style: TextStyle(
            fontSize: 28,
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
          'Choose your registration category',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSelectionSection(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSelectionCard(
          context: context,
          title: 'Family Member',
          subtitle: 'Register as a family member to request funeral services',
          icon: Icons.family_restroom_rounded,
          userType: UserType.waris,
          color: AppColors.info,
        ),
        
        const SizedBox(height: 24),
        
        _buildSelectionCard(
          context: context,
          title: 'Staff Member',
          subtitle: 'Register as a staff member to provide funeral services',
          icon: Icons.work_rounded,
          userType: UserType.staff,
          color: AppColors.accent,
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
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 120,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToAuth(context, userType),
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: color,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: color,
                  ),
                ),
                
                const SizedBox(width: 20),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.highlight.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.highlight,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Collaboration with Pertubuhan Sentuhan Setia Kasih',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Secure & Trusted Service',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}