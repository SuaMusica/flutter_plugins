import 'package:smplayer/src/event.dart';
import 'package:smplayer/src/event_type.dart';
import 'package:smplayer/src/media.dart';

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
