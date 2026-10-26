// AarogyaMP — Vitals Entry Screen (M1 / M3 — Person C)
// Aligned with Stitch UI Screen 8: projects/5690353454197586822/screens/989cc0db409a4dc887f11c04064d20a2
// Reference §6: temperature_f, heart_rate_bpm, systolic_bp, diastolic_bp, spo2_pct

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/assessment_service.dart';
import '../../core/router/app_router.dart';
import '../../widgets/shared_widgets.dart';
import 'symptom_input_screens.dart' show IntakeStepper;

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
  final _tempController = TextEditingController(text: '98.6');
  final _bpSysController = TextEditingController(text: '120');
  final _bpDiaController = TextEditingController(text: '80');
  final _hrController = TextEditingController(text: '76');
  final _spo2Controller = TextEditingController(text: '98');
  final _respController = TextEditingController();

  String _tempUnit = 'F'; // 'F' or 'C'
  bool _isLoading = false;

  @override
  void dispose() {
    _tempController.dispose();
    _bpSysController.dispose();
    _bpDiaController.dispose();
    _hrController.dispose();
    _spo2Controller.dispose();
    _respController.dispose();
    super.dispose();
  }

  void _adjustTemp(double delta) {
    HapticFeedback.selectionClick();
    double current = double.tryParse(_tempController.text) ?? (_tempUnit == 'F' ? 98.6 : 37.0);
    current = (current + delta);
    setState(() {
      _tempController.text = current.toStringAsFixed(1);
    });
  }

  void _toggleTempUnit(String unit) {
    if (_tempUnit == unit) return;
    HapticFeedback.selectionClick();
    double? val = double.tryParse(_tempController.text);
    setState(() {
      _tempUnit = unit;
      if (val != null) {
        if (unit == 'C') {
          // F to C
          _tempController.text = (((val - 32) * 5) / 9).toStringAsFixed(1);
        } else {
          // C to F
          _tempController.text = (((val * 9) / 5) + 32).toStringAsFixed(1);
        }
      }
    });
  }

  void _adjustPulse(int delta) {
    HapticFeedback.selectionClick();
    int current = int.tryParse(_hrController.text) ?? 76;
    current = (current + delta).clamp(30, 220);
    setState(() {
      _hrController.text = current.toString();
    });
  }

  void _adjustSpo2(int delta) {
    HapticFeedback.selectionClick();
    int current = int.tryParse(_spo2Controller.text) ?? 98;
    current = (current + delta).clamp(60, 100);
    setState(() {
      _spo2Controller.text = current.toString();
    });
  }

  Map<String, dynamic> _buildVitals() {
    final vitals = <String, dynamic>{};
    if (_tempController.text.isNotEmpty) {
      double? temp = double.tryParse(_tempController.text);
      if (temp != null) {
        // Convert to F for backend schema if recorded in C
        if (_tempUnit == 'C') {
          temp = ((temp * 9) / 5) + 32;
        }
        vitals['temperature_f'] = temp;
      }
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
    return vitals;
  }

  Future<void> _submitWithVitals() async {
    if (_formKey.currentState?.validate() == false) return;
    await _executeAssessment(_buildVitals());
  }

  Future<void> _skipVitals() async {
    await _executeAssessment(null);
  }

  Future<void> _executeAssessment(Map<String, dynamic>? vitals) async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(assessmentServiceProvider).submitAssessment(
            rawText: widget.rawText,
            inputMode: widget.inputMode,
            vitals: (vitals != null && vitals.isNotEmpty) ? vitals : null,
          );
      if (!mounted) return;
      if (result.isEmergency) {
        context.push(Routes.emergency, extra: result);
      } else {
        context.push(
          Routes.assessment.replaceAll(':id', result.assessmentId),
          extra: result,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('मूल्यांकन त्रुटि / Error: ${e.toString()}'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7FEFC),
      body: SafeArea(
        child: Column(
          children: [
            const StitchHeader(subtitle: 'Ai Intake'),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 4-Stage Progress Stepper
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: IntakeStepper(activeStep: 2),
                      ),

                      // Friendly Institutional Header Banner
                      _buildInstitutionalBanner(),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Body Temperature Card
                            _buildTemperatureCard(),
                            const SizedBox(height: 14),

                            // 2. Blood Pressure Card
                            _buildBloodPressureCard(),
                            const SizedBox(height: 14),

                            // 3. Pulse / Heart Rate Card
                            _buildPulseCard(),
                            const SizedBox(height: 14),

                            // 4. Oxygen Saturation (SpO2) Card
                            _buildSpo2Card(),
                            const SizedBox(height: 14),

                            // 5. Respiratory Rate Card
                            _buildRespiratoryCard(),
                            const SizedBox(height: 14),

                            // Quick Context Card
                            _buildClinicalAssuranceCard(),
                            const SizedBox(height: 18),

                            // Bottom Actions Stack
                            _buildActionButtons(),
                            const SizedBox(height: 32),
                          ],
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
    );
  }

  // ── Friendly Institutional Header Banner ──────────────────────────────────
  Widget _buildInstitutionalBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFDCF2F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'स्वास्थ्य माप / Vitals',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A1F1E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'सभी माप वैकल्पिक हैं। आप इन्हें छोड़ सकते हैं और डॉक्टर को दिखा सकते हैं।',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 12,
                    color: Color(0xFF3E4943),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'All vitals are optional. You can enter now, later, or skip entirely.',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 11,
                    color: Color(0xFF6E7A73),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Body Temperature Card ──────────────────────────────────────────────
  Widget _buildTemperatureCard() {
    double? val = double.tryParse(_tempController.text);
    bool isElevated = false;
    if (val != null) {
      if (_tempUnit == 'F' && val > 99.5) isElevated = true;
      if (_tempUnit == 'C' && val > 37.5) isElevated = true;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.device_thermostat_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'शरीर का तापमान',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A1F1E),
                        ),
                      ),
                      Text(
                        'Body Temperature',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          color: Color(0xFF6E7A73),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Unit Toggle Pill
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF2F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _buildUnitOption('°F', _tempUnit == 'F', () => _toggleTempUnit('F')),
                    _buildUnitOption('°C', _tempUnit == 'C', () => _toggleTempUnit('C')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stepper Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _adjustTemp(-0.2),
                icon: const Icon(Icons.remove_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDCF2F0),
                  foregroundColor: const Color(0xFF0A1F1E),
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _tempController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0A1F1E),
                          ),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      Text(
                        '°$_tempUnit',
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6E7A73),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isElevated ? const Color(0xFFFFDAD6) : const Color(0xFFDCF2F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isElevated
                          ? 'हल्का बढ़ा हुआ / Slightly elevated'
                          : 'सामान्य / Normal (${_tempUnit == 'F' ? '97.0 - 99.0 °F' : '36.1 - 37.2 °C'})',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isElevated ? const Color(0xFF93000A) : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _adjustTemp(0.2),
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDCF2F0),
                  foregroundColor: const Color(0xFF0A1F1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _tempController.clear()),
              child: const Text(
                'मुझे नहीं पता / I don\'t know',
                style: TextStyle(fontFamily: 'NotoSans', fontSize: 11, color: AppColors.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Blood Pressure Card ────────────────────────────────────────────────
  Widget _buildBloodPressureCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_heart_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'रक्तचाप (Blood Pressure)',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A1F1E),
                        ),
                      ),
                      Text(
                        'BP in mmHg',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          color: Color(0xFF6E7A73),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF2F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'mmHg',
                  style: TextStyle(fontFamily: 'NotoSans', fontSize: 11, color: Color(0xFF3E4943)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F8F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ऊपरी (Systolic)',
                        style: TextStyle(fontFamily: 'NotoSans', fontSize: 11, color: Color(0xFF3E4943)),
                      ),
                      TextField(
                        controller: _bpSysController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A1F1E),
                        ),
                        decoration: const InputDecoration(
                          hintText: '120',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F8F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'निचला (Diastolic)',
                        style: TextStyle(fontFamily: 'NotoSans', fontSize: 11, color: Color(0xFF3E4943)),
                      ),
                      TextField(
                        controller: _bpDiaController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A1F1E),
                        ),
                        decoration: const InputDecoration(
                          hintText: '80',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF2F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'सामान्य / Ideal: 120/80',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _bpSysController.clear();
                  _bpDiaController.clear();
                }),
                child: const Text(
                  'मुझे नहीं पता / I don\'t know',
                  style: TextStyle(fontFamily: 'NotoSans', fontSize: 11, color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Pulse / Heart Rate Card ────────────────────────────────────────────
  Widget _buildPulseCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'नाड़ी की गति',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A1F1E),
                        ),
                      ),
                      Text(
                        'Pulse / Heart Rate',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          color: Color(0xFF6E7A73),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF2F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'bpm',
                  style: TextStyle(fontFamily: 'NotoSans', fontSize: 11, color: Color(0xFF3E4943)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _adjustPulse(-1),
                icon: const Icon(Icons.remove_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDCF2F0),
                  foregroundColor: const Color(0xFF0A1F1E),
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _hrController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A1F1E),
                      ),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCF2F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'सामान्य / Normal (60 - 100 bpm)',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _adjustPulse(1),
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDCF2F0),
                  foregroundColor: const Color(0xFF0A1F1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _hrController.clear()),
              child: const Text(
                'मुझे नहीं पता / I don\'t know',
                style: TextStyle(fontFamily: 'NotoSans', fontSize: 11, color: AppColors.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Oxygen Saturation (SpO2) Card ──────────────────────────────────────
  Widget _buildSpo2Card() {
    int? val = int.tryParse(_spo2Controller.text);
    bool isLow = val != null && val < 95;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.air_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ऑक्सीजन स्तर',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A1F1E),
                        ),
                      ),
                      Text(
                        'SpO2 / Oxygen Saturation',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          color: Color(0xFF6E7A73),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF2F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '%',
                  style: TextStyle(fontFamily: 'NotoSans', fontSize: 11, color: Color(0xFF3E4943)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _adjustSpo2(-1),
                icon: const Icon(Icons.remove_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDCF2F0),
                  foregroundColor: const Color(0xFF0A1F1E),
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _spo2Controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0A1F1E),
                          ),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const Text(
                        '%',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6E7A73),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLow ? const Color(0xFFFFDAD6) : const Color(0xFFDCF2F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isLow ? 'सतर्कता / Low (<95%)' : 'सुरक्षित / Safe (95% - 100%)',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isLow ? const Color(0xFF93000A) : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _adjustSpo2(1),
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDCF2F0),
                  foregroundColor: const Color(0xFF0A1F1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _spo2Controller.clear()),
              child: const Text(
                'मुझे नहीं पता / I don\'t know',
                style: TextStyle(fontFamily: 'NotoSans', fontSize: 11, color: AppColors.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Respiratory Rate Card ──────────────────────────────────────────────
  Widget _buildRespiratoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.air_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'श्वसन दर',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A1F1E),
                        ),
                      ),
                      Text(
                        'Respiratory Rate (Optional)',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          color: Color(0xFF6E7A73),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF2F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'breaths/min',
                  style: TextStyle(fontFamily: 'NotoSans', fontSize: 11, color: Color(0xFF3E4943)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Center(
            child: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F8F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _respController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A1F1E),
                ),
                decoration: const InputDecoration(
                  hintText: '--',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'सामान्य वयस्क / Typical adult: 12-20',
              style: TextStyle(fontFamily: 'NotoSans', fontSize: 11, color: Color(0xFF6E7A73)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Clinical Assurance Card ─────────────────────────────────────────
  Widget _buildClinicalAssuranceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF2F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.healing_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'सटीक सलाह के लिए / For accurate advice',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A1F1E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'यदि कोई उपकरण पास नहीं है, तो सीधे छोड़ सकते हैं। हमारा AI डॉक्टर लक्षणों के आधार पर भी परामर्श देगा।',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 11,
                    color: Color(0xFF3E4943),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action Deck ────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _submitWithVitals,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.verified_rounded, size: 20),
          label: const Text(
            'माप सहेजें और मूल्यांकन देखें / Save & Urgency Check',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 4,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _skipVitals,
          icon: const Icon(Icons.skip_next_rounded, size: 20, color: AppColors.secondary),
          label: const Text(
            'अभी छोड़ें / Skip Vitals & Assess Urgency',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: Color(0xFFBDC9C1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x10000000), blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? AppColors.primary : const Color(0xFF6E7A73),
          ),
        ),
      ),
    );
  }
}
