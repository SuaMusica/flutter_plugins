import 'package:suamusica_player/src/event.dart';
import 'package:suamusica_player/src/event_type.dart';
import 'package:suamusica_player/src/media.dart';

class BeforePlayEvent extends Event {
  Function(bool) operation;

  BeforePlayEvent(
      {String id, Media media, this.operation})
      : super(type: EventType.BEFORE_PLAY, media: media);

  continueWithLoadingOnly() {
    this.operation(true);
  }

  continueWithLoadingAndPlay() {
    this.operation(false);
  }
}
