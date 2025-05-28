enum RepeatMode { REPEAT_MODE_OFF, REPEAT_MODE_ONE, REPEAT_MODE_ALL }

extension ParseToString on RepeatMode {
  String toShortString() {
    switch (this) {
      case RepeatMode.REPEAT_MODE_OFF:
        return 'Disabled';
      case RepeatMode.REPEAT_MODE_ALL:
        return 'Queue';
      case RepeatMode.REPEAT_MODE_ONE:
        return 'Track';
    }
  }
}
