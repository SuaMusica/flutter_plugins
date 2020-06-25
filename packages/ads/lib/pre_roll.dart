import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smads/pre_roll_controller.dart';
import 'package:smads/pre_roll_events.dart';

class PreRoll extends StatelessWidget {
  final Function(PreRollEvent, Map<String, dynamic>) listener;
  final Function(PreRollController) onCreated;
  final double maxHeight;
  PreRoll({
    Key key,
    this.listener,
    this.onCreated,
    this.maxHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return Container();
    }
    final UniqueKey _key = UniqueKey();
    final viewType = 'suamusica/pre_roll';
    final creationParams = <String, dynamic>{
      'adSize': {
        'width': 640,
        'height': 480,
      },
    };
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height,
      ),
      child: defaultTargetPlatform == TargetPlatform.android
          ? AndroidView(
              key: _key,
              viewType: viewType,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onPlatformViewCreated,
            )
          : UiKitView(
              key: _key,
              viewType: viewType,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onPlatformViewCreated,
            ),
    );
  }

  void _onPlatformViewCreated(int id) {
    PreRollController _controller = PreRollController(id, listener);
    if (onCreated != null) {
      onCreated(_controller);
    }
  }
}
