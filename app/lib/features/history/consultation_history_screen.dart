// AarogyaMP — Consultation History & Health Records Screen (M2 / M3 — Person C)
// Aligned with Stitch UI Screen 6: projects/5690353454197586822/screens/a8e9edd8507e4290a65a602848e67305
// Route: /history — Displays patient consultation history and ABDM records.

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
    ref.watch(authProvider);
    final history = ref.read(authProvider.notifier).getConsultationHistory();

    return Scaffold(
      backgroundColor: const Color(0xFFE7FEFC),
      body: SafeArea(
        child: Column(
          children: [
            const StitchHeader(subtitle: 'Records & History'),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ABDM Digital Health Locker Banner
                    _buildAbdmLockerBanner(),

                    // Section Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'परामर्श इतिहास / Consultations',
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0A1F1E),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCF2F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${history.length} रिकॉर्ड',
                              style: const TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (history.isEmpty)
                      _buildEmptyState(context)
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: history.map((item) {
                            return _buildHistoryItem(context, ref, item);
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Past Assessment Archive Preview Card
                    _buildPastAssessmentsSection(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) {
          if (i == 0) context.go(Routes.patientHome);
          if (i == 1) context.push(Routes.symptomVoice);
          if (i == 2) context.push(Routes.doctorList);
          if (i == 3) {} // already here
        },
      ),
    );
  }

  Widget _buildAbdmLockerBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Text(
                      'आयुष्मान भारत डिजिटल मिशन (ABDM)',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A1F1E),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'आपके सभी परामर्श व डिजिटल पर्चे सुरक्षित रूप से आयुष्मान भारत हेल्थ एकाउंट (ABHA) से लिंक हैं।',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 11,
                    color: Color(0xFF3E4943),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7E4)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFDCF2F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_edu_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Consultation History',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A1F1E),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'कोई पूर्व परामर्श नहीं मिला',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E7A73),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'जब आप सत्यापित डॉक्टरों से परामर्श लेंगे, तो आपकी बातचीत, सलाह व प्रिस्क्रिप्शन यहां दिखाई देंगे।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 12,
              color: Color(0xFF6E7A73),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => context.push(Routes.doctorList),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.person_search_rounded, size: 18),
            label: const Text(
              'सत्यापित डॉक्टर खोजें / Find Doctors',
              style: TextStyle(fontFamily: 'NotoSans', fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
    final consultationId = item['consultationId']?.toString() ?? '';
    final doctorName = item['doctorName']?.toString() ?? 'Doctor';
    final specialty = item['specialty']?.toString() ?? 'General Medicine';
    final rawDate = item['updatedAt']?.toString();
    DateTime? dt;
    if (rawDate != null) dt = DateTime.tryParse(rawDate);
    final dateStr = dt != null ? DateFormat('MMM d, y · h:mm a').format(dt) : 'Recent';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCF2F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              doctorName,
                              style: const TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0A1F1E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        specialty,
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 12,
                          color: Color(0xFF3E4943),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF6E7A73)),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'बातचीत खोलें',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildPastAssessmentsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_heart_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'डिजिटल स्वास्थ्य पर्ची अभिलेख',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A1F1E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF2F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FHIR v4.0.1',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'सभी पूर्व प्राथमिक जांच रिकॉर्ड एनडीएचएम (NDHM) मानकों के अनुसार एन्क्रिप्टेड हैं। डॉक्टर को दिखाने के लिए QR कोड शेयर कर सकते हैं।',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 11,
              color: Color(0xFF6E7A73),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
