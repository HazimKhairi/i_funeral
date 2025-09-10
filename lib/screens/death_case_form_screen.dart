import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../models/death_case_model.dart';
import '../services/death_case_service.dart';

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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
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

      await _deathCaseService.createDeathCase(deathCase);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit application: ${e.toString()}'),
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF50C878),
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
                'Successfully Submitted',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
            'Your application has been successfully submitted. Our staff will contact you shortly.',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to home
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF4A90E2),
                fontWeight: FontWeight.bold,
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
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D44),
        foregroundColor: Colors.white,
        title: Text(
          _serviceType?.displayName ?? 'Application Form',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceTypeHeader(),
              const SizedBox(height: 30),
              _buildFormFields(),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTypeHeader() {
    final color = _serviceType == ServiceType.fullService 
        ? const Color(0xFF4A90E2) 
        : const Color(0xFF50C878);
    
    final icon = _serviceType == ServiceType.fullService 
        ? Icons.home_work_rounded 
        : Icons.local_shipping_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _serviceType?.displayName ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                    'Please fill in the deceased information completely',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
            'Deceased Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        
        // Nama Penuh
        _buildTextField(
          controller: _fullNameController,
            label: 'Full Name',
            icon: Icons.person_rounded,
            validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter full name';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Umur
        _buildTextField(
          controller: _ageController,
            label: 'Age',
            icon: Icons.cake_rounded,
            keyboardType: TextInputType.number,
            validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter age';
            }
            final age = int.tryParse(value);
            if (age == null || age <= 0 || age > 150) {
              return 'Please enter a valid age';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Jantina
        _buildGenderSelection(),
        
        const SizedBox(height: 16),
        
        // Sebab Kematian
        _buildTextField(
          controller: _causeOfDeathController,
            label: 'Cause of Death',
            icon: Icons.medical_information_rounded,
            maxLines: 2,
            validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cause of death';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Alamat
        _buildTextField(
          controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_rounded,
            maxLines: 3,
            validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter address';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Lokasi Penghantaran (Optional for Full Service, Required for Delivery Only)
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
              return 'Please enter delivery location';
              }
            }
            return null;
          },
        ),
      ],
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        prefixIcon: Icon(icon, color: const Color(0xFFB0B0B0)),
        filled: true,
        fillColor: const Color(0xFF2D2D44),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4A90E2),
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

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFFB0B0B0),
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
                        ? const Color(0xFF4A90E2).withOpacity(0.2)
                        : const Color(0xFF2D2D44),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == Gender.lelaki 
                          ? const Color(0xFF4A90E2)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.male_rounded,
                        color: _selectedGender == Gender.lelaki 
                            ? const Color(0xFF4A90E2)
                            : const Color(0xFFB0B0B0),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Men',
                        style: TextStyle(
                          color: _selectedGender == Gender.lelaki 
                              ? const Color(0xFF4A90E2)
                              : const Color(0xFFB0B0B0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                        ? const Color(0xFF4A90E2).withOpacity(0.2)
                        : const Color(0xFF2D2D44),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == Gender.perempuan 
                          ? const Color(0xFF4A90E2)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.female_rounded,
                        color: _selectedGender == Gender.perempuan 
                            ? const Color(0xFF4A90E2)
                            : const Color(0xFFB0B0B0),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Women',
                        style: TextStyle(
                          color: _selectedGender == Gender.perempuan 
                              ? const Color(0xFF4A90E2)
                              : const Color(0xFFB0B0B0),
                          fontWeight: FontWeight.w600,
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
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A90E2),
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
            : const Text(
                'Submit Application',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}