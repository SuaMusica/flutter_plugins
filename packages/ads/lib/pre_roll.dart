import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smads/pre_roll_controller.dart';

class PreRoll extends StatelessWidget {
  final double maxHeight;
  final PreRollController controller;

  PreRoll({
    Key key,
    this.maxHeight,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return Container();
    }
    final UniqueKey _key = UniqueKey();
    final viewType = 'suamusica/pre_roll_view';
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
    controller.play();
  }
}
