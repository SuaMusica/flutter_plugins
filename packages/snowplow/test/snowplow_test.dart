import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowplow/snowplow.dart';

void main() {
  const MethodChannel channel = MethodChannel('snowplow');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Snowplow.platformVersion, '42');
  });
}
