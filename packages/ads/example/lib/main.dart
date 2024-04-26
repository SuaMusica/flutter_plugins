import 'package:flutter/material.dart';
import 'dart:async';

import 'package:smads/smads.dart';
import 'package:smads_example/widgets/widgets.dart';

void main() => runApp(MaterialApp(home: MyApp()));

ValueNotifier<bool> preRollNotifier = ValueNotifier(false);
ValueNotifier<bool> isAudioAd = ValueNotifier(false);

PreRollController controller = PreRollController(preRollListener);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AppLifecycleListener listener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    listener = AppLifecycleListener(
      onInactive: () {
        debugPrint('[AppLifecycleState]: inactive');
      },
      onPause: () {
        debugPrint('[AppLifecycleState]: paused');
      },
      onResume: () {
        debugPrint('[AppLifecycleState]: resumed');
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[AppLifecycleState]: (didChangeAppLifecycleState) $state');
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.resumed:
      case AppLifecycleState.detached:
      default:
        debugPrint('[AppLifecycleState]: $state');
    }
  }

  @override
  void dispose() {
    listener.dispose();

    WidgetsBinding.instance.removeObserver(this);
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
              icon: Icons.video_call_rounded,
              title: 'Load video',
              onTap: () {
                loadAds(videoTarget);
              },
            ),
            SMAdsTile(
              icon: Icons.video_call_rounded,
              title: 'Load video with delay for 5 seconds',
              onTap: () {
                Future.delayed(Duration(seconds: 5), () {
                  debugPrint('[Background] call load in bg video');
                  loadAds(videoTarget);
                });
              },
            ),
            SMAdsTile(
              icon: Icons.audiotrack_rounded,
              title: 'Load audio',
              onTap: () {
                loadAds(audioTarget);
              },
            ),
            SMAdsTile(
              icon: Icons.audiotrack_rounded,
              title: 'Load audio with delay for 5 seconds',
              onTap: () {
                Future.delayed(Duration(seconds: 5), () {
                  debugPrint('[Background] call load in bg audio');
                  loadAds(audioTarget);
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
                controller.dispose();
                preRollNotifier.value = false;
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
            PreRollUI(
              preRollNotifier: preRollNotifier,
              controller: controller,
            ),
          ],
        ),
      ),
    );
  }
}

class PreRollUI extends StatelessWidget {
  const PreRollUI({
    super.key,
    required this.preRollNotifier,
    required this.controller,
  });

  final ValueNotifier<bool> preRollNotifier;
  final PreRollController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([preRollNotifier, isAudioAd]),
      builder: (context, child) {
        debugPrint(
          '[PREROLL]: preRollNotifier, should show: ${preRollNotifier.value}',
        );

        return preRollNotifier.value
            ? PreRoll(
                controller: controller,
                maxHeight: isAudioAd.value ? audioAdSize : videoAdSize,
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
      "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=",
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
      preRollNotifier.value = true;
      isAudioAd.value = args['ad.contentType'].contains('audio');
    case PreRollEvent.COMPLETED:
      preRollNotifier.value = false;
      controller.dispose();
    default:
  }
}

void loadAds(Map<String, dynamic> target) {
  preRollNotifier.value = true;
  controller.load(target);
}
