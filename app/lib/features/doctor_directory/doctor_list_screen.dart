// AarogyaMP — Doctor List + Doctor Profile Screens (M1 — Person C)
// Reference §12: doctor_list_screen.dart, doctor_profile_screen.dart
// IMPORTANT: Never render contact info for unverified doctors (defense-in-depth per Reference §14)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/doctor_model.dart';
import '../../core/services/mock_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../widgets/shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Doctor List Screen
// ─────────────────────────────────────────────────────────────────────────────
class DoctorListScreen extends ConsumerStatefulWidget {
  final String? initialSpecialty;

  const DoctorListScreen({super.key, this.initialSpecialty});

  @override
  ConsumerState<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends ConsumerState<DoctorListScreen> {
  String? _selectedSpecialty;
  late Future<List<Doctor>> _doctorsFuture;

  static const List<String> _specialties = [
    'All',
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'ENT Specialist',
    'Orthopedic Specialist',
    'Neurologist',
    'Mental Health Professional',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSpecialty = widget.initialSpecialty;
    _loadDoctors();
  }

  void _loadDoctors() {
    _doctorsFuture = ref.read(mockServiceProvider).getDoctors(
          specialty: _selectedSpecialty == 'All' ? null : _selectedSpecialty,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find a Doctor'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Map view',
            onPressed: () => context.push(Routes.doctorMap),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Specialty filter chips
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _specialties.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final s = _specialties[i];
                    final selected = _selectedSpecialty == s ||
                        (s == 'All' && _selectedSpecialty == null);
                    return FilterChip(
                      label: Text(s),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedSpecialty = s == 'All' ? null : s;
                          _loadDoctors();
                        });
                      },
                      selectedColor: AppColors.primaryLight,
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.primary : AppColors.surfaceBorder,
                      ),
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1),

            // Doctor list
            Expanded(
              child: FutureBuilder<List<Doctor>>(
                future: _doctorsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final doctors = snap.data ?? [];
                  if (doctors.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.outlineVariant),
                          const SizedBox(height: 12),
                          Text(
                            'No verified doctors found\nfor this specialty.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: doctors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _DoctorCard(
                      doctor: doctors[i],
                      onTap: () => context.push(
                        Routes.doctorProfile.replaceAll(':id', doctors[i].id),
                        extra: doctors[i],
                      ),
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

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const _DoctorCard({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Defense-in-depth: do not render unverified doctors
    if (!doctor.isVerified) return const SizedBox.shrink();

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  doctor.name.replaceAll('Dr. ', '').substring(0, 1),
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doctor.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const VerifiedBadge(),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    doctor.specialty,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (doctor.qualification != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      doctor.qualification!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (doctor.hospital != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_outlined, size: 13, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doctor.hospital!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (doctor.distanceKm != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.distanceKm!.toStringAsFixed(1)} km away',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Doctor Profile Screen
// ─────────────────────────────────────────────────────────────────────────────
class DoctorProfileScreen extends ConsumerWidget {
  final String doctorId;
  final Doctor? doctor; // passed via route extra to avoid re-fetch

  const DoctorProfileScreen({
    super.key,
    required this.doctorId,
    this.doctor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (doctor != null) {
      return _buildProfile(context, ref, doctor!);
    }
    return FutureBuilder<Doctor?>(
      future: ref.read(mockServiceProvider).getDoctorById(doctorId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingOverlay(message: 'Loading doctor profile...');
        }
        if (!snap.hasData || snap.data == null) {
          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
            body: const Center(child: Text('Doctor not found.')),
          );
        }
        return _buildProfile(context, ref, snap.data!);
      },
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, Doctor doc) {
    // Defense-in-depth: never show unverified doctor profile
    if (!doc.isVerified) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: Text('This doctor profile is not available.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppColors.surface,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          doc.name.replaceAll('Dr. ', '').substring(0, 1),
                          style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(doc.name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      doc.specialty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (doc.qualification != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        doc.qualification!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const VerifiedBadge(),
                  ],
                ),
              ),
              const Divider(height: 1),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Contact action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ContactButton(
                            icon: Icons.call_rounded,
                            label: 'Call',
                            color: AppColors.primary,
                            onTap: () async {
                              final uri = Uri.parse('tel:${doc.phone}');
                              if (await canLaunchUrl(uri)) await launchUrl(uri);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ContactButton(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            color: AppColors.secondary,
                            onTap: () async {
                              if (doc.email == null) return;
                              final uri = Uri.parse(
                                'mailto:${doc.email}?subject=Consultation%20Request%20via%20AarogyaMP',
                              );
                              if (await canLaunchUrl(uri)) await launchUrl(uri);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ContactButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Chat',
                            color: AppColors.tertiary,
                            onTap: () => context.push(
                              Routes.chat.replaceAll(':consultationId', 'mock-consult-${doc.id}'),
                              extra: {'doctorName': doc.name, 'doctorId': doc.id},
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Info cards
                    if (doc.hospital != null)
                      _InfoRow(
                        icon: Icons.local_hospital_outlined,
                        label: 'Hospital',
                        value: doc.hospital!,
                      ),
                    if (doc.address != null)
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: doc.address!,
                      ),
                    if (doc.distanceKm != null)
                      _InfoRow(
                        icon: Icons.near_me_outlined,
                        label: 'Distance',
                        value: '${doc.distanceKm!.toStringAsFixed(1)} km from your location',
                      ),
                    if (doc.availability != null && doc.availability!.isNotEmpty)
                      _AvailabilityCard(availability: doc.availability!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final Map<String, dynamic> availability;

  const _AvailabilityCard({required this.availability});

  @override
  Widget build(BuildContext context) {
    final dayNames = {'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu', 'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun'};
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Availability', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          ...availability.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      dayNames[e.key] ?? e.key,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(e.value.toString(), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
