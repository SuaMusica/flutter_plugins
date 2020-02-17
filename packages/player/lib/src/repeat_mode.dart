enum RepeatMode { NONE, QUEUE, TRACK }

extension ParseToString on RepeatMode {
  String toShortString() {
    switch (this) {
      case RepeatMode.NONE:
        return 'Disabled';
      case RepeatMode.QUEUE:
        return 'Queue';
      case RepeatMode.TRACK:
        return 'Track';
      default:
        return "Unknown";
    }
  }
}
