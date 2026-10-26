// AarogyaMP — Emergency SOS Active Screen (M1 / M3 — Person C)
// Aligned with Stitch UI Screen 7: projects/5690353454197586822/screens/7b8d973f19b04a4bb6fc4cff5e7c66c2
// Reference §10, §12, §18: Strict Non-Diagnostic disclaimer, 108 ambulance dispatch, 104 helpline, Hamidia Hospital trauma triage.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/assessment_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';

class EmergencyScreen extends StatefulWidget {
  final AssessmentResult? result;

  const EmergencyScreen({super.key, this.result});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _activeLang = 'hi'; // 'hi' or 'en'

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String number) async {
    HapticFeedback.heavyImpact();
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        _showCallError(number);
      }
    } catch (_) {
      if (!mounted) return;
      _showCallError(number);
    }
  }

  Future<void> _openMaps(String query) async {
    final uri = Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(query)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps application.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps application.')),
      );
    }
  }

  void _showCallError(String number) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not launch call. Please dial $number manually.'),
        backgroundColor: AppColors.emergencyRed,
      ),
    );
  }

  Future<bool> _promptExitConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _activeLang == 'hi' ? 'आपातकालीन स्क्रीन छोड़ें?' : 'Leave Emergency Screen?',
                style: const TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          _activeLang == 'hi'
              ? 'क्या आप सुनिश्चित हैं? कृपया 108 पर कॉल करें या नजदीकी आपातकालीन कक्ष जाने के बाद ही बाहर निकलें।'
              : 'Are you sure? Please call 108 or proceed to the nearest emergency facility before leaving.',
          style: const TextStyle(fontFamily: 'NotoSans', height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _activeLang == 'hi' ? 'यहीं रहें / Stay' : 'Stay Here',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _activeLang == 'hi' ? 'बाहर जाएं / Leave' : 'Leave Screen',
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final triggers = widget.result?.emergencyTriggers;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _promptExitConfirmation();
        if (shouldLeave && context.mounted) {
          context.go(Routes.patientHome);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE7FEFC),
        body: SafeArea(
          child: Column(
            children: [
              // ── 1. Sticky Stitch Header ───────────────────────────────────
              _buildStitchHeader(),

              // ── 2. Scrollable Emergency Content ───────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Utility Ribbon: Bilingual Switch & Offline Status
                      _buildUtilityRibbon(),

                      // Immediate Pulsing Critical Banner
                      _buildPulsingAlertBanner(),

                      // Top Mandated Action Directive
                      _buildActionDirectiveBanner(),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Verified Emergency Calling Cards (108 & 104)
                            _buildCallingCards(),
                            const SizedBox(height: 16),

                            // Nearest Emergency Trauma Centre Card
                            _buildNearestTraumaCard(),
                            const SizedBox(height: 16),

                            // Triggered Red Flag Indicators Section
                            _buildTriggeredSignsCard(triggers),
                            const SizedBox(height: 16),

                            // Patient Self-Care while waiting
                            _buildFirstAidWaitingCard(),
                            const SizedBox(height: 16),

                            // Regulatory & Non-Diagnostic Disclaimer
                            _buildRegulatoryFooter(),
                            const SizedBox(height: 24),

                            // Intentional Exit Button
                            _buildExitButton(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stitch Screen 7 Header ────────────────────────────────────────────────
  Widget _buildStitchHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7FEFC).withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Color(0xFFDDE7E4))),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Back Button with confirmation
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0A1F1E)),
            onPressed: () async {
              final shouldLeave = await _promptExitConfirmation();
              if (shouldLeave && mounted) {
                context.go(Routes.patientHome);
              }
            },
            tooltip: 'Go back',
          ),
          const SizedBox(width: 4),

          // Logo badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),

          // Title
          Expanded(
            child: Text(
              _activeLang == 'hi' ? 'आपातकालीन SOS सक्रिय' : 'Emergency SOS Active',
              style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A1F1E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Top right 108 SOS button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _makeCall('108'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergencyRed.withOpacity(0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '108',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Avatar Icon
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Top Utility Ribbon ────────────────────────────────────────────────────
  Widget _buildUtilityRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFE1F8F6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                _activeLang == 'hi'
                    ? 'यह मार्गदर्शन ऑफलाइन सुरक्षित है'
                    : 'Works Offline • Emergency Ready',
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3E4943),
                ),
              ),
            ],
          ),

          // Language Switcher Pill
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD0E7E5),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _activeLang = 'hi'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _activeLang == 'hi' ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'हिंदी',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _activeLang == 'hi' ? Colors.white : const Color(0xFF3E4943),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _activeLang = 'en'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _activeLang == 'en' ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'ENG',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _activeLang == 'en' ? Colors.white : const Color(0xFF3E4943),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pulsing Alert Banner ──────────────────────────────────────────────────
  Widget _buildPulsingAlertBanner() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFBA1A1A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBA1A1A).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'अत्यंत गंभीर • EMERGENCY WARNING',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _activeLang == 'hi'
                  ? 'तत्काल आपातकालीन चिकित्सा सहायता आवश्यक है'
                  : 'URGENT MEDICAL ATTENTION REQUIRED',
              style: const TextStyle(
                fontFamily: 'NotoSans',
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _activeLang == 'hi'
                  ? 'देरी न करें। सीधे अस्पताल जाएं या तुरंत 108 डायल करें।'
                  : 'Do not delay. Proceed to emergency care or call 108 now.',
              style: TextStyle(
                fontFamily: 'NotoSans',
                color: Colors.white.withOpacity(0.92),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mandated Action Directive Banner ──────────────────────────────────────
  Widget _buildActionDirectiveBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF87171)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emergency_rounded, color: Color(0xFFBA1A1A), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeLang == 'hi'
                      ? 'तुरंत नजदीकी अस्पताल जाएं या 108 पर कॉल करें'
                      : 'Seek Immediate In-Person Care or Call 108',
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFBA1A1A),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _activeLang == 'hi'
                      ? 'यह एक आपातकालीन चेतावनी है। ऑनलाइन चैट या इंतजार न करें।'
                      : 'This is an acute triage trigger. Do not wait for online consultations.',
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 12,
                    color: Color(0xFF93000A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Emergency Calling Cards ───────────────────────────────────────────────
  Widget _buildCallingCards() {
    return Column(
      children: [
        // 108 Ambulance Card (Ultra prominent)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _makeCall('108'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFBA1A1A).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'मुफ़्त 24x7 सेवा • Free 24x7 MP Service',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _activeLang == 'hi' ? '108 डायल करें / Call 108' : 'Call 108 Ambulance',
                          style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'एम्बुलेंस सहायता (MP Ambulance Dispatch)',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 104 Tele-Triage Helpline Card
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _makeCall('104'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD0E7E5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBDC9C1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF99EFE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Color(0xFF006F67), size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '104 स्वास्थ्य हेल्पलाइन / Health Helpline 104',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A1F1E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'म.प्र. शासन टेली-परामर्श • Medical Guidance',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 12,
                            color: Color(0xFF3E4943),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.call_rounded, color: AppColors.secondary, size: 22),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Nearest Emergency Trauma Facility Card ────────────────────────────────
  Widget _buildNearestTraumaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
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
                  Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'नजदीकी ट्रॉमा सेंटर • Nearest Emergency',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF99EFE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '3.2 km',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF006F67),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const Text(
            'हमीदिया अस्पताल (Hamidia Hospital Trauma Centre)',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A1F1E),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'रॉयल मार्केट, मेडिकल कॉलेज कैंपस, भोपाल (MP)',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 13,
              color: Color(0xFF3E4943),
            ),
          ),
          const SizedBox(height: 12),

          // Map indicator preview block
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFDCF2F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBDC9C1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x10000000), blurRadius: 4),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fmd_bad_rounded, color: AppColors.emergencyRed, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Emergency Wing Active • 24x7 Ready',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A1F1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Split Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makeCall('07552540590'),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 18, color: AppColors.primary),
                  label: const Text(
                    '0755-2540590',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A1F1E),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFBDC9C1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openMaps('Hamidia Hospital Bhopal Madhya Pradesh'),
                  icon: const Icon(Icons.directions_rounded, size: 18, color: Colors.white),
                  label: Text(
                    _activeLang == 'hi' ? 'रास्ता देखें' : 'Get Route',
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Triggered Red Flag Indicators Card ────────────────────────────────────
  Widget _buildTriggeredSignsCard(List<EmergencyTrigger>? triggers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF87171)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.report_problem_rounded, color: AppColors.emergencyRed, size: 20),
              const SizedBox(width: 8),
              Text(
                _activeLang == 'hi'
                    ? 'लक्षण जिन्होंने चेतावनी सक्रिय की'
                    : 'Triggered Emergency Signs',
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A1F1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Patient-entered primary indicators requiring acute evaluation:',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 12,
              color: Color(0xFF3E4943),
            ),
          ),
          const SizedBox(height: 12),

          if (triggers != null && triggers.isNotEmpty)
            ...triggers.map((t) => _buildTriggerItem(t.ruleId, t.description))
          else ...[
            _buildTriggerItem(
              'सांस लेने में कठिनाई / Shortness of Breath',
              'Severe respiratory distress reported during evaluation',
            ),
            const SizedBox(height: 8),
            _buildTriggerItem(
              'रक्तचाप में अत्यधिक वृद्धि / Critical Blood Pressure',
              'Critical vital indicator flag (severe systolic elevation)',
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'This assessment was triggered by rule-based safety criteria, not AI. Seek emergency care immediately.',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Color(0xFF7F1D1D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerItem(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF2F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDAD6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.air_rounded, color: AppColors.emergencyRed, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A1F1E),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 11,
                    color: Color(0xFF3E4943),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── First Aid While Waiting ───────────────────────────────────────────────
  Widget _buildFirstAidWaitingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F8F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBDC9C1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_rounded, color: AppColors.tertiary, size: 20),
              SizedBox(width: 8),
              Text(
                'जब तक सहायता न पहुंचे / While Waiting for Ambulance',
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A1F1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFirstAidStep('1', 'मरीज को आराम से सीधी स्थिति में बिठाएं (Keep patient sitting upright comfortably).'),
          _buildFirstAidStep('2', 'गले व छाती के कपड़े ढीले रखें (Loosen all restrictive neck and chest clothing).'),
          _buildFirstAidStep('3', 'मरीज को अकेला न छोड़ें (Do not leave patient unattended).'),
          _buildFirstAidStep('4', 'मुंह से कोई भी ठोस भोजन या बिना डॉक्टर पूछे दवा न दें (Do not administer food or arbitrary medication).'),
        ],
      ),
    );
  }

  Widget _buildFirstAidStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.tertiary),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tertiary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 12,
                color: Color(0xFF3E4943),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Regulatory Footer ─────────────────────────────────────────────────────
  Widget _buildRegulatoryFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD0E7E5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded, size: 18, color: Color(0xFF6E7A73)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This is an AI-generated possible-conditions read, not a medical diagnosis. A doctor makes the final call. मध्य प्रदेश लोक स्वास्थ्य एवं परिवार कल्याण विभाग (MP Health Dept Triage Protocol v4.2). यह प्रणाली डिजिटल निदान का स्थान नहीं लेती। आपात स्थिति में तुरंत अस्पताल पहुंचें।',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 11,
                color: Color(0xFF3E4943),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Intentional Exit Button ───────────────────────────────────────────────
  Widget _buildExitButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          final shouldLeave = await _promptExitConfirmation();
          if (shouldLeave && mounted) {
            context.go(Routes.patientHome);
          }
        },
        icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF6E7A73)),
        label: Text(
          _activeLang == 'hi'
              ? 'मैंने सहायता बुला ली है — वापस जाएं'
              : 'I have called for help — return to home',
          style: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3E4943),
          ),
        ),
      ),
    );
  }
}
