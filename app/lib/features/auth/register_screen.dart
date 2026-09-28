// AarogyaMP — Register Screen (M2 — Person C)
// Real auth: POST /api/auth/register with full payload.
// Doctor registration requires specialty (server validates this).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';

// The 13 fixed specialties from specialty_map.yaml (Reference §7 — FROZEN)
const _kSpecialties = [
  'General Physician',
  'Cardiologist',
  'Dermatologist',
  'Pediatrician',
  'ENT Specialist',
  'Orthopedic Specialist',
  'Neurologist',
  'Gastroenterologist',
  'Gynecologist',
  'Ophthalmologist',
  'Urologist',
  'Psychiatrist',
  'Mental Health Professional',
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _qualificationController = TextEditingController();
  UserRole _selectedRole = UserRole.patient;
  String? _selectedSpecialty;
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const _useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
            specialty: _selectedRole == UserRole.doctor ? _selectedSpecialty : null,
            qualification: _selectedRole == UserRole.doctor
                ? _qualificationController.text.trim()
                : null,
          );
      if (!mounted) return;
      if (_selectedRole == UserRole.doctor) {
        context.go(Routes.pendingVerification);
      } else {
        context.go(Routes.patientHome);
      }
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = _friendlyError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.riskHighBg,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('already exists')) {
      return 'This phone number is already registered. Try logging in.';
    }
    if (raw.contains('specialty')) {
      return 'Please select your medical specialty.';
    }
    if (raw.contains('SocketException') || raw.contains('connection')) {
      return 'Cannot reach server. Check your network connection.';
    }
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join AarogyaMP',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Create your account to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 28),

                // Role selector
                Text('I am a', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildRoleChip(
                        UserRole.patient, 'Patient', Icons.person_outline_rounded),
                    const SizedBox(width: 12),
                    _buildRoleChip(UserRole.doctor, 'Doctor',
                        Icons.medical_services_outlined),
                  ],
                ),

                // Doctor info banner
                if (_selectedRole == UserRole.doctor) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFBBF24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Doctor accounts require verification before accessing patient data.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF92400E),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Full name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your name';
                    if (v.trim().length < 2) return 'Name too short';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    hintText: '10-digit mobile number',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!_useMocks && v.trim().length < 10) {
                      return 'Enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Doctor-only: Specialty dropdown
                if (_selectedRole == UserRole.doctor) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSpecialty,
                    decoration: const InputDecoration(
                      labelText: 'Specialty *',
                      prefixIcon:
                          Icon(Icons.local_hospital_outlined, size: 20),
                    ),
                    items: _kSpecialties
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSpecialty = v),
                    validator: (v) {
                      if (_selectedRole == UserRole.doctor &&
                          (v == null || v.isEmpty)) {
                        return 'Please select your specialty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Doctor-only: Qualification (optional)
                  TextFormField(
                    controller: _qualificationController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Qualification (optional)',
                      prefixIcon: Icon(Icons.school_outlined, size: 20),
                      hintText: 'e.g. MBBS, MD (Cardiology)',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please create a password';
                    if (!_useMocks && v.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                        children: const [
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
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
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(UserRole role, String label, IconData icon) {
    final selected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRole = role;
          _selectedSpecialty = null; // reset on role switch
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
