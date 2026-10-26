// AarogyaMP — Patient Home Screen (Stitch Prototype 5690353454197586822 Screen 3)
// Full fidelity redesign matching official public health and AYUSH layout
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/router/app_router.dart';
import '../../widgets/shared_widgets.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }


  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(isHindiProvider);
    final auth = ref.watch(authProvider);
    final patientName = (auth.name != null && auth.name!.isNotEmpty)
        ? auth.name!
        : (isHindi ? 'रामेश्वर जी' : 'Rameshwar Ji');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StitchHeader(
        title: 'AarogyaMP',
        subtitle: isHindi ? 'मुख्य पृष्ठ' : 'Home',
        onProfileTap: () => _showProfileSheet(context, ref, auth),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Emergency Warning Bar (Stitch Reference) ─────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF87171), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.emergencyRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emergency_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'आपातकाल?' : 'Emergency?',
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF93000A),
                            ),
                          ),
                          Text(
                            isHindi ? 'तुरंत 108 डायल करें • एम्बुलेंस सहायता' : 'Dial 108 immediately for ambulance',
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF93000A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse('tel:108');
                        // ignore: deprecated_member_use
                        await launchUrl(uri);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '108',
                              style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. Patient Greeting & ABDM Health ID Header ────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08172B2A),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isHindi ? 'सक्रिय स्वास्थ्य मित्र' : 'Active Health ID',
                                style: const TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isHindi ? 'नमस्ते, $patientName' : 'Hello, $patientName',
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                isHindi ? 'भोपाल, मध्य प्रदेश' : 'Bhopal, MP',
                                style: const TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            patientName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: -2,
                          right: -2,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.verified_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 3. Hero Card: Symptom Intake Main Interaction ───────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C172B2A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Public Health Support Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.spa_rounded, color: AppColors.primary, size: 15),
                          const SizedBox(width: 5),
                          Text(
                            isHindi ? 'सार्वजनिक स्वास्थ्य सहायता' : 'Public Health Support',
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isHindi ? 'आप कैसा महसूस कर रहे हैं?' : 'How are you feeling today?',
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHindi
                          ? 'लक्षण बताएं और तुरंत शासकीय प्राथमिक परामर्श पाएं'
                          : 'Share your symptoms to get quick clinical triage',
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Accessible Glowing Voice Button (Stitch Spec: 112px round)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.28),
                                  blurRadius: 24,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => context.push(Routes.symptomVoice),
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(28),
                                elevation: 8,
                                shadowColor: const Color(0x40000000),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.mic_rounded, size: 44, color: Colors.white),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _WaveBar(height: 8),
                                      SizedBox(width: 2),
                                      _WaveBar(height: 14),
                                      SizedBox(width: 2),
                                      _WaveBar(height: 8),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isHindi ? 'लक्षण बोलकर बताएं' : 'Speak Symptoms',
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHindi ? 'सभी के लिए सरल और सहज ध्वनि इनपुट' : 'Quick and natural voice-to-AI intake',
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Secondary Text Intake Button
                    OutlinedButton.icon(
                      onPressed: () => context.push(Routes.symptomText),
                      icon: const Icon(Icons.keyboard_outlined, size: 20, color: AppColors.primary),
                      label: Text(
                        isHindi ? 'टाइप करके लिखें' : 'Type Symptoms',
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: AppColors.surfaceContainerLow,
                        side: const BorderSide(color: AppColors.surfaceBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 4. Quick Entry Card for Vitals (Stitch Reference) ───────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surfaceBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06172B2A),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.monitor_heart_rounded,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHindi ? 'स्वास्थ्य माप' : 'Enter Vitals',
                                style: const TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isHindi
                                    ? 'बीपी, शुगर, ऑक्सीजन, तापमान'
                                    : 'BP, Sugar, SpO2, Temperature',
                                style: const TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            isHindi ? 'वैकल्पिक' : 'Optional',
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 4-Column Vitals Metric Preview Grid
                    Row(
                      children: [
                        _VitalPill(
                          label: isHindi ? 'रक्तचाप' : 'BP',
                          value: '120/80',
                          unit: 'mmHg',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _VitalPill(
                          label: isHindi ? 'शुगर' : 'Sugar',
                          value: '104',
                          unit: 'mg/dL',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _VitalPill(
                          label: isHindi ? 'ऑक्सीजन' : 'SpO2',
                          value: '98%',
                          unit: isHindi ? 'सामान्य' : 'Normal',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _VitalPill(
                          label: isHindi ? 'तापमान' : 'Temp',
                          value: '98.4°',
                          unit: '°F',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isHindi
                                ? '💡 अभी भरें अथवा बाद में अपडेट करें'
                                : '💡 Enter now or update anytime',
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.push(Routes.vitals),
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: Text(
                            isHindi ? 'दर्ज करें' : 'Update',
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 5. Quick Health Action Links ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go(Routes.doctorList),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isHindi ? 'डॉक्टर खोजें' : 'Find Doctors',
                                      style: const TextStyle(
                                        fontFamily: 'NotoSans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      isHindi ? 'सत्यापित शासकीय डॉक्टर' : 'Verified MP Govt Doctors',
                                      style: const TextStyle(
                                        fontFamily: 'NotoSans',
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go(Routes.history),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined, color: AppColors.secondary, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isHindi ? 'परामर्श इतिहास' : 'Medical Records',
                                      style: const TextStyle(
                                        fontFamily: 'NotoSans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      isHindi ? 'पिछले परामर्श एवं रिपोर्ट' : 'Past consults & triage',
                                      style: const TextStyle(
                                        fontFamily: 'NotoSans',
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
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

              // ── 6. Safety & Non-Diagnostic Disclaimer Note ────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AarogyaMP provides AI-generated possible-conditions triage reads, not confirmed diagnoses. Registered doctors make the final medical call.',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) {}
          if (i == 1) context.go(Routes.symptomVoice);
          if (i == 2) context.go(Routes.doctorList);
          if (i == 3) context.go(Routes.history);
        },
      ),
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref, AuthState auth) {
    showPatientProfileSheet(context, ref);
  }
}

class _WaveBar extends StatelessWidget {
  final double height;
  const _WaveBar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _VitalPill extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _VitalPill({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              unit,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
