import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equalizer/equalizer.dart';

void main() {
  const MethodChannel channel = MethodChannel('equalizer');

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
    expect(await Equalizer.platformVersion, '42');
  });
}