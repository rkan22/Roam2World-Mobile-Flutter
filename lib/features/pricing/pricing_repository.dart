import '../../core/api/api_client.dart';
import '../packages/package_catalog.dart';
import '../packages/packages_repository.dart';
import '../partners/dealer_network_data.dart';
import '../partners/dealer_network_repository.dart';
import 'pricing_rule.dart';

class PricingWorkspaceData {
  const PricingWorkspaceData({required this.rules, required this.dealers, required this.packages});
  final List<PricingRule> rules;
  final List<DealerSummary> dealers;
  final List<MobilePackage> packages;
}

class PricingRepository {
  PricingRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient;

  Future<PricingWorkspaceData> fetchWorkspace() async {
    final rulesFuture = _apiClient.get<List<PricingRule>>(
      '/api/v1/pricing-rules/',
      parser: pricingRulesFromResponse,
    );
    final dealersFuture = DealerNetworkRepository(apiClient: _apiClient).fetchNetwork();
    final packagesFuture = PackagesRepository(apiClient: _apiClient).fetchPackages();
    final results = await Future.wait([rulesFuture, dealersFuture, packagesFuture]);
    return PricingWorkspaceData(
      rules: results[0] as List<PricingRule>,
      dealers: (results[1] as DealerNetworkData).dealers,
      packages: (results[2] as PackageCatalog).packages,
    );
  }

  Future<PricingRule> createRule({
    required int dealerId,
    required String provider,
    String? packageId,
    required double markup,
    double? minMarkup,
    double? maxMarkup,
    int priority = 0,
  }) {
    return _apiClient.post<PricingRule>(
      '/api/v1/pricing-rules/',
      data: {
        'provider': provider,
        'package_id': packageId?.isEmpty == true ? null : packageId,
        'dealer': dealerId,
        'target_role': 'dealer',
        'markup_percentage': markup,
        'min_markup_percentage': minMarkup,
        'max_markup_percentage': maxMarkup,
        'priority': priority,
        'is_active': true,
      },
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        final data = root['data'] is Map ? Map<String, dynamic>.from(root['data'] as Map) : root;
        return PricingRule.fromJson(data);
      },
    );
  }

  Future<PricingRule> updateRule(PricingRule rule, {required double markup}) {
    return _apiClient.patch<PricingRule>(
      '/api/v1/pricing-rules/${rule.id}/',
      data: {'markup_percentage': markup, 'target_role': 'dealer'},
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        final data = root['data'] is Map ? Map<String, dynamic>.from(root['data'] as Map) : root;
        return PricingRule.fromJson(data);
      },
    );
  }

  Future<void> deleteRule(int id) => _apiClient.delete('/api/v1/pricing-rules/$id/');
}
