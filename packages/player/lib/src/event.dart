import 'package:equatable/equatable.dart';
import 'package:suamusica_player/src/event_type.dart';
import 'package:suamusica_player/src/media.dart';
import 'package:uuid/uuid.dart';

class Event extends Equatable {
  static final _uuid = Uuid();
  final String id;
  final EventType type;
  final Media media;

  Event({id, this.type, this.media}) : id = id ?? _uuid.v4();

  @override
  String toString() => "Event id: $id type: $type media: $media";
}
