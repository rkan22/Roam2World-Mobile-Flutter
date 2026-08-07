import 'package:roam_lpa_core/roam_lpa_core.dart';
import 'package:test/test.dart';

void main() {
  test('parses canonical activation code', () {
    final code = LpaActivationCode.parse('LPA:1$smdp.example$MATCH123');
    expect(code.smdpAddress, 'smdp.example');
    expect(code.matchingId, 'MATCH123');
    expect(code.canonical, 'LPA:1$smdp.example$MATCH123');
  });

  test('normalizes lowercase prefix and confirmation code', () {
    final code = LpaActivationCode.parse('lpa:1$smdp.example$MATCH123$9876');
    expect(code.confirmationCode, '9876');
    expect(code.canonical, 'LPA:1$smdp.example$MATCH123$9876');
  });

  test('rejects incomplete code', () {
    expect(() => LpaActivationCode.parse('LPA:1$smdp.example'), throwsFormatException);
  });
}
