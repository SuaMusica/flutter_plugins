import 'dart:async';

import 'package:equalizer/equalizer_controller.dart';
import 'package:flutter/services.dart';

enum CONTENT_TYPE { MUSIC, MOVIE, GAME, VOICE }

class Equalizer {
  static const MethodChannel _channel = const MethodChannel('equalizer');

  static const String _METHOD_CHANNEL_EXTERNAL_PRESETS_PREFIX =
      "external.presets.";
  static const String _METHOD_CHANNEL_DEFAULT_PREFIX = "";
  static String _methodChannelPrefix = _METHOD_CHANNEL_DEFAULT_PREFIX;

  /// Open's the device equalizer.
  ///
  /// - [audioSessionId] enable audio effects for the current session.
  /// - [contentType] optional parameter. Defaults to [CONTENT_TYPE.MUSIC]
  ///
  /// [android]:
  /// https://developer.android.com/reference/android/media/MediaPlayer#getAudioSessionId()
  static Future open(int audioSessionId,
      [CONTENT_TYPE contentType = CONTENT_TYPE.MUSIC]) async {
    return await _channel.invokeMethod(
      appendMethodPrefix('open'),
      {'audioSessionId': audioSessionId, 'contentType': contentType.index},
    );
  }

  /// Set [audioSessionId] for equalizer.
  ///
  /// [android]:
  /// https://developer.android.com/reference/android/media/MediaPlayer#getAudioSessionId()
  static Future<void> setAudioSessionId(int audioSessionId) async {
    await _channel.invokeMethod(
        appendMethodPrefix('setAudioSessionId'), audioSessionId);
  }

  /// Remove current [audioSessionId] for equalizer.
  static Future<void> removeAudioSessionId(int audioSessionId) async {
    await _channel.invokeMethod(
        appendMethodPrefix('removeAudioSessionId'), audioSessionId);
  }

  /// Initialize a custom equalizer.
  ///
  /// [audioSessionId] enable audio effects for the current session.
  static Future<void> initWithPresets(EQInit initialization) async {
    _methodChannelPrefix = _METHOD_CHANNEL_EXTERNAL_PRESETS_PREFIX;
    await _channel.invokeMethod(
        appendMethodPrefix('init'), initialization.toPlatformInput());
  }

  /// Initialize a custom equalizer.
  ///
  /// [audioSessionId] enable audio effects for the current session.
  static Future<void> init(int audioSessionId) async {
    _methodChannelPrefix = _METHOD_CHANNEL_DEFAULT_PREFIX;
    await _channel.invokeMethod(appendMethodPrefix('init'), audioSessionId);
  }

  /// Release the custom equalizer resources.
  static Future<void> release() async {
    await _channel.invokeMethod(appendMethodPrefix('release'));
  }

  /// Enable/disable a custom equalizer.
  static Future<void> setEnabled(bool enabled) async {
    await _channel.invokeMethod(appendMethodPrefix('enable'), enabled);
  }

  static Future<bool> isEnabled() async {
    return await _channel.invokeMethod(appendMethodPrefix('isEnabled')) ??
        false;
  }

  /// Returns the band level range in a list of integers represented in [dB].
  /// The first element is
  /// the lower limit of the range, the second element the upper limit.
  static Future<List<int>> getBandLevelRange() async {
    return (await _channel
            .invokeMethod(appendMethodPrefix('getBandLevelRange')))
        .cast<int>();
  }

  /// Returns the band level in [dB].
  static Future<int> getBandLevel(int bandId) async {
    return await _channel.invokeMethod(
            appendMethodPrefix('getBandLevel'), bandId) ??
        0;
  }

  /// Set the band level for a custom equalizer.
  ///
  /// - [bandId] can be retrieved from [getCenterBandFreqs]
  /// - [level] can be retrieved from [getBandLevel]
  static Future<void> setBandLevel(int bandId, int level) async {
    // The level retrieved here is in dB. The native platform requires
    // the level in millibels.
    await _channel.invokeMethod(
      appendMethodPrefix('setBandLevel'),
      {'bandId': bandId, 'level': level},
    );
  }

  /// Returns the center band frequencies in milliHertz.
  static Future<List<int>> getCenterBandFreqs() async {
    return (await _channel
                .invokeMethod(appendMethodPrefix('getCenterBandFreqs')))
            .cast<int>() ??
        [];
  }

  /// Returns the preset names available on device.
  static Future<List<String>> getPresetNames() async {
    return (await _channel.invokeMethod(appendMethodPrefix('getPresetNames')))
            .cast<String>() ??
        [];
  }

  /// Set the preset name.
  static Future<void> setPreset(String presetName) async {
    await _channel.invokeMethod(appendMethodPrefix('setPreset'), presetName);
  }

  /// Get current preset.
  static Future<int> getCurrentPreset() async {
    return (await _channel
            .invokeMethod(appendMethodPrefix('getCurrentPreset'))) ??
        0;
  }

  static Future<bool> deviceHasEqualizer(int audioSessionId) async {
    return await _channel.invokeMethod(
          appendMethodPrefix('deviceHasEqualizer'),
          {'audioSessionId': audioSessionId},
        ) ??
        false;
  }

  static String appendMethodPrefix(String method) {
    return _methodChannelPrefix + method;
  }

  static void vibrate(int milliseconds, int amplitude) async {
    _channel.invokeMethod(appendMethodPrefix('vibrate'), {
      'milliseconds': milliseconds,
      'amplitude': amplitude,
    });
  }
}
