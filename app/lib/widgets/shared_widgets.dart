// AarogyaMP — Shared widgets (M1 — Person C)
// RiskBadge, DisclaimerBanner, SectionCard, LoadingOverlay, VerifiedBadge

import 'package:flutter/material.dart';
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
        return _BadgeConfig(
          text: AppColors.riskEmergencyText,
          bg: AppColors.riskEmergencyBg,
          border: AppColors.riskEmergencyBorder,
        );
      case 'HIGH':
        return _BadgeConfig(
          text: AppColors.riskHighText,
          bg: AppColors.riskHighBg,
          border: AppColors.riskHighBorder,
        );
      case 'MODERATE':
        return _BadgeConfig(
          text: AppColors.riskModerateText,
          bg: AppColors.riskModerateBg,
          border: AppColors.riskModerateBorder,
        );
      default: // LOW
        return _BadgeConfig(
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
        border: Border(
          left: accentColor != null
              ? BorderSide(color: accentColor!, width: 4)
              : const BorderSide(color: AppColors.surfaceBorder),
          right: const BorderSide(color: AppColors.surfaceBorder),
          top: const BorderSide(color: AppColors.surfaceBorder),
          bottom: const BorderSide(color: AppColors.surfaceBorder),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D172B2A),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services_rounded),
            label: 'Doctors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
