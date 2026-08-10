import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'admin_whatsapp_data.dart';

class AdminWhatsAppRepository {
  AdminWhatsAppRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AdminWhatsAppData> fetch() => _apiClient.get<AdminWhatsAppData>(
    ApiEndpoints.mobileAdminWhatsApp,
    parser: AdminWhatsAppData.fromResponse,
  );

  Future<AdminWhatsAppData> updateFeatured(
    List<WhatsAppCatalogItem> catalog,
    Map<String, bool> featured,
  ) => _apiClient.post<AdminWhatsAppData>(
    ApiEndpoints.mobileAdminWhatsApp,
    data: {
      'catalog': catalog
          .map(
            (item) => item.toUpdateJson(
              featured: featured[item.packageId] ?? item.featured,
            ),
          )
          .toList(growable: false),
    },
    parser: AdminWhatsAppData.fromResponse,
  );
}
