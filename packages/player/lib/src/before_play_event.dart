import '../player.dart';

class BeforePlayEvent extends Event {
  Function(bool) operation;

  BeforePlayEvent({
    String? id,
    required Media media,
    required this.operation,
    required int queuePosition,
  }) : super(
          type: EventType.BEFORE_PLAY,
          media: media,
          queuePosition: queuePosition,
        );

  continueWithLoadingOnly() {
    this.operation(true);
  }

  continueWithLoadingAndPlay() {
    this.operation(false);
  }
}
