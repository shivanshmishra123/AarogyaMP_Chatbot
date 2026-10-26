// AarogyaMP — Assessment Result Screen (Stitch Prototype 5690353454197586822 Screen 8)
// Full fidelity redesign matching official public health and AYUSH layout
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/assessment_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../widgets/shared_widgets.dart';

class AssessmentResultScreen extends StatefulWidget {
  final AssessmentResult result;

  const AssessmentResultScreen({super.key, required this.result});

  @override
  State<AssessmentResultScreen> createState() => _AssessmentResultScreenState();
}

class _AssessmentResultScreenState extends State<AssessmentResultScreen> {
  bool _pdfSaved = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    // Safety: if this is somehow an emergency result, redirect to emergency screen
    if (result.isEmergency) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(Routes.emergency, extra: result);
      });
      return const LoadingOverlay(message: 'Redirecting...');
    }

    final level = result.riskLevel.toUpperCase();
    final riskColor = _riskColor(level);
    final hindiRiskTitle = _hindiRiskTitle(level);
    final timeframeAdvice = _timeframeAdvice(level);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StitchHeader(
        title: 'AarogyaMP',
        subtitle: 'Assessment Result',
        showBack: true,
        onBackTap: () => context.go(Routes.patientHome),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. ABDM Breadcrumb & Timestamp ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primary),
                      SizedBox(width: 5),
                      Text(
                        'आयुष्मान भारत (ABDM) अनुरूप',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'आज, सक्रिय',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Degraded Path Banner (when aiStatus == 'unavailable') ───────
              if (result.aiStatus == 'unavailable') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.riskModerateBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.riskModerateBorder),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 20, color: AppColors.riskModerateText),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI narrative is temporarily unavailable. Risk level is based on rule-based assessment only.',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.riskModerateText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── 2. Primary Assessment Summary Card ─────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C172B2A),
                      blurRadius: 10,
                      offset: Offset(0, 3),
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.schedule_rounded, color: riskColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'स्वास्थ्य मूल्यांकन स्थिति / Health Assessment',
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: riskColor,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$hindiRiskTitle / $level Urgency',
                                style: const TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                timeframeAdvice,
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: riskColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4-Stage Urgency Spectrum Gauge (Stitch Visual)
                    Row(
                      children: [
                        _GaugePill(
                          hindi: 'सामान्य',
                          eng: 'Low',
                          isActive: level == 'LOW',
                          color: AppColors.riskLowText,
                        ),
                        const SizedBox(width: 6),
                        _GaugePill(
                          hindi: 'मध्यम',
                          eng: 'Moderate',
                          isActive: level == 'MODERATE',
                          color: AppColors.riskModerateText,
                        ),
                        const SizedBox(width: 6),
                        _GaugePill(
                          hindi: 'उच्च',
                          eng: 'High',
                          isActive: level == 'HIGH',
                          color: AppColors.riskHighText,
                        ),
                        const SizedBox(width: 6),
                        _GaugePill(
                          hindi: 'आपातकाल',
                          eng: 'Emergency',
                          isActive: level == 'EMERGENCY',
                          color: AppColors.riskEmergencyText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Urgency Rationale Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: riskColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'जोखिम स्तर का आधार:',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  result.recommendationText ?? 'डॉक्टर से परामर्श लें और पर्याप्त विश्राम करें।',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── 3. Suggested Specialist Consultation Card ───────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surfaceBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08172B2A),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'सुझाया गया विशेषज्ञ परामर्श',
                              style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text(
                            'Primary Match',
                            style: TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${result.recommendedSpecialty ?? "General Physician"} (सामान्य चिकित्सक) या आयुष विशेषज्ञ',
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'उद्देश्य / Reason: प्राथमिक जांच, शारीरिक तापमान संतुलन और समग्र स्वास्थ्य सलाह हेतु।',
                            style: TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Public Health Assurance
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: AppColors.secondary),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'सार्वजनिक विकल्प: आप सीधे निकटतम प्राथमिक स्वास्थ्य केंद्र (PHC) अथवा किसी भी पंजीकृत MBBS सामान्य चिकित्सक से मिल सकते हैं।',
                              style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 11,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── 4. Non-Diagnosis: Possible Considerations Card ──────────────
              if (result.possibleConditions != null &&
                  result.possibleConditions!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.science_outlined, color: AppColors.outline, size: 20),
                          SizedBox(width: 8),
                          const Text(
                            'Possible Causes',
                            style: TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Prominent Non-Diagnosis Banner (Stitch Spec)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'यह चिकित्सीय निदान नहीं है / Possible Considerations - NOT a Diagnosis',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBA1A1A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'आपके द्वारा बताए गए लक्षणों के आधार पर यह संभावित स्थितियां हो सकती हैं। अंतिम पुष्टि केवल डॉक्टर की जांच के बाद ही संभव है:',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...result.possibleConditions!.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final cond = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '$idx. ${cond.name}',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  cond.likelihood.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── 5. Reassurance & AYUSH Self-Care Note ──────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.self_improvement_rounded, color: AppColors.primary, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'पर्याप्त जल और विश्राम लें',
                            style: TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'गुनगुना पानी पिएं और आंखों को तनाव से बचाएं। यह आराम की अवधि आपके शरीर की रोग प्रतिरोधक क्षमता बढ़ाती है।',
                            style: TextStyle(
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
              const SizedBox(height: 14),

              // ── 6. Mandatory Non-Diagnostic Disclaimer Banner (Reference §10) 
              const DisclaimerBanner(),
              const SizedBox(height: 20),

              // ── 7. Primary Action Stack (Stitch Buttons) ────────────────────
              // CTA 1: Find Verified Nearby Doctors
              ElevatedButton.icon(
                onPressed: () => context.push(
                  Routes.doctorList,
                  extra: result.recommendedSpecialty,
                ),
                icon: const Icon(Icons.person_search_rounded, size: 22),
                label: Text(
                  result.recommendedSpecialty != null
                      ? 'Find a ${result.recommendedSpecialty} near me'
                      : 'Find Verified Doctors',
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 10),

              // CTA 2: 2-Column Split: Save PDF & Show QR Code
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _pdfSaved = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('मूल्यांकन रिपोर्ट PDF सहेजी गई! (Report saved)'),
                            backgroundColor: AppColors.primary,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        _pdfSaved ? Icons.check_circle_rounded : Icons.download_rounded,
                        size: 18,
                        color: _pdfSaved ? AppColors.primary : AppColors.onSurface,
                      ),
                      label: Text(
                        _pdfSaved ? 'सहेजा गया!' : 'रिपोर्ट सहेजें / PDF',
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.surfaceBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showQrModal(context, result.assessmentId),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.secondary),
                      label: const Text(
                        'दिखाएं / QR Code',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.surfaceBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // CTA 3: Return to Home
              TextButton.icon(
                onPressed: () => context.go(Routes.patientHome),
                icon: const Icon(Icons.home_outlined, size: 18, color: AppColors.onSurfaceVariant),
                label: const Text(
                  'होम पर वापस जाएं / Back to Home',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrModal(BuildContext context, String assessmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.qr_code_rounded, size: 40, color: AppColors.primary),
            SizedBox(height: 8),
            Text(
              'ABDM टोकन QR कोड',
              style: TextStyle(fontFamily: 'NotoSans', fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'क्लिनिक या PHC रिसेप्शन पर यह QR स्कैन कराएं ताकि आपका मूल्यांकन सीधे डॉक्टर के डैशबोर्ड पर साझा हो सके।',
              style: TextStyle(fontFamily: 'NotoSans', fontSize: 12, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 140, color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              'टोकन: MP-ABDM-${assessmentId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 42),
            ),
            child: const Text('बंद करें / Close'),
          ),
        ],
      ),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'EMERGENCY':
        return AppColors.riskEmergencyText;
      case 'HIGH':
        return AppColors.riskHighText;
      case 'MODERATE':
        return AppColors.riskModerateText;
      default:
        return AppColors.riskLowText;
    }
  }

  String _hindiRiskTitle(String level) {
    switch (level) {
      case 'EMERGENCY':
        return 'आपातकालीन जोखिम';
      case 'HIGH':
        return 'उच्च जोखिम';
      case 'MODERATE':
        return 'मध्यम जोखिम';
      default:
        return 'सामान्य / कम जोखिम';
    }
  }

  String _timeframeAdvice(String level) {
    switch (level) {
      case 'HIGH':
        return 'सलाह: 6-12 घंटे के भीतर डॉक्टर से संपर्क करें (Consult within 6-12h)';
      case 'MODERATE':
        return 'सलाह: 24 घंटे में डॉक्टर को दिखाएं (Consult within 24h)';
      default:
        return 'सलाह: सामान्य परामर्श अथवा टेली-ओपीडी (Routine Consultation)';
    }
  }
}

class _GaugePill extends StatelessWidget {
  final String hindi;
  final String eng;
  final bool isActive;
  final Color color;

  const _GaugePill({
    required this.hindi,
    required this.eng,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? color : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              hindi,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? Colors.white : AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              eng,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white70 : AppColors.onSurfaceVariant.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
