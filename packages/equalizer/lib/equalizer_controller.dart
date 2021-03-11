import 'package:equalizer/equalizer.dart';
import 'package:flutter/material.dart';

class Preset {
  Preset(this.index, this.name);

  final int index;
  final String name;
}

class BandLevelRange {
  BandLevelRange(this.min, this.max);

  final double min, max;
}

class BandData {
  BandData(this.centerBandFrequencyList, this.bandLevelRange);

  List<int> centerBandFrequencyList = [];
  BandLevelRange bandLevelRange;
}

class EqualizerController {
  EqualizerController({required int audioSessionId}) {
    this.init(audioSessionId);
  }

  init(int audioSessionId) async {
    await Equalizer.init(audioSessionId);
    await _notifyInitialData();
  }

  ValueNotifier<List<Preset>> equalizerPresetNotifier =
      ValueNotifier<List<Preset>>([]);
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
    final bandLevelRange = BandLevelRange(
        bandLevelRangeList[0].toDouble(), bandLevelRangeList[1].toDouble());

    return BandData(centerBandFrequencyList, bandLevelRange);
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

  _notifyCurrentPresetPosition() async {
    final currentPreset = await Equalizer.getCurrentPreset();
    currentPresetPositionNotifier.value = currentPreset;
  }

  _notifyPresetNames() async {
    final presetNames = await (Equalizer.getPresetNames());
    var presetList = presetNames
        .map((name) => Preset(presetNames.indexOf(name), name))
        .toList();
    equalizerPresetNotifier.value = presetList;
  }

  _notifyIsEnabled() async {
    final isEnabled = await Equalizer.isEnabled();
    enabledNotifier.value = isEnabled;
  }
}
