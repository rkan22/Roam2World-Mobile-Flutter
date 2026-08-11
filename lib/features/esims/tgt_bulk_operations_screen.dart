import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import 'provider_lifecycle_repository.dart';

class TgtBulkOperationsScreen extends StatefulWidget {
  const TgtBulkOperationsScreen({super.key});

  @override
  State<TgtBulkOperationsScreen> createState() =>
      _TgtBulkOperationsScreenState();
}

class _TgtBulkOperationsScreenState extends State<TgtBulkOperationsScreen> {
  final _repository = ProviderLifecycleRepository();
  final _rows = TextEditingController();
  bool _activation = false;
  bool _submitting = false;
  ProviderOperationResult? _result;
  String? _error;

  @override
  void dispose() {
    _rows.dispose();
    super.dispose();
  }

  List<TgtBulkItem> _parseRows() {
    final items = <TgtBulkItem>[];
    for (final rawLine in const LineSplitter().convert(_rows.text)) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final columns = line.split(',').map((value) => value.trim()).toList();
      if (columns.length < 2 || columns[0].isEmpty || columns[1].isEmpty) {
        throw const FormatException(
          'Each row must contain ICCID and package ID.',
        );
      }
      items.add(
        TgtBulkItem(
          iccid: columns[0],
          packageId: columns[1],
          customerEmail: columns.length > 2 ? columns[2] : null,
          customerName: columns.length > 3 ? columns[3] : null,
          customerPhone: columns.length > 4 ? columns[4] : null,
        ),
      );
    }
    if (items.isEmpty) {
      throw const FormatException('Add at least one operation row.');
    }
    if (_activation &&
        items.any((item) => item.customerEmail?.isEmpty != false)) {
      throw const FormatException('Customer email is required for activation.');
    }
    return items;
  }

  Future<void> _submit({required bool validateOnly}) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
      _result = null;
    });
    try {
      final items = _parseRows();
      final result = _activation
          ? await _repository.submitTgtBulkActivation(
              items,
              validateOnly: validateOnly,
            )
          : await _repository.submitTgtBulkTopup(
              items,
              validateOnly: validateOnly,
            );
      if (!mounted) return;
      setState(() => _result = result);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TGT bulk operations')),
    body: ListView(
      padding: const EdgeInsets.all(B2BSpacing.lg),
      children: [
        Text(
          'Orange Balkans batch processing',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: B2BSpacing.xs),
        Text(
          'Validate every row before submitting provider operations.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: B2BSpacing.lg),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Top-up')),
            ButtonSegment(value: true, label: Text('Activate')),
          ],
          selected: {_activation},
          onSelectionChanged: _submitting
              ? null
              : (value) => setState(() => _activation = value.first),
        ),
        const SizedBox(height: B2BSpacing.md),
        TextField(
          controller: _rows,
          minLines: 8,
          maxLines: 14,
          enabled: !_submitting,
          decoration: const InputDecoration(
            labelText: 'Operation rows',
            alignLabelWithHint: true,
            hintText:
                'ICCID,PACKAGE_ID,EMAIL,NAME,PHONE\n8944...,E-185-...,client@example.com,Client,555...',
          ),
        ),
        const SizedBox(height: B2BSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _submitting
                    ? null
                    : () => _submit(validateOnly: true),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Validate'),
              ),
            ),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: _submitting
                    ? null
                    : () => _submit(validateOnly: false),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: const Text('Submit'),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: B2BSpacing.md),
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: B2BSpacing.lg),
          Text(
            'Provider result',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: B2BSpacing.sm),
          SelectableText(
            const JsonEncoder.withIndent('  ').convert(_result!.data),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );
}
