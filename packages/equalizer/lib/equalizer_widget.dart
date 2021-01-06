
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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataNotifier<List<Preset>>>.value(
          value: equalizerPresetNotifier,
        ),
        ChangeNotifierProvider<DataNotifier<bool>>.value(
          value: enabledNotifier,
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
              context.select((DataNotifier<List<Preset>> n) => n.data),
              context.select((DataNotifier<bool> n) => n.data),
            ),
          ],
        );
      },
    );
  }
}
