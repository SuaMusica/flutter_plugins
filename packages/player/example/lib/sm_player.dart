import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:aws/aws.dart';
import 'package:suamusica_player/player.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:suamusica_player_example/app_colors.dart';
import 'package:suamusica_player_example/ui_data.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SMPlayer extends StatefulWidget {
  SMPlayer({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SMPlayerState();
}

class _SMPlayerState extends State<SMPlayer> {
  Player _player;
  Media currentMedia;
  String mediaLabel = '';
  var duration = Duration(seconds: 0);
  var position = Duration(seconds: 0);
  var _shuffled = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      var player = Player(
        cookieSigner: cookieSigner,
        autoPlay: false,
      );
      player.onEvent.listen((Event event) async {
        print("Event: [${event.type}] [${event.media.author}-${event.media.name}] [${event.position}] [${event.duration}]");

        switch (event.type) {
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
                  currentMedia = event.media;
                  mediaLabel = toMediaLabel();
                });
              }
            }
            break;
          case EventType.PLAYING:
            setState(() {
              currentMedia = event.media;
              mediaLabel = toMediaLabel();
            });
            break;

          case EventType.PAUSED:
            setState(() {
              currentMedia = event.media;
              mediaLabel = toMediaLabel();
            });
            break;

          case EventType.NEXT:
          case EventType.PREVIOUS:
            setState(() {
              currentMedia = event.media;
              mediaLabel = toMediaLabel();
            });
            break;
          default:
        }
      });

      var media1 = Media(
          id: "1",
          name: "Track 1",
          url:
              "https://android.suamusica.com.br/373377/2238511/03+Solteiro+Largado.mp3",
          coverUrl:
              "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
          author: "Xand Avião",
          isLocal: false,
          isVerified: true,
          shareUrl: "");

      var media2 = Media(
          id: "2",
          name: "Track 2",
          url: "https://android.suamusica.com.br/373377/2238511/02+O+Bebe.mp3",
          coverUrl:
              "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
          author: "Xand Avião",
          isLocal: false,
          isVerified: true,
          shareUrl: "");

      var media3 = Media(
          id: "3",
          name: "Track 3",
          url:
              "https://android.suamusica.com.br/373377/2238511/03+Solteiro+Largado.mp3",
          coverUrl:
              "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
          author: "Xand Avião",
          isLocal: false,
          isVerified: true,
          shareUrl: "");

      var media4 = Media(
          id: "4",
          name: "Track 4",
          url: "https://android.suamusica.com.br/373377/2238511/02+O+Bebe.mp3",
          coverUrl:
              "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
          author: "Xand Avião",
          isLocal: false,
          isVerified: true,
          shareUrl: "");

      var media5 = Media(
          id: "5",
          name: "Track 5",
          url:
              "https://android.suamusica.com.br/373377/2238511/03+Solteiro+Largado.mp3",
          coverUrl:
              "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
          author: "Xand Avião",
          isLocal: false,
          isVerified: true,
          shareUrl: "");

      var media6 = Media(
          id: "6",
          name: "Track 6",
          url: "https://android.suamusica.com.br/373377/2238511/02+O+Bebe.mp3",
          coverUrl:
              "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
          author: "Xand Avião",
          isLocal: false,
          isVerified: true,
          shareUrl: "");

      player.enqueue(media1);
      player.enqueue(media2);
      // player.enqueue(media3);
      // player.enqueue(media4);
      // player.enqueue(media5);
      // player.enqueue(media6);

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
        resource, keyPairId, expiresOn, null, null);

    return cookies;
  }

  String get positionText {
    var minutes = position.inMinutes.toString().padLeft(2, "0");
    var seconds = (position.inSeconds % 60).toString().padLeft(2, "0");
    return minutes + ":" + seconds;
  }

  String get durationText {
    var minutes = duration.inMinutes.toString().padLeft(2, "0");
    var seconds = (duration.inSeconds % 60).toString().padLeft(2, "0");
    return minutes + ":" + seconds;
  }

  void playOrPause() async {
    print("Player State: ${_player.state}");

    if (_player.state == PlayerState.IDLE && _player.current != null) {
      int result = await _player.play(_player.current);
      if (result == Player.Ok) {
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text('Audio is now playing!!!!')));
      }
    } else if (_player.state == PlayerState.BUFFERING && _player.current != null) {
      int result = await _player.resume();
      if (result == Player.Ok) {
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text('Audio is now playing!!!!')));
      }  
    } else if (_player.state == PlayerState.PLAYING) {
      int result = await _player.pause();
      if (result == Player.Ok) {
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text('Audio is now paused!!!!')));
      }
    } else if (_player.state == PlayerState.PAUSED) {
      int result = await _player.resume();
      if (result == Player.Ok) {
        Scaffold.of(context).showSnackBar(
            SnackBar(content: Text('Audio is now playing again!!!!')));
      }
    } else {
      int result = await _player.next();
      if (result == Player.Ok) {
        Scaffold.of(context).showSnackBar(
            SnackBar(content: Text('Audio is now playing again!!!!')));
      }
    }
  }

  void seek(double p) {
    setState(() {
      position = Duration(milliseconds: p.round());
      if (_player.state != PlayerState.STOPPED) {
        _player.seek(position);
      }
    });
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
        _player.unshuffle();
        _shuffled = false;
      } else {
        _player.shuffle();
        _shuffled = true;
      }
    });
  }

  toMediaLabel() {
    if (currentMedia != null) {
      return "Tocando: ${currentMedia.author} - ${currentMedia.name}";
    } else {
      return '';
    }
  }

  _repeatModeToColor() {
    if (_player.repeatMode == RepeatMode.NONE) {
      return AppColors.black;
    } else if (_player.repeatMode == RepeatMode.QUEUE) {
      return AppColors.primary;
    } else {
      return AppColors.darkPink;
    }
  }

  _changeRepeatMode() {
    if (_player.repeatMode == RepeatMode.NONE) {
      setState(() {
        _player.repeatMode = RepeatMode.QUEUE;
      });
    } else if (_player.repeatMode == RepeatMode.QUEUE) {
      setState(() {
        _player.repeatMode = RepeatMode.TRACK;
      });
    } else {
      setState(() {
        _player.repeatMode = RepeatMode.NONE;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<int> colorCodes = <int>[600, 500, 100];

    return Container(
      padding: EdgeInsets.only(top: 8.0, bottom: 0.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Stack(children: <Widget>[
            Wrap(
              direction: Axis.horizontal,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 20.0),
                      child:
                          Text(positionText, style: TextStyle(fontSize: 14.0)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 20.0),
                      child:
                          Text(durationText, style: TextStyle(fontSize: 14.0)),
                    )
                  ],
                ),
              ],
            ),
            duration == null
                ? Container()
                : Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 5.0),
                    child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.0,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7.0),
                          showValueIndicator: ShowValueIndicator.always,
                        ),
                        child: Slider(
                          activeColor: AppColors.redPink,
                          inactiveColor: AppColors.inactiveColor,
                          min: 0.0,
                          max: duration.inMilliseconds.toDouble(),
                          value: position?.inMilliseconds?.toDouble() ?? 0.0,
                          onChanged: (double value) {
                            seek(value);
                          },
                        ))),
          ]),
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
                            ))),
                  ),
                  Material(
                      borderRadius: BorderRadius.circular(58.0),
                      clipBehavior: Clip.hardEdge,
                      child: IconButton(
                        iconSize: 58,
                        icon: _player.state == PlayerState.PLAYING
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
                            ))),
                  ),
                ],
              )),
              Container(
                margin: EdgeInsets.only(right: 8),
                child: Material(
                    borderRadius: BorderRadius.circular(25.0),
                    clipBehavior: Clip.hardEdge,
                    child: IconButton(
                      iconSize: 25,
                      icon: SvgPicture.asset(UIData.btPlayerRepeat,
                          color: _repeatModeToColor()),
                      onPressed: _changeRepeatMode,
                    )),
              ),
            ],
          ),
          SizedBox(height: 30),
          Text(mediaLabel),
          SizedBox(height: 30),
          Expanded(
              child: SizedBox(
            height: 200,
            child: ListView.separated(
              padding: const EdgeInsets.all(8.0),
              itemCount: _player.items.length,
              itemBuilder: (BuildContext context, int index) {
                var media = _player.items[index];
                return Container(
                  height: 50,
                  color: Colors.blue[colorCodes[index % 3]],
                  child: Center(child: Text('${media.id} - ${media.name}')),
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(),
            ),
          ))
        ],
      ),
    );
  }
}
