import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smaws/aws.dart';
import 'package:smplayer/player.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:smplayer_example/app_colors.dart';
import 'package:smplayer_example/ui_data.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SMPlayer extends StatefulWidget {
  SMPlayer({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SMPlayerState();
}

class _SMPlayerState extends State<SMPlayer> {
  late Player _player;
  Media? currentMedia;
  String mediaLabel = '';
  Duration duration = Duration(seconds: 0);
  Duration position = Duration(seconds: 0);
  var _shuffled = false;

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
        localMediaValidator: (m) async => m.url,
        initializeIsar: false,
      );
      player.onEvent.listen((Event event) async {
        // print(
        //     "Event: [${event.type}] [${event.media.author}-${event.media.name}] [${event.position}] [${event.duration}]");

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

      player.enqueue(media1);
      player.enqueue(media2);

      if (!mounted) return;

      setState(() {
        _player = player;
      });
    } on PlatformException {}
  }

  Future<CookiesForCustomPolicy> cookieSigner() async {
    const key = [
      'LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQ0KTUlJRW93SUJBQUtDQVFFQ',
      'W9TUURNQVU0SWd6RFNpa3A1U1dDSWRmNldFQldkMXFJd1JyQXpLS2NRbXBNbDE3bQ0KbDdL',
      'SGsraXFOTktPVWYzdEsxTFZjeEJIUU1udkZoeTN2RUhqQ2kzdVJtYXpDakRHRGZsanN2Q3N5SlNRNXc4eA0KRk5mQT',
      'ROM1QyNFdBVlBBc3ptT2JiaWNyTDFqWEV2OGpGcXZWd0tnUUlQalpTek1haDE4Z0lJZ2xFWXk0eXdvTQ0KUVZwaGE5S1R',
      'Mdy83QlZvd1REWWhRQ3NjZlBmbUxXSmlwT01oV3F3aUhNRkNTUFYyd3JobERId0N2T0ZhUXlnYg',
      '0KeHNNeEtUY0dNSXNkMEZnZFA4UVBva2JvT3ZQdEI1RnA5W',
      'm42M0thMTY1WFVYTW96MEk5amFvTFhCYXhteHlNeQ0KTmdmYzcxRTJ3R0ZZNFpicndJdHNmWXNyZlhUUlJQaU',
      'JpK0hnQndJREFRQUJBb0lCQUVTQVhxcUhUWG1NRzJq',
      'bg0KWHR2K3VmZFJMU2RmRW1MaXBjZ1JhMnlTcEFMSDFZOXoxR3NnaGVvbXVsU0NQZVkxSUNHT3NSYWRFTzFGNnRGbg0KbStQM3ptQ0Ji',
      'ZzJYa3Z6K0J2UGgxTFE1QS9xd3pYaXNTSjBucXVMczZpY2o5WTRtRzZZUlNmM2x3TUg3N2xJeA0KQytXV',
      'Fh1YnJpdys1T2daeHp4RkZLdzhwVVRqSC9YMDZ0azJsY2pIY3dzUHRzdVliN1ZBVWJDKy9Cdkd2ZFBwMg0KdWk0cy96Q0RYak',
      '5RQ2x6Y1BCaFZ1WUt0ZXVTK2VXSTFubFZJdGlwdUJQZFAzbWlKWC9xZzluSE9vWEdPMW5PTw0KRkFIdExvdkt5VGpXTVh5L3ZWcVlpa3JrVnNwMGF6Yk1yd2pTZ1lsbVJ1dFpCQm1DR1J4bW5Gc1BJSC92Z3RONQ0K',
      'cWNVeXJRRUNnWUVBK0pxdHc0L1lVSENVczlBYk8zN1psczAxdEdsOHVnZzk2ZlZjSU4',
      '4bzFhelBCOFZ4cHlTLw0KTGVGOHVUS1AvTVdFSXBKS2hGczNxZGFUY2l2bTFKUGdPclN0Z1NJbmtjWWx1SDBBMnFxV0pVQ29ESjJ5Snc5bQ0KMmRSZ1ZyeUE5SzlHMFV4SVg2',
      'Yjg5WVZyanZ1SlpvRmZ0OG1LTWMxNDQ5S3hXZ2FlczQ4Z0tXY0NnWUVBcGU4Ng0KZVRUNzFuazJISVoyc0VZVXpVaThLeFQ5RFlJVlZZMlg0QWd3VGRWMldOK3dYZmoyekxjckhVK1ZxNytoYzlEcw0KNEc',
      'wUGp2QmovMHRaNExOZmxjTDc3NTU0NnNNRW1sVEpkZmY1V3RhSW1D',
      'U2VYejUwUnIyYjZRaEtiR2F2eHY4UQ0KYm5YalRBTjJTTDNsdkN6c0E3Z1ZHMXRrWlNkQTJXT25JRXJ1VUdFQ2dZQUM4NE1na1RLV01kL3lDb1JvUG1kQw0KM1FqSU',
      'xZQm5qUFYvTTRSMmQyKzZxYVNEaVJxQ1MzTmhqZzIyL1J5c2VZUEtEVWFKTDdRSGRoNmwrbE54THBnNA0KMmpBOUdqU3lERklpVUltVUR2WmR',
      'WdGtuM1M5aU8xS1RQMnd0VzJ1RWZCZ3hIK0MwRWYxcXhMeTBJOVJMdlRsdg0KcXhyUzRJZVEzTTF5TGlYd0o4RFAvUU',
      'tCZ0dOTXBVNXhnWi9ZaTZSSVozQ1hqODFGa0sycmNzQUpyNkN5Q2tnYw0KUG1QbHNWd0FDUGhEaTlYNGEwbXd',
      'IWjVaSUZKQm5lK3o5RktTMHhTczBBMWk2bm1oNU1pQnFsUzYvZDhwakNJWA0Ka2xaaytmc3FOc2hDaEt6c3ZRZVlXWWxEYmorRTFoMTBXT0JkVmdTejkyNUQ1NzFXQlBPSkhxeFY4RDNubjlUNA0KWW1NaEFvR0JBSTJKb',
      'llnekF3bWpXWVNzOEFXZWpSUUNDd0MwTEdLSVdLU2t6U2NVTkZyajJzWE5pRkQrVXhjcA0KWWJsbXluRU9jOFVTcXBOTjlBQStXZytuaHJoVTVMeS9uWWpaRmZIQ3BtQnlkQlpPMEpxOGtS',
      'b0pZYnA1RkpJag0KNDlVMlJUMDdTSElOQWV5cXRxS0cyQ0RWMFdmTCtKb2p',
      'yUk9NTmRxZHdXUWNiM1N5dmxvOA0KLS0tLS1FTkQgUlNBIFBSSVZBVEUgS0VZLS0tLS0NCg',
      '==',
    ];
    final signer = CookieSigner.from(
      utf8.decode(base64.decode(key.join())),
      isDirect: true,
    );
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

    if (_player.state == PlayerState.IDLE && _player.current != null) {
      int result = await _player.play(_player.current!);
      if (result == Player.Ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Audio is now playing!!!!')));
      }
    } else if (_player.state == PlayerState.BUFFERING &&
        _player.current != null) {
      int result = await _player.resume();
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
      int result = await _player.resume();
      if (result == Player.Ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Audio is now playing again!!!!')));
      }
    } else {
      int? result = await _player.next();
      if (result == Player.Ok) {
        ScaffoldMessenger.of(context).showSnackBar(
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
      return "Tocando: ${currentMedia!.author} - ${currentMedia!.name}";
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
