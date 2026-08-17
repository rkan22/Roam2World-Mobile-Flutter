import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';

class ProviderStatusSheet extends StatelessWidget {
  const ProviderStatusSheet({super.key, required this.data});

  final Map<String, dynamic> data;

  dynamic _read(List<List<String>> paths) {
    for (final path in paths) {
      dynamic current = data;
      var found = true;
      for (final key in path) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          found = false;
          break;
        }
      }
      if (found && current != null && '$current'.trim().isNotEmpty) {
        return current;
      }
    }
    return null;
  }

  double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  String _usage(dynamic value) {
    final mb = _number(value);
    if (mb == null) return '—';
    if (mb >= 1024) {
      final gb = mb / 1024;
      return '${gb.toStringAsFixed(gb == gb.roundToDouble() ? 0 : 2)} GB';
    }
    return '${mb.toStringAsFixed(mb == mb.roundToDouble() ? 0 : 1)} MB';
  }

  String _text(dynamic value, {String fallback = '—'}) {
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty ? fallback : text;
  }

  String _date(dynamic value) {
    final raw = _text(value, fallback: '—');
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _text(
      _read([
        ['usage', 'status'],
        ['status'],
        ['raw', 'data', 'status'],
      ]),
      fallback: 'Unknown',
    );
    final normalizedStatus = status.toLowerCase();
    final active =
        normalizedStatus.contains('active') &&
        !normalizedStatus.contains('notactive');
    final statusColor = active ? AppColors.success : AppColors.danger;

    final iccid = _text(
      _read([
        ['iccid'],
        ['usage', 'iccid'],
        ['raw', 'data', 'iccid'],
      ]),
    );
    final total = _read([
      ['usage', 'total_mb'],
      ['raw', 'data', 'dataTotal'],
      ['data', 'total_mb'],
    ]);
    final used = _read([
      ['usage', 'used_mb'],
      ['raw', 'data', 'dataUsage'],
      ['data', 'used_mb'],
    ]);
    final remaining = _read([
      ['usage', 'remaining_mb'],
      ['raw', 'data', 'dataResidual'],
      ['data', 'remaining_mb'],
    ]);
    final profileStatus = _text(
      _read([
        ['usage', 'profile_status'],
        ['profile_status'],
        ['raw', 'data', 'profile_status'],
      ]),
    );
    final providerMessage = _text(
      _read([
        ['raw', 'msg'],
        ['message'],
        ['msg'],
      ]),
    );
    final startDate = _read([
      ['usage', 'start_date'],
      ['start_date'],
      ['raw', 'data', 'startDate'],
    ]);
    final endDate = _read([
      ['usage', 'end_date'],
      ['end_date'],
      ['raw', 'data', 'endDate'],
    ]);

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .78,
        minChildSize: .48,
        maxChildSize: .94,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Text(
              'Live provider status',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Latest response from the provider.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            _Surface(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.sim_card_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'eSIM Data Plan',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Provider status',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status.replaceAll('_', ' '),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  _RowItem(
                    icon: Icons.badge_outlined,
                    label: 'ICCID',
                    value: iccid,
                    singleLine: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Surface(
              title: 'Usage',
              child: Row(
                children: [
                  Expanded(
                    child: _UsageCard(
                      label: 'Total',
                      value: _usage(total),
                      icon: Icons.cloud_upload_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _UsageCard(
                      label: 'Used',
                      value: _usage(used),
                      icon: Icons.pie_chart_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _UsageCard(
                      label: 'Remaining',
                      value: _usage(remaining),
                      icon: Icons.sync_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Surface(
              title: 'Profile',
              child: Column(
                children: [
                  _RowItem(
                    icon: Icons.download_done_rounded,
                    label: 'Profile status',
                    value: profileStatus,
                  ),
                  _RowItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Provider message',
                    value: providerMessage,
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Surface(
              title: 'Validity',
              child: Column(
                children: [
                  _RowItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Start date',
                    value: _date(startDate),
                    singleLine: true,
                  ),
                  _RowItem(
                    icon: Icons.event_available_outlined,
                    label: 'End date',
                    value: _date(endDate),
                    singleLine: true,
                    last: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(B2BRadius.lg),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
        ],
        child,
      ],
    ),
  );
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
    this.singleLine = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;
  final bool singleLine;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: singleLine
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              : Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
        ),
      ],
    ),
  );
}
