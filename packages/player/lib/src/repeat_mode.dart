enum RepeatMode { NONE, QUEUE, TRACK }

extension ParseToString on RepeatMode {
  String toShortString() => switch (this) {
    RepeatMode.NONE => 'Disabled',
    RepeatMode.QUEUE => 'Queue',
    RepeatMode.TRACK => 'Track',
    // ignore: unreachable_switch_case
    _ => "Unknown",
  };
}
