// AarogyaMP — Assessment Result Screen (M1 — Person C)
// Shows the AI assessment card per Reference §10.
// DisclaimerBanner is MANDATORY on every non-emergency assessment.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/assessment_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../widgets/shared_widgets.dart';

class AssessmentResultScreen extends StatelessWidget {
  final AssessmentResult result;

  const AssessmentResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // Safety: if this is somehow an emergency result, redirect to emergency screen
    if (result.isEmergency) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(Routes.emergency, extra: result);
      });
      return const LoadingOverlay(message: 'Redirecting...');
    }

    final riskColor = _riskColor(result.riskLevel);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assessment Result'),
        leading: BackButton(onPressed: () => context.go(Routes.patientHome)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Risk band card ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    top: BorderSide(color: riskColor, width: 4),
                    left: const BorderSide(color: AppColors.surfaceBorder),
                    right: const BorderSide(color: AppColors.surfaceBorder),
                    bottom: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0D172B2A), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RiskBadge(riskLevel: result.riskLevel, large: true),
                    const SizedBox(height: 8),
                    Text(
                      'Based on your symptoms & vitals',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Possible conditions ────────────────────────────
              if (result.possibleConditions != null &&
                  result.possibleConditions!.isNotEmpty) ...[
                SectionCard(
                  accentColor: riskColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Possible Causes',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      ...result.possibleConditions!.map(
                        (c) => _ConditionRow(condition: c),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Recommendation ─────────────────────────────────
              if (result.recommendationText != null) ...[
                SectionCard(
                  accentColor: AppColors.secondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.recommend_rounded, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'Recommendation',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result.recommendationText!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Disclaimer (MANDATORY — Reference §10) ─────────
              const DisclaimerBanner(),
              const SizedBox(height: 20),

              // ── Find a doctor CTA ──────────────────────────────
              if (result.recommendedSpecialty != null) ...[
                ElevatedButton.icon(
                  onPressed: () => context.push(
                    Routes.doctorList,
                    extra: result.recommendedSpecialty,
                  ),
                  icon: const Icon(Icons.search_rounded),
                  label: Text('Find a ${result.recommendedSpecialty} near me'),
                ),
                const SizedBox(height: 12),
              ],

              OutlinedButton.icon(
                onPressed: () => context.go(Routes.patientHome),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to Home'),
              ),

              // AI status note (if unavailable)
              if (result.aiStatus == 'unavailable') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI narrative is temporarily unavailable. Risk level is based on rule-based assessment only.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Color _riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':
        return AppColors.riskHighBorder;
      case 'MODERATE':
        return AppColors.riskModerateBorder;
      default:
        return AppColors.riskLowBorder;
    }
  }
}

class _ConditionRow extends StatelessWidget {
  final PossibleCondition condition;
  const _ConditionRow({required this.condition});

  @override
  Widget build(BuildContext context) {
    final likelihood = condition.likelihood.toLowerCase();
    final color = likelihood == 'high'
        ? AppColors.riskHighText
        : likelihood == 'medium'
            ? AppColors.riskModerateText
            : AppColors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.onSurface, fontSize: 16)),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    condition.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    condition.likelihood,
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
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
}
