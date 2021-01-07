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
    var equalizerPresetNotifier = _equalizerController.equalizerPresetNotifier;
    var enabledNotifier = _equalizerController.enabledNotifier;
    var bandLevelNotifier = _equalizerController.bandLevelNotifier;

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
        )
      ],
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EqualizerSwitch(
              _equalizerController,
              titleDisabled: this.titleDisabled,
              titleEnabled: this.titleEnabled,
            ),
            EqualizerPresetList(
              _equalizerController,
              context.select((ValueNotifier<List<Preset>> n) => n.value),
              context.select((ValueNotifier<bool> n) => n.value),
            ),
            EqualizerBandSlideGroup(_equalizerController),
          ],
        );
      },
    );
  }
}
