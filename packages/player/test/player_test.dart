import 'dart:io';

import 'package:smaws/aws.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smplayer/player.dart';
import 'package:smplayer/src/media.dart';
import 'package:smplayer/src/player.dart';

void main() {
  const MethodChannel channel = MethodChannel('suamusica_player');
  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return Player.Ok;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  final media1 = Media(
      id: "1",
      name: "O Bebe",
      url: "https://android.suamusica.com.br/373377/2238511/02+O+Bebe.mp3",
      coverUrl:
          "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
      author: "Xand Avião",
      isLocal: false,
      isVerified: true,
      shareUrl: "");

  final media2 = Media(
      id: "2",
      name: "Solteiro Largado",
      url:
          "https://android.suamusica.com.br/373377/2238511/03+Solteiro+Largado.mp3",
      coverUrl:
          "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
      author: "Xand Avião",
      isLocal: false,
      isVerified: true,
      shareUrl: "");

  final media3 = Media(
      id: "3",
      name: "Borrachinha",
      url: "https://android.suamusica.com.br/373377/2238511/05+Borrachinha.mp3",
      coverUrl:
          "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
      author: "Xand Avião",
      isLocal: false,
      isVerified: false,
      shareUrl: "");

  group('Player operations', () {
    test('Adding null media shall throw exception', () async {
      final subject = createPlayer();
      expect(() => subject.enqueue(null), throwsArgumentError);
    });
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
    test('Removing null media shall throw exception', () async {
      final subject = createPlayer();
      expect(() => subject.remove(null), throwsArgumentError);
    });
    test('Removing a media shall be supported', () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      subject.remove(media2);

      expect(subject.size, 2);
      expect(subject.top, media1);
      expect(subject.items, [media1, media3]);
    });
    test('Add all with null list shall throw an exception', () async {
      final subject = createPlayer();
      expect(() => subject.enqueueAll(null), throwsArgumentError);
    });
    test('Add all shall be supported', () async {
      final subject = createPlayer();
      final items = List<Media>();
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
      final items = List<Media>();
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
      final items = List<Media>();
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
      expect(() => subject.rewind(), throwsAssertionError);
    });
    test('Rewind on a queue that was not played shall raise an error',
        () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      expect(() => subject.rewind(), throwsAssertionError);
    });
    test('Rewind shall be supported', () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      subject.play(media1);

      subject.rewind();

      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Previous on empty queue shall raise an error', () async {
      final subject = createPlayer();
      expect(() => subject.previous(), throwsAssertionError);
    });
    test('Previous on a queue that was not played shall raise an error',
        () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      expect(() => subject.previous(), throwsAssertionError);
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
      expect(subject.current, media1);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.previous(), Player.Ok);
      expect(await subject.previous(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media1);
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
      expect(subject.current, media1);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.previous(), Player.Ok);
      sleep(Duration(seconds: 3));
      expect(await subject.previous(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Next on empty queue shall raise an error', () async {
      final subject = createPlayer();
      expect(() => subject.next(), throwsAssertionError);
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
      expect(subject.current, media1);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Next when reaching the end of the queue shall return null', () async {
      final subject = createPlayer();

      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media1);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media2);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(subject.items, [media1, media2, media3]);

      expect(await subject.next(), Player.NotOk);
      expect(subject.size, 3);
      expect(subject.current, media3);
      expect(subject.items, [media1, media2, media3]);
    });
    test('Clear shall remove all tracks from queue', () async {
      final subject = createPlayer();

      final items = List<Media>();
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
    test('Current on an unplayed queue shall return null', () async {
      final subject = createPlayer();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      expect(subject.size, 3);
      expect(subject.current, null);
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

Player createPlayer() => Player(cookieSigner: cookieSigner, autoPlay: false);

Future<CookiesForCustomPolicy> cookieSigner() async {
  DateTime expiresOn = DateTime.now().add(Duration(hours: 12));
  return CookiesForCustomPolicy(
    expiresOn,
    Entry(CookieSigner.PolicyKey, "ABC"),
    Entry(CookieSigner.KeyPairIdKey, "ABC"),
    Entry(CookieSigner.SignatureKey, "ABC"),
  );
}

class SMPlayer extends StatefulWidget {
  final player;

  SMPlayer({Key key, this.player}) : super(key: key);

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
