import 'package:equalizer/equalizer_controller.dart';
import 'package:flutter/material.dart';

class EqualizerSwitch extends StatefulWidget {
  EqualizerSwitch(
    this.controller, {
    Key key,
    this.titleDisabled,
    this.titleEnabled,
  }) : super(key: key);

  final EqualizerController controller;
  final Widget titleDisabled;
  final Widget titleEnabled;

  @override
  _EqualizerSwitchState createState() => _EqualizerSwitchState();
}

class _EqualizerSwitchState extends State<EqualizerSwitch> {
  bool isEnabled = false;

  @override
  void initState() {
    widget.controller.isEnabled().then((value) => {
          setState(() {
            isEnabled = value;
          })
        });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: isEnabled ? widget.titleEnabled : widget.titleDisabled,
      value: isEnabled,
      onChanged: (value) {
        widget.controller.setEnabled(value);
        setState(() {
          isEnabled = value;
        });
      },
    );
  }
}