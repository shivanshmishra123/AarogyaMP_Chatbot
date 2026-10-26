// AarogyaMP — Shared widgets (M1 — Person C)
// RiskBadge, DisclaimerBanner, SectionCard, LoadingOverlay, VerifiedBadge

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_outlined),
            activeIcon: Icon(Icons.local_hospital_rounded),
            label: 'गृह / Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none_rounded),
            activeIcon: Icon(Icons.mic_rounded),
            label: 'बोलें / Intake',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services_rounded),
            label: 'डॉक्टर / Doctors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description_rounded),
            label: 'इतिहास / Records',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StitchHeader — Pixel-perfect top app bar from Stitch Prototype 5690353454197586822
// ─────────────────────────────────────────────────────────────────────────────
class StitchHeader extends StatefulWidget implements PreferredSizeWidget {
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
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<StitchHeader> createState() => _StitchHeaderState();
}

class _StitchHeaderState extends State<StitchHeader> {
  bool _isHindi = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: AppColors.surfaceBorder, width: 1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (widget.showBack) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
                onPressed: widget.onBackTap ?? () => Navigator.of(context).maybePop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                    widget.title,
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
                    widget.subtitle,
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
              onTap: () {
                setState(() => _isHindi = !_isHindi);
              },
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
                        fontWeight: _isHindi ? FontWeight.w700 : FontWeight.w400,
                        color: _isHindi ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Text(
                      '/',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.outlineVariant,
                      ),
                    ),
                    Text(
                      'EN',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 11,
                        fontWeight: !_isHindi ? FontWeight.w700 : FontWeight.w400,
                        color: !_isHindi ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Profile circle
            GestureDetector(
              onTap: widget.onProfileTap,
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

