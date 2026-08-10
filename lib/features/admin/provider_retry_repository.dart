import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'provider_retry_data.dart';

class ProviderRetryRepository {
  ProviderRetryRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ProviderRetryQueueData> fetchQueue({
    String? status,
    bool dueOnly = false,
  }) {
    final query = <String, dynamic>{
      'limit': 100,
      if (status != null && status.isNotEmpty) 'status': status,
      if (dueOnly) 'due': true,
    };
    return _apiClient.get<ProviderRetryQueueData>(
      ApiEndpoints.mobileAdminProviderRetryQueue,
      queryParameters: query,
      parser: ProviderRetryQueueData.fromResponse,
    );
  }

  Future<ProviderRetryItem> triggerRetry(int itemId, {String? note}) {
    return _action(
      itemId,
      action: 'trigger_retry',
      note: note,
    );
  }

  Future<ProviderRetryItem> scheduleRetry(
    int itemId, {
    required int minutes,
    String? note,
  }) {
    return _action(
      itemId,
      action: 'schedule_retry',
      note: note,
      extra: {'minutes': minutes},
    );
  }

  Future<ProviderRetryItem> resolve(int itemId, {String? note}) {
    return _action(itemId, action: 'resolve', note: note);
  }

  Future<ProviderRetryItem> cancel(int itemId, {String? note}) {
    return _action(itemId, action: 'cancel', note: note);
  }

  Future<ProviderRetryItem> _action(
    int itemId, {
    required String action,
    String? note,
    Map<String, dynamic> extra = const {},
  }) {
    return _apiClient.post<ProviderRetryItem>(
      ApiEndpoints.mobileAdminProviderRetryAction(itemId),
      data: {
        'action': action,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        ...extra,
      },
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        final data = root['data'] is Map
            ? Map<String, dynamic>.from(root['data'] as Map)
            : root;
        return ProviderRetryItem.fromJson(data);
      },
    );
  }
}
