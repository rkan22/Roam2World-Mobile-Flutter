import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/profile/profile_repository.dart';

void main() {
  test('mobile user profile parses nested backend response', () {
    final profile = MobileUserProfile.fromResponse({
      'success': true,
      'data': {
        'user': {
          'id': 42,
          'email': 'partner@example.com',
          'first_name': 'Roam',
          'last_name': 'Partner',
          'role': 'reseller',
          'country_code': '+90',
          'phone_number': '5550000000',
          'profile': {'country': 'TR'},
        },
      },
    });

    expect(profile.id, 42);
    expect(profile.fullName, 'Roam Partner');
    expect(profile.profile['country'], 'TR');
  });
}
