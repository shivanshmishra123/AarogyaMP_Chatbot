// AarogyaMP — Emergency Screen (M1 — Person C)
// Reference §10, §12: Full-screen, NO possible-causes list, NO dismiss-and-forget.
// Structurally different from AssessmentResultScreen — not just a red color swap.
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

  @override
  void initState() {
    super.initState();
    // Lock navigation — user must actively choose to go back
    // (no swipe-to-dismiss, no back gesture intercepted — handled by pop scope below)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _call108() async {
    HapticFeedback.heavyImpact();
    final uri = Uri.parse('tel:108');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone call. Please dial 108 manually.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final triggers = widget.result?.emergencyTriggers;

    return PopScope(
      // Require explicit action to leave emergency screen
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave Emergency Screen?'),
            content: const Text(
              'Are you sure? Please call 108 or go to the nearest emergency room before leaving this screen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.emergencyRed),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          context.go(Routes.patientHome);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.emergencyRedBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // Pulsing emergency icon
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergencyRed.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emergency_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'EMERGENCY',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppColors.emergencyRed,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Seek immediate emergency medical care.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.emergencyRedDark,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Do not wait. Do not chat. Go to the nearest emergency room or call 108 NOW.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF7F1D1D),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 108 SOS button
                GestureDetector(
                  onTap: _call108,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergencyRed.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.call_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Call 108 — Ambulance',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // What triggered this (if rule info available)
                if (triggers != null && triggers.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.riskEmergencyBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: AppColors.emergencyRed),
                            const SizedBox(width: 8),
                            Text(
                              'Why this alert was triggered',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.emergencyRed,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...triggers.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(color: AppColors.emergencyRed, fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    t.description,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFF7F1D1D),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This assessment was made by a rule-based safety system, not AI. Seek emergency care immediately.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Steps to follow
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Steps to take right now:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      _EmergencyStep(number: '1', text: 'Call 108 or ask someone nearby to help'),
                      _EmergencyStep(number: '2', text: 'Stay calm and stay seated or lie down'),
                      _EmergencyStep(number: '3', text: 'Do not eat, drink, or take medication without guidance'),
                      _EmergencyStep(number: '4', text: 'Go to the nearest emergency room if 108 is delayed'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Leave screen (intentional, behind a confirmation)
                TextButton(
                  onPressed: () async {
                    final shouldLeave = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Leave Emergency Screen?'),
                        content: const Text(
                          'Please confirm you have called 108 or are on your way to an emergency room.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Stay'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: TextButton.styleFrom(foregroundColor: AppColors.onSurfaceVariant),
                            child: const Text('I understand, leave'),
                          ),
                        ],
                      ),
                    );
                    if (shouldLeave == true && context.mounted) {
                      context.go(Routes.patientHome);
                    }
                  },
                  child: Text(
                    'I have called for help — go back',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyStep extends StatelessWidget {
  final String number;
  final String text;

  const _EmergencyStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.riskEmergencyBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.riskEmergencyBorder),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emergencyRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
