import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smads/pre_roll_events.dart';

abstract class PreRollEventHandler {
  final Function(PreRollEvent, Map<String, dynamic>) _listener;

  PreRollEventHandler(Function(PreRollEvent, Map<String, dynamic>) listener)
      : _listener = listener;

  Future<dynamic> handleEvent(MethodCall call) async {
    if (call.method == "onAdEvent") {
      final args = Map<String, dynamic>.from(call.arguments);
      final String? type = args["type"];
      debugPrint("[PREROLL]: handleEvent - onAdEvent - $type | $args");
      _listener(type!.toPreRollEvent(), args);
    }
    return null;
  }
}
