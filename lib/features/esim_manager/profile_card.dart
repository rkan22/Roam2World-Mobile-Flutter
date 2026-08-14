import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class EuiccProfile {
  const EuiccProfile({
    required this.name,
    required this.provider,
    required this.iccid,
    required this.matchingId,
    required this.enabled,
  });

  final String name;
  final String provider;
  final String iccid;
  final String matchingId;
  final bool enabled;
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.profile,
    required this.onToggle,
    required this.onMenu,
    this.cardKey,
    super.key,
  });

  final EuiccProfile profile;
  final VoidCallback onToggle;
  final VoidCallback onMenu;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A43), Color(0xFF075985), Color(0xFF0EA5E9)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: .22)),
                ),
                child: const Icon(Icons.business_center_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Roam2World B2B',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: onMenu,
                tooltip: 'Profil işlemleri',
                color: Colors.white,
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            profile.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.provider,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProfileChip(label: 'ICCID', value: profile.iccid),
              _ProfileChip(label: 'EID / Matching', value: profile.matchingId),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                profile.enabled ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                color: profile.enabled ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.enabled ? 'Kurumsal hat aktif' : 'Kurulum ve aktivasyon bekliyor',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onToggle,
                icon: Icon(profile.enabled ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded),
                label: Text(profile.enabled ? 'Pasifleştir' : 'Aktifleştir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
