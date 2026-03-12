enum PlayerRepeatMode { NONE, QUEUE, TRACK }

extension ParseToString on PlayerRepeatMode {
  String toShortString() => switch (this) {
    PlayerRepeatMode.NONE => 'Disabled',
    PlayerRepeatMode.QUEUE => 'Queue',
    PlayerRepeatMode.TRACK => 'Track',
    // ignore: unreachable_switch_case
    _ => "Unknown",
  };
}
