import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:smads/pre_roll_controller.dart';

class PreRoll extends StatefulWidget {
  final double? maxHeight;
  final PreRollController? controller;
  final bool useHybridComposition;
  final bool useinitExpensiveAndroidView;

  const PreRoll({
    Key? key,
    this.maxHeight,
    this.controller,
    this.useHybridComposition = false,
    this.useinitExpensiveAndroidView = false,
  }) : super(key: key);

  @override
  State<PreRoll> createState() => _PreRollState();
}

class _PreRollState extends State<PreRoll> {
  double? get maxHeight => widget.maxHeight;
  PreRollController? get controller => widget.controller;
  bool get useHybridComposition => widget.useHybridComposition;
  bool get useinitExpensiveAndroidView => widget.useinitExpensiveAndroidView;

  static const _viewType = 'suamusica/pre_roll_view';
  static const _creationParams = <String, dynamic>{
    'adSize': {'width': 640, 'height': 480},
  };
  static const _codec = StandardMessageCodec();
  static const _gestureRecognizers = <Factory<OneSequenceGestureRecognizer>>{};

  final UniqueKey _viewKey = UniqueKey();

  void _onPlatformViewCreated(int id) {
    if (defaultTargetPlatform == TargetPlatform.android) controller?.play();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    final maxHeightItem =
        maxHeight ?? MediaQuery.maybeSizeOf(context)?.height ?? double.infinity;

    return RepaintBoundary(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeightItem),
        child: defaultTargetPlatform == TargetPlatform.android
            ? (useHybridComposition
                ? PlatformViewLink(
                    key: _viewKey,
                    viewType: _viewType,
                    surfaceFactory: (_, controller) => AndroidViewSurface(
                          controller: controller as AndroidViewController,
                          gestureRecognizers: _gestureRecognizers,
                          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                        ),
                    onCreatePlatformView: (params) =>
                        (useinitExpensiveAndroidView
                            ? PlatformViewsService.initExpensiveAndroidView(
                                id: params.id,
                                viewType: _viewType,
                                layoutDirection: TextDirection.ltr,
                                creationParams: _creationParams,
                                creationParamsCodec: _codec,
                              )
                            : PlatformViewsService.initSurfaceAndroidView(
                                id: params.id,
                                viewType: _viewType,
                                layoutDirection: TextDirection.ltr,
                                creationParams: _creationParams,
                                creationParamsCodec: _codec,
                              ))
                          ..addOnPlatformViewCreatedListener((id) {
                            params.onPlatformViewCreated(id);
                            _onPlatformViewCreated(id);
                          })
                          ..create())
                : AndroidView(
                    key: _viewKey,
                    viewType: _viewType,
                    creationParams: _creationParams,
                    creationParamsCodec: _codec,
                    onPlatformViewCreated: _onPlatformViewCreated,
                    clipBehavior: Clip.none,
                  ))
            : UiKitView(
                key: _viewKey,
                viewType: _viewType,
                creationParams: _creationParams,
                creationParamsCodec: _codec,
                onPlatformViewCreated: _onPlatformViewCreated,
              ),
      ),
    );
  }
}
