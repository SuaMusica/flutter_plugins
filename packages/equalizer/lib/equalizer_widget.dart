import 'package:equalizer/equalizer_band_slide.dart';
import 'package:equalizer/equalizer_controller.dart';
import 'package:equalizer/equalizer_preset_list.dart';
import 'package:equalizer/equalizer_switch.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EqualizerWidget extends StatelessWidget {
  EqualizerWidget(
    this._equalizerController, {
    this.titleDisabled,
    this.titleEnabled,
  });

  final EqualizerController _equalizerController;
  final Widget titleDisabled;
  final Widget titleEnabled;

  @override
  Widget build(BuildContext context) {
    final equalizerPresetNotifier = _equalizerController.equalizerPresetNotifier;
    final enabledNotifier = _equalizerController.enabledNotifier;
    final bandLevelNotifier = _equalizerController.bandLevelNotifier;
    final currentPresetPositionNotifier = _equalizerController.currentPresetPositionNotifier;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ValueNotifier<List<Preset>>>.value(
          value: equalizerPresetNotifier,
        ),
        ChangeNotifierProvider<ValueNotifier<bool>>.value(
          value: enabledNotifier,
        ),
        ChangeNotifierProvider<ValueNotifier<List<int>>>.value(
          value: bandLevelNotifier,
        ),
        ChangeNotifierProvider<ValueNotifier<int>>.value(
          value: currentPresetPositionNotifier,
        ),
      ],
      builder: (context, _) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EqualizerSwitch(
                _equalizerController,
                titleDisabled: this.titleDisabled,
                titleEnabled: this.titleEnabled,
              ),
              EqualizerPresetList(_equalizerController),
              EqualizerBandSlideGroup(_equalizerController),
              SizedBox(height: 40,)
            ],
          ),
        );
      },
    );
  }
}
