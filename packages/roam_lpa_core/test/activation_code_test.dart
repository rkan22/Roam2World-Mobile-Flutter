import 'package:flutter_test/flutter_test.dart';
import 'package:roam_lpa_core/roam_lpa_core.dart';

void main() {
  test('parses canonical activation code', () {
    final code = LpaActivationCode.parse(r'LPA:1$smdp.example$MATCH123');
    expect(code.smdpAddress, 'smdp.example');
    expect(code.matchingId, 'MATCH123');
    expect(code.canonical, r'LPA:1$smdp.example$MATCH123');
  });

  test('normalizes lowercase prefix and confirmation code', () {
    final code = LpaActivationCode.parse(r'lpa:1$smdp.example$MATCH123$9876');
    expect(code.confirmationCode, '9876');
    expect(code.canonical, r'LPA:1$smdp.example$MATCH123$9876');
  });

  test('rejects incomplete code', () {
    expect(
      () => LpaActivationCode.parse(r'LPA:1$smdp.example'),
      throwsFormatException,
    );
  });
}
