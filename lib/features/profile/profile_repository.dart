import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class MobileUserProfile {
  const MobileUserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.countryCode,
    required this.phoneNumber,
    required this.profile,
    required this.isActive,
    this.createdAt,
    this.lastLogin,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String countryCode;
  final String phoneNumber;
  final Map<String, dynamic> profile;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  String get fullName => '$firstName $lastName'.trim();

  factory MobileUserProfile.fromResponse(dynamic response) {
    final root = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;
    return MobileUserProfile(
      id: int.tryParse('${user['id'] ?? 0}') ?? 0,
      email: (user['email'] ?? '').toString(),
      firstName: (user['first_name'] ?? '').toString(),
      lastName: (user['last_name'] ?? '').toString(),
      role: (user['role'] ?? '').toString(),
      countryCode: (user['country_code'] ?? '').toString(),
      phoneNumber: (user['phone_number'] ?? '').toString(),
      profile: user['profile'] is Map
          ? Map<String, dynamic>.from(user['profile'] as Map)
          : const {},
      isActive: user['is_active'] != false,
      createdAt: DateTime.tryParse(
        (user['created_at'] ?? user['date_joined'] ?? '').toString(),
      ),
      lastLogin: DateTime.tryParse((user['last_login'] ?? '').toString()),
    );
  }
}

class ProfileRepository {
  ProfileRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<MobileUserProfile> fetchProfile() => _apiClient.get<MobileUserProfile>(
    ApiEndpoints.userProfile,
    parser: MobileUserProfile.fromResponse,
  );

  Future<MobileUserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? countryCode,
    String? phoneNumber,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) => _apiClient.patch<MobileUserProfile>(
    ApiEndpoints.updateUserProfile,
    data: {
      if (firstName != null) 'first_name': firstName.trim(),
      if (lastName != null) 'last_name': lastName.trim(),
      if (countryCode != null) 'country_code': countryCode.trim(),
      if (phoneNumber != null) 'phone_number': phoneNumber.trim(),
      if (address != null) 'address': address.trim(),
      if (city != null) 'city': city.trim(),
      if (state != null) 'state': state.trim(),
      if (country != null) 'country': country.trim(),
      if (postalCode != null) 'postal_code': postalCode.trim(),
    },
    parser: MobileUserProfile.fromResponse,
  );

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) => _apiClient.post<void>(
    ApiEndpoints.passwordChange,
    data: {
      'old_password': oldPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    },
    parser: (_) {},
  );
}
