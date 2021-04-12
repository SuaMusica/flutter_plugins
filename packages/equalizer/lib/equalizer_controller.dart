import 'package:equalizer/equalizer.dart';
import 'package:flutter/material.dart';

class EQBand {
  EQBand({
    this.desiredLevel,
    required this.levelPercent,
  });

  /// if desired level is between android band level range, its will be used
  int? desiredLevel;

  /// if desired level is not between android band level range,
  /// this attribute will be used to keep compatibility between
  /// the android devices
  int levelPercent;

  Map<String, dynamic> toPlatformInput() {
    return {
      'band.desired_level': desiredLevel,
      'band.level_percent': levelPercent,
    };
  }
}

class EQPreset {
  EQPreset({
    required this.name,
    required this.bands,
  });

  String name;
  List<EQBand> bands;

  Map<String, dynamic> toPlatformInput() {
    return {
      'preset.name': name,
      'preset.bands': bands.map((e) => e.toPlatformInput()).toList(),
    };
  }
}

class EQInit {
  EQInit({
    required this.sessionId,
    required this.presets,
  });

  int sessionId;
  List<EQPreset> presets;

  Map<String, dynamic> toPlatformInput() {
    return {
      'session_id': sessionId,
      'presets': presets.map((e) => e.toPlatformInput()).toList(),
    };
  }
}

class PresetData {
  PresetData(this.index, this.name);

  final int index;
  final String name;
}

class BandLevelRangeData {
  BandLevelRangeData(this.min, this.max);

  final double min, max;
}

class BandData {
  BandData(this.centerBandFrequencyList, this.bandLevelRange);

  List<int> centerBandFrequencyList;
  BandLevelRangeData bandLevelRange;
}

class EqualizerController {
  EqualizerController({required int audioSessionId}) {
    this._init(audioSessionId);
  }

  EqualizerController.withPresets({
    required EQInit eqInit
  }) {
    this._initWithPresets(eqInit);
  }

  late int sessionId;

  _init(int audioSessionId) async {
    this.sessionId = audioSessionId;
    await Equalizer.init(audioSessionId);
    await _notifyInitialData();
  }

  _initWithPresets(EQInit eqInit) async {
    this.sessionId = eqInit.sessionId;
    await Equalizer.initWithPresets(eqInit);
    await _notifyInitialData();
  }

  ValueNotifier<List<PresetData>> equalizerPresetNotifier =
      ValueNotifier<List<PresetData>>([]);
  ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(false);
  ValueNotifier<List<int>> bandLevelNotifier = ValueNotifier<List<int>>([]);
  ValueNotifier<int> currentPresetPositionNotifier = ValueNotifier<int>(0);

  Future _notifyInitialData() async {
    await _notifyPresetNames();
    await _notifyCurrentPresetPosition();
    await _notifyIsEnabled();
    await _notifyBandLevel();
  }

  Future _notifyBandLevel() async {
    final centerBandFrequencyList = await (Equalizer.getCenterBandFreqs());
    final List<int> bandLevelList = [];
    for (var i = 0; i < centerBandFrequencyList.length; i++) {
      final bandLevel = await Equalizer.getBandLevel(i);
      bandLevelList.add(bandLevel);
    }
    bandLevelNotifier.value = bandLevelList;
  }

  Future<BandData> getBandData() async {
    final centerBandFrequencyList = await Equalizer.getCenterBandFreqs();
    final bandLevelRangeList = await (Equalizer.getBandLevelRange());
    final bandLevelRange = BandLevelRangeData(
        bandLevelRangeList[0].toDouble(), bandLevelRangeList[1].toDouble());

    return BandData(centerBandFrequencyList, bandLevelRange);
  }

  Future<bool> deviceHasEqualizer() async {
    return Equalizer.deviceHasEqualizer(sessionId);
  }

  Future<bool> isEnabled() async {
    return Equalizer.isEnabled();
  }

  Future setEnabled(bool value) async {
    await Equalizer.setEnabled(value);
    enabledNotifier.value = value;
  }

  Future setBandLevel(int bandId, int level) async {
    await Equalizer.setBandLevel(bandId, level);
    await _notifyCurrentPresetPosition();
  }

  Future<void> setPreset(String presetName) async {
    await Equalizer.setPreset(presetName);
    await _notifyBandLevel();
  }

  Future<void> vibrate(int milliseconds, int amplitude) async {
    Equalizer.vibrate(milliseconds, amplitude);
  }

  _notifyCurrentPresetPosition() async {
    final currentPreset = await Equalizer.getCurrentPreset();
    currentPresetPositionNotifier.value = currentPreset;
  }

  _notifyPresetNames() async {
    final presetNames = await (Equalizer.getPresetNames());
    var presetList = presetNames
        .map((name) => PresetData(presetNames.indexOf(name), name))
        .toList();
    equalizerPresetNotifier.value = presetList;
  }

  _notifyIsEnabled() async {
    final isEnabled = await Equalizer.isEnabled();
    enabledNotifier.value = isEnabled;
  }
}
