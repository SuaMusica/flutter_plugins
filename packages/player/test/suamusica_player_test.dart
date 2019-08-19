import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suamusica_player/player.dart';

void main() {
  const MethodChannel channel = MethodChannel('suamusica_player');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Player.platformVersion, '42');
  });
}
