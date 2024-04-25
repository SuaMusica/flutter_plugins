import 'package:flutter/material.dart';
import 'dart:async';

import 'package:smads/sm.dart';
import 'package:smads_example/widgets/widgets.dart';

void main() => runApp(
      MaterialApp(
        home: MyApp(),
      ),
    );

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

ValueNotifier<bool> adsValueNotifier = ValueNotifier(false);

class _MyAppState extends State<MyApp> {
//   final ads = SMAds(
// //    adUrl:
//    "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=",
//    adUrl:
//        "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=",
//     adUrl:
//         "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=",
//     contentUrl: "https://assets.suamusica.com.br/video/virgula.mp3",
//   );
  static const target = {
    "age": "34",
    "tipo": "1",
    "vip": "0",
    "gender": "1",
    "version": "6867",
    "ppid": "6d83fd8be4872555440fab67103896c8bee7b064b1b3ab0260f503c8dfc76e39",
    // video ad
    // "__URL__":
    //     "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=",
    "__URL__":
        "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=",
    "__CONTENT__": "https://assets.suamusica.com.br/video/virgula.mp3",
  };

  final audioTarget = Map<String, dynamic>.from(target);
  final controller = PreRollController(preRollListener);

  @override
  void initState() {
    super.initState();
    audioTarget["__URL__"] =
        "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480%7C400x300%7C730x400&iu=/7090806/Suamusica.com.br-ROA-Preroll&impl=s&gdfp_req=1&env=instream&output=vast&unviewed_position_start=1&description_url=http%3A%2F%2Fwww.suamusica.com.br%2F&correlator=&tfcd=0&npa=0&ad_type=audio&vad_type=linear&ciu_szs=300x250&cust_params=teste%3D1";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: ListView(
          children: [
            ColoredBox(
              color: Colors.green,
              child: PreRollUI(
                adsValueNotifier: adsValueNotifier,
                controller: controller,
              ),
            ),
            SMAdsButton(
              title: 'Call bottom sheet',
              onPressed: () {
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
            SMAdsButton(
              title: 'Load video',
              onPressed: () {
                // ok, works as expected
                adsValueNotifier.value = true;
                controller.load(target);

                // not works as well, giving signal fatal error
                // adsValueNotifier.value = true;
                // Future.delayed(Duration(seconds: 5), () {
                //   controller.load(target);
                // });

                // also not works as well, giving signal fatal error
                // controller.load(target);
                // adsValueNotifier.value = true;
              },
            ),
            SMAdsButton(
              title: 'Load video with delay for 5 seconds',
              onPressed: () {
                Future.delayed(Duration(seconds: 5), () {
                  controller.load(target);
                });
              },
            ),
            SMAdsButton(
              title: 'Load audio',
              onPressed: () {
                controller.load(audioTarget);
              },
            ),
            SMAdsButton(
              title: 'Load audio with delay for 5 seconds',
              onPressed: () {
                final modifiedTarget = Map<String, dynamic>.from(target);
                modifiedTarget["__URL__"] =
                    "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480%7C400x300%7C730x400&iu=/7090806/Suamusica.com.br-ROA-Preroll&impl=s&gdfp_req=1&env=instream&output=vast&unviewed_position_start=1&description_url=http%3A%2F%2Fwww.suamusica.com.br%2F&correlator=&tfcd=0&npa=0&ad_type=audio&vad_type=linear&ciu_szs=300x250&cust_params=teste%3D1";

                controller.load(modifiedTarget);
              },
            ),
            SMAdsButton(
              title: 'play',
              onPressed: () {
                controller.play();
              },
            ),
            SMAdsButton(
              title: 'Pause',
              onPressed: () {
                controller.pause();
              },
            ),
            SMAdsButton(
              title: 'Skip',
              onPressed: () {
                controller.skip();
              },
            ),
            SMAdsButton(
              title: 'Dispose',
              onPressed: () {
                controller.dispose();
                adsValueNotifier.value = false;
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
          ],
        ),
      ),
    );
  }
}

class PreRollUI extends StatefulWidget {
  const PreRollUI({
    Key? key,
    required this.adsValueNotifier,
    required this.controller,
  }) : super(key: key);

  final ValueNotifier<bool> adsValueNotifier;
  final PreRollController controller;

  @override
  State<PreRollUI> createState() => _PreRollUIState();
}

class _PreRollUIState extends State<PreRollUI> {
  @override
  Widget build(BuildContext context) {
    /// With this, platform view will be created multiple times
    // for (int i = 0; i < 1000; i++) {
    //   debugPrint("Rebuilding $i");
    //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //     setState(() {});
    //   });
    // }

    return AnimatedBuilder(
      animation: widget.adsValueNotifier,
      builder: (context, child) {
        return widget.adsValueNotifier.value
            ? AspectRatio(
                aspectRatio: 640 / 480,
                child: PreRoll(
                  controller: widget.controller,
                  maxHeight: 480,
                  useHybridComposition: true,
                  useinitExpensiveAndroidView: true,
                ),
              )
            : SizedBox.shrink();
      },
    );
  }
}

void preRollListener(PreRollEvent event, Map<String, dynamic> args) {
  debugPrint('[PREROLL]: Event: $event, args: $args');

  switch (event) {
    case PreRollEvent.LOADED:
      adsValueNotifier.value = true;
    case PreRollEvent.COMPLETED:
      adsValueNotifier.value = false;
    default:
  }
}
