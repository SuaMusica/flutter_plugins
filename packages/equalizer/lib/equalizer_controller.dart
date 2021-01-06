import 'package:equalizer/equalizer.dart';
import 'package:flutter/material.dart';

class DataNotifier<T> extends ChangeNotifier {
  DataNotifier({this.data});

  T data;

  setData(T presets) {
    this.data = presets;
    this.notifyListeners();
  }

  notify() {
    notifyListeners();
  }
}

class Preset {
  Preset(this.index, this.name, this.checked);

  final int index;
  final String name;
  final bool checked;
}

class BandLevelRange {
  BandLevelRange(this.min, this.max);

  final double min, max;
}

class BandData {
  BandData(this.centerBandFrequencyList, this.bandLevelRange);

  List<int> centerBandFrequencyList;
  BandLevelRange bandLevelRange;
}

class EqualizerController {
  init(int audioSessionId) async {
    await Equalizer.init(audioSessionId);
    await _notifyInitialData();
  }

  DataNotifier equalizerPresetNotifier = DataNotifier<List<Preset>>(data: []);
  DataNotifier enabledNotifier = DataNotifier<bool>(data: false);
  DataNotifier bandLevelNotifier = DataNotifier<List<int>>(data: []);

  Future _notifyInitialData() async {
    await _notifyPresetNames();
    await _notifyIsEnabled();
    await _notifyBandLevel();
  }

  Future _notifyBandLevel() async {
    final centerBandFrequencyList = await Equalizer.getCenterBandFreqs();
    final List<int> bandLevelList = [];
    for (var i = 0; i < centerBandFrequencyList.length; i++) {
      final bandLevel = await Equalizer.getBandLevel(i);
      bandLevelList.add(bandLevel);
    }
    bandLevelNotifier.setData(bandLevelList);
  }

  Future<BandData> getBandData() async {
    final centerBandFrequencyList = await Equalizer.getCenterBandFreqs();
    final bandLevelRangeList = await Equalizer.getBandLevelRange();
    final bandLevelRange = BandLevelRange(
        bandLevelRangeList[0].toDouble(), bandLevelRangeList[1].toDouble());

    return BandData(centerBandFrequencyList, bandLevelRange);
  }

  Future<bool> isEnabled() async {
    return Equalizer.isEnabled();
  }

  Future setEnabled(bool value) async {
    await Equalizer.setEnabled(value);
    enabledNotifier.setData(value);
  }

  Future setBandLevel(int bandId, int level) async {
    await Equalizer.setBandLevel(bandId, level);
    await _notifyPresetNames();
  }

  Future<void> setPreset(String presetName) async {
    await Equalizer.setPreset(presetName);
    await _notifyBandLevel();
  }

  Future<int> getCurrentPresetPosition() async {
    return Equalizer.getCurrentPreset();
  }

  _notifyPresetNames() async {
    final currentPreset = await Equalizer.getCurrentPreset();
    final presetNames = await Equalizer.getPresetNames();
    final currentPresetName = presetNames[currentPreset];
    var presetList = presetNames
        .map((name) =>
            Preset(presetNames.indexOf(name), name, name == currentPresetName))
        .toList();
    equalizerPresetNotifier.setData(presetList);
  }

  _notifyIsEnabled() async {
    final isEnabled = await Equalizer.isEnabled();
    enabledNotifier.setData(isEnabled);
  }
}
