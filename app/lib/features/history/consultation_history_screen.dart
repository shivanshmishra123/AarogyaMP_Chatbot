// AarogyaMP — Consultation History Screen (M2 — Person C)
// Route: /history — Displays patient consultation history and allows resuming chats.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ConsultationHistoryScreen extends ConsumerWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.read(authProvider.notifier).getConsultationHistory();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation History'),
        automaticallyImplyLeading: false,
      ),
      body: history.isEmpty ? _buildEmptyState(context) : _buildHistoryList(context, ref, history),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) {
          if (i == 0) context.go(Routes.patientHome);
          if (i == 1) context.push(Routes.doctorList);
          if (i == 2) {
            final auth = ref.read(authProvider);
            final lastId = auth.lastConsultationId;
            final docName = auth.lastConsultationDoctorName ?? 'Doctor';
            if (lastId != null && lastId.isNotEmpty) {
              context.push(
                Routes.chat.replaceAll(':consultationId', lastId),
                extra: {'doctorName': docName},
              );
            } else {
              context.push(Routes.doctorList);
            }
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_edu_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Consultation History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you consult with doctors, your conversations and consultation notes will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(Routes.doctorList),
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: const Text('Find Doctors'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> items,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final consultationId = item['consultationId']?.toString() ?? '';
        final doctorName = item['doctorName']?.toString() ?? 'Doctor';
        final specialty = item['specialty']?.toString() ?? 'General Medicine';
        final rawDate = item['updatedAt']?.toString();
        DateTime? dt;
        if (rawDate != null) dt = DateTime.tryParse(rawDate);
        final dateStr = dt != null ? DateFormat('MMM d, y · h:mm a').format(dt) : 'Recent';

        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ref.read(authProvider.notifier).setLastConsultation(
                    consultationId: consultationId,
                    doctorName: doctorName,
                  );
              context.push(
                Routes.chat.replaceAll(':consultationId', consultationId),
                extra: {'doctorName': doctorName},
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          specialty,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 12, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Resume',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
