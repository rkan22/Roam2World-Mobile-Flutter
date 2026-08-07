import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'esim_catalog.dart';

class LpaInstallScreen extends StatefulWidget {
  const LpaInstallScreen({super.key, required this.esim});

  final MobileEsim esim;

  @override
  State<LpaInstallScreen> createState() => _LpaInstallScreenState();
}

class _LpaInstallScreenState extends State<LpaInstallScreen> {
  int _step = 0;
  double _progress = 0;

  void _advance() {
    if (_step >= 3) return;
    setState(() {
      _step++;
      _progress = switch (_step) { 1 => .45, 2 => .72, 3 => 1, _ => 0 };
    });
  }

  @override
  Widget build(BuildContext context) {
    final complete = _step == 3;
    return Scaffold(
      appBar: AppBar(title: const Text('Cihaza Yükle (LPA)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _StepHeader(step: _step),
            const SizedBox(height: 24),
            _EsimCard(esim: widget.esim),
            const SizedBox(height: 32),
            Icon(
              complete ? Icons.check_circle_rounded : (_step == 0 ? Icons.phone_iphone_rounded : Icons.settings_rounded),
              size: 92,
              color: complete ? Colors.green : AppColors.primary,
            ),
            const SizedBox(height: 18),
            Text(
              switch (_step) {
                0 => 'eSIM kuruluma hazır',
                1 => 'Profil indiriliyor…',
                2 => 'Profil yükleniyor…',
                _ => 'eSIM başarıyla yüklendi!',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              complete
                  ? 'Profil cihazda hazır. Desteklenen cihazlarda etkinleştirme işlemi LPA servis katmanından tamamlanacak.'
                  : 'Kurulum sırasında internet bağlantısını kesmeyin ve uygulamayı kapatmayın.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 28),
            LinearProgressIndicator(value: _progress, minHeight: 8, borderRadius: BorderRadius.circular(99)),
            const SizedBox(height: 8),
            Text('%${(_progress * 100).round()}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 32),
            if (!complete)
              ElevatedButton.icon(
                onPressed: _advance,
                icon: Icon(_step == 0 ? Icons.download_rounded : Icons.arrow_forward_rounded),
                label: Text(_step == 0 ? 'Kurulumu Başlat' : 'Devam Et'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Tamamla'),
              ),
            const SizedBox(height: 10),
            if (!complete) OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Hazırlık', 'İndiriliyor', 'Yükleniyor', 'Tamamlandı'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= step;
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: active ? AppColors.primary : AppColors.border,
                child: index < step
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : Text('${index + 1}', style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 6),
              Text(labels[index], maxLines: 1, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? AppColors.primary : AppColors.textSecondary)),
            ],
          ),
        );
      }),
    );
  }
}

class _EsimCard extends StatelessWidget {
  const _EsimCard({required this.esim});
  final MobileEsim esim;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(esim.packageName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(esim.provider, style: const TextStyle(color: AppColors.textSecondary)),
            if (esim.iccid.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('ICCID  ${esim.iccid}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      );
}
