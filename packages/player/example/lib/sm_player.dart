import 'package:flutter/material.dart';
import 'package:smaws/aws.dart';
import 'package:smplayer/player.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:smplayer_example/app_colors.dart';
import 'package:smplayer_example/service_discovery.dart';
import 'package:smplayer_example/ui_data.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mdns_plugin/mdns_plugin.dart';

class SMPlayer extends StatefulWidget {
  SMPlayer({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SMPlayerState();
}

var media1 = Media(
  id: 1,
  albumTitle: "Album",
  albumId: 1,
  name: "Track 1",
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
  isSpot: false,
  ownerId: 0,
  playlistId: 0,
);

var media3 = Media(
  id: 3,
  albumTitle: "Album unsigned",
  albumId: 1,
  name: "Track unsigned",
  url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
  coverUrl: "https://picsum.photos/500/500",
  bigCoverUrl: "https://picsum.photos/500/500",
  author: "Unknown",
  fallbackUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
  isLocal: false,
  isVerified: true,
  shareUrl: "",
  isSpot: false,
  ownerId: 0,
  playlistId: 0,
);

var media4 = Media(
  id: 4,
  albumTitle: "É o Grelo",
  albumId: 1,
  name: "01 - VIDA LOK4 part.1",
  url:
      "https://ios-stream.suamusica.com.br/61523203/4435593/stream/01+-+VIDA+LOK4+part.1.m3u8",
  coverUrl:
      "https://images.suamusica.com.br/FTpOBQiRWVspoErSnNQgZxhou40=/500x500/filters:format(webp)/61523203/4435593/cd_cover.jpeg",
  bigCoverUrl:
      "https://images.suamusica.com.br/FTpOBQiRWVspoErSnNQgZxhou40=/500x500/filters:format(webp)/61523203/4435593/cd_cover.jpeg",
  author: "É o Grelo",
  fallbackUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
  isLocal: false,
  isVerified: true,
  shareUrl: "",
  isSpot: false,
  ownerId: 0,
  playlistId: 0,
);

var media2 = Media(
  id: 2,
  albumTitle: "Album",
  albumId: 1,
  name: "Track 2",
  url: "https://android.suamusica.com.br/373377/2238511/02+O+Bebe.mp3",
  coverUrl:
      "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
  bigCoverUrl:
      "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
  author: "Xand Avião",
  isLocal: false,
  isVerified: true,
  shareUrl: "",
  isSpot: false,
  ownerId: 0,
  playlistId: 0,
);

class _SMPlayerState extends State<SMPlayer> {
  late Player _player;
  Media? currentMedia;
  Duration duration = Duration(seconds: 0);
  Duration position = Duration(seconds: 0);
  var _shuffled = false;
  bool _loading = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      var player = Player(
        playerId: "smplayer",
        cookieSigner: cookieSigner,
        autoPlay: false,
        localMediaValidator: (m) => m.url,
        initializeIsar: false,
      );
      player.onEvent.listen((Event event) async {
        print("Event: ${event.type}");
        switch (event.type) {
          case EventType.IDLE:
            setState(() {
              position = Duration(seconds: 0);
              duration = Duration(seconds: 0);
            });
            break;
          case EventType.BEFORE_PLAY:
            if (event is BeforePlayEvent) {
              // event.continueWithLoadingOnly();
              event.continueWithLoadingAndPlay();
            }
            break;

          case EventType.POSITION_CHANGE:
            if (event is PositionChangeEvent) {
              if (event.position <= event.duration) {
                setState(() {
                  position = event.position;
                  duration = event.duration;
                });
              }
            }
            break;

          case EventType.STATE_READY:
            setState(() {
              _loading = false;
            });
            break;
          case EventType.PLAYING:
            break;

          case EventType.SET_CURRENT_MEDIA_INDEX:
            setState(() {
              _currentIndex = event.queuePosition;
            });
            break;
          case EventType.PAUSED:
            break;
          case EventType.BUFFERING:
            setState(() {
              _loading = true;
            });
            break;
          case EventType.NEXT:
          case EventType.PREVIOUS:
            break;
          default:
        }
      });

      final listOfMedias = <Media>[];

      // for (var i = 0; i < 250; i++) {
      listOfMedias.addAll([media1, media2, media3, media4]);
      // }

      player.enqueueAll(listOfMedias, autoPlay: false);

      if (!mounted) return;

      setState(() {
        _player = player;
      });
    } on PlatformException {}
  }

  Future<CookiesForCustomPolicy> cookieSigner() async {
    final signer = CookieSigner.from('assets/pk-APKAIORXYQDPHCKBDXYQ.pem');
    const resource = 'https://*.suamusica.com.br*';
    const keyPairId = "APKAIORXYQDPHCKBDXYQ";
    DateTime expiresOn = DateTime.now().add(Duration(hours: 12));

    final cookies = await signer.getCookiesForCustomPolicy(
      resourceUrlOrPath: resource,
      keyPairId: keyPairId,
      expiresOn: expiresOn,
    );

    return cookies;
  }

  String get positionText {
    var minutes = position.inMinutes.toString().padLeft(2, "0");
    var seconds = (position.inSeconds % 60).toString().padLeft(2, "0");
    return (minutes) + ":" + seconds;
  }

  String get durationText {
    var minutes = duration.inMinutes.toString().padLeft(2, "0");
    var seconds = (duration.inSeconds % 60).toString().padLeft(2, "0");
    return (minutes) + ":" + seconds;
  }

  void playOrPause() async {
    print("Player State: ${_player.state}");

    if (_player.state == PlayerState.STATE_READY) {
      int result = await _player.play();
      if (result == Player.Ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Audio is now playing!!!!')));
      }
    } else if (_player.state == PlayerState.PLAYING) {
      int result = await _player.pause();
      if (result == Player.Ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Audio is now paused!!!!')));
      }
    } else if (_player.state == PlayerState.PAUSED) {
      int result = await _player.play();
      if (result == Player.Ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Audio is now playing again!!!!')));
      }
    }
  }

  void seek(double p) {
    setState(
      () {
        position = Duration(milliseconds: p.round());
        if (_player.state != PlayerState.STOPPED) {
          _player.seek(position);
        }
      },
    );
  }

  void next() {
    _player.next();
  }

  void previous() {
    _player.previous();
  }

  void shuffleOrUnshuffle() {
    setState(() {
      if (_shuffled) {
        _player.toggleShuffle();
        _shuffled = false;
      } else {
        _player.toggleShuffle();
        _shuffled = true;
      }
    });
  }

  toMediaLabel() {
    if (currentMedia != null) {
      return "Tocando: ${currentMedia!.author} - ${currentMedia!.name}";
    } else {
      return '';
    }
  }

  _repeatModeToColor() {
    if (_player.repeatMode == RepeatMode.REPEAT_MODE_OFF) {
      return AppColors.black;
    } else if (_player.repeatMode == RepeatMode.REPEAT_MODE_ALL) {
      return AppColors.primary;
    } else {
      return AppColors.darkPink;
    }
  }

  Future<void> pickLocalFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null) {
      String? filePath = result.files.single.path;
      var localMedia = Media(
        id: DateTime.now().millisecondsSinceEpoch, // Unique ID
        albumTitle: "Local Album",
        albumId: 0,
        name: result.files.single.name,
        url: filePath ?? "",
        coverUrl: "", // You can set a default cover URL or leave it empty
        bigCoverUrl: "",
        author: "Local Author",
        isLocal: true,
        isVerified: false,
        shareUrl: "",
        isSpot: false,
        ownerId: 0,
        playlistId: 0,
      );

      setState(() {
        _player.enqueueAll([localMedia], autoPlay: true);
      });
    }
  }

  Map<String, Uint8List> toTXTMap(Map<dynamic, dynamic>? txt) {
    final map = <String, Uint8List>{};
    txt?.forEach((key, value) {
      if (key != null && value != null) {
        map.putIfAbsent(key, () => value);
      }
    });

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final List<int> colorCodes = <int>[600, 500, 100];
    List<MDNSService> foundServices = [];

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: Text(
                'Media Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Remove all'),
              onTap: () {
                _player.stop();
                _player.removeAll();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.queue),
              title: Text('Add all medias (AutoPlay)'),
              onTap: () {
                setState(() {
                  _player.enqueueAll(
                    [media1, media2, media3, media4],
                    autoPlay: true,
                  );
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.queue),
              title: Text('Add all medias'),
              onTap: () {
                _player.enqueueAll(
                  [media1, media2, media3, media4],
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.folder),
              title: Text('Add local file'),
              onTap: () {
                pickLocalFile();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('Play from queue (second - 50 seconds)'),
              onTap: () {
                _player.playFromQueue(
                  1,
                  loadOnly: true,
                  position: Duration(seconds: 50),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Add media1'),
              onTap: () {
                _player.enqueueAll([media1]);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('SM Player'),
        actions: [
          IconButton(
            icon: Icon(Icons.cast),
            onPressed: () {
              ServiceDiscovery(
                (service) {
                  String castId =
                      String.fromCharCodes(service.map['txt']['id']);
                  _player.cast(castId);
                },
              ).startDiscovery();
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.only(top: 8.0, bottom: 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                Wrap(
                  direction: Axis.horizontal,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(left: 20.0),
                          child: Text(positionText,
                              style: TextStyle(fontSize: 14.0)),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 20.0),
                          child: Text(durationText,
                              style: TextStyle(fontSize: 14.0)),
                        )
                      ],
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 5.0),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.0,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                      showValueIndicator: ShowValueIndicator.always,
                    ),
                    child: Slider(
                      activeColor: AppColors.redPink,
                      inactiveColor: AppColors.inactiveColor,
                      min: 0.0,
                      max: duration.inMilliseconds.toDouble(),
                      value: position.inMilliseconds.toDouble(),
                      onChanged: (double value) {
                        seek(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 8),
                  child: Material(
                      borderRadius: BorderRadius.circular(25.0),
                      clipBehavior: Clip.hardEdge,
                      child: IconButton(
                        iconSize: 25,
                        icon: SvgPicture.asset(UIData.btPlayerSuffle,
                            color: _shuffled
                                ? AppColors.darkPink
                                : AppColors.primary),
                        onPressed: shuffleOrUnshuffle,
                      )),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(left: 8, right: 8),
                        child: Material(
                          borderRadius: BorderRadius.circular(40.0),
                          clipBehavior: Clip.hardEdge,
                          child: IconButton(
                            onPressed: previous,
                            iconSize: 40,
                            icon: Container(
                              child: SvgPicture.asset(UIData.btPlayerPrevious),
                            ),
                          ),
                        ),
                      ),
                      Material(
                          borderRadius: BorderRadius.circular(58.0),
                          clipBehavior: Clip.hardEdge,
                          child: IconButton(
                            iconSize: 58,
                            icon: _loading
                                ? Container(
                                    width: 58,
                                    height: 58,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 5,
                                    ),
                                  )
                                : _player.state == PlayerState.PLAYING
                                    ? SvgPicture.asset(UIData.btPlayerPause)
                                    : SvgPicture.asset(UIData.btPlayerPlay),
                            onPressed: playOrPause,
                          )),
                      Container(
                        margin: EdgeInsets.only(left: 8, right: 8),
                        child: Material(
                          borderRadius: BorderRadius.circular(40.0),
                          clipBehavior: Clip.hardEdge,
                          child: IconButton(
                            onPressed: next,
                            iconSize: 40,
                            icon: Container(
                              child: SvgPicture.asset(UIData.btPlayerNext),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Material(
                      borderRadius: BorderRadius.circular(25.0),
                      clipBehavior: Clip.hardEdge,
                      child: IconButton(
                        iconSize: 25,
                        icon: SvgPicture.asset(UIData.btPlayerRepeat,
                            color: _repeatModeToColor()),
                        onPressed: _player.toggleRepeatMode,
                      )),
                ),
              ],
            ),
            SizedBox(height: 30),
            if (_player.items.isNotEmpty)
              Text('Tocando: ${_player.items[_currentIndex].name}'),
            SizedBox(height: 30),
            Expanded(
              child: SizedBox(
                height: 200,
                child: ReorderableListView(
                  onReorder: (int oldIndex, int newIndex) {
                    if (newIndex > _player.items.length) {
                      newIndex = _player.items.length;
                    }
                    if (oldIndex < newIndex) {
                      newIndex--;
                    }
                    _player.reorder(oldIndex, newIndex);
                  },
                  children: _player.items
                      .mapIndexed(
                        (index, media) => GestureDetector(
                          key: Key('queueItemWidgetKey$index'),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              border: index == _currentIndex
                                  ? Border.all(color: Colors.red, width: 2.0)
                                  : null,
                              color: HSLColor.fromAHSL(
                                      0.8, (index * 137.5) % 360, 0.7, 0.8)
                                  .toColor(),
                            ),
                            child: Center(
                                child: Text('${media.id} - ${media.name}')),
                          ),
                          onTap: () {
                            _player.playFromQueue(index);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
