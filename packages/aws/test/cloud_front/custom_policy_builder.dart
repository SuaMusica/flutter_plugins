import 'package:smaws/src/cloud_front/custom_policy_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final resource = 'https://android.suamusica.com.br*';
  final expiresOn = DateTime.parse('2022-10-13T09:05:00Z');
  final activeFrom = DateTime.parse('2019-01-01T00:00:00Z');
  final ipRange = '*';

  group('Custom Policy Builder Test Suit', () {
    test('Resource must not be null', () {
      final subject = CustomPolicyBuilder();
      expect(() => subject.build(null, null, null, null), throwsArgumentError);
    });

    test('Expires on must not be null', () {
      final subject = CustomPolicyBuilder();
      expect(() => subject.build(resource, null, null, null), throwsArgumentError);
    });

    test('Test success policy build', () {
      final subject = CustomPolicyBuilder();
      final policy = subject.build(resource, expiresOn, null, null);
      expect(policy, '{"Statement":[{"Resource":"https://android.suamusica.com.br*","Condition":{"DateLessThan":{"AWS:EpochTime":1665651900}}}]}');
    });

    test('Test activeFrom being used', () {
      final subject = CustomPolicyBuilder();
      final policy = subject.build(resource, expiresOn, activeFrom, null);
      expect(policy, '{"Statement":[{"Resource":"https://android.suamusica.com.br*","Condition":{"DateLessThan":{"AWS:EpochTime":1665651900},"DateGreaterThan":{"AWS:EpochTime":1546300800}}}]}');
    });

    test('Test ipRange being used', () {
      final subject = CustomPolicyBuilder();
      final policy = subject.build(resource, expiresOn, activeFrom, ipRange);
      expect(policy, '{"Statement":[{"Resource":"https://android.suamusica.com.br*","Condition":{"DateLessThan":{"AWS:EpochTime":1665651900},"IpAddress":{"AWS:SourceIp":"*"},"DateGreaterThan":{"AWS:EpochTime":1546300800}}}]}');
    });
  });

}
