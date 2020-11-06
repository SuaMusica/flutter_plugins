import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:smads/pre_roll_controller.dart';
import 'package:device_info/device_info.dart';

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
          ? FutureBuilder(
              future: DeviceInfoPlugin().androidInfo,
              builder: (BuildContext context,
                  AsyncSnapshot<AndroidDeviceInfo> snapshot) {
                if (snapshot.hasError || !snapshot.hasData) {
                  return Container();
                }
                return snapshot.data.version.sdkInt >= 28
                    ? PlatformViewLink(
                        key: _key,
                        viewType: viewType,
                        surfaceFactory: (BuildContext context,
                                PlatformViewController controller) =>
                            AndroidViewSurface(
                          controller: controller,
                          gestureRecognizers: const <
                              Factory<OneSequenceGestureRecognizer>>{},
                          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                        ),
                        onCreatePlatformView:
                            (PlatformViewCreationParams params) =>
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
                      );
              },
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
