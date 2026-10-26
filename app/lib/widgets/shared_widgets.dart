// AarogyaMP — Shared widgets (M1 — Person C)
// RiskBadge, DisclaimerBanner, SectionCard, LoadingOverlay, VerifiedBadge

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/locale_provider.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RiskBadge — pill badge for LOW / MODERATE / HIGH / EMERGENCY
// ─────────────────────────────────────────────────────────────────────────────
class RiskBadge extends StatelessWidget {
  final String riskLevel;
  final bool large;

  const RiskBadge({super.key, required this.riskLevel, this.large = false});

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig(riskLevel);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: config.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 10 : 8,
            height: large ? 10 : 8,
            decoration: BoxDecoration(
              color: config.text,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            riskLevel,
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: large ? 14 : 11,
              fontWeight: FontWeight.w700,
              color: config.text,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _badgeConfig(String level) {
    switch (level.toUpperCase()) {
      case 'EMERGENCY':
        return const _BadgeConfig(
          text: AppColors.riskEmergencyText,
          bg: AppColors.riskEmergencyBg,
          border: AppColors.riskEmergencyBorder,
        );
      case 'HIGH':
        return const _BadgeConfig(
          text: AppColors.riskHighText,
          bg: AppColors.riskHighBg,
          border: AppColors.riskHighBorder,
        );
      case 'MODERATE':
        return const _BadgeConfig(
          text: AppColors.riskModerateText,
          bg: AppColors.riskModerateBg,
          border: AppColors.riskModerateBorder,
        );
      default: // LOW
        return const _BadgeConfig(
          text: AppColors.riskLowText,
          bg: AppColors.riskLowBg,
          border: AppColors.riskLowBorder,
        );
    }
  }
}

class _BadgeConfig {
  final Color text, bg, border;
  const _BadgeConfig({required this.text, required this.bg, required this.border});
}

// ─────────────────────────────────────────────────────────────────────────────
// DisclaimerBanner — mandatory on every non-emergency assessment (Reference §10)
// ─────────────────────────────────────────────────────────────────────────────
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFBBF24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This is an AI-generated possible-conditions read, not a medical diagnosis. A doctor makes the final call.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF92400E),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VerifiedBadge — green chip shown on verified doctors
// ─────────────────────────────────────────────────────────────────────────────
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.riskLowBg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.riskLowBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 12, color: AppColors.riskLowText),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.riskLowText,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SectionCard — standard content card with optional left-accent border
// ─────────────────────────────────────────────────────────────────────────────
class SectionCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;

  const SectionCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D172B2A),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: padding ??
                EdgeInsets.fromLTRB(accentColor != null ? 20 : 16, 16, 16, 16),
            child: child,
          ),
          if (accentColor != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: accentColor),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LoadingOverlay — full-screen loading with emerald spinner
// ─────────────────────────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            if (message != null) ...[
              const SizedBox(height: 20),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBottomNav — shared bottom nav for patient role
// ─────────────────────────────────────────────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasScope = context.findAncestorWidgetOfExactType<ProviderScope>() != null ||
        context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() != null;
    if (hasScope) {
      return _ConsumerAppBottomNav(currentIndex: currentIndex, onTap: onTap);
    }
    return _buildNavContent(currentIndex, onTap, false);
  }

  static Widget _buildNavContent(int currentIndex, ValueChanged<int> onTap, bool isHindi) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_hospital_outlined),
            activeIcon: const Icon(Icons.local_hospital_rounded),
            label: isHindi ? 'गृह' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.mic_none_rounded),
            activeIcon: const Icon(Icons.mic_rounded),
            label: isHindi ? 'बोलें' : 'Intake',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.medical_services_outlined),
            activeIcon: const Icon(Icons.medical_services_rounded),
            label: isHindi ? 'डॉक्टर' : 'Doctors',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.description_outlined),
            activeIcon: const Icon(Icons.description_rounded),
            label: isHindi ? 'इतिहास' : 'Records',
          ),
        ],
      ),
    );
  }
}

class _ConsumerAppBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ConsumerAppBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHindi = ref.watch(isHindiProvider);
    return AppBottomNav._buildNavContent(currentIndex, onTap, isHindi);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StitchHeader — Pixel-perfect top app bar without height truncation or overflow
// ─────────────────────────────────────────────────────────────────────────────
class StitchHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onProfileTap;
  final VoidCallback? onBackTap;
  final bool showBack;

  const StitchHeader({
    super.key,
    this.title = 'AarogyaMP',
    this.subtitle = 'Home',
    this.onProfileTap,
    this.onBackTap,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  static String _localizeSubtitle(String sub, bool isHindi) {
    if (!isHindi) return sub;
    switch (sub.trim().toLowerCase()) {
      case 'home':
        return 'होम';
      case 'find doctors':
        return 'डॉक्टर खोजें';
      case 'ai intake':
        return 'लक्षण जांच';
      case 'text intake':
        return 'लक्षण विवरण';
      case 'vitals intake':
        return 'वाइटल्स माप';
      case 'assessment':
      case 'assessment result':
        return 'स्वास्थ्य मूल्यांकन';
      case 'records':
      case 'records & history':
      case 'consultation records':
        return 'परामर्श इतिहास';
      default:
        return sub;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasScope = context.findAncestorWidgetOfExactType<ProviderScope>() != null;
    if (!hasScope) {
      return _StitchHeaderContent(
        title: title,
        subtitle: subtitle,
        onProfileTap: onProfileTap,
        onBackTap: onBackTap,
        showBack: showBack,
        isHindi: false,
        onToggleLang: null,
      );
    }
    return _ConsumerStitchHeader(
      title: title,
      subtitle: subtitle,
      onProfileTap: onProfileTap,
      onBackTap: onBackTap,
      showBack: showBack,
    );
  }
}

class _ConsumerStitchHeader extends ConsumerWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onProfileTap;
  final VoidCallback? onBackTap;
  final bool showBack;

  const _ConsumerStitchHeader({
    required this.title,
    required this.subtitle,
    required this.onProfileTap,
    required this.onBackTap,
    required this.showBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHindi = ref.watch(isHindiProvider);
    return _StitchHeaderContent(
      title: title,
      subtitle: subtitle,
      onProfileTap: onProfileTap ?? () => showPatientProfileSheet(context, ref),
      onBackTap: onBackTap,
      showBack: showBack,
      isHindi: isHindi,
      onToggleLang: () => ref.read(isHindiProvider.notifier).toggle(),
    );
  }
}

/// Global profile sheet accessible from anywhere in the app
void showPatientProfileSheet(BuildContext context, WidgetRef ref) {
  final auth = ref.read(authProvider);
  final isHindi = ref.read(isHindiProvider);
  final nameDisplay = auth.name ?? (isHindi ? 'अतिथि नागरिक' : 'Guest Citizen');
  final phoneDisplay = auth.phone ?? '+91 98765 00000';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nameDisplay,
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            isHindi ? 'सत्यापित' : 'Verified',
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phoneDisplay,
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
                  title: Text(
                    isHindi ? 'डॉक्टर खोजें' : 'Find Doctors',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push(Routes.doctorList);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.history_rounded, color: AppColors.secondary),
                  title: Text(
                    isHindi ? 'परामर्श इतिहास' : 'Consultation History',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push(Routes.history);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.emergencyRed),
            label: Text(
              isHindi ? 'लॉग आउट' : 'Log Out',
              style: const TextStyle(
                color: AppColors.emergencyRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StitchHeaderContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onProfileTap;
  final VoidCallback? onBackTap;
  final bool showBack;
  final bool isHindi;
  final VoidCallback? onToggleLang;

  const _StitchHeaderContent({
    required this.title,
    required this.subtitle,
    required this.onProfileTap,
    required this.onBackTap,
    required this.showBack,
    required this.isHindi,
    required this.onToggleLang,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final displaySubtitle = StitchHeader._localizeSubtitle(subtitle, isHindi);

    return Container(
      padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: AppColors.surfaceBorder, width: 1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            if (showBack) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
                onPressed: onBackTap ?? () => Navigator.of(context).maybePop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
            ],
            // Logo + Titles
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    displaySubtitle,
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Red 108 Emergency Pill Button
            InkWell(
              onTap: () async {
                final uri = Uri.parse('tel:108');
                // ignore: deprecated_member_use
                await launchUrl(uri);
              },
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33DC2626),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '108',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Bilingual Toggle Pill: हिं / EN
            InkWell(
              onTap: onToggleLang,
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'हिं',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 11,
                        fontWeight: isHindi ? FontWeight.w800 : FontWeight.w500,
                        color: isHindi ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        '/',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.outlineVariant,
                        ),
                      ),
                    ),
                    Text(
                      'EN',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 11,
                        fontWeight: !isHindi ? FontWeight.w800 : FontWeight.w500,
                        color: !isHindi ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Profile circle
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


