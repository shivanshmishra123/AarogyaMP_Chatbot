// AarogyaMP — Symptom Input Screens (M1 / M3 — Person C)
// Aligned with Stitch UI Screen 12: projects/5690353454197586822/screens/6f19a25032aa466e9e2b9eac833cff0b
// Reference §14: Transcripts must be editable. Bilingual support (Hindi/English).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../widgets/shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. Symptom Voice Input Screen (Stitch Screen 12)
// ─────────────────────────────────────────────────────────────────────────────
class SymptomVoiceInputScreen extends StatefulWidget {
  const SymptomVoiceInputScreen({super.key});

  @override
  State<SymptomVoiceInputScreen> createState() => _SymptomVoiceInputScreenState();
}

class _SymptomVoiceInputScreenState extends State<SymptomVoiceInputScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _isListening = false;
  bool _isPaused = false;
  String _englishTransliteration = '';
  final List<String> _extractedSymptoms = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const String _sampleHindiTranscript =
      'मुझे कल रात से तेज़ सिरदर्द और सूखी खांसी हो रही है, साथ ही हल्का बुखार महसूस हो रहा है।';
  static const String _sampleTransliteration =
      '"I have had severe headache and dry cough since last night, and feeling a slight fever."';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Pre-populate with default voice draft for prototype realism
    _controller.text = _sampleHindiTranscript;
    _englishTransliteration = _sampleTransliteration;
    _extractedSymptoms.addAll([
      'सिरदर्द / Headache',
      'सूखी खांसी / Dry Cough',
      'हल्का बुखार / Mild Fever',
    ]);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleListening() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = !_isListening;
      _isPaused = false;
    });

    if (_isListening) {
      _pulseController.repeat(reverse: true);
      // Simulate real-time speech capture
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted || !_isListening) return;
        setState(() {
          _isListening = false;
          _controller.text = _sampleHindiTranscript;
          _englishTransliteration = _sampleTransliteration;
          if (!_extractedSymptoms.contains('सिरदर्द / Headache')) {
            _extractedSymptoms.addAll([
              'सिरदर्द / Headache',
              'सूखी खांसी / Dry Cough',
              'हल्का बुखार / Mild Fever',
            ]);
          }
        });
        _pulseController.stop();
        _pulseController.reset();
      });
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _addQuickSymptom(String symptom) {
    HapticFeedback.lightImpact();
    setState(() {
      if (!_extractedSymptoms.contains(symptom)) {
        _extractedSymptoms.add(symptom);
      }
      final current = _controller.text.trim();
      if (!current.contains(symptom.split('(')[0].trim())) {
        _controller.text = current.isEmpty ? symptom : '$current, $symptom';
      }
    });
  }

  void _continue() {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया अपने लक्षण दर्ज करें / Please describe symptoms')),
      );
      return;
    }
    context.push(
      Routes.vitals,
      extra: {
        'raw_text': _controller.text.trim(),
        'input_mode': 'voice',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7FEFC),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Stitch Header with 108 SOS & Language Toggle
            const StitchHeader(subtitle: 'Ai Intake'),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Red Flag Emergency Alert Banner
                    _buildEmergencyWarningBanner(),

                    // 4-Stage Progress Stepper
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: IntakeStepper(activeStep: 1),
                    ),

                    // Voice Triage Hero Card
                    _buildHeroContextCard(),

                    // Central Voice Recording & Interactive Console
                    _buildVoiceConsoleCard(),

                    // Live Editable Transcript Container
                    _buildEditableTranscriptCard(),

                    // Mandatory Transparency Notice
                    _buildTransparencyNotice(),

                    // Quick Add Common Symptoms
                    _buildQuickAddMosaic(),

                    // Floating Action Deck
                    _buildActionDeck(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Emergency Red Flag Warning Banner ─────────────────────────────────────
  Widget _buildEmergencyWarningBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF87171)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFBA1A1A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'गंभीर लक्षण सतर्कता / Urgent Warning',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF93000A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBA1A1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'RED FLAG',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 12,
                      color: Color(0xFF93000A),
                      height: 1.35,
                    ),
                    children: [
                      const TextSpan(
                        text: 'यदि सांस लेने में गंभीर तकलीफ, सीने में भारीपन या बेहोशी महसूस हो तो तुरंत ',
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => launchUrl(Uri.parse('tel:108')),
                          child: const Text(
                            '108 आपातकालीन सेवा',
                            style: TextStyle(
                              fontFamily: 'NotoSans',
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFBA1A1A),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' को कॉल करें।'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Context Card ─────────────────────────────────────────────────────
  Widget _buildHeroContextCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF2F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'स्वास्थ्य सहायक / VOICE TRIAGE',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'अपनी भाषा में समस्या बताएं',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A1F1E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'मध्य प्रदेश प्राथमिक स्वास्थ्य सेवा AI ध्वनि सहायक',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 12,
                    color: Color(0xFF3E4943),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 30),
          ),
        ],
      ),
    );
  }

  // ── Central Voice Recording & Interactive Console ─────────────────────────
  Widget _buildVoiceConsoleCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7E4)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Tactical Pulse Mic Button
          Center(
            child: GestureDetector(
              onTap: _toggleListening,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isListening ? const Color(0xFFBA1A1A) : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? const Color(0xFFBA1A1A) : AppColors.primary)
                                .withValues(alpha: 0.35),
                            blurRadius: _isListening ? 24 : 12,
                            spreadRadius: _isListening ? 4 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Audio Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCF2F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isListening ? AppColors.emergencyRed : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isListening
                      ? 'सुन रहे हैं... / Listening (Hindi/English)'
                      : 'माइक पर टैप करके बोलें / Tap Mic to Speak',
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'बेझिझक बोलें, जैसे डॉक्टर को बताते हैं',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 12,
              color: Color(0xFF6E7A73),
            ),
          ),
          const SizedBox(height: 12),

          // Real-time animated audio waveform equalizer bars
          SizedBox(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(12, (index) {
                final heights = [12.0, 24.0, 32.0, 16.0, 28.0, 36.0, 22.0, 30.0, 18.0, 26.0, 14.0, 20.0];
                final color = (index % 3 == 0)
                    ? AppColors.secondary
                    : (index % 2 == 0)
                        ? AppColors.primary
                        : AppColors.tertiary;
                return Container(
                  width: 5,
                  height: _isListening ? heights[index] : (heights[index] * 0.4).clamp(6.0, 36.0),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: _isListening ? color : color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Voice Controls Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isPaused = !_isPaused);
                  },
                  icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18),
                  label: Text(_isPaused ? 'जारी रखें' : 'रोकें / Pause', style: const TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFBDC9C1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _controller.clear();
                      _englishTransliteration = '';
                      _extractedSymptoms.clear();
                    });
                  },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('फिर से बोलें', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFBDC9C1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(Routes.symptomText),
                  icon: const Icon(Icons.keyboard_rounded, size: 18),
                  label: const Text('कीबोर्ड', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFBDC9C1)),
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

  // ── Live Editable Transcript Container ────────────────────────────────────
  Widget _buildEditableTranscriptCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7E4)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'आपका विवरण / Live Transcript',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A1F1E),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: AppColors.tertiary, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'ड्राफ्ट सहेजा गया',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'सुधारने के लिए नीचे दिए गए बॉक्स पर टैप करें (Tap below to edit directly):',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 11,
              color: Color(0xFF6E7A73),
            ),
          ),
          const SizedBox(height: 10),

          // Bilingual Editable Text Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F8F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBDC9C1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 2,
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 14,
                    color: Color(0xFF0A1F1E),
                    height: 1.4,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'बोलें अथवा यहां लिखें...',
                  ),
                  onChanged: (text) => setState(() {}),
                ),
                if (_englishTransliteration.isNotEmpty) ...[
                  const Divider(height: 16, color: Color(0xFFBDC9C1)),
                  const Text(
                    'ENGLISH TRANSLITERATION',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _englishTransliteration,
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF3E4943),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Extracted Symptom Badges
          if (_extractedSymptoms.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _extractedSymptoms.map((sym) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        sym,
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Mandatory Transparency Rule Notice ────────────────────────────────────
  Widget _buildTransparencyNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF2F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'नियम: सटीक मूल्यांकन के लिए कृपया अपने शब्दों की पुष्टि करें। बिना आपकी सहमति के यह रिकॉर्ड आगे नहीं भेजा जाएगा। Transcripts are never submitted automatically without your review.',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 11,
                color: Color(0xFF3E4943),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contextual Quick Add Symptoms Mosaic ───────────────────────────────────
  Widget _buildQuickAddMosaic() {
    const quickItems = [
      'गले में खराश (Sore Throat)',
      'बदन दर्द (Body Ache)',
      'चक्कर आना (Dizziness)',
      'पेट दर्द (Stomach Pain)',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'त्वरित जोड़ें (Quick Add Common Symptoms)',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A1F1E),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickItems.map((item) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _addQuickSymptom(item),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCF2F0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBDC9C1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          item,
                          style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A1F1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Sticky Floating Action Deck ───────────────────────────────────────────
  Widget _buildActionDeck() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _continue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'पुष्टि करें और आगे बढ़ें',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  ' / Confirm & Continue',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.symptomText),
            icon: const Icon(Icons.keyboard_alt_rounded, size: 18, color: AppColors.primary),
            label: const Text(
              'कीबोर्ड से लिखें / Switch to Keyboard Typing',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Color(0xFFBDC9C1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Symptom Text Input Screen (Keyboard Mode)
// ─────────────────────────────────────────────────────────────────────────────
class SymptomTextInputScreen extends StatefulWidget {
  const SymptomTextInputScreen({super.key});

  @override
  State<SymptomTextInputScreen> createState() => _SymptomTextInputScreenState();
}

class _SymptomTextInputScreenState extends State<SymptomTextInputScreen> {
  final _controller = TextEditingController();
  final int _minChars = 15;

  bool get _canContinue => _controller.text.trim().length >= _minChars;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addQuickSymptom(String symptom) {
    HapticFeedback.lightImpact();
    final current = _controller.text.trim();
    setState(() {
      _controller.text = current.isEmpty ? symptom : '$current, $symptom';
    });
  }

  void _continue() {
    if (!_canContinue) return;
    context.push(
      Routes.vitals,
      extra: {
        'raw_text': _controller.text.trim(),
        'input_mode': 'text',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7FEFC),
      body: SafeArea(
        child: Column(
          children: [
            const StitchHeader(subtitle: 'Ai Intake (Text)'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const IntakeStepper(activeStep: 1),
                    const SizedBox(height: 14),

                    // Title Header
                    const Text(
                      'अपनी भाषा में लक्षण लिखें',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A1F1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Describe your symptoms in Hindi, English, or mixed. Include how long you have had them and severity.',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        color: Color(0xFF3E4943),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Text Area Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBDC9C1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _controller,
                            maxLines: 6,
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 14,
                              color: Color(0xFF0A1F1E),
                              height: 1.4,
                            ),
                            decoration: const InputDecoration(
                              hintText:
                                  'उदा. मुझे 2 दिन से तेज़ बुखार और सिरदर्द है। शरीर में बहुत कमजोरी लग रही है...\n(e.g. Having fever for 2 days with headache and chills...)',
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const Divider(height: 16, color: Color(0xFFDDE7E4)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _canContinue
                                    ? 'आगे बढ़ने के लिए तैयार / Ready to continue'
                                    : 'कम से कम ${_minChars - _controller.text.trim().length} अक्षर और लिखें',
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _canContinue ? AppColors.primary : const Color(0xFF93000A),
                                ),
                              ),
                              Text(
                                '${_controller.text.trim().length} chars',
                                style: const TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 11,
                                  color: Color(0xFF6E7A73),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick suggestions
                    const Text(
                      'त्वरित सुझाव (Quick Suggestions):',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A1F1E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'तेज़ बुखार (High Fever)',
                        'सिरदर्द (Headache)',
                        'खांसी (Cough)',
                        'उल्टी / जी मिचलाना (Nausea)',
                        'सीने में दर्द (Chest Pain)',
                      ].map((item) {
                        return ActionChip(
                          label: Text(item, style: const TextStyle(fontFamily: 'NotoSans', fontSize: 11)),
                          backgroundColor: const Color(0xFFDCF2F0),
                          onPressed: () => _addQuickSymptom(item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    ElevatedButton(
                      onPressed: _canContinue ? _continue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'पुष्टि करें और आगे बढ़ें / Continue to Vitals',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.mic_rounded, size: 18),
                      label: const Text(
                        'बोलकर बताएं / Switch to Voice Intake',
                        style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. 4-Stage Intake Stepper (Stitch Screen 12 Header Tracker)
// ─────────────────────────────────────────────────────────────────────────────
class IntakeStepper extends StatelessWidget {
  final int activeStep;

  const IntakeStepper({super.key, required this.activeStep});

  @override
  Widget build(BuildContext context) {
    const steps = [
      {'num': '1', 'title': 'लक्षण', 'sub': 'Symptoms'},
      {'num': '2', 'title': 'माप', 'sub': 'Vitals'},
      {'num': '3', 'title': 'जांच', 'sub': 'Triage'},
      {'num': '4', 'title': 'समीक्षा', 'sub': 'Summary'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE7E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'चरण $activeStep / 4 • ${steps[activeStep - 1]['title']} दर्ज करें',
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Step $activeStep of 4: ${steps[activeStep - 1]['sub']}',
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 11,
                  color: Color(0xFF6E7A73),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(steps.length, (index) {
              final isCurrent = (index + 1) == activeStep;
              final isPassed = (index + 1) < activeStep;
              final color = (isCurrent || isPassed) ? AppColors.primary : const Color(0xFFD0E7E5);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == steps.length - 1 ? 0 : 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${index + 1}. ${steps[index]['title']}',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent ? AppColors.primary : const Color(0xFF6E7A73),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Backwards compatibility StepIndicator alias
// ─────────────────────────────────────────────────────────────────────────────
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({super.key, required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return IntakeStepper(activeStep: currentStep);
  }
}
