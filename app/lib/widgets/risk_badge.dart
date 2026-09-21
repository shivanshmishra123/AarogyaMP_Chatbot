/// AarogyaMP — Risk badge widget stub (Person C, M1)
/// Colors MUST match Reference §6 Risk Level Bands.
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class RiskBadge extends StatelessWidget {
  final String riskLevel; // LOW | MODERATE | HIGH | EMERGENCY
  const RiskBadge({super.key, required this.riskLevel});

  Color get _color {
    switch (riskLevel) {
      case 'EMERGENCY': return AppTheme.riskEmergency;
      case 'HIGH': return AppTheme.riskHigh;
      case 'MODERATE': return AppTheme.riskModerate;
      case 'LOW': return AppTheme.riskLow;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(riskLevel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: _color,
    );
  }
}
