// AarogyaMP — Vitals Entry Screen (M1 — Person C)
// Reference §6: temperature_f, heart_rate_bpm, systolic_bp, diastolic_bp, spo2_pct
// Inline validation flags obviously-invalid values before submit.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/mock_service.dart';
import '../../core/router/app_router.dart';
import '../symptom_intake/symptom_input_screens.dart' show StepIndicator;

class VitalsEntryScreen extends ConsumerStatefulWidget {
  final String rawText;
  final String inputMode;

  const VitalsEntryScreen({
    super.key,
    required this.rawText,
    required this.inputMode,
  });

  @override
  ConsumerState<VitalsEntryScreen> createState() => _VitalsEntryScreenState();
}

class _VitalsEntryScreenState extends ConsumerState<VitalsEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tempController = TextEditingController();
  final _hrController = TextEditingController();
  final _bpSysController = TextEditingController();
  final _bpDiaController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tempController.dispose();
    _hrController.dispose();
    _bpSysController.dispose();
    _bpDiaController.dispose();
    _spo2Controller.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildVitals() {
    final vitals = <String, dynamic>{};
    if (_tempController.text.isNotEmpty) {
      vitals['temperature_f'] = double.tryParse(_tempController.text);
    }
    if (_hrController.text.isNotEmpty) {
      vitals['heart_rate_bpm'] = int.tryParse(_hrController.text);
    }
    if (_bpSysController.text.isNotEmpty) {
      vitals['systolic_bp'] = int.tryParse(_bpSysController.text);
    }
    if (_bpDiaController.text.isNotEmpty) {
      vitals['diastolic_bp'] = int.tryParse(_bpDiaController.text);
    }
    if (_spo2Controller.text.isNotEmpty) {
      vitals['spo2_pct'] = int.tryParse(_spo2Controller.text);
    }
    if (_ageController.text.isNotEmpty) {
      vitals['age'] = int.tryParse(_ageController.text);
    }
    return vitals;
  }

  Future<void> _submit() async {
    // Validate only if fields have values
    if (_formKey.currentState?.validate() == false) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(mockServiceProvider).submitAssessment(
            rawText: widget.rawText,
            inputMode: widget.inputMode,
            vitals: _buildVitals().isEmpty ? null : _buildVitals(),
          );
      if (!mounted) return;
      final nav = context;
      if (result.isEmergency) {
        nav.go(Routes.emergency, extra: result);
      } else {
        nav.go(
          Routes.assessment.replaceAll(':id', result.assessmentId),
          extra: result,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vitals Entry'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepIndicator(currentStep: 2, totalSteps: 3),
                const SizedBox(height: 24),

                Text(
                  'Enter Your Vitals',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'All fields are optional. Providing vitals improves assessment accuracy.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),

                // Temperature
                _VitalField(
                  controller: _tempController,
                  label: 'Temperature',
                  unit: '°F',
                  icon: Icons.thermostat_rounded,
                  hint: '98.6',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,1}'))],
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final n = double.tryParse(v);
                    if (n == null) return 'Invalid value';
                    if (n < 90 || n > 115) return 'Must be 90–115°F (use °F)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Heart rate
                _VitalField(
                  controller: _hrController,
                  label: 'Heart Rate',
                  unit: 'bpm',
                  icon: Icons.favorite_rounded,
                  hint: '72',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final n = int.tryParse(v);
                    if (n == null) return 'Invalid value';
                    if (n < 20 || n > 300) return 'Must be 20–300 bpm';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Blood pressure
                Text('Blood Pressure', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _VitalField(
                        controller: _bpSysController,
                        label: 'Systolic',
                        unit: 'mmHg',
                        icon: Icons.monitor_heart_outlined,
                        hint: '120',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = int.tryParse(v);
                          if (n == null) return 'Invalid';
                          if (n < 50 || n > 300) return '50–300';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _VitalField(
                        controller: _bpDiaController,
                        label: 'Diastolic',
                        unit: 'mmHg',
                        icon: Icons.monitor_heart_outlined,
                        hint: '80',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = int.tryParse(v);
                          if (n == null) return 'Invalid';
                          if (n < 20 || n > 200) return '20–200';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // SpO2
                _VitalField(
                  controller: _spo2Controller,
                  label: 'Oxygen Saturation (SpO₂)',
                  unit: '%',
                  icon: Icons.air_rounded,
                  hint: '98',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final n = int.tryParse(v);
                    if (n == null) return 'Invalid value';
                    if (n < 50 || n > 100) return 'Must be 50–100%';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Age
                _VitalField(
                  controller: _ageController,
                  label: 'Age',
                  unit: 'years',
                  icon: Icons.person_outline_rounded,
                  hint: '30',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final n = int.tryParse(v);
                    if (n == null) return 'Invalid value';
                    if (n < 0 || n > 130) return 'Must be 0–130';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Analyse Symptoms'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            final result = await ref.read(mockServiceProvider).submitAssessment(
                                  rawText: widget.rawText,
                                  inputMode: widget.inputMode,
                                );
                            if (!mounted) return;
                            if (result.isEmergency) {
                              context.go(Routes.emergency, extra: result);
                            } else {
                              context.go(
                                Routes.assessment.replaceAll(':id', result.assessmentId),
                                extra: result,
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                  child: const Text('Skip Vitals & Continue'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VitalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final String? Function(String?)? validator;

  const _VitalField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    required this.hint,
    required this.keyboardType,
    required this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: TextInputAction.next,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixText: unit,
        suffixStyle: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 13,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
