import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smads/pre_roll_controller.dart';

class PreRoll extends StatefulWidget {
  final String adUnitId;
  final void Function(String, Map<String, dynamic>) listener;
  final void Function(PreRollController) onCreated;

  PreRoll({
    Key key,
    @required this.adUnitId,
    this.listener,
    this.onCreated,
  }) : super(key: key);

  @override
  _PreRollState createState() => _PreRollState();
}

class _PreRollState extends State<PreRoll> {
  final UniqueKey _key = UniqueKey();
  PreRollController _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return SizedBox.fromSize(
        size: Size(640, 480),
        child: AndroidView(
          key: _key,
          viewType: 'suamusica/pre_roll',
          creationParams: <String, dynamic>{
            'adUnitId': widget.adUnitId,
            'adSize': {
              'width': 640,
              'height': 480,
            },
          },
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox.fromSize(
        size: Size(640, 480),
        child: UiKitView(
          key: _key,
          viewType: 'suamusica/pre_roll',
          creationParams: <String, dynamic>{
            'adUnitId': widget.adUnitId,
            'adSize': {
              'width': 640,
              'height': 480,
            },
          },
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    }
    return Container();
  }

  void _onPlatformViewCreated(int id) {
    _controller = PreRollController(id, widget.listener);
    if (widget.onCreated != null) {
      widget.onCreated(_controller);
    }
  }
}
