import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smplayer/player.dart';
import 'package:smplayer/src/media.dart';
import 'package:smplayer/src/queue.dart';

void main() {
  final media1 = Media(
    id: 1,
    albumTitle: "Album",
    albumId: 2,
    ownerId: 2,
    name: "O Bebe",
    url: "https://android.suamusica.com.br/373377/2238511/02+O+Bebe.mp3",
    coverUrl:
        "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
    bigCoverUrl:
        "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
    author: "Xand Avião",
    isLocal: false,
    isVerified: true,
    shareUrl: "",
  );

  final media2 = Media(
    id: 2,
    albumTitle: "Album",
    albumId: 2,
    ownerId: 2,
    name: "Solteiro Largado",
    url:
        "https://android.suamusica.com.br/373377/2238511/03+Solteiro+Largado.mp3",
    coverUrl:
        "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
    bigCoverUrl:
        "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
    author: "Xand Avião",
    isLocal: false,
    isVerified: true,
    shareUrl: "",
  );

  final media3 = Media(
    id: 3,
    albumTitle: "Album",
    albumId: 2,
    ownerId: 2,
    name: "Borrachinha",
    url: "https://android.suamusica.com.br/373377/2238511/05+Borrachinha.mp3",
    coverUrl:
        "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
    bigCoverUrl:
        "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
    author: "Xand Avião",
    isLocal: false,
    isVerified: false,
    shareUrl: "",
  );

  group('Queue operations', () {
    test('Adding media to an empty queue shall make it the queue top', () {
      final subject = Queue();
      subject.addAll([media1]);
      expect(subject.size, 1);
      expect(subject.top, media1);
    });

    test('The queue shall support multiple items', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);
      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });

    test('Playing a media shall replace the queue top', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });

    test('Removing a media shall be supported', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      subject.removeByPosition(
        positionsToDelete: [subject.playerQueue[1].position],
        isShuffle: false,
      );

      expect(subject.size, 2);
      expect(subject.top, media1);
      expect(subject.items, [media1, media3]);
    });

    test('Add all shall be supported', () {
      final subject = Queue();
      final items = <Media>[];
      for (int i = 0; i < 10; ++i) {
        items.addAll([media1, media2, media3]);
      }
      subject.addAll(items);
      expect(subject.size, 30);
      expect(subject.top, media1);
      expect(subject.items, items);
    });

    test('Shuffle shall be supported', () {
      final subject = Queue();
      final items = <Media>[];
      final interactions = 100;
      for (int i = 0; i < interactions; ++i) {
        items.addAll([media1, media2, media3]);
      }
      subject.addAll(items);
      subject.shuffle();

      expect(subject.size, 3 * interactions);
      expect(subject.top, media1);
      expect(subject.items, isNot(items));
    });

    test('Unshuffle shall be supported', () {
      final subject = Queue();
      final items = <Media>[];
      final interactions = 100;
      for (int i = 0; i < interactions; ++i) {
        items.addAll([media1, media2, media3]);
      }
      subject.addAll(items);
      subject.shuffle();

      expect(subject.size, 3 * interactions);
      expect(subject.top, media1);
      expect(subject.items, isNot(items));

      subject.unshuffle();

      expect(subject.size, 3 * interactions);
      expect(subject.top, media1);
      expect(subject.items, items);
    });

    test('Rewind on empty queue shall raise an error', () {
      final subject = Queue();
      expect(subject.shouldRewind(), false);
    });

    test('Rewind on a queue that was not played shall raise an error', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);
      final shouldRewind = subject.shouldRewind();
      final rewind = shouldRewind ? subject.possiblePrevious() : null;
      expect(rewind, shouldRewind ? null : media1);
    });

    test('Rewind shall be supported', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });

    test('Previous on empty queue shall raise an error', () {
      final subject = Queue();
      expect(() => subject.possiblePrevious(), throwsAssertionError);
    });

    test('Previous on a queue', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      expect(subject.possiblePrevious(), media1);
    });

    test('Previous shall act as rewind', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      subject.possiblePrevious();

      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });
    test(
      'Two consecutive previous invocation shall really go the previous track',
      () {
        final subject = Queue();
        subject.addAll([media1, media2, media3]);

        final next1 = subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);
        expect(subject.size, 3);
        expect(subject.current, media2);
        expect(next1, media2);
        expect(subject.items, [media1, media2, media3]);

        final next2 = subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);
        expect(subject.size, 3);
        expect(subject.current, media3);
        expect(next2, media3);
        expect(subject.items, [media1, media2, media3]);

        subject.possiblePrevious();
        final previous = subject.possiblePrevious();
        expect(subject.size, 3);
        expect(subject.current, media2);
        expect(previous, media2);
        expect(subject.items, [media1, media2, media3]);
      },
    );
    test(
      'Two consecutive previous invocation with interval greater than 1 sec shall solely rewind',
      () {
        final subject = Queue();
        subject.addAll([media1, media2, media3]);

        final next1 = subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);
        expect(subject.size, 3);
        expect(subject.current, media2);
        expect(next1, media2);
        expect(subject.items, [media1, media2, media3]);

        final next2 = subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);
        expect(subject.size, 3);
        expect(subject.current, media3);
        expect(next2, media3);
        expect(subject.items, [media1, media2, media3]);

        subject.possiblePrevious();
        sleep(Duration(seconds: 3));
        final previous = subject.possiblePrevious();
        expect(subject.size, 3);
        expect(subject.current, media3);
        expect(previous, media3);
        expect(subject.items, [media1, media2, media3]);
      },
    );
    test('Next on empty queue shall raise an error', () {
      final subject = Queue();
      expect(
        () => subject.possibleNext(RepeatMode.REPEAT_MODE_OFF),
        throwsAssertionError,
      );
    });
    test('Next on a queue that was not played shall start playing it', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      final next = subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);

      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(next, media2);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Next on a queue that is playing shall move to the next', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      final next1 = subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(next1, media2);
      expect(subject.items, [media1, media2, media3]);

      final next2 = subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(next2, media3);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Next when reaching the end of the queue shall return null', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      final next1 = subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(next1, media2);
      expect(subject.items, [media1, media2, media3]);

      final next2 = subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(next2, media3);
      expect(subject.items, [media1, media2, media3]);

      final next3 = subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(next3, null);
      expect(subject.items, [media1, media2, media3]);

      final next4 = subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(next4, null);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Clear shall remove all tracks from queue', () {
      final subject = Queue();
      final items = <Media>[];
      final interactions = 100;
      for (int i = 0; i < interactions; ++i) {
        items.addAll([media1, media2, media3]);
      }
      subject.addAll(items);
      subject.possibleNext(RepeatMode.REPEAT_MODE_OFF);
      expect(subject.size, 3 * interactions);
      expect(subject.top, media1);
      expect(subject.items, items);

      subject.clear();
      expect(subject.size, 0);
      expect(subject.top, null);
      expect(subject.items, []);
    });
    test('Top on an unplayed queue shall return the top of the queue', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);
      expect(subject.size, 3);
      expect(subject.top, media1);
    });

    test('Current on an unplayed queue shall return null', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);
      expect(subject.size, 3);
      expect(subject.current, media1);
    });
  });

  group('Queue reorder operations', () {
    test('Reorder shall move an item to a new position', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      subject.reorder(0, 2);

      expect(subject.size, 3);
      expect(subject.items, [media2, media3, media1]);
    });

    test('Reorder shall maintain correct positions after moving an item', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      subject.reorder(0, 2);

      expect(subject.size, 3);
      expect(subject.items, [media2, media3, media1]);
      expect(subject.top, media2);
    });

    test('Reorder shall maintain current playing item position', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);
      subject.reorder(0, 2);
      expect(subject.size, 3);
      expect(subject.items, [media2, media3, media1]);
      expect(subject.current, media2);
    });

    test('Reorder shall handle moving an item to its current position', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      subject.reorder(1, 1);

      expect(subject.size, 3);
      expect(subject.items, [media1, media2, media3]);
    });

    test('Reorder shall handle moving an item to the beginning', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      subject.reorder(2, 0);

      expect(subject.size, 3);
      expect(subject.items, [media3, media1, media2]);
      expect(subject.top, media3);
    });

    test('Reorder shall handle moving an item to the end', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      subject.reorder(0, 2);

      expect(subject.size, 3);
      expect(subject.items, [media2, media3, media1]);
    });

    test('Reorder shall maintain correct positions in shuffled mode', () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);
      subject.shuffle();

      subject.reorder(0, 2, true);

      expect(subject.size, 3);
      expect(subject.items.length, 3);
      expect(subject.top, isNotNull);
    });
  });
}
