import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'profile_card.dart';
import 'profiles_header.dart';

class RoamLpaScreen extends StatelessWidget {
  const RoamLpaScreen({super.key, this.activationCode});

  final String? activationCode;

  @override
  Widget build(BuildContext context) {
    final code = activationCode?.trim();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roam2World eSIM Manager'),
        leading: IconButton(
          tooltip: 'Roam2World’e dön',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ProfilesHeader(),
            const SizedBox(height: 18),
            ProfileCard(
              profile: EuiccProfile(
                name: 'Kurumsal eSIM profili',
                provider: 'Roam2World B2B',
                iccid: 'Aktivasyon bekliyor',
                matchingId: code == null || code.isEmpty
                    ? 'Kod girilmedi'
                    : _summarizeActivationCode(code),
                enabled: false,
              ),
              onToggle: () {},
              onMenu: () {},
            ),
            const SizedBox(height: 18),
            const _ReadinessPanel(),
          ],
        ),
      ),
    );
  }

  static String _summarizeActivationCode(String code) {
    if (code.length <= 22) return code;
    return '${code.substring(0, 12)}…${code.substring(code.length - 8)}';
  }
}


class _ReadinessPanel extends StatelessWidget {
  const _ReadinessPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: .16)),
      ),
      child: const Text(
        'Bu alan Roam2World B2B marka deneyimiyle eSIM profil yönetimini sunar. Cihaz desteği uygun olduğunda yükleme işlemleri mevcut LPA akışı üzerinden devam eder.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.45),
      ),
    );
  }
}
