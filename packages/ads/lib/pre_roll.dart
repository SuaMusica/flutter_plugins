import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:smads/pre_roll_controller.dart';

const _kPreRollViewType = 'suamusica/pre_roll_view';
const _kPreRollCreationParamsCodec = StandardMessageCodec();
const _kPreRollCreationParams = <String, dynamic>{
  'adSize': {
    'width': 640,
    'height': 480,
  },
};

class PreRoll extends StatefulWidget {
  const PreRoll({
    super.key,
    this.maxHeight,
    this.controller,
    this.useHybridComposition = false,
    this.useinitExpensiveAndroidView = false,
    this.useInitHybridAndroidView = true,
  });

  final double? maxHeight;
  final PreRollController? controller;
  final bool useHybridComposition;
  final bool useinitExpensiveAndroidView;
  final bool useInitHybridAndroidView;

  @override
  State<PreRoll> createState() => _PreRollState();
}

class _PreRollState extends State<PreRoll> {
  bool? _hcppSupported;
  final Key _platformViewKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android &&
        widget.useHybridComposition) {
      print(
        '[_PreRollState] initState pre_roll hcpp: $widget.useHybridComposition',
      );

      HybridAndroidViewController.checkIfSupported().then((supported) {
        print(
          '[_PreRollState] checkIfSupported pre_roll hcpp: $supported',
        );

        if (mounted) {
          setState(() => _hcppSupported = supported);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    debugPrint('[PREROLL] Building PreRoll');

    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.maxHeight ?? MediaQuery.of(context).size.height,
      ),
      child: switch (defaultTargetPlatform) {
        TargetPlatform.android => _PreRollAndroidView(
            useHybridComposition: widget.useHybridComposition,
            useinitExpensiveAndroidView: widget.useinitExpensiveAndroidView,
            useInitHybridAndroidView: widget.useInitHybridAndroidView,
            hcppSupported: _hcppSupported,
            controller: widget.controller,
            platformViewKey: _platformViewKey,
          ),
        _ => _PreRollIosView(
            controller: widget.controller,
            platformViewKey: _platformViewKey,
          ),
      },
    );
  }
}

class _PreRollAndroidView extends StatelessWidget {
  const _PreRollAndroidView({
    required this.useHybridComposition,
    required this.useinitExpensiveAndroidView,
    required this.useInitHybridAndroidView,
    required this.hcppSupported,
    required this.controller,
    required this.platformViewKey,
  });

  final bool useHybridComposition;
  final bool useinitExpensiveAndroidView;
  final bool useInitHybridAndroidView;
  final bool? hcppSupported;
  final PreRollController? controller;
  final Key platformViewKey;

  @override
  Widget build(BuildContext context) {
    if (!useHybridComposition) {
      return _PreRollTextureLayerAndroidView(
        controller: controller,
        platformViewKey: platformViewKey,
      );
    }

    if (hcppSupported == null) {
      return const SizedBox.shrink();
    }

    return _PreRollHybridPlatformViewLink(
      useHcpp: hcppSupported!,
      useinitExpensiveAndroidView: useinitExpensiveAndroidView,
      useInitHybridAndroidView: useInitHybridAndroidView,
      controller: controller,
      platformViewKey: platformViewKey,
    );
  }
}

class _PreRollHybridPlatformViewLink extends StatelessWidget {
  const _PreRollHybridPlatformViewLink({
    required this.useHcpp,
    required this.useinitExpensiveAndroidView,
    required this.useInitHybridAndroidView,
    required this.controller,
    required this.platformViewKey,
  });

  final bool useHcpp;
  final bool useinitExpensiveAndroidView;
  final bool useInitHybridAndroidView;
  final PreRollController? controller;
  final Key platformViewKey;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      key: platformViewKey,
      viewType: _kPreRollViewType,
      surfaceFactory: (
        BuildContext context,
        PlatformViewController controller,
      ) =>
          AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      ),
      onCreatePlatformView: (PlatformViewCreationParams params) {
        print(
          '[_PreRollHybridPlatformViewLink] onCreatePlatformView pre_roll hcpp: $useHcpp, $useInitHybridAndroidView',
        );

        final AndroidViewController viewController =
            useHcpp && useInitHybridAndroidView
                ? PlatformViewsService.initHybridAndroidView(
                    id: params.id,
                    viewType: _kPreRollViewType,
                    layoutDirection: TextDirection.ltr,
                    creationParams: _kPreRollCreationParams,
                    creationParamsCodec: _kPreRollCreationParamsCodec,
                    onFocus: () => params.onFocusChanged(true),
                  )
                : useinitExpensiveAndroidView
                    ? PlatformViewsService.initExpensiveAndroidView(
                        id: params.id,
                        viewType: _kPreRollViewType,
                        layoutDirection: TextDirection.ltr,
                        creationParams: _kPreRollCreationParams,
                        creationParamsCodec: _kPreRollCreationParamsCodec,
                      )
                    : PlatformViewsService.initSurfaceAndroidView(
                        id: params.id,
                        viewType: _kPreRollViewType,
                        layoutDirection: TextDirection.ltr,
                        creationParams: _kPreRollCreationParams,
                        creationParamsCodec: _kPreRollCreationParamsCodec,
                      );

        return viewController
          ..addOnPlatformViewCreatedListener((int id) {
            params.onPlatformViewCreated(id);
            _onPreRollPlatformViewCreated(controller, id);
          })
          ..create();
      },
    );
  }
}

class _PreRollTextureLayerAndroidView extends StatelessWidget {
  const _PreRollTextureLayerAndroidView({
    required this.controller,
    required this.platformViewKey,
  });

  final PreRollController? controller;
  final Key platformViewKey;

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      key: platformViewKey,
      viewType: _kPreRollViewType,
      creationParams: _kPreRollCreationParams,
      creationParamsCodec: _kPreRollCreationParamsCodec,
      onPlatformViewCreated: (id) =>
          _onPreRollPlatformViewCreated(controller, id),
      clipBehavior: Clip.none,
    );
  }
}

class _PreRollIosView extends StatelessWidget {
  const _PreRollIosView({
    required this.controller,
    required this.platformViewKey,
  });

  final PreRollController? controller;
  final Key platformViewKey;

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      key: platformViewKey,
      viewType: _kPreRollViewType,
      creationParams: _kPreRollCreationParams,
      creationParamsCodec: _kPreRollCreationParamsCodec,
      onPlatformViewCreated: (id) =>
          _onPreRollPlatformViewCreated(controller, id),
    );
  }
}

void _onPreRollPlatformViewCreated(PreRollController? controller, int id) {
  debugPrint('Platform view created withs id: $id');
  if (Platform.isAndroid) {
    controller?.play();
  }
}
