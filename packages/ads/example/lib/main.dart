import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smads/smads.dart';
import 'package:smads_example/widgets/widgets.dart';

void main() => runApp(
      ChangeNotifierProvider(
        create: (context) => PreRollNotifier(),
        child: MaterialApp(
          home: MyApp(),
        ),
      ),
    );

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late PreRollNotifier preRollNotifier;
  late PreRollController controller;

  StreamController<bool> _streamController = StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    preRollNotifier = context.read<PreRollNotifier>();
    controller = preRollNotifier.controller;

    _streamController.stream.listen((event) {
      debugPrint('event: $event');
    });
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
        centerTitle: true,
      ),
      body: Center(
        child: ListView(
          children: [
            SMAdsTile(
              icon: Icons.align_vertical_bottom_rounded,
              title: 'Call bottom sheet',
              onTap: () {
                controller.pause();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  builder: (context) {
                    return SMAdsBottomSheet(controller: controller);
                  },
                );
              },
            ),
            SMAdsTile(
              icon: Icons.audiotrack_rounded,
              title: 'Load audio',
              onTap: () {
                loadAds(
                  preRollNotifier: preRollNotifier,
                  target: audioTarget,
                );
              },
            ),
            SMAdsTile(
              icon: Icons.audiotrack_rounded,
              title: 'Load audio with delay for 5 seconds',
              onTap: () {
                debugPrint('[TESTE] 5 before');

                Future.delayed(Duration(seconds: 5), () {
                  debugPrint('[TESTE] 5 afer');
                  debugPrint('[Background] call load in bg video');
                  preRollNotifier.setShouldShow(true);
                  _streamController.add(true);
                  controller.load(audioTarget);
                  Future.delayed(Duration(seconds: 3), () {
                    controller.play();
                  });
                });
              },
            ),
            SMAdsTile(
              icon: Icons.audiotrack_rounded,
              title: 'Load audio with delay for 5 seconds pure',
              onTap: () {
                debugPrint('[TESTE] 5 before');

                Future.delayed(
                  Duration(seconds: 5),
                  () {
                    preRollNotifier.setShouldShow(true);
                    controller.load(audioTarget);
                    Future.delayed(Duration(milliseconds: 1), () {
                      controller.play();
                    });
                  },
                );
              },
            ),
            SMAdsTile(
              icon: Icons.video_call_rounded,
              title: 'Load video',
              onTap: () {
                loadAds(
                  preRollNotifier: preRollNotifier,
                  target: videoTarget,
                );
              },
            ),
            SMAdsTile(
              icon: Icons.video_call_rounded,
              title: 'Load video with delay for 5 seconds',
              onTap: () {
                Future.delayed(Duration(seconds: 5), () {
                  debugPrint('[Background] call load in bg video');
                  loadAds(
                    preRollNotifier: preRollNotifier,
                    target: videoTarget,
                  );
                });
              },
            ),
            SMAdsTile(
              icon: Icons.play_arrow_rounded,
              title: 'play',
              onTap: () {
                controller.play();
              },
            ),
            SMAdsTile(
              icon: Icons.pause_rounded,
              title: 'Pause',
              onTap: () {
                controller.pause();
              },
            ),
            SMAdsTile(
              icon: Icons.skip_next_rounded,
              title: 'Skip',
              onTap: () {
                controller.skip();
              },
            ),
            SMAdsTile(
              icon: Icons.delete_rounded,
              title: 'Dispose',
              onTap: () {
                context.read<PreRollNotifier>().setShouldShow(false);
                controller.dispose();
              },
            ),
            SizedBox(
              height: 50,
              child: Center(
                child: FutureBuilder<int>(
                  future: controller.screenStatus,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Text("Screen Status: ${snapshot.data}");
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ),
            Divider(),
            // StreamBuilder<bool>(
            //     stream: _streamController.stream,
            //     builder: (context, snapshot) {
            //       debugPrint('teste snapshot: ${snapshot.data}');
            //       return snapshot.hasData && snapshot.data!
            //           ? PreRollUI(
            //               controller: controller,
            //             )
            //           : SizedBox.shrink();
            //     }),
            PreRollUI(controller: controller),
          ],
        ),
      ),
    );
  }
}

class PreRollUI extends StatelessWidget {
  const PreRollUI({
    super.key,
    required this.controller,
  });

  final PreRollController controller;

  @override
  Widget build(BuildContext context) {
    return Selector<PreRollNotifier, ({bool shouldShow, bool isAudioAd})>(
      selector: (context, notifier) => (
        shouldShow: notifier.shouldShow,
        isAudioAd: notifier.isAudioAd,
      ),
      builder: (context, value, child) {
        debugPrint(
          '[teste PREROLL]: preRollNotifier, should show: ${value.shouldShow}, isAudioAd: ${value.isAudioAd}',
        );

        return value.shouldShow
            ? PreRoll(
                controller: controller,
                maxHeight: value.isAudioAd ? audioAdSize : videoAdSize,
                useHybridComposition: true,
                useinitExpensiveAndroidView: true,
              )
            : SizedBox.shrink();
      },
    );
  }
}

const audioAdSize = 250.0;
const videoAdSize = 310.0;

const videoTarget = {
  "age": "34",
  "tipo": "1",
  "vip": "0",
  "gender": "1",
  "version": "6867",
  "ppid": "6d83fd8be4872555440fab67103896c8bee7b064b1b3ab0260f503c8dfc76e39",
  "__URL__":
      // "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480%7C400x300%7C730x400&iu=/7090806/Suamusica.com.br-ROA-Preroll&impl=s&gdfp_req=1&env=instream&output=vast&unviewed_position_start=1&description_url=http%3A%2F%2Fwww.suamusica.com.br%2F&correlator=&tfcd=0&npa=0&ad_type=video_audio&vad_type=linear&ciu_szs=300x250&cust_params=teste%3D1",
      //  "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=",
      "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator=",
  "__CONTENT__": "https://assets.suamusica.com.br/video/virgula.mp3",
};

const audioTarget = {
  "age": "34",
  "tipo": "1",
  "vip": "0",
  "gender": "1",
  "version": "6867",
  "ppid": "6d83fd8be4872555440fab67103896c8bee7b064b1b3ab0260f503c8dfc76e39",
  "__URL__":
      "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480%7C400x300%7C730x400&iu=/7090806/Suamusica.com.br-ROA-Preroll&impl=s&gdfp_req=1&env=instream&output=vast&unviewed_position_start=1&description_url=http%3A%2F%2Fwww.suamusica.com.br%2F&correlator=&tfcd=0&npa=0&ad_type=audio&vad_type=linear&ciu_szs=300x250&cust_params=teste%3D1",
  "__CONTENT__": "https://assets.suamusica.com.br/video/virgula.mp3",
};

void preRollListener(PreRollEvent event, Map<String, dynamic> args) {
  debugPrint('[PREROLL]: Event: $event, args: $args');

  switch (event) {
    case PreRollEvent.LOADED:
      // preRollNotifier.value = true;
      // isAudioAd.value = args['ad.contentType'].contains('audio');

      // preRollNotifier.setShouldShow(true);
      // preRollNotifier.setIsAudioAd(args['ad.contentType'].contains('audio'));
      break;
    case PreRollEvent.COMPLETED:
    // controller.dispose();
    default:
  }
}

void loadAds({
  required PreRollNotifier preRollNotifier,
  required Map<String, dynamic> target,
}) {
  preRollNotifier
    ..setShouldShow(true)
    ..controller.load(target);
}

class PreRollNotifier extends ChangeNotifier {
  bool _shouldShow = false;
  bool _isAudioAd = false;
  PreRollController controller = PreRollController(preRollListener);

  bool get shouldShow => _shouldShow;
  bool get isAudioAd => _isAudioAd;

  void setShouldShow(bool value) {
    debugPrint('[TESTE] shouldshow $value');

    if (_shouldShow != value) {
      _shouldShow = value;
      notifyListeners();
    }
  }

  void setIsAudioAd(bool value) {
    if (_isAudioAd != value) {
      _isAudioAd = value;
      notifyListeners();
    }
  }
}

// android
// [PREROLL]: Event: PreRollEvent.ERROR, args: {type: ERROR, error.code: VAST_LOAD_TIMEOUT, error.message: Ad request reached a timeout. Caused by: 8}

// ios 
// flutter: [PREROLL]: Event: PreRollEvent.LOADED, args: {ad.title: External - Single Inline Linear Skippable, ad.contentType: video/mp4, ad.creativeID: 138382063765, ad.dealID: , ad.system: GDFP, ad.description: External - Single Inline Linear Skippable ad, ad.id: 5926628810, ad.advertiserName: , type: LOADED, ad.creativeAdID: }
// flutter: [PREROLL]: Event: PreRollEvent.ERROR, args: {type: ERROR, error.code: VAST_MEDIA_LOAD_TIMEOUT, error.message: VAST media file loading reached a timeout of 8 seconds.}
// flutter: [PREROLL]: Event: PreRollEvent.PAUSED, args: {type: PAUSE, ad.title: External - Single Inline Linear Skippable, ad.advertiserName: , ad.dealID: , ad.id: 5926628810, ad.creativeAdID: , ad.system: GDFP, ad.description: External - Single Inline Linear Skippable ad, ad.contentType: video/mp4, ad.creativeID: 138382063765}
// flutter: [PREROLL]: Event: PreRollEvent.ALL_ADS_COMPLETED, args: {ad.creativeID: 138382063765, ad.creativeAdID: , ad.description: External - Single Inline Linear Skippable ad, ad.contentType: video/mp4, ad.system: GDFP, ad.advertiserName: , type: ALL_ADS_COMPLETED, ad.title: External - Single Inline Linear Skippable, ad.dealID: , ad.id: 5926628810}