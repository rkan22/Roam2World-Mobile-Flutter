import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'package_catalog.dart';
import 'packages_repository.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final _repository = PackagesRepository();
  final _searchController = TextEditingController();
  final _operators = const [
    ('All Operators', ''),
    ('Vodafone', 'vodafone'),
    ('Orange Europe', 'worldmove'),
    ('Orange World', 'orange-world'),
    ('KPN Europe', 'kpn'),
    ('T.T Turkey', 'turkey'),
    ('Orange Big Data', 'flexnet'),
    ('Orange Balkans', 'orange-balkans'),
    ('Manual Fulfillment', 'manual'),
  ];
  final _validityOptions = const [30, 60, 90];
  final _dataOptions = const [1,3,5,10,20,30,50,60,100,135,200,300,400,500];

  Timer? _searchTimer;
  List<MobilePackage> _packages = const [];
  String _selectedType = '';
  String _selectedOperator = '';
  int? _selectedValidity;
  num? _selectedData;
  bool _loading = true;
  bool _showingStaleData = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchTimer?.cancel(); _searchController.dispose(); super.dispose(); }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() { _loading = _packages.isEmpty; _error = null; });
    try {
      final catalog = await _repository.fetchPackages(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() { _packages = catalog.packages; _showingStaleData = _repository.lastFetchUsedStale; });
    } on ApiException catch (error) {
      if (!mounted) return; setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return; setState(() => _error = 'Packages could not be loaded.');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  List<MobilePackage> get _visiblePackages {
    final term = _searchController.text.trim().toLowerCase();
    return _packages.where((item) {
      if (_selectedOperator.isNotEmpty && item.operatorKey != _selectedOperator) return false;
      if (_selectedType.isNotEmpty && item.packageType.toLowerCase() != _selectedType) return false;
      if (_selectedValidity != null && item.validityDays != _selectedValidity) return false;
      if (_selectedData != null && item.dataGb != _selectedData) return false;
      if (term.isNotEmpty && ![item.name,item.destination,item.displayProvider,item.id,item.dataLabel,item.validityLabel].any((value) => value.toLowerCase().contains(term))) return false;
      return true;
    }).toList(growable: false);
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 250), () => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 1),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              if (_showingStaleData) ...[const _StaleDataBanner(), const SizedBox(height: 14)],
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('eSIM Marketplace', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 5),
                  Text('Choose the right plan for your customer in seconds.', style: theme.textTheme.bodyMedium),
                ])),
                IconButton.filledTonal(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_none_rounded)),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: B2BGradients.primary, borderRadius: BorderRadius.circular(B2BRadius.xl), boxShadow: B2BShadows.card),
                child: Row(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.public_rounded, color: Colors.white)),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Global coverage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Search local, regional and global reseller plans.', style: TextStyle(color: Colors.white70, height: 1.35)),
                  ])),
                ]),
              ),
              const SizedBox(height: 18),
              _CatalogFilterPanel(
                operators: _operators, validityOptions: _validityOptions, dataOptions: _dataOptions,
                operator: _selectedOperator, type: _selectedType, validity: _selectedValidity, data: _selectedData,
                searchController: _searchController,
                onOperatorChanged: (value) => setState(() => _selectedOperator = value),
                onTypeChanged: (value) => setState(() => _selectedType = value),
                onValidityChanged: (value) => setState(() => _selectedValidity = value),
                onDataChanged: (value) => setState(() => _selectedData = value),
                onSearchChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Plans', trailing: '${_visiblePackages.length} plans'),
              const SizedBox(height: 18),
              if (_loading) const ContentLoadingState(label: 'Loading packages...')
              else if (_error != null && _packages.isEmpty) ContentErrorState(message: _error!, onRetry: () => _load(forceRefresh: true))
              else if (_visiblePackages.isEmpty) ContentEmptyState(
                icon: Icons.inventory_2_outlined, title: 'No packages found', message: 'Try changing or clearing the catalog filters.', actionLabel: 'Clear filters',
                onAction: () { _searchController.clear(); setState(() { _selectedType=''; _selectedOperator=''; _selectedValidity=null; _selectedData=null; }); },
              )
              else for (var index = 0; index < _visiblePackages.length; index++) ...[
                _PackageTile(package: _visiblePackages[index], onTap: () => context.push('/packages/detail', extra: _visiblePackages[index])),
                if (index != _visiblePackages.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});
  final String title; final String trailing;
  @override Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
    Text(trailing, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
  ]);
}

class _CatalogFilterPanel extends StatelessWidget {
  const _CatalogFilterPanel({required this.operators, required this.validityOptions, required this.dataOptions, required this.operator, required this.type, required this.validity, required this.data, required this.searchController, required this.onOperatorChanged, required this.onTypeChanged, required this.onValidityChanged, required this.onDataChanged, required this.onSearchChanged});
  final List<(String,String)> operators; final List<int> validityOptions; final List<num> dataOptions; final String operator; final String type; final int? validity; final num? data; final TextEditingController searchController; final ValueChanged<String> onOperatorChanged; final ValueChanged<String> onTypeChanged; final ValueChanged<int?> onValidityChanged; final ValueChanged<num?> onDataChanged; final ValueChanged<String> onSearchChanged;
  @override Widget build(BuildContext context) {
    final theme=Theme.of(context);
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(B2BRadius.xl), border: Border.all(color: theme.colorScheme.outlineVariant), boxShadow: theme.brightness==Brightness.light?B2BShadows.card:null), child: Material(type: MaterialType.transparency, child: ExpansionTile(tilePadding: EdgeInsets.zero, childrenPadding: const EdgeInsets.only(top:8), initiallyExpanded:false, title: Text('Catalog filters', style: theme.textTheme.titleMedium), subtitle: Text('Operator, type, validity, data and search', style: theme.textTheme.bodySmall), children: [
      _FilterField(label:'Operator', child: DropdownButtonFormField<String>(key:ValueKey(operator), initialValue:operator, isExpanded:true, items:operators.map((item)=>DropdownMenuItem(value:item.$2, child:Text(item.$1))).toList(), onChanged:(value)=>onOperatorChanged(value??''))),
      const SizedBox(height:12),
      _FilterField(label:'Type', child: DropdownButtonFormField<String>(key:ValueKey(type), initialValue:type, isExpanded:true, items:const [DropdownMenuItem(value:'', child:Text('All Types')), DropdownMenuItem(value:'esim', child:Text('eSIM')), DropdownMenuItem(value:'simcard', child:Text('SIM Card'))], onChanged:(value)=>onTypeChanged(value??''))),
      const SizedBox(height:12),
      Row(children:[Expanded(child:_FilterField(label:'Validity', child:DropdownButtonFormField<String>(key:ValueKey('validity-$validity'), initialValue:validity?.toString()??'', isExpanded:true, items:[const DropdownMenuItem(value:'', child:Text('All')), ...validityOptions.map((item)=>DropdownMenuItem(value:'$item', child:Text('$item Days')))], onChanged:(value)=>onValidityChanged(int.tryParse(value??''))))), const SizedBox(width:10), Expanded(child:_FilterField(label:'Data', child:DropdownButtonFormField<String>(key:ValueKey('data-$data'), initialValue:data?.toString()??'', isExpanded:true, items:[const DropdownMenuItem(value:'', child:Text('All')), ...dataOptions.map((item)=>DropdownMenuItem(value:'$item', child:Text('${item}GB')))], onChanged:(value)=>onDataChanged(num.tryParse(value??'')))))]),
      const SizedBox(height:12),
      _FilterField(label:'Search', child:TextField(controller:searchController, onChanged:onSearchChanged, decoration:const InputDecoration(hintText:'Search', prefixIcon:Icon(Icons.search_rounded)))),
    ])));
  }
}

class _FilterField extends StatelessWidget { const _FilterField({required this.label, required this.child}); final String label; final Widget child; @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(label.toUpperCase(), style:Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight:FontWeight.w900, letterSpacing:.7)), const SizedBox(height:6), child]); }

class _StaleDataBanner extends StatelessWidget { const _StaleDataBanner(); @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:14, vertical:12), decoration:BoxDecoration(color:AppColors.warning.withValues(alpha:.12), borderRadius:BorderRadius.circular(16), border:Border.all(color:AppColors.warning.withValues(alpha:.4))), child:const Row(children:[Icon(Icons.cloud_off_rounded,size:19,color:AppColors.warning),SizedBox(width:10),Expanded(child:Text('Could not refresh. Showing the last available packages.',style:TextStyle(fontWeight:FontWeight.w700))) ])); }

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.package, required this.onTap}); final MobilePackage package; final VoidCallback onTap;
  @override Widget build(BuildContext context) { final theme=Theme.of(context); return Material(color:theme.colorScheme.surface,borderRadius:BorderRadius.circular(B2BRadius.xl),child:InkWell(borderRadius:BorderRadius.circular(B2BRadius.xl),onTap:onTap,child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(borderRadius:BorderRadius.circular(B2BRadius.xl),border:Border.all(color:theme.colorScheme.outlineVariant),boxShadow:theme.brightness==Brightness.light?B2BShadows.card:null),child:Column(children:[
    Row(children:[Container(height:54,width:54,alignment:Alignment.center,decoration:BoxDecoration(color:AppColors.primaryLight,borderRadius:BorderRadius.circular(17)),child:_CountryVisual(code:package.countryCode,destinationKey:package.destinationKey)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(package.destination,style:theme.textTheme.titleMedium?.copyWith(fontSize:16.5)),const SizedBox(height:3),Text(package.displayProvider,style:theme.textTheme.bodySmall)])),const SizedBox(width:10),Text(package.formattedPrice,style:theme.textTheme.titleMedium?.copyWith(color:AppColors.primary,fontSize:17))]),
    const SizedBox(height:14),
    Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),decoration:BoxDecoration(color:AppColors.surfaceMuted,borderRadius:BorderRadius.circular(16)),child:Row(children:[Expanded(child:_InlineMetric(icon:Icons.data_usage_rounded,value:package.dataLabel)),Container(width:1,height:26,color:AppColors.border),Expanded(child:_InlineMetric(icon:Icons.schedule_rounded,value:package.validityLabel)),Container(width:1,height:26,color:AppColors.border),const Expanded(child:_InlineMetric(icon:Icons.network_cell_rounded,value:'4G / 5G'))])),
    const SizedBox(height:14),
    Row(children:[Text('Reseller-ready plan',style:theme.textTheme.bodySmall?.copyWith(fontWeight:FontWeight.w700)),const Spacer(),FilledButton(onPressed:onTap,style:FilledButton.styleFrom(minimumSize:const Size(92,40),padding:const EdgeInsets.symmetric(horizontal:16)),child:const Text('View plan'))]),
  ])))); }
}

class _InlineMetric extends StatelessWidget { const _InlineMetric({required this.icon, required this.value}); final IconData icon; final String value; @override Widget build(BuildContext context)=>Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,size:16,color:AppColors.textSecondary),const SizedBox(width:5),Flexible(child:Text(value,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:12.5)))]); }

class _CountryVisual extends StatelessWidget {
  const _CountryVisual({required this.code, required this.destinationKey});
  final String code; final String destinationKey;
  @override Widget build(BuildContext context) {
    if (destinationKey.toLowerCase() == 'europe') {
      return Padding(padding:const EdgeInsets.all(6),child:Image.asset('assets/catalog/europe.png',width:42,height:42,fit:BoxFit.contain,errorBuilder:(context,error,stackTrace)=>const Icon(Icons.public_rounded,color:AppColors.primary,size:27)));
    }
    if (code.length != 2) return const Icon(Icons.public_rounded,color:AppColors.primary,size:27);
    return ClipRRect(borderRadius:BorderRadius.circular(6),child:Image.network('https://flagsapi.com/${code.toUpperCase()}/flat/64.png',width:34,height:24,fit:BoxFit.cover,errorBuilder:(context,error,stackTrace)=>const Icon(Icons.public_rounded,color:AppColors.primary,size:27)));
  }
}
"""
open("/mnt/data/packages_screen_modified.dart