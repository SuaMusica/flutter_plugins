import 'dart:async';

import 'package:flutter/services.dart';

abstract class PreRollEventHandler {
  final Function(String, Map<String, dynamic>) _listener;

  PreRollEventHandler(Function(String, Map<String, dynamic>) listener)
      : _listener = listener;

  Future<dynamic> handleEvent(MethodCall call) async {
    _listener(call.method, null);
    return null;
  }
}
