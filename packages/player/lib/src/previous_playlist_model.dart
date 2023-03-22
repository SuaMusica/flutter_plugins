import 'package:isar/isar.dart';

part 'previous_playlist_model.g.dart';

@collection
class PreviousPlaylistMusics {
  PreviousPlaylistMusics({
    this.id = 1,
    this.musics,
  });
  Id id = Isar.autoIncrement;
  List<String>? musics;
  @override
  String toString() => 'PreviousPlaylistMusics(musics: $musics})';
}

@collection
class PreviousPlaylistCurrentIndex {
  PreviousPlaylistCurrentIndex({
    this.id = 1,
    this.currentIndex,
  });
  Id id = Isar.autoIncrement;
  int? currentIndex;

  @override
  String toString() =>
      'PreviousPlaylistCurrentIndex(currentIndex: $currentIndex)';
}

@collection
class PreviousPlaylistPosition {
  PreviousPlaylistPosition({
    required this.id,
    required this.position,
    required this.duration,
  });
  Id id = Isar.autoIncrement;
  double position;
  double duration;
  @override
  String toString() => 'PreviousPlaylistPosition(position: $position)';
}
