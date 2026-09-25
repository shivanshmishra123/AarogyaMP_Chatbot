// AarogyaMP — Doctor Dashboard Screens (M1 — Person C)
// Doctor Queue + Patient Detail (doctor role only)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../widgets/shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock patient queue data (for M1 mocks)
// ─────────────────────────────────────────────────────────────────────────────
class _MockPatient {
  final String id;
  final String name;
  final String riskLevel;
  final String symptoms;
  final String vitals;
  final String timeAgo;
  final String recommendation;
  final List<String> possibleConditions;

  const _MockPatient({
    required this.id,
    required this.name,
    required this.riskLevel,
    required this.symptoms,
    required this.vitals,
    required this.timeAgo,
    required this.recommendation,
    required this.possibleConditions,
  });
}

const _mockPatients = [
  _MockPatient(
    id: 'p_001',
    name: 'Rahul Sharma',
    riskLevel: 'MODERATE',
    symptoms: 'Fever since 2 days, headache and body ache. Temperature around 102°F.',
    vitals: 'Temp: 102°F · HR: 98 bpm · BP: 145/92 mmHg · SpO₂: 96%',
    timeAgo: '5 min ago',
    recommendation: 'Consult a physician within 24 hours.',
    possibleConditions: ['Viral/febrile illness (high)', 'Influenza-like illness (medium)'],
  ),
  _MockPatient(
    id: 'p_002',
    name: 'Priya Joshi',
    riskLevel: 'HIGH',
    symptoms: 'Chest tightness and shortness of breath since this morning. Mild dizziness.',
    vitals: 'Temp: 98.6°F · HR: 110 bpm · BP: 160/100 mmHg · SpO₂: 94%',
    timeAgo: '12 min ago',
    recommendation: 'Urgent evaluation required — seek care today.',
    possibleConditions: ['Hypertensive urgency (medium)', 'Acute coronary syndrome (low)'],
  ),
  _MockPatient(
    id: 'p_003',
    name: 'Ankit Patel',
    riskLevel: 'LOW',
    symptoms: 'Mild cold and runny nose for 1 day. No fever.',
    vitals: 'Temp: 98.4°F · HR: 72 bpm',
    timeAgo: '28 min ago',
    recommendation: 'Rest, stay hydrated, monitor.',
    possibleConditions: ['Common cold (high)', 'Mild allergic rhinitis (medium)'],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Doctor Queue Screen
// ─────────────────────────────────────────────────────────────────────────────
class PatientQueueScreen extends StatelessWidget {
  const PatientQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () => context.go(Routes.login),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header summary
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Row(
                children: [
                  _SummaryChip(
                    label: '${_mockPatients.length} patients',
                    color: AppColors.primary,
                    icon: Icons.people_outline_rounded,
                  ),
                  const SizedBox(width: 10),
                  _SummaryChip(
                    label: '1 urgent',
                    color: AppColors.riskHighText,
                    icon: Icons.priority_high_rounded,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _mockPatients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = _mockPatients[i];
                  return _PatientQueueCard(
                    patient: p,
                    onTap: () => context.push(
                      Routes.patientDetail.replaceAll(':id', p.id),
                      extra: p,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientQueueCard extends StatelessWidget {
  final _MockPatient patient;
  final VoidCallback onTap;

  const _PatientQueueCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x0D172B2A), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(patient.name, style: Theme.of(context).textTheme.titleSmall),
                ),
                RiskBadge(riskLevel: patient.riskLevel),
                const SizedBox(width: 8),
                Text(
                  patient.timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              patient.symptoms,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      Routes.chat.replaceAll(':consultationId', 'mock-consult-${patient.id}'),
                      extra: {'doctorName': 'Dr. Sunita Verma', 'doctorId': 'doc_sunita'},
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('Reply'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient Detail Screen (doctor role)
// ─────────────────────────────────────────────────────────────────────────────
class PatientDetailScreen extends StatelessWidget {
  final String patientId;
  final _MockPatient? patient;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final p = patient ??
        _mockPatients.firstWhere(
          (x) => x.id == patientId,
          orElse: () => _mockPatients.first,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(p.name),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Risk band
              Row(
                children: [
                  RiskBadge(riskLevel: p.riskLevel, large: true),
                  const SizedBox(width: 12),
                  Text(
                    p.timeAgo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Symptoms
              SectionCard(
                accentColor: AppColors.secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sick_outlined, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text('Patient\'s Symptoms', style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(p.symptoms, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Vitals
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monitor_heart_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Vitals', style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(p.vitals, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // AI Assessment (labeled clearly as AI-generated)
              SectionCard(
                accentColor: AppColors.tertiary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_outlined, size: 16, color: AppColors.tertiary),
                        const SizedBox(width: 8),
                        Text('AI Assessment', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF9C3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFDE047)),
                          ),
                          child: Text(
                            'AI-generated · not a diagnosis',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF713F12),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Possible conditions:',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    ...p.possibleConditions.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 14)),
                            Expanded(child: Text(c, style: Theme.of(context).textTheme.bodySmall)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Recommendation: ${p.recommendation}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Reply CTA
              ElevatedButton.icon(
                onPressed: () => context.push(
                  Routes.chat.replaceAll(':consultationId', 'mock-consult-${p.id}'),
                  extra: {'doctorName': 'Dr. Sunita Verma', 'doctorId': 'doc_sunita'},
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Respond via Chat'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending Verification Screen
// ─────────────────────────────────────────────────────────────────────────────
class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFBBF24), width: 2),
                ),
                child: const Icon(Icons.hourglass_empty_rounded, size: 40, color: Color(0xFFD97706)),
              ),
              const SizedBox(height: 24),
              Text(
                'Verification Pending',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your doctor account is under review. Our team will verify your credentials and notify you within 1–2 business days.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => context.go(Routes.login),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Consultation History Screen
// ─────────────────────────────────────────────────────────────────────────────
class ConsultationHistoryScreen extends StatelessWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation History'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: _mockPatients.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded, size: 48, color: AppColors.outlineVariant),
                    const SizedBox(height: 12),
                    Text(
                      'No past consultations yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _mockPatients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = _mockPatients[i];
                  return SectionCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: RiskBadge(riskLevel: p.riskLevel),
                      title: Text(p.symptoms, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(p.timeAgo),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
                    ),
                  );
                },
              ),
      ),
    );
  }
}
