import 'package:smplayer/src/event.dart';
import 'package:smplayer/src/event_type.dart';
import 'package:smplayer/src/media.dart';

enum NetworkStatus {
  CONNECTED,
  DISCONNECTED,
}

class NetworkChangeEvent extends Event {
  NetworkChangeEvent({
    String id,
    Media media,
    int queuePosition,
    this.networkStatus,
  }) : super(
          type: EventType.NETWORK_CHANGE,
          media: media,
          queuePosition: queuePosition,
        );

  final NetworkStatus networkStatus;

  @override
  String toString() => "${super.toString()} networkStatus: $networkStatus";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkChangeEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          media == other.media &&
          queuePosition == queuePosition &&
          error == other.error &&
          errorType == other.errorType &&
          position == other.position &&
          duration == other.duration &&
          networkStatus == other.networkStatus;

  @override
  int get hashCode => [type, media, error, errorType, networkStatus].hashCode;
}
