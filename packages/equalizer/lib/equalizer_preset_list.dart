import 'package:equalizer/equalizer_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EqualizerPresetList extends StatelessWidget {
  EqualizerPresetList(
    this.equalizerController,
    this.onSelectType,
  );

  final EqualizerController equalizerController;
  final Function(String)? onSelectType;

  @override
  Widget build(BuildContext context) {
    return Consumer<ValueNotifier<List<PresetData>>>(
      builder: (context, notifierPresetList, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...notifierPresetList.value
                .map((preset) => _presetTile(context, preset, onSelectType))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _presetTile(
      BuildContext context, PresetData preset, Function(String)? onSelectType) {
    final enabled = context.select((ValueNotifier<bool> n) => n.value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer<ValueNotifier<int>>(
          builder: (context, currentPresetPositionNotifier, _) =>
              RadioListTile<int>(
            dense: true,
            contentPadding: EdgeInsets.only(left: 12, right: 12),
            title: Text(preset.name),
            value: preset.index,
            groupValue: currentPresetPositionNotifier.value,
            onChanged: enabled
                ? (int? value) {
                    if (value != null) {
                      final notifier = context.read<ValueNotifier<int>>();
                      notifier.value = value;
                      equalizerController.setPreset(preset.name);
                      onSelectType?.call(preset.name);
                    }
                  }
                : null,
          ),
        ),
        Divider(
          height: 4,
        ),
      ],
    );
  }
}
