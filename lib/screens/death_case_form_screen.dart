import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../models/death_case_model.dart';
import '../services/death_case_service.dart';
import '../services/notification_service.dart'; // Add this import
import '../theme/app_colors.dart';

class DeathCaseFormScreen extends StatefulWidget {
  const DeathCaseFormScreen({super.key});

  @override
  State<DeathCaseFormScreen> createState() => _DeathCaseFormScreenState();
}

class _DeathCaseFormScreenState extends State<DeathCaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deathCaseService = DeathCaseService();
  
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _causeOfDeathController = TextEditingController();
  final _addressController = TextEditingController();
  final _deliveryLocationController = TextEditingController();
  
  ServiceType? _serviceType;
  UserModel? _currentUser;
  Gender _selectedGender = Gender.lelaki;
  bool _isLoading = false;

  // DEBUG VARIABLES
  List<String> _debugMessages = [];
  bool _showDebugPanel = false;
  bool _notificationSent = false;
  String? _notificationError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _serviceType = arguments['serviceType'] as ServiceType;
    _currentUser = arguments['currentUser'] as UserModel?;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _causeOfDeathController.dispose();
    _addressController.dispose();
    _deliveryLocationController.dispose();
    super.dispose();
  }

  // DEBUG METHOD
  void _addDebugMessage(String message) {
    setState(() {
      _debugMessages.add('${DateTime.now().toLocal().toString().substring(11, 19)}: $message');
    });
    print('🔍 DEBUG: $message'); // Also print to console
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _debugMessages.clear();
      _notificationSent = false;
      _notificationError = null;
      _showDebugPanel = true;
    });

    try {
      _addDebugMessage('Starting form submission...');
      
      final deathCase = DeathCaseModel(
        id: '', // Will be set by Firestore
        fullName: _fullNameController.text.trim(),
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        causeOfDeath: _causeOfDeathController.text.trim(),
        address: _addressController.text.trim(),
        deliveryLocation: _deliveryLocationController.text.trim().isEmpty 
            ? null 
            : _deliveryLocationController.text.trim(),
        serviceType: _serviceType!,
        warisId: _currentUser!.id,
        status: CaseStatus.pending,
        createdAt: DateTime.now(),
      );

      _addDebugMessage('Death case model created');
      _addDebugMessage('Saving to Firestore...');

      // Create death case with debugging
      final caseId = await _deathCaseService.createDeathCase(deathCase);
      
      _addDebugMessage('Case saved to Firestore with ID: ${caseId.substring(0, 8)}...');
      
      // Test notification directly here for debugging
      await _testNotificationSending(deathCase.fullName, caseId, deathCase.serviceType);

      if (mounted) {
        _addDebugMessage('Form submission completed successfully');
        
        // Show success dialog after a short delay to see debug info
        await Future.delayed(const Duration(seconds: 2));
        _showSuccessDialog();
      }
    } catch (e) {
      _addDebugMessage('ERROR: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${e.toString()}'),
            backgroundColor: AppColors.error,
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

  // DEBUG NOTIFICATION TEST
  Future<void> _testNotificationSending(String caseName, String caseId, ServiceType serviceType) async {
    try {
      _addDebugMessage('Testing notification system...');
      
      // Test direct notification call
      await NotificationService.notifyStaffNewCase(
        caseName: caseName,
        caseId: caseId,
        serviceType: serviceType,
      );
      
      setState(() {
        _notificationSent = true;
      });
      _addDebugMessage('✅ Notification sent successfully!');
      
    } catch (e) {
      setState(() {
        _notificationError = e.toString();
      });
      _addDebugMessage('❌ Notification failed: ${e.toString()}');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Successfully Submitted',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your request has been successfully submitted. Our staff will contact you shortly.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            
            // NOTIFICATION STATUS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _notificationSent 
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _notificationSent 
                      ? AppColors.success
                      : AppColors.error,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _notificationSent 
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: _notificationSent 
                        ? AppColors.success
                        : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _notificationSent 
                          ? 'Staff notifications sent successfully'
                          : 'Notification failed: ${_notificationError ?? 'Unknown error'}',
                      style: TextStyle(
                        color: _notificationSent 
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to home
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          _serviceType == ServiceType.fullService 
              ? 'Full Service Request' 
              : 'Delivery Service Request',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // ADD DEBUG TOGGLE BUTTON
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showDebugPanel = !_showDebugPanel;
              });
            },
            icon: Icon(
              Icons.bug_report,
              color: _showDebugPanel ? AppColors.warning : AppColors.textMuted,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // DEBUG PANEL
          if (_showDebugPanel) _buildDebugPanel(),
          
          // MAIN CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceTypeHeader(),
                    const SizedBox(height: 30),
                    _buildFormSection(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DEBUG PANEL WIDGET
  Widget _buildDebugPanel() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bug_report,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Debug Panel - Notification Status',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _debugMessages.clear();
                  });
                },
                icon: const Icon(
                  Icons.clear,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: _debugMessages.isEmpty
                  ? const Text(
                      'Submit form to see debug information...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _debugMessages.map((message) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: message.contains('✅') 
                                  ? AppColors.success
                                  : message.contains('❌') 
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Your existing methods remain the same...
  Widget _buildServiceTypeHeader() {
    final color = _serviceType == ServiceType.fullService 
        ? AppColors.info 
        : AppColors.accent;
    
    final icon = _serviceType == ServiceType.fullService 
        ? Icons.home_work_rounded 
        : Icons.local_shipping_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              size: 28,
              color: color,
            ),
          ),
          
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _serviceType == ServiceType.fullService 
                      ? 'Full Service' 
                      : 'Delivery Only',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please fill in the deceased information completely',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rest of your existing methods (_buildFormSection, _buildTextField, etc.) remain the same...
  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deceased Information',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please provide accurate information about the deceased',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          
          // Full Name
          _buildTextField(
            controller: _fullNameController,
            label: 'Full Name',
            icon: Icons.person_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the full name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Age
          _buildTextField(
            controller: _ageController,
            label: 'Age',
            icon: Icons.cake_rounded,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the age';
              }
              final age = int.tryParse(value);
              if (age == null || age <= 0 || age > 150) {
                return 'Please enter a valid age';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Gender Selection
          _buildGenderSelection(),
          
          const SizedBox(height: 20),
          
          // Cause of Death
          _buildTextField(
            controller: _causeOfDeathController,
            label: 'Cause of Death',
            icon: Icons.medical_information_rounded,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the cause of death';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Address
          _buildTextField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_rounded,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the address';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Delivery Location
          _buildTextField(
            controller: _deliveryLocationController,
            label: _serviceType == ServiceType.deliveryOnly 
                ? 'Delivery Location *' 
                : 'Delivery Location (Optional)',
            icon: Icons.local_shipping_rounded,
            maxLines: 2,
            validator: (value) {
              if (_serviceType == ServiceType.deliveryOnly) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the delivery location';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon, 
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: AppColors.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.info,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = Gender.lelaki;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedGender == Gender.lelaki 
                        ? AppColors.info.withOpacity(0.2)
                        : AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == Gender.lelaki 
                          ? AppColors.info
                          : AppColors.surfaceColor,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _selectedGender == Gender.lelaki 
                              ? AppColors.info.withOpacity(0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.male_rounded,
                          color: _selectedGender == Gender.lelaki 
                              ? AppColors.info
                              : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Male',
                        style: TextStyle(
                          color: _selectedGender == Gender.lelaki 
                              ? AppColors.info
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = Gender.perempuan;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedGender == Gender.perempuan 
                        ? AppColors.info.withOpacity(0.2)
                        : AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == Gender.perempuan 
                          ? AppColors.info
                          : AppColors.surfaceColor,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _selectedGender == Gender.perempuan 
                              ? AppColors.info.withOpacity(0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.female_rounded,
                          color: _selectedGender == Gender.perempuan 
                              ? AppColors.info
                              : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Female',
                        style: TextStyle(
                          color: _selectedGender == Gender.perempuan 
                              ? AppColors.info
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: AppColors.textMuted,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Submitting Request...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Submit Request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}