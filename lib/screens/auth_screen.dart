import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  late UserType _userType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userType = ModalRoute.of(context)!.settings.arguments as UserType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserModel? user;
      
      if (_isLogin) {
        user = await _authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        user = await _authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          userType: _userType,
          phoneNumber: _phoneController.text.trim().isEmpty 
              ? null 
              : _phoneController.text.trim(),
        );
      }

      if (user != null && mounted) {
        // Navigate to respective homepage
        final route = user.userType == UserType.waris 
            ? '/waris-home' 
            : '/staff-home';
        Navigator.pushNamedAndRemoveUntil(
          context,
          route,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 20),
              
              _buildHeader(),
              
              const SizedBox(height: 50),
              
              _buildForm(),
              
              const SizedBox(height: 30),
              
              _buildSubmitButton(),
              
              const SizedBox(height: 24),
              
              _buildToggleButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userTypeTitle = _userType == UserType.waris ? 'Waris' : 'Staff';
    final actionTitle = _isLogin ? 'Log Masuk' : 'Daftar';
    
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _userType == UserType.waris 
                ? const Color(0xFF4A90E2) 
                : const Color(0xFF50C878),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            _userType == UserType.waris 
                ? Icons.family_restroom_rounded 
                : Icons.work_rounded,
            size: 30,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 20),
        
        Text(
          '$actionTitle $userTypeTitle',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
            _isLogin 
              ? 'Welcome back! Please log in to your account'
              : 'Create a new account to use our services',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFB0B0B0),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLogin) ...[
            _buildTextField(
              controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_rounded,
                validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
          ],
          
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
                if (value == null || value.isEmpty) {
                return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
                }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFFB0B0B0),
              ),
            ),
            validator: (value) {
                if (value == null || value.isEmpty) {
                return 'Please enter your password';
                }
                if (value.length < 6) {
                return 'Password must be at least 6 characters';
                }
              return null;
            },
          ),
          
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _phoneController,
                label: 'Phone Number (Optional)',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        prefixIcon: Icon(icon, color: const Color(0xFFB0B0B0)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF2D2D44),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _userType == UserType.waris 
                ? const Color(0xFF4A90E2) 
                : const Color(0xFF50C878),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final color = _userType == UserType.waris 
        ? const Color(0xFF4A90E2) 
        : const Color(0xFF50C878);
        
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isLogin ? 'Login' : 'Register',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLogin = !_isLogin;
          // Clear form when switching
          _nameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _phoneController.clear();
        });
      },
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14),
          children: [
            TextSpan(
              text: _isLogin 
                ? "Don't have an account? "
                : 'Already have an account? ',
              style: const TextStyle(color: Color(0xFFB0B0B0)),
            ),
            TextSpan(
              text: _isLogin ? 'Register here' : 'Login here',
              style: TextStyle(
                color: _userType == UserType.waris 
                    ? const Color(0xFF4A90E2) 
                    : const Color(0xFF50C878),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}