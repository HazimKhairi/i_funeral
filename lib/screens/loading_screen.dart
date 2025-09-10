import 'dart:async';

import 'package:flutter/material.dart';
import 'package:i_funeral/models/enums.dart';
import 'package:i_funeral/services/auth_service.dart' show AuthService;

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
 final _authService = AuthService();
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkLoginAndNavigate();
    // TODO: implement initState
  }

    void _checkLoginAndNavigate() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      try {
        // Check if user is already logged in
        final loginStatus = await _authService.checkLoginStatus();
        
        if (loginStatus != null && loginStatus['isLoggedIn'] == true) {
          final user = loginStatus['user'];
          
          // Navigate to appropriate home screen
          final route = user.userType == UserType.waris 
              ? '/waris-home' 
              : '/staff-home';
              
          Navigator.pushNamedAndRemoveUntil(
            context,
            route,
            (route) => false,
          );
        } else {
          // Not logged in, go to registration
          Navigator.pushReplacementNamed(context, '/registration');
        }
      } catch (e) {
        // Error checking login, go to registration
        Navigator.pushReplacementNamed(context, '/registration');
      }
    }
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // fade in animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    //scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }


  
  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                        color: Color(0xFF4A90E2).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                        ),
                      ],
                      ),
                      child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                      ),
                    ),
                   
                    SizedBox(height: 20),
                    
                    const Text(
                      'I-Funeral',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    SizedBox(height: 12),

                    Center(
                      child: const Text(
                        'Collaboration with Pertubuhan Sentuhan Setia Kasih',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w300,
                          
                          ),
                      ),
                    ),

                    SizedBox(height: 60),

                    SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                        strokeWidth: 3,
                      ),
                    ),

                    SizedBox(height: 20),

                    const Text('Loading...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B0B0),
                    ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
