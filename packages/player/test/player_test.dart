import 'dart:io';

import 'package:smaws/aws.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smplayer/player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('suamusica.com.br/player');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async {
      return Player.Ok;
    },
  );

  final media1 = Media(
      id: 1,
      albumTitle: "Album",
      albumId: 2,
      name: "O Bebe",
      url: "https://android.suamusica.com.br/373377/2238511/02+O+Bebe.mp3",
      coverUrl:
          "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
      bigCoverUrl:
          "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
      author: "Xand Avião",
      isLocal: false,
      isVerified: true,
      ownerId: 2,
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
      ownerId: 2,
      albumId: 2,
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

  group('Player operations', () {
    test('Adding media to an empty queue shall make it the queue top',
        () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      expect(subject.size, 1);
      expect(subject.top, media1);
    });
    test('The queue shall support multiple items', () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Playing a media shall replace the queue top', () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.play(media3);
      expect(subject.size, 2);
      expect(subject.top, media3);
      expect(subject.items, [media3, media2]);
    });

    test('Removing a media shall be supported', () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      subject.removeByPosition(positionsToDelete: [1], isShuffle: false);

      expect(subject.size, 2);
      expect(subject.top, media1);
      expect(subject.items, [media1, media3]);
    });

    test('Add all shall be supported', () async {
      final subject = createPlayer();
      final items = <Media>[];
      for (int i = 0; i < 10; ++i) {
        items.addAll([media1, media2, media3]);
      }
      subject.enqueueAll(items);
      expect(subject.size, 30);
      expect(subject.top, media1);
      expect(subject.items, items);
    });
    test('Shuffle shall be supported', () async {
      final subject = createPlayer();
      final items = <Media>[];
      final interactions = 100;
      for (int i = 0; i < interactions; ++i) {
        items.addAll([media1, media2, media3]);
      }
      subject.enqueueAll(items);
      subject.shuffle();

      expect(subject.size, 3 * interactions);
      expect(subject.top, media1);
      expect(subject.items, isNot(items));
    });
    test('Unshuffle shall be supported', () async {
      final subject = createPlayer();
      final items = <Media>[];
      final interactions = 100;
      for (int i = 0; i < interactions; ++i) {
        items.addAll([media1, media2, media3]);
      }
      subject.enqueueAll(items);
      subject.shuffle();

      expect(subject.size, 3 * interactions);
      expect(subject.top, media1);
      expect(subject.items, isNot(items));

      subject.unshuffle();

      expect(subject.size, 3 * interactions);
      expect(subject.top, media1);
      expect(subject.items, items);
    });
    test('Rewind on empty queue shall raise an error', () async {
      final subject = createPlayer();
      expect(subject.rewind(), throwsAssertionError);
    });
    test('Rewind on a queue that was not played shall raise an error',
        () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      expect(await subject.rewind(), 1);
    });
    test(
      'Rewind shall be supported',
      () async {
        final subject = createPlayer();
        subject.enqueue(media1);
        subject.enqueue(media2);
        subject.enqueue(media3);
        subject.play(media1);

        subject.rewind();

        expect(subject.size, 3);
        expect(subject.top, media1);
        expect(subject.items, [media1, media2, media3]);
      },
    );
    test(
      'Previous on empty queue shall raise an error',
      () async {
        final subject = createPlayer();
        expect(() => subject.previous(), throwsRangeError);
      },
    );
    test('Previous on a queue that was not played shall raise an error',
        () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      final a = await subject.previous();
      expect(a, 1);
    });
    test('Previous shall act as rewind', () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      subject.play(media1);

      subject.previous();

      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });
    test(
        'Two consecutive previous invocation shall really go the previous track',
        () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.previous(), Player.Ok);
      expect(await subject.previous(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(subject.items, [media1, media2, media3]);
    });
    test(
        'Two consecutive previous invocation with interval greater than 1 sec shall solely rewind',
        () async {
      final subject = createPlayer();

      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.previous(), Player.Ok);
      sleep(Duration(seconds: 3));
      expect(await subject.previous(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Next on empty queue shall raise an error', () async {
      final subject = createPlayer();
      expect(await subject.next(), null);
    });
    test('Next on a queue that was not played shall start playing it',
        () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Next on a queue that is playing shall move to the next', () async {
      final subject = createPlayer();

      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      expect(await subject.next(), Player.Ok);

      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Next when reaching the end of the queue shall return null', () async {
      final subject = createPlayer();

      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), null);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), null);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Clear shall remove all tracks from queue', () async {
      final subject = createPlayer();

      final items = <Media>[];
      final interactions = 100;
      for (int i = 0; i < interactions; ++i) {
        items.addAll([media1, media2, media3]);
      }
      subject.enqueueAll(items);
      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3 * interactions);
      expect(subject.top, media1);
      expect(subject.items, items);

      subject.clear();
      expect(subject.size, 0);
      expect(subject.top, null);
      expect(subject.items, []);
    });
    test('Top on an unplayed queue shall return the top of the queue',
        () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      expect(subject.size, 3);
      expect(subject.top, media1);
    });
    test('Current on an unplayed queue shall return media1', () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      expect(subject.size, 3);
      expect(subject.current, media1);
    });
  });
  group('Events', () {
    test('Test event emit chain', () async {
      final subject = createPlayer();
      await subject.play(media1);

      // expectLater(
      //     subject.onEvent,
      //     emitsInOrder([
      //       Event(type: EventType.PLAY_REQUESTED, media: media1),
      //       Event(type: EventType.BEFORE_PLAY, media: media1),
      //       Event(type: EventType.PLAYING, media: media1)
      //     ]));
    });
  });
}

Player createPlayer() => Player(
      cookieSigner: cookieSigner,
      autoPlay: false,
      playerId: "smplayer",
      localMediaValidator: null,
      initializeIsar: false,
    );

Future<CookiesForCustomPolicy> cookieSigner() async {
  DateTime expiresOn = DateTime.now().add(Duration(hours: 12));
  return CookiesForCustomPolicy(
    expires: expiresOn,
    policy: Entry(CookieSigner.PolicyKey, "ABC"),
    keyPairId: Entry(CookieSigner.KeyPairIdKey, "ABC"),
    signature: Entry(CookieSigner.SignatureKey, "ABC"),
  );
}

class SMPlayer extends StatefulWidget {
  final player;

  SMPlayer({
    Key? key,
    this.player,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SMPlayerState(player);
}

class _SMPlayerState extends State<SMPlayer> {
  final player;

  _SMPlayerState(this.player);

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
