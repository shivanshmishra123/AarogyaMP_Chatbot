// AarogyaMP — Doctor Dashboard Screens (M2 — Person C)
// USE_MOCKS=true  → mock patient list (unchanged M1 UX)
// USE_MOCKS=false → GET /api/doctor/queue live data
//
// Screens in this file:
//   PatientQueueScreen    — doctor's incoming patient queue
//   PatientDetailScreen   — per-patient symptom + AI assessment view
//   PendingVerificationScreen
//   ConsultationHistoryScreen
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/models/consultation_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../widgets/shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data (USE_MOCKS=true only)
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
    symptoms: 'Fever since 2 days, headache and body ache. Temp ~102°F.',
    vitals: 'Temp: 102°F · HR: 98 bpm · BP: 145/92 mmHg · SpO₂: 96%',
    timeAgo: '5 min ago',
    recommendation: 'Consult a physician within 24 hours.',
    possibleConditions: [
      'Viral/febrile illness (high)',
      'Influenza-like illness (medium)'
    ],
  ),
  _MockPatient(
    id: 'p_002',
    name: 'Priya Joshi',
    riskLevel: 'HIGH',
    symptoms: 'Chest tightness and shortness of breath since this morning.',
    vitals: 'Temp: 98.6°F · HR: 110 bpm · BP: 160/100 mmHg · SpO₂: 94%',
    timeAgo: '12 min ago',
    recommendation: 'Urgent evaluation required — seek care today.',
    possibleConditions: [
      'Hypertensive urgency (medium)',
      'Acute coronary syndrome (low)'
    ],
  ),
  _MockPatient(
    id: 'p_003',
    name: 'Ankit Patel',
    riskLevel: 'LOW',
    symptoms: 'Mild cold and runny nose for 1 day. No fever.',
    vitals: 'Temp: 98.4°F · HR: 72 bpm',
    timeAgo: '28 min ago',
    recommendation: 'Rest, stay hydrated, monitor.',
    possibleConditions: [
      'Common cold (high)',
      'Mild allergic rhinitis (medium)'
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Patient Queue Screen
// ─────────────────────────────────────────────────────────────────────────────
class PatientQueueScreen extends ConsumerStatefulWidget {
  const PatientQueueScreen({super.key});

  @override
  ConsumerState<PatientQueueScreen> createState() => _PatientQueueScreenState();
}

class _PatientQueueScreenState extends ConsumerState<PatientQueueScreen> {
  static const _useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);

  List<PatientQueueItem> _liveQueue = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!_useMocks) _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(Endpoints.doctorQueue);
      final list = (response.data as List)
          .map((e) => PatientQueueItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() => _liveQueue = list);
    } on DioException catch (e) {
      setState(() => _error = _friendlyError(e));
    } catch (e) {
      setState(() => _error = 'Could not load queue.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _friendlyError(DioException e) {
    if (e.response?.statusCode == 401) return 'Session expired. Please log in again.';
    if (e.response?.statusCode == 403) return 'Access denied.';
    return 'Could not load patient queue. Check your connection.';
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Queue'),
        actions: [
          if (!_useMocks)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _isLoading ? null : _loadQueue,
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: _useMocks ? _buildMockQueue(context) : _buildLiveQueue(context),
      ),
    );
  }

  // ── Mock queue ─────────────────────────────────────────────────────────────

  Widget _buildMockQueue(BuildContext context) {
    final urgent = _mockPatients.where((p) => p.riskLevel == 'HIGH' || p.riskLevel == 'EMERGENCY').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              if (urgent > 0)
                _SummaryChip(
                  label: '$urgent urgent',
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
              return _MockQueueCard(
                patient: p,
                onView: () => context.push(
                  Routes.patientDetail.replaceAll(':id', p.id),
                  extra: p,
                ),
                onReply: () => context.push(
                  Routes.chat.replaceAll(':consultationId', 'mock-consult-${p.id}'),
                  extra: {'doctorName': ref.read(authProvider).name ?? 'Doctor', 'doctorId': 'mock-doc'},
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Live queue ─────────────────────────────────────────────────────────────

  Widget _buildLiveQueue(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.outlineVariant),
              const SizedBox(height: 12),
              Text(_error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadQueue,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final urgent = _liveQueue
        .where((p) =>
            p.riskLevel == 'HIGH' ||
            p.riskLevel == 'EMERGENCY' ||
            p.isEmergency)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Row(
            children: [
              _SummaryChip(
                label: '${_liveQueue.length} patients',
                color: AppColors.primary,
                icon: Icons.people_outline_rounded,
              ),
              if (urgent > 0) ...[
                const SizedBox(width: 10),
                _SummaryChip(
                  label: '$urgent urgent',
                  color: AppColors.riskHighText,
                  icon: Icons.priority_high_rounded,
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _liveQueue.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_rounded,
                          size: 48, color: AppColors.outlineVariant),
                      const SizedBox(height: 12),
                      Text(
                        'No patients in queue.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadQueue,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _liveQueue.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = _liveQueue[i];
                      return _LiveQueueCard(
                        item: item,
                        onView: () => context.push(
                          Routes.patientDetail.replaceAll(':id', item.consultationId),
                          extra: item,
                        ),
                        onReply: () => context.push(
                          Routes.chat.replaceAll(':consultationId', item.consultationId),
                          extra: {
                            'doctorName': ref.read(authProvider).name ?? 'Doctor',
                            'doctorId': 'live',
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Queue card widgets
// ─────────────────────────────────────────────────────────────────────────────

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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }
}

class _MockQueueCard extends StatelessWidget {
  final _MockPatient patient;
  final VoidCallback onView;
  final VoidCallback onReply;
  const _MockQueueCard({required this.patient, required this.onView, required this.onReply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D172B2A), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(patient.name, style: Theme.of(context).textTheme.titleSmall)),
              RiskBadge(riskLevel: patient.riskLevel),
              const SizedBox(width: 8),
              Text(patient.timeAgo,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Text(patient.symptoms,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Reply'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveQueueCard extends StatelessWidget {
  final PatientQueueItem item;
  final VoidCallback onView;
  final VoidCallback onReply;
  const _LiveQueueCard({required this.item, required this.onView, required this.onReply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isEmergency
              ? AppColors.riskHighText.withValues(alpha: 0.4)
              : AppColors.surfaceBorder,
          width: item.isEmergency ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0D172B2A), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(item.patientName,
                      style: Theme.of(context).textTheme.titleSmall)),
              if (item.riskLevel != null) RiskBadge(riskLevel: item.riskLevel!),
              const SizedBox(width: 8),
              Text(item.timeAgoText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.symptomSummary,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Reply'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient Detail Screen (doctor role)
// ─────────────────────────────────────────────────────────────────────────────
class PatientDetailScreen extends ConsumerWidget {
  final String patientId; // In live mode = consultation_id
  final Object? extra;    // _MockPatient (mock) or PatientQueueItem (live)

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    this.extra,
  });

  static const _useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_useMocks) return _buildMockDetail(context, ref);
    return _buildLiveDetail(context, ref);
  }

  Widget _buildMockDetail(BuildContext context, WidgetRef ref) {
    final p = extra is _MockPatient
        ? extra as _MockPatient
        : _mockPatients.firstWhere((x) => x.id == patientId,
            orElse: () => _mockPatients.first);
    return _DetailScaffold(
      title: p.name,
      riskLevel: p.riskLevel,
      timeLabel: p.timeAgo,
      symptoms: p.symptoms,
      vitals: p.vitals,
      possibleConditions: p.possibleConditions,
      recommendation: p.recommendation,
      onChat: () => context.push(
        Routes.chat.replaceAll(':consultationId', 'mock-consult-${p.id}'),
        extra: {'doctorName': ref.read(authProvider).name ?? 'Doctor', 'doctorId': 'mock-doc'},
      ),
    );
  }

  Widget _buildLiveDetail(BuildContext context, WidgetRef ref) {
    if (extra is! PatientQueueItem) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: Text('Patient data not found.')),
      );
    }
    final item = extra as PatientQueueItem;
    return _DetailScaffold(
      title: item.patientName,
      riskLevel: item.riskLevel,
      timeLabel: item.timeAgoText,
      symptoms: item.symptomSummary,
      vitals: null, // not in PatientQueueItem (M3 TODO: add if GET /patients/{id} is wired)
      possibleConditions: null,
      recommendation: null,
      onChat: () => context.push(
        Routes.chat.replaceAll(':consultationId', item.consultationId),
        extra: {'doctorName': ref.read(authProvider).name ?? 'Doctor', 'doctorId': 'live'},
      ),
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  final String title;
  final String? riskLevel;
  final String timeLabel;
  final String symptoms;
  final String? vitals;
  final List<String>? possibleConditions;
  final String? recommendation;
  final VoidCallback onChat;

  const _DetailScaffold({
    required this.title,
    required this.riskLevel,
    required this.timeLabel,
    required this.symptoms,
    required this.vitals,
    required this.possibleConditions,
    required this.recommendation,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (riskLevel != null) RiskBadge(riskLevel: riskLevel!, large: true),
                  const SizedBox(width: 12),
                  Text(timeLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 16),

              SectionCard(
                accentColor: AppColors.secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sick_outlined, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text('Patient\'s Symptoms',
                            style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(symptoms, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),

              if (vitals != null) ...[
                const SizedBox(height: 12),
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
                      Text(vitals!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],

              if (possibleConditions != null && possibleConditions!.isNotEmpty) ...[
                const SizedBox(height: 12),
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
                      Text('Possible conditions:',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 6),
                      ...possibleConditions!.map(
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
                      if (recommendation != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Recommendation: $recommendation',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onChat,
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
                child: const Icon(Icons.hourglass_empty_rounded,
                    size: 40, color: Color(0xFFD97706)),
              ),
              const SizedBox(height: 24),
              Text('Verification Pending',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Your doctor account is under review. Our team will verify your credentials and notify you within 1–2 business days.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
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
      body: const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded, size: 48, color: AppColors.outlineVariant),
              SizedBox(height: 12),
              Text('No past consultations yet.',
                  style: TextStyle(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
