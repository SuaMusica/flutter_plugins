import 'package:equalizer/equalizer_controller.dart';
import 'package:flutter/material.dart';

class EqualizerPresetList extends StatefulWidget {
  EqualizerPresetList(this.equalizerController, this.presetList, this.enabled);

  final EqualizerController equalizerController;
  final List<Preset> presetList;
  final bool enabled;

  @override
  _EqualizerPresetListState createState() => _EqualizerPresetListState();
}

class _EqualizerPresetListState extends State<EqualizerPresetList> {
  int groupValue = 0;

  @override
  void initState() {
    widget.equalizerController.getCurrentPresetPosition().then((value) => {
          setState(() {
            groupValue = value;
          })
        });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.presetList.map((preset) => _presetTile(preset)).toList(),
      ],
    );
  }

  Widget _presetTile(Preset preset) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RadioListTile<int>(
          dense: true,
          contentPadding: EdgeInsets.only(left: 12, right: 12),
          title: Text(preset.name),
          value: preset.index,
          groupValue: groupValue,
          onChanged: widget.enabled
              ? (int value) {
                  setState(() {
                    groupValue = value;
                  });
                  widget.equalizerController.setPreset(preset.name);
                }
              : null,
        ),
        Divider(),
      ],
    );
  }
}
