import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
      shareUrl: "");

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
      shareUrl: "");

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
      shareUrl: "");

  group('Queue operations', () {
    test('Adding media to an empty queue shall make it the queue top', () {
      final subject = Queue();
      subject.add(media1);
      expect(subject.size, 1);
      expect(subject.top, media1);
    });

    test('The queue shall support multiple items', () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);
      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });

    test('Playing a media shall replace the queue top', () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.play(media3);

      expect(subject.size, 2);
      expect(subject.top, media3);
      expect(subject.items, [media3, media2]);
    });

    test('Removing a media shall be supported', () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);

      subject.removeByPosition(
          positionsToDelete: [subject.storage[1].position], isShuffle: false);

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

    test(
      'Rewind on empty queue shall raise an error',
      () {
        final subject = Queue();
        expect(
          () => subject.rewind(),
          throwsAssertionError,
        );
      },
    );

    test('Rewind on a queue that was not played shall raise an error', () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);

      expect(subject.rewind(), media1);
    });

    test('Rewind shall be supported', () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);
      subject.play(media1);

      subject.rewind();

      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });

    test('Previous on empty queue shall raise an error', () {
      final subject = Queue();
      expect(() => subject.previous(), throwsAssertionError);
    });

    test('Previous on a queue', () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);

      expect(subject.previous(), media1);
    });

    test('Previous shall act as rewind', () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);
      subject.play(media1);

      subject.previous();

      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });
    test(
        'Two consecutive previous invocation shall really go the previous track',
        () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);

      final next1 = subject.next();
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(next1, media2);
      expect(subject.items, [media1, media2, media3]);

      final next2 = subject.next();
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(next2, media3);
      expect(subject.items, [media1, media2, media3]);

      subject.previous();
      final previous = subject.previous();
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(previous, media2);
      expect(subject.items, [media1, media2, media3]);
    });
    test(
        'Two consecutive previous invocation with interval greater than 1 sec shall solely rewind',
        () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);

      final next1 = subject.next();
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(next1, media2);
      expect(subject.items, [media1, media2, media3]);

      final next2 = subject.next();
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(next2, media3);
      expect(subject.items, [media1, media2, media3]);

      subject.previous();
      sleep(Duration(seconds: 3));
      final previous = subject.previous();
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(previous, media3);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Next on empty queue shall raise an error', () {
      final subject = Queue();
      expect(() => subject.next(), throwsAssertionError);
    });
    test('Next on a queue that was not played shall start playing it', () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);

      final next = subject.next();

      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(next, media2);
      expect(subject.items, [media1, media2, media3]);
    });
    test(
      'Next on a queue that is playing shall move to the next',
      () {
        final subject = Queue();
        subject.add(media1);
        subject.add(media2);
        subject.add(media3);

        final next1 = subject.next();
        expect(subject.size, 3);
        expect(subject.current, media2);
        expect(next1, media2);
        expect(subject.items, [media1, media2, media3]);

        final next2 = subject.next();
        expect(subject.size, 3);
        expect(subject.current, media3);
        expect(next2, media3);
        expect(subject.items, [media1, media2, media3]);
      },
    );
    test('Next when reaching the end of the queue shall return null', () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);

      final next1 = subject.next();
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(next1, media2);
      expect(subject.items, [media1, media2, media3]);

      final next2 = subject.next();
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(next2, media3);
      expect(subject.items, [media1, media2, media3]);

      final next3 = subject.next();
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(next3, null);
      expect(subject.items, [media1, media2, media3]);

      final next4 = subject.next();
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
      subject.next();
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
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);
      expect(subject.size, 3);
      expect(subject.top, media1);
    });

    test('Current on an unplayed queue shall return null', () {
      final subject = Queue();
      subject.add(media1);
      subject.add(media2);
      subject.add(media3);
      expect(subject.size, 3);
      expect(subject.current, media1);
    });

    test(
        'Add with enqueueAfterCurrent during shuffle should preserve original order on unshuffle',
        () {
      final subject = Queue();
      final originalItems = <Media>[media1, media2, media3];
      subject.addAll(originalItems);

      // Move to media2
      subject.next();
      expect(subject.current, media2);

      // Shuffle
      subject.shuffle();
      expect(subject.size, 3);
      expect(subject.current, media2);

      // Add media1 copy as new item after current while shuffled
      final media4 = Media(
          id: 4,
          albumTitle: "Album 4",
          albumId: 4,
          ownerId: 4,
          name: "Nova Musica",
          url: "https://example.com/4.mp3",
          coverUrl: "https://example.com/cover4.jpeg",
          bigCoverUrl: "https://example.com/cover4_big.jpeg",
          author: "Artista 4",
          isLocal: false,
          isVerified: true,
          shareUrl: "");

      subject.add(media4, true);
      expect(subject.size, 4);

      // The new item should be right after current in shuffled view
      expect(subject.storage[subject.index + 1].item, media4);

      // Unshuffle
      subject.unshuffle();

      // Original order should be restored with new item at the end
      expect(subject.size, 4);
      expect(subject.items[0], media1);
      expect(subject.items[1], media2);
      expect(subject.items[2], media3);
      expect(subject.items[3], media4);

      // Verify each item's cover matches its name
      expect(subject.storage[0].item.name, "O Bebe");
      expect(subject.storage[0].item.coverUrl, media1.coverUrl);
      expect(subject.storage[1].item.name, "Solteiro Largado");
      expect(subject.storage[1].item.coverUrl, media2.coverUrl);
      expect(subject.storage[2].item.name, "Borrachinha");
      expect(subject.storage[2].item.coverUrl, media3.coverUrl);
      expect(subject.storage[3].item.name, "Nova Musica");
      expect(subject.storage[3].item.coverUrl, "https://example.com/cover4.jpeg");
    });

    test(
        'AddAll with enqueueAfterCurrent during shuffle should preserve original order on unshuffle',
        () {
      final subject = Queue();
      subject.addAll([media1, media2, media3]);

      subject.next();
      expect(subject.current, media2);

      subject.shuffle();

      final media4 = Media(
          id: 4,
          albumTitle: "Album 4",
          albumId: 4,
          ownerId: 4,
          name: "Nova Musica 1",
          url: "https://example.com/4.mp3",
          coverUrl: "https://example.com/cover4.jpeg",
          bigCoverUrl: "https://example.com/cover4_big.jpeg",
          author: "Artista 4",
          isLocal: false,
          isVerified: true,
          shareUrl: "");

      final media5 = Media(
          id: 5,
          albumTitle: "Album 5",
          albumId: 5,
          ownerId: 5,
          name: "Nova Musica 2",
          url: "https://example.com/5.mp3",
          coverUrl: "https://example.com/cover5.jpeg",
          bigCoverUrl: "https://example.com/cover5_big.jpeg",
          author: "Artista 5",
          isLocal: false,
          isVerified: true,
          shareUrl: "");

      subject.addAll([media4, media5], enqueueAfterCurrent: true);
      expect(subject.size, 5);

      // New items should be after current in shuffled view
      expect(subject.storage[subject.index + 1].item, media4);
      expect(subject.storage[subject.index + 2].item, media5);

      subject.unshuffle();

      // Original order restored, new items at end
      expect(subject.items[0], media1);
      expect(subject.items[1], media2);
      expect(subject.items[2], media3);
      expect(subject.items[3], media4);
      expect(subject.items[4], media5);
    });
  });
}
