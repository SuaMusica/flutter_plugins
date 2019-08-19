import 'dart:typed_data';

import 'package:aws/src/cloud_front/default_content_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Default Content Cleaner Test Suit', () {
    test('Making a simple content Url Safer', () {
      final subject = DefaultContentCleaner();
      final input = Uint8List.fromList('Sample'.codeUnits);
      final result = subject.makeBytesUrlSafe(input);
      expect(result, 'U2FtcGxl');
    });

    test('Policy Content shall be cleaned', () {
      final subject = DefaultContentCleaner();
      final input = Uint8List.fromList('{"Statement":[{"Resource":"https://android.suamusica.com.br*","Condition":{"DateLessThan":{"AWS:EpochTime":1665651900},"IpAddress":{"AWS:SourceIp":"*"},"DateGreaterThan":{"AWS:EpochTime":1546300800}}}]}'.codeUnits);
      final result = subject.makeBytesUrlSafe(input);
      expect(result, 'eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9hbmRyb2lkLnN1YW11c2ljYS5jb20uYnIqIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoxNjY1NjUxOTAwfSwiSXBBZGRyZXNzIjp7IkFXUzpTb3VyY2VJcCI6IioifSwiRGF0ZUdyZWF0ZXJUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE1NDYzMDA4MDB9fX1dfQ__');
    });
  });
}
