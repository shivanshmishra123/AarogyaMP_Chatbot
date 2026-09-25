// AarogyaMP — Symptom Text Input Screen (M1 — Person C)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';

class SymptomTextInputScreen extends StatefulWidget {
  const SymptomTextInputScreen({super.key});

  @override
  State<SymptomTextInputScreen> createState() => _SymptomTextInputScreenState();
}

class _SymptomTextInputScreenState extends State<SymptomTextInputScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final int _minChars = 20;

  bool get _canContinue => _controller.text.trim().length >= _minChars;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_canContinue) return;
    // Pass symptom text to vitals screen via query param
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Describe Your Symptoms'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              StepIndicator(currentStep: 1, totalSteps: 3),
              const SizedBox(height: 24),

              Text(
                'What are you experiencing?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Describe your symptoms in your own words. Include when they started, how severe they are, and any other relevant details.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),

              // Text area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _focusNode.hasFocus ? AppColors.primary : AppColors.surfaceBorder,
                      width: _focusNode.hasFocus ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. "I have had fever for 2 days with headache and body ache. Temperature is around 102°F..."',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Character count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _canContinue
                        ? 'Looks good! Tap Continue.'
                        : 'Please add at least ${_minChars - _controller.text.trim().length} more characters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _canContinue ? AppColors.primary : AppColors.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '${_controller.text.trim().length} chars',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _canContinue ? _continue : null,
                child: const Text('Continue to Vitals'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Symptom Voice Input Screen (M1 — Person C)
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
  bool _hasTranscript = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // In M1 mocks: pressing the mic pre-fills a sample transcript
  // Real speech_to_text wired in M2 (or as M1 stretch goal)
  static const String _mockTranscript =
      'I have been having fever since yesterday evening, around 102 degrees. Also feeling severe headache and body pain. No cough but feeling very weak.';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      _pulseController.repeat(reverse: true);
      // Simulate STT transcript after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted || !_isListening) return;
        setState(() {
          _isListening = false;
          _hasTranscript = true;
          _controller.text = _mockTranscript;
        });
        _pulseController.stop();
        _pulseController.reset();
      });
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _continue() {
    if (_controller.text.trim().isEmpty) return;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voice Symptom Input'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepIndicator(currentStep: 1, totalSteps: 3),
              const SizedBox(height: 24),

              Text(
                _isListening ? 'Listening...' : 'Tap mic to speak',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Speak naturally. Describe your symptoms, duration, and severity.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 40),

              // Mic button
              Center(
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _isListening ? AppColors.emergencyRed : AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? AppColors.emergencyRed : AppColors.primary)
                                    .withOpacity(0.3),
                                blurRadius: _isListening ? 24 : 12,
                                spreadRadius: _isListening ? 4 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              if (_isListening) ...[
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Recording... tap to stop',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.emergencyRed,
                        ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Transcript area (always editable — Reference §14)
              if (_hasTranscript || _controller.text.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'Review & Edit Transcript',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFBBF24)),
                      ),
                      child: Text(
                        'Always review before submitting',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF92400E),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        hintText: 'Your transcript will appear here...',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _controller.text.trim().isNotEmpty ? _continue : null,
                  child: const Text('Continue to Vitals'),
                ),
              ] else ...[
                const Spacer(),
                Center(
                  child: Text(
                    'Your transcript will appear here for review',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.outlineVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step indicator widget (reused in symptom → vitals → result flow)
// ─────────────────────────────────────────────────────────────────────────────
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i + 1 <= currentStep;
        final labels = ['Symptoms', 'Vitals', 'Assessment'];
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (i < totalSteps - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: active && i + 1 < currentStep
                        ? AppColors.primary
                        : AppColors.surfaceBorder,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
