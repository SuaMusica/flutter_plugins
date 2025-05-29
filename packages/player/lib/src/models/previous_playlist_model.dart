import 'package:isar/isar.dart';

part 'previous_playlist_model.g.dart';

@collection
class PreviousPlaylistMusics {
  PreviousPlaylistMusics({this.id = 1, this.musics});
  Id id = Isar.autoIncrement;
  List<String>? musics;
  @override
  String toString() => 'PreviousPlaylistMusics(musics: $musics})';
}

@collection
class PreviousPlaylistCurrentIndex {
  PreviousPlaylistCurrentIndex({
    this.id = 1,
    required this.currentIndex,
    required this.mediaId,
  });
  Id id = Isar.autoIncrement;
  int? currentIndex;
  int mediaId;
  @override
  String toString() =>
      'PreviousPlaylistCurrentIndex(currentIndex: $currentIndex)';
}

@collection
class PreviousPlaylistPosition {
  PreviousPlaylistPosition({
    this.id = 1,
    required this.mediaId,
    required this.position,
    required this.duration,
  });
  Id id = Isar.autoIncrement;
  int mediaId;
  double position;
  double duration;
  @override
  String toString() =>
      'PreviousPlaylistPosition(duration: $duration,position: $position,position: $position,mediaId:$mediaId)';
}
