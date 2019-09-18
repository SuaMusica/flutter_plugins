import 'dart:io';

import 'package:aws/aws.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suamusica_player/player.dart';
import 'package:suamusica_player/src/media.dart';
import 'package:suamusica_player/src/player.dart';

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
    testWidgets('Adding null media shall throw exception',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      expect(() => subject.enqueue(null), throwsArgumentError);
    });
    testWidgets('Adding media to an empty queue shall make it the queue top',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      expect(subject.size, 1);
      expect(subject.top, media1);
    });
    testWidgets('The queue shall support multiple items',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });
    testWidgets('Playing a media shall replace the queue top',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.play(media3);
      expect(subject.size, 2);
      expect(subject.top, media3);
      expect(subject.items, [media3, media2]);
    });
    testWidgets('Removing null media shall throw exception',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      expect(() => subject.remove(null), throwsArgumentError);
    });
    testWidgets('Removing a media shall be supported',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      subject.remove(media2);

      expect(subject.size, 2);
      expect(subject.top, media1);
      expect(subject.items, [media1, media3]);
    });
    testWidgets('Add all with null list shall throw an exception',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      expect(() => subject.enqueueAll(null), throwsArgumentError);
    });
    testWidgets('Add all shall be supported', (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      final items = List<Media>();
      for (int i = 0; i < 10; ++i) {
        items.addAll([media1, media2, media3]);
      }
      subject.enqueueAll(items);
      expect(subject.size, 30);
      expect(subject.top, media1);
      expect(subject.items, items);
    });
    testWidgets('Shuffle shall be supported', (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
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
    testWidgets('Unshuffle shall be supported', (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
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
    testWidgets('Rewind on empty queue shall raise an error',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      expect(() => subject.rewind(), throwsAssertionError);
    });
    testWidgets('Rewind on a queue that was not played shall raise an error',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      expect(() => subject.rewind(), throwsAssertionError);
    });
    testWidgets('Rewind shall be supported', (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      subject.play(media1);

      subject.rewind();

      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });
    testWidgets('Previous on empty queue shall raise an error',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      expect(() => subject.previous(), throwsAssertionError);
    });
    testWidgets('Previous on a queue that was not played shall raise an error',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      expect(() => subject.previous(), throwsAssertionError);
    });
    testWidgets('Previous shall act as rewind', (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      subject.play(media1);

      subject.previous();

      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });
    testWidgets(
        'Two consecutive previous invocation shall really go the previous track',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      await tester.pump(Duration(seconds: 3));

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
    testWidgets(
        'Two consecutive previous invocation with interval greater than 1 sec shall solely rewind',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();

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
    testWidgets('Next on empty queue shall raise an error',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      expect(() => subject.next(), throwsAssertionError);
    });
    testWidgets('Next on a queue that was not played shall start playing it',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);

      expect(await subject.next(), Player.Ok);
      expect(subject.size, 3);
      expect(subject.top, media1);
      expect(subject.items, [media1, media2, media3]);
    });
    testWidgets('Next on a queue that is playing shall move to the next',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();

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
    testWidgets('Next when reaching the end of the queue shall return null',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();

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
    testWidgets('Clear shall remove all tracks from queue',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();

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
    testWidgets('Top on an unplayed queue shall return the top of the queue',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      expect(subject.size, 3);
      expect(subject.top, media1);
    });

    testWidgets('Current on an unplayed queue shall return null',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump();
      subject.enqueue(media1);
      subject.enqueue(media2);
      subject.enqueue(media3);
      expect(subject.size, 3);
      expect(subject.current, null);
    });
  }); 

  group('Events', () {
    testWidgets('Test event emit chain',
        (WidgetTester tester) async {
      final subject = Player(cookieSigner);
      await tester.pumpWidget(new SMPlayer(player: subject));
      await tester.pump(Duration(seconds: 5));
      await subject.play(media1);

      // TODO: Fix this!
      // subject.onEvent.listen((Event event) async {
      //   print("HERE: $event");
      // });

      // expect(subject.onEvent, emitsInOrder([
      //   Event(type: EventType.PLAY_REQUESTED, media: media1),
      //   Event(type: EventType.BEFORE_PLAY, media: media1),
      //   Event(type: EventType.PLAYING, media: media1)
      // ]));
    });
  });
}

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
