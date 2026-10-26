// AarogyaMP — Symptom Input Screens (M1 / M3 — Person C)
// Aligned with Stitch UI Screen 12: projects/5690353454197586822/screens/6f19a25032aa466e9e2b9eac833cff0b
// Reference §14: Transcripts must be editable. Bilingual support (Hindi/English).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/router/app_router.dart';
import '../../widgets/shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. Symptom Voice Input Screen (Stitch Screen 12)
// ─────────────────────────────────────────────────────────────────────────────
class SymptomVoiceInputScreen extends ConsumerStatefulWidget {
  const SymptomVoiceInputScreen({super.key});

  @override
  ConsumerState<SymptomVoiceInputScreen> createState() => _SymptomVoiceInputScreenState();
}

class _SymptomVoiceInputScreenState extends ConsumerState<SymptomVoiceInputScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _isListening = false;
  bool _isPaused = false;
  String _englishTransliteration = '';
  String _baseTranscript = '';
  final List<String> _extractedSymptoms = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _streamTimer;

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

    // Start with empty transcript ready for user input
    _controller.text = '';
    _baseTranscript = '';
    _updateTransliteration('');
    _syncSymptoms('');
  }

  Future<bool> _initSpeech() async {
    if (_speechInitialized) return true;

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          final isHi = ref.read(isHindiProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isHi
                  ? 'माइक्रोफ़ोन अनुमति आवश्यक है'
                  : 'Microphone permission is required for voice input'),
            ),
          );
        }
        return false;
      }

      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            _baseTranscript = _controller.text.trim();
            setState(() {
              _isListening = false;
              _pulseController.stop();
              _pulseController.reset();
            });
          }
        },
        onError: (errorNotification) {
          if (!mounted) return;
          _baseTranscript = _controller.text.trim();
          setState(() {
            _isListening = false;
            _pulseController.stop();
            _pulseController.reset();
          });
        },
      );

      _speechInitialized = available;
      return available;
    } catch (e) {
      debugPrint('Speech initialization error: $e');
      _speechInitialized = false;
      return false;
    }
  }

  void _syncSymptoms(String text) {
    _extractedSymptoms.clear();
    final lower = text.toLowerCase();
    if (text.contains('सिरदर्द') || lower.contains('headache')) {
      _extractedSymptoms.add('headache');
    }
    if (text.contains('खांसी') || lower.contains('cough')) {
      _extractedSymptoms.add('cough');
    }
    if (text.contains('बुखार') || lower.contains('fever')) {
      _extractedSymptoms.add('fever');
    }
    if (text.contains('गले में खराश') || lower.contains('sore throat')) {
      _extractedSymptoms.add('sore_throat');
    }
    if (text.contains('बदन दर्द') || lower.contains('body ache')) {
      _extractedSymptoms.add('body_ache');
    }
    if (text.contains('चक्कर') || lower.contains('dizziness')) {
      _extractedSymptoms.add('dizziness');
    }
    if (text.contains('छाती') || text.contains('सीने') || lower.contains('chest pain')) {
      _extractedSymptoms.add('chest_pain');
    }
  }

  String _symptomLabel(String key, bool isHindi) {
    switch (key) {
      case 'headache':
        return isHindi ? 'सिरदर्द' : 'Headache';
      case 'cough':
        return isHindi ? 'सूखी खांसी' : 'Dry Cough';
      case 'fever':
        return isHindi ? 'बुखार' : 'Fever';
      case 'sore_throat':
        return isHindi ? 'गले में खराश' : 'Sore Throat';
      case 'body_ache':
        return isHindi ? 'बदन दर्द' : 'Body Ache';
      case 'dizziness':
        return isHindi ? 'चक्कर' : 'Dizziness';
      case 'chest_pain':
        return isHindi ? 'सीने में दर्द' : 'Chest Pain';
      default:
        return key;
    }
  }

  void _updateTransliteration(String text) {
    if (text.trim().isEmpty) {
      setState(() => _englishTransliteration = '');
      return;
    }

    final hasHindi = RegExp(r'[\u0900-\u097F]').hasMatch(text);
    if (!hasHindi) {
      setState(() {
        _englishTransliteration = '"$text"';
      });
      return;
    }

    final recognized = <String>[];
    if (text.contains('तेज़ सिरदर्द') || text.contains('सिरदर्द')) recognized.add('severe headache');
    if (text.contains('सूखी खांसी') || text.contains('खांसी')) recognized.add('dry cough');
    if (text.contains('हल्का बुखार') || text.contains('तेज़ बुखार') || text.contains('बुखार')) recognized.add('fever');
    if (text.contains('छाती में दर्द') || text.contains('सीने में दर्द')) recognized.add('chest pain');
    if (text.contains('सांस लेने में तकलीफ') || text.contains('सांस फूलना')) recognized.add('shortness of breath');
    if (text.contains('गले में खराश')) recognized.add('sore throat');
    if (text.contains('बदन दर्द')) recognized.add('body ache');
    if (text.contains('चक्कर')) recognized.add('dizziness');
    if (text.contains('पेट दर्द')) recognized.add('abdominal pain');
    if (text.contains('उल्टी')) recognized.add('vomiting');
    if (text.contains('कल रात से')) recognized.add('since last night');

    setState(() {
      if (recognized.isNotEmpty) {
        _englishTransliteration = '"Patient reports: ${recognized.join(', ')}."';
      } else {
        _englishTransliteration = '"$text"';
      }
    });
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    if (_speech.isListening) {
      _speech.stop();
    }
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();
    _streamTimer?.cancel();

    if (_isListening) {
      await _stopListening();
      return;
    }

    final isHi = ref.read(isHindiProvider);
    final ready = await _initSpeech();

    if (!ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHi
                ? 'आवाज़ पहचान सेवा उपलब्ध नहीं है, डेमो मोड चालू किया जा रहा है'
                : 'Speech recognition unavailable on device, running demo voice input'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      _startDemoSimulation();
      return;
    }

    // Capture the existing text so new speech appends rather than overwriting
    _baseTranscript = _controller.text.trim();

    setState(() {
      _isListening = true;
      _isPaused = false;
    });
    _pulseController.repeat(reverse: true);

    final localeId = isHi ? 'hi_IN' : 'en_IN';

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            final combined = _baseTranscript.isNotEmpty
                ? '$_baseTranscript $words'
                : words;
            setState(() {
              _controller.text = combined;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: combined.length),
              );
              _updateTransliteration(combined);
              _syncSymptoms(combined);
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: localeId,
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      debugPrint('Speech listen error: $e');
      await _stopListening();
    }
  }

  Future<void> _stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _streamTimer?.cancel();
    _baseTranscript = _controller.text.trim();
    if (mounted) {
      setState(() {
        _isListening = false;
        _isPaused = false;
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _startDemoSimulation() {
    _baseTranscript = _controller.text.trim();
    setState(() {
      _isListening = true;
      _isPaused = false;
    });
    _pulseController.repeat(reverse: true);

    final isHi = ref.read(isHindiProvider);
    int step = 0;
    final phrases = isHi
        ? [
            'मुझे कल रात से...',
            'मुझे कल रात से तेज़ सिरदर्द और सूखी खांसी...',
            'मुझे कल रात से तेज़ सिरदर्द और सूखी खांसी हो रही है, साथ ही हल्का बुखार महसूस हो रहा है।',
          ]
        : [
            'I have been having...',
            'I have been having severe headache and dry cough...',
            'I have been having severe headache and dry cough since yesterday with mild fever.',
          ];

    _streamTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted || !_isListening) {
        timer.cancel();
        return;
      }
      if (step < phrases.length) {
        final p = phrases[step];
        final combined = _baseTranscript.isNotEmpty ? '$_baseTranscript $p' : p;
        setState(() {
          _controller.text = combined;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: combined.length),
          );
          _updateTransliteration(combined);
          _syncSymptoms(combined);
        });
        step++;
      } else {
        timer.cancel();
        _baseTranscript = _controller.text.trim();
        setState(() {
          _isListening = false;
        });
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  void _addQuickSymptom(String symptom) {
    HapticFeedback.lightImpact();
    final cleanSym = symptom.split('(')[0].trim();
    final current = _controller.text.trim();
    final updated = current.isEmpty ? cleanSym : '$current, $cleanSym';
    _baseTranscript = updated;
    setState(() {
      _controller.text = updated;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: updated.length),
      );
      _updateTransliteration(updated);
      _syncSymptoms(updated);
    });
  }

  void _continue() {
    if (_controller.text.trim().isEmpty) {
      final isHi = ref.read(isHindiProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isHi ? 'कृपया अपने लक्षण दर्ज करें' : 'Please describe your symptoms')),
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
    final isHindi = ref.watch(isHindiProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE7FEFC),
      appBar: StitchHeader(
        subtitle: isHindi ? 'ध्वनि लक्षण' : 'Voice Intake',
        showBack: true,
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.patientHome);
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Red Flag Emergency Alert Banner
              _buildEmergencyWarningBanner(isHindi),

              // 4-Stage Progress Stepper
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: IntakeStepper(activeStep: 1),
              ),

              // Voice Triage Hero Card
              _buildHeroContextCard(isHindi),

              // Central Voice Recording & Interactive Console
              _buildVoiceConsoleCard(isHindi),

              // Live Editable Transcript Container
              _buildEditableTranscriptCard(isHindi),

              // Mandatory Transparency Notice
              _buildTransparencyNotice(isHindi),

              // Quick Add Common Symptoms
              _buildQuickAddMosaic(isHindi),

              // Floating Action Deck
              _buildActionDeck(isHindi),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Emergency Red Flag Warning Banner ─────────────────────────────────────
  Widget _buildEmergencyWarningBanner(bool isHindi) {
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
                    Text(
                      isHindi ? 'गंभीर लक्षण सतर्कता' : 'Urgent Warning',
                      style: const TextStyle(
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isHindi
                          ? 'यदि सांस लेने में गंभीर तकलीफ, सीने में भारीपन या बेहोशी महसूस हो तो तुरंत '
                          : 'If you experience severe breathing difficulty, chest tightness, or fainting, call ',
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        color: Color(0xFF93000A),
                        height: 1.35,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse('tel:108')),
                      child: Text(
                        isHindi ? '108 आपातकालीन सेवा' : '108 Emergency Helpline',
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFBA1A1A),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      isHindi ? ' को कॉल करें।' : ' immediately.',
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        color: Color(0xFF93000A),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Context Card ─────────────────────────────────────────────────────
  Widget _buildHeroContextCard(bool isHindi) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'स्वास्थ्य सहायक' : 'VOICE TRIAGE',
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isHindi ? 'अपनी भाषा में समस्या बताएं' : 'Describe your symptoms',
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A1F1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isHindi
                      ? 'मध्य प्रदेश प्राथमिक स्वास्थ्य सेवा AI ध्वनि सहायक'
                      : 'Madhya Pradesh Primary Healthcare AI Voice Assistant',
                  style: const TextStyle(
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
  Widget _buildVoiceConsoleCard(bool isHindi) {
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
                      ? (isHindi ? 'सुन रहे हैं... (अपनी भाषा में बोलें)' : 'Listening... (Speak naturally)')
                      : (isHindi ? 'माइक पर टैप करके बोलें' : 'Tap mic to start speaking'),
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
          Text(
            isHindi ? 'बेझिझक बोलें, जैसे डॉक्टर को बताते हैं' : 'Describe how you feel, just like speaking to a doctor',
            style: const TextStyle(
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
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    if (_isListening) {
                      await _stopListening();
                      setState(() => _isPaused = true);
                    } else if (_isPaused) {
                      setState(() => _isPaused = false);
                      await _toggleListening();
                    } else {
                      await _toggleListening();
                    }
                  },
                  icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18),
                  label: Text(_isPaused ? (isHindi ? 'जारी रखें' : 'Resume') : (isHindi ? 'रोकें' : 'Pause'), style: const TextStyle(fontSize: 11)),
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
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await _stopListening();
                    setState(() {
                      _baseTranscript = '';
                      _controller.clear();
                      _englishTransliteration = '';
                      _extractedSymptoms.clear();
                      _isPaused = false;
                    });
                    await _toggleListening();
                  },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(isHindi ? 'फिर से बोलें' : 'Restart', style: const TextStyle(fontSize: 11)),
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
                  label: Text(isHindi ? 'कीबोर्ड' : 'Keyboard', style: const TextStyle(fontSize: 11)),
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
  Widget _buildEditableTranscriptCard(bool isHindi) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    isHindi ? 'आपका विवरण' : 'Live Transcript',
                    style: const TextStyle(
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
                  const Icon(Icons.cloud_done_rounded, color: AppColors.tertiary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    isHindi ? 'ड्राफ्ट सहेजा गया' : 'Draft saved',
                    style: const TextStyle(
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
          Text(
            isHindi
                ? 'सुधारने के लिए नीचे दिए गए बॉक्स पर टैप करें:'
                : 'Tap below to edit transcript directly:',
            style: const TextStyle(
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
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: isHindi ? 'बोलें अथवा यहां लिखें...' : 'Speak or type here...',
                  ),
                  onChanged: (text) {
                    _baseTranscript = text.trim();
                    _updateTransliteration(text);
                    _syncSymptoms(text);
                    setState(() {});
                  },
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
                        _symptomLabel(sym, isHindi),
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
  Widget _buildTransparencyNotice(bool isHindi) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF2F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isHindi
                  ? 'सटीक मूल्यांकन के लिए कृपया अपने शब्दों की पुष्टि करें। बिना आपकी सहमति के यह रिकॉर्ड आगे नहीं भेजा जाएगा।'
                  : 'Notice: Transcripts are never submitted without your review and confirmation.',
              style: const TextStyle(
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
  Widget _buildQuickAddMosaic(bool isHindi) {
    final quickItems = isHindi
        ? ['गले में खराश', 'बदन दर्द', 'चक्कर आना', 'पेट दर्द']
        : ['Sore Throat', 'Body Ache', 'Dizziness', 'Stomach Pain'];

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
          Text(
            isHindi ? 'त्वरित जोड़ें' : 'Quick Add Common Symptoms',
            style: const TextStyle(
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
  Widget _buildActionDeck(bool isHindi) {
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isHindi ? 'पुष्टि करें और आगे बढ़ें' : 'Confirm & Continue',
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.symptomText),
            icon: const Icon(Icons.keyboard_alt_rounded, size: 18, color: AppColors.primary),
            label: Text(
              isHindi ? 'कीबोर्ड से लिखें' : 'Switch to Keyboard Typing',
              style: const TextStyle(
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
class SymptomTextInputScreen extends ConsumerStatefulWidget {
  const SymptomTextInputScreen({super.key});

  @override
  ConsumerState<SymptomTextInputScreen> createState() => _SymptomTextInputScreenState();
}

class _SymptomTextInputScreenState extends ConsumerState<SymptomTextInputScreen> {
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
    final isHindi = ref.watch(isHindiProvider);

    final suggestions = isHindi
        ? ['तेज़ बुखार', 'सिरदर्द', 'खांसी', 'जी मिचलाना', 'सीने में दर्द']
        : ['High Fever', 'Headache', 'Cough', 'Nausea', 'Chest Pain'];

    return Scaffold(
      backgroundColor: const Color(0xFFE7FEFC),
      appBar: StitchHeader(
        subtitle: isHindi ? 'लक्षण लिखें' : 'Text Intake',
        showBack: true,
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.patientHome);
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const IntakeStepper(activeStep: 1),
              const SizedBox(height: 14),

              // Title Header
              Text(
                isHindi ? 'अपनी भाषा में लक्षण लिखें' : 'Describe your symptoms',
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A1F1E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isHindi
                    ? 'हिंदी, अंग्रेज़ी या मिश्रित भाषा में लिखें। यह भी बताएं कि लक्षण कब से हैं और कितने गंभीर हैं।'
                    : 'Describe your symptoms in English, Hindi, or mixed. Include how long you have had them and severity.',
                style: const TextStyle(
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
                      decoration: InputDecoration(
                        hintText: isHindi
                            ? 'उदा. मुझे 2 दिन से तेज़ बुखार और सिरदर्द है। शरीर में बहुत कमजोरी लग रही है...'
                            : 'e.g. Having fever for 2 days with headache and chills. Feeling very weak...',
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
                              ? (isHindi ? 'आगे बढ़ने के लिए तैयार' : 'Ready to continue')
                              : (isHindi
                                  ? 'कम से कम ${_minChars - _controller.text.trim().length} अक्षर और लिखें'
                                  : 'Write at least ${_minChars - _controller.text.trim().length} more characters'),
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _canContinue ? AppColors.primary : const Color(0xFF93000A),
                          ),
                        ),
                        Text(
                          '${_controller.text.trim().length} ${isHindi ? 'अक्षर' : 'chars'}',
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
              Text(
                isHindi ? 'त्वरित सुझाव:' : 'Quick Suggestions:',
                style: const TextStyle(
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
                children: suggestions.map((item) {
                  return Material(
                    color: const Color(0xFFD6F5ED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFF8AE0CA)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _addQuickSymptom(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00382E),
                          ),
                        ),
                      ),
                    ),
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
                child: Text(
                  isHindi ? 'पुष्टि करें और आगे बढ़ें' : 'Continue to Vitals',
                  style: const TextStyle(
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
                label: Text(
                  isHindi ? 'बोलकर बताएं' : 'Switch to Voice Intake',
                  style: const TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
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
    final hasScope = context.findAncestorWidgetOfExactType<ProviderScope>() != null ||
        context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() != null;
    if (hasScope) {
      return _ConsumerIntakeStepper(activeStep: activeStep);
    }
    return _buildContent(activeStep, false);
  }

  static Widget _buildContent(int activeStep, bool isHindi) {
    final steps = isHindi
        ? [
            {'num': '1', 'title': 'लक्षण'},
            {'num': '2', 'title': 'माप'},
            {'num': '3', 'title': 'जांच'},
            {'num': '4', 'title': 'समीक्षा'},
          ]
        : [
            {'num': '1', 'title': 'Symptoms'},
            {'num': '2', 'title': 'Vitals'},
            {'num': '3', 'title': 'Triage'},
            {'num': '4', 'title': 'Summary'},
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
                isHindi
                    ? 'चरण $activeStep / 4 • ${steps[activeStep - 1]['title']} दर्ज करें'
                    : 'Step $activeStep of 4 • Enter ${steps[activeStep - 1]['title']}',
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Step $activeStep / 4',
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

class _ConsumerIntakeStepper extends ConsumerWidget {
  final int activeStep;

  const _ConsumerIntakeStepper({required this.activeStep});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHindi = ref.watch(isHindiProvider);
    return IntakeStepper._buildContent(activeStep, isHindi);
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
