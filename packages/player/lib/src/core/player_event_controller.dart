import 'dart:async';
import 'package:flutter/material.dart';

import 'package:smplayer/src/models/event.dart';
import 'package:smplayer/src/enums/event_type.dart';

class PlayerEventController {
  final StreamController<Event> _eventStreamController =
      StreamController<Event>();
  Stream<Event>? _stream;
  bool _shallSendEvents = true;
  final List<EventType> _chromeCastEnabledEvents = [
    EventType.BEFORE_PLAY,
    EventType.NEXT,
    EventType.PREVIOUS,
    EventType.POSITION_CHANGE,
    EventType.REWIND,
    EventType.PLAY_REQUESTED,
    EventType.PAUSED,
    EventType.PLAYING,
    EventType.EXTERNAL_RESUME_REQUESTED,
    EventType.EXTERNAL_PAUSE_REQUESTED,
    EventType.SET_CURRENT_MEDIA_INDEX,
  ];

  Stream<Event> get onEvent {
    _stream ??= _eventStreamController.stream.asBroadcastStream();
    return _stream!;
  }

  bool get shallSendEvents => _shallSendEvents;
  set shallSendEvents(bool value) => _shallSendEvents = value;

  void add(Event event) {
    if (event.type != EventType.POSITION_CHANGE) {
      debugPrint(
        'APP LOGS ==> PlayerEventController _addUsingPlayer ${event.type}',
      );
    }
    if (!_eventStreamController.isClosed &&
        (_shallSendEvents || _chromeCastEnabledEvents.contains(event.type))) {
      _eventStreamController.add(event);
    }
  }

  Future<void> dispose() async {
    if (!_eventStreamController.isClosed) {
      await _eventStreamController.close();
    }
  }
}
