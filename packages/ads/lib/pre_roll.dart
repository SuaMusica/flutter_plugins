import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:smads/pre_roll_controller.dart';

class PreRoll extends StatelessWidget {
  final double? maxHeight;
  final PreRollController? controller;
  final bool usePlatformLink;
  PreRoll({
    Key? key,
    this.maxHeight,
    this.controller,
    this.usePlatformLink = false,
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
          ? (usePlatformLink
              ? PlatformViewLink(
                  key: _key,
                  viewType: viewType,
                  surfaceFactory: (BuildContext context,
                          PlatformViewController controller) =>
                      AndroidViewSurface(
                    controller: controller as AndroidViewController,
                    gestureRecognizers: const <
                        Factory<OneSequenceGestureRecognizer>>{},
                    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                  ),
                  onCreatePlatformView: (PlatformViewCreationParams params) =>
                      PlatformViewsService.initSurfaceAndroidView(
                    id: params.id,
                    viewType: viewType,
                    layoutDirection: TextDirection.ltr,
                    creationParams: creationParams,
                    creationParamsCodec: const StandardMessageCodec(),
                  )
                        ..addOnPlatformViewCreatedListener((int id) {
                          params.onPlatformViewCreated(id);
                          _onPlatformViewCreated(id);
                        })
                        ..create(),
                )
              : AndroidView(
                  key: _key,
                  viewType: viewType,
                  creationParams: creationParams,
                  creationParamsCodec: const StandardMessageCodec(),
                  onPlatformViewCreated: _onPlatformViewCreated,
                  clipBehavior: Clip.none,
                ))
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
    controller?.play();
  }
}
