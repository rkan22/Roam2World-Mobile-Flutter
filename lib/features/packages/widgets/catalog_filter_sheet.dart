import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../design_system/tokens/b2b_tokens.dart';
import '../package_catalog.dart';

class CatalogFilterSelection {
  const CatalogFilterSelection({
    this.operatorKey = '',
    this.packageType = '',
    this.countryCode = '',
    this.dataRange = '',
    this.validityRange = '',
  });

  final String operatorKey;
  final String packageType;
  final String countryCode;
  final String dataRange;
  final String validityRange;

  int get activeCount => [
    operatorKey,
    packageType,
    countryCode,
    dataRange,
    validityRange,
  ].where((value) => value.isNotEmpty).length;

  CatalogFilterSelection copyWith({
    String? operatorKey,
    String? packageType,
    String? countryCode,
    String? dataRange,
    String? validityRange,
  }) {
    return CatalogFilterSelection(
      operatorKey: operatorKey ?? this.operatorKey,
      packageType: packageType ?? this.packageType,
      countryCode: countryCode ?? this.countryCode,
      dataRange: dataRange ?? this.dataRange,
      validityRange: validityRange ?? this.validityRange,
    );
  }
}

class CatalogFilterToolbar extends StatelessWidget {
  const CatalogFilterToolbar({
    super.key,
    required this.searchController,
    required this.selection,
    required this.operatorLabel,
    required this.countryLabel,
    required this.onSearchChanged,
    required this.onFiltersPressed,
    required this.onClearAll,
  });

  final TextEditingController searchController;
  final CatalogFilterSelection selection;
  final String operatorLabel;
  final String countryLabel;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFiltersPressed;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (selection.operatorKey.isNotEmpty) operatorLabel,
      if (selection.packageType.isNotEmpty)
        selection.packageType == 'simcard' ? 'SIM Card' : 'eSIM',
      if (selection.countryCode.isNotEmpty) countryLabel,
      if (selection.dataRange.isNotEmpty) dataRangeLabel(selection.dataRange),
      if (selection.validityRange.isNotEmpty)
        validityRangeLabel(selection.validityRange),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search plans, operators, countries...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: onFiltersPressed,
              icon: const Icon(Icons.filter_list_rounded),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Filters'),
                  if (selection.activeCount > 0) ...[
                    const SizedBox(width: 7),
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${selection.activeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final label in labels)
                Chip(label: Text(label), visualDensity: VisualDensity.compact),
              TextButton(onPressed: onClearAll, child: const Text('Clear all')),
            ],
          ),
        ],
      ],
    );
  }
}

Future<CatalogFilterSelection?> showCatalogFilterSheet(
  BuildContext context, {
  required CatalogFilterSelection initialSelection,
  required List<(String, String)> operators,
  required List<PackageCountry> countries,
}) {
  return showModalBottomSheet<CatalogFilterSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CatalogFilterSheet(
      initialSelection: initialSelection,
      operators: operators,
      countries: countries,
    ),
  );
}

class _CatalogFilterSheet extends StatefulWidget {
  const _CatalogFilterSheet({
    required this.initialSelection,
    required this.operators,
    required this.countries,
  });

  final CatalogFilterSelection initialSelection;
  final List<(String, String)> operators;
  final List<PackageCountry> countries;

  @override
  State<_CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<_CatalogFilterSheet> {
  late CatalogFilterSelection _selection;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialSelection;
  }

  void _reset() {
    setState(() => _selection = const CatalogFilterSelection());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.only(top: 28),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(B2BRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Expanded(
                  child: Text(
                    'Filters',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterTitle(label: 'Product type'),
                  _ChoiceWrap(
                    values: const [
                      ('', 'All'),
                      ('esim', 'eSIM'),
                      ('simcard', 'SIM Card'),
                    ],
                    selected: _selection.packageType,
                    onSelected: (value) => setState(
                      () =>
                          _selection = _selection.copyWith(packageType: value),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FilterTitle(label: 'Country / Coverage'),
                  DropdownButtonFormField<String>(
                    initialValue: _selection.countryCode,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All countries'),
                      ),
                      for (final country in widget.countries)
                        DropdownMenuItem(
                          value: country.code,
                          child: Text(country.name),
                        ),
                    ],
                    onChanged: (value) => setState(
                      () => _selection = _selection.copyWith(
                        countryCode: value ?? '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FilterTitle(label: 'Data allowance'),
                  _ChoiceWrap(
                    values: const [
                      ('', 'Any'),
                      ('1-5', '1 – 5 GB'),
                      ('6-20', '6 – 20 GB'),
                      ('21-50', '21 – 50 GB'),
                      ('51-100', '51 – 100 GB'),
                      ('101-200', '101 – 200 GB'),
                      ('200+', '200+ GB'),
                    ],
                    selected: _selection.dataRange,
                    onSelected: (value) => setState(
                      () => _selection = _selection.copyWith(dataRange: value),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FilterTitle(label: 'Validity'),
                  _ChoiceWrap(
                    values: const [
                      ('', 'Any'),
                      ('1-7', '1 – 7 Days'),
                      ('8-30', '8 – 30 Days'),
                      ('31-90', '31 – 90 Days'),
                      ('91-180', '91 – 180 Days'),
                      ('180+', '180+ Days'),
                    ],
                    selected: _selection.validityRange,
                    onSelected: (value) => setState(
                      () => _selection = _selection.copyWith(
                        validityRange: value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FilterTitle(label: 'Operator'),
                  DropdownButtonFormField<String>(
                    initialValue: _selection.operatorKey,
                    isExpanded: true,
                    items: widget.operators
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.$2,
                            child: Text(item.$1),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => _selection = _selection.copyWith(
                        operatorKey: value ?? '',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selection),
                child: Text(
                  _selection.activeCount == 0
                      ? 'Apply filters'
                      : 'Apply filters (${_selection.activeCount})',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
    ),
  );
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String)> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in values)
          ChoiceChip(
            label: Text(item.$2),
            selected: selected == item.$1,
            onSelected: (_) => onSelected(item.$1),
          ),
      ],
    );
  }
}

String dataRangeLabel(String value) => switch (value) {
  '1-5' => '1 – 5 GB',
  '6-20' => '6 – 20 GB',
  '21-50' => '21 – 50 GB',
  '51-100' => '51 – 100 GB',
  '101-200' => '101 – 200 GB',
  '200+' => '200+ GB',
  _ => '',
};

String validityRangeLabel(String value) => switch (value) {
  '1-7' => '1 – 7 Days',
  '8-30' => '8 – 30 Days',
  '31-90' => '31 – 90 Days',
  '91-180' => '91 – 180 Days',
  '180+' => '180+ Days',
  _ => '',
};

bool matchesDataRange(num? value, String range) {
  if (range.isEmpty) return true;
  if (value == null) return false;

  return switch (range) {
    '1-5' => value >= 1 && value <= 5,
    '6-20' => value >= 6 && value <= 20,
    '21-50' => value >= 21 && value <= 50,
    '51-100' => value >= 51 && value <= 100,
    '101-200' => value >= 101 && value <= 200,
    '200+' => value > 200,
    _ => true,
  };
}

bool matchesValidityRange(int? value, String range) {
  if (range.isEmpty) return true;
  if (value == null) return false;

  return switch (range) {
    '1-7' => value >= 1 && value <= 7,
    '8-30' => value >= 8 && value <= 30,
    '31-90' => value >= 31 && value <= 90,
    '91-180' => value >= 91 && value <= 180,
    '180+' => value > 180,
    _ => true,
  };
}
