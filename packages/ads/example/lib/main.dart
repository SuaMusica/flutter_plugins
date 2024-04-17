import 'package:flutter/material.dart';
import 'dart:async';

// import 'package:smads/smads.dart';
import 'package:smads/sm.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
//   final ads = SMAds(
// //    adUrl:
// //    "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=",
// //    adUrl:
// //        "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=",
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
    "__URL__":
        "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=",
    "__CONTENT__": "https://assets.suamusica.com.br/video/virgula.mp3",
  };

  ValueNotifier<bool> adsValueNotifier = ValueNotifier(false);
  final PreRollController controller = PreRollController(preRollListener);

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    // ads.onEvent.listen((e) {
    //   print("Got an AdEvent: ${e.toString()}");
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ColoredBox(
          color: Colors.red,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                ColoredBox(
                  color: Colors.green,
                  child: PreRollUI(
                    adsValueNotifier: adsValueNotifier,
                    controller: controller,
                  ),
                ),
                // load
                MaterialButton(
                  child: Text('Load'),
                  color: Colors.blueAccent,
                  onPressed: () {
                    adsValueNotifier.value = true;
                    controller.load(target);
                    Future.delayed(Duration(seconds: 9), () {
                      adsValueNotifier.value = false;
                    });
                  },
                ),
                SizedBox(height: 20),
                // MaterialButton(
                //   child: Text('play'),
                //   color: Colors.blueAccent,
                //   onPressed: () async {
                //     controller.play();
                //   },
                // ),
                SizedBox(
                  height: 20,
                ),
                MaterialButton(
                  child: Text('Pause'),
                  color: Colors.blueAccent,
                  onPressed: () {
                    controller.pause();
                  },
                ),
                SizedBox(height: 20),
                MaterialButton(
                  child: Text('Skip'),
                  color: Colors.blueAccent,
                  onPressed: () {
                    controller.skip();
                  },
                ),
                SizedBox(height: 20),
                MaterialButton(
                  child: Text('Dispose'),
                  color: Colors.blueAccent,
                  onPressed: () {
                    controller.dispose();
                  },
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 50,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PreRollUI extends StatelessWidget {
  const PreRollUI({
    Key? key,
    required this.adsValueNotifier,
    required this.controller,
  }) : super(key: key);

  final ValueNotifier<bool> adsValueNotifier;
  final PreRollController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: adsValueNotifier,
      builder: (context, child) => adsValueNotifier.value
          ? AspectRatio(
              aspectRatio: 640 / 480,
              child: PreRoll(
                controller: controller,
                maxHeight: 480,
                useHybridComposition: true,
                useinitExpensiveAndroidView: true,
              ),
            )
          : SizedBox.shrink(),
    );
  }
}

void preRollListener(PreRollEvent event, Map<String, dynamic> args) {
  debugPrint("Event: $event, args: $args");
}
