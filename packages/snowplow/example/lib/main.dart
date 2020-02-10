import 'package:flutter/material.dart';
import 'package:snowplow/snowplow.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: FutureBuilder<bool>(
            future: Snowplow().setUserId("00012"),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const CircularProgressIndicator();
                default:
                  if (snapshot.hasError) {
                    return Text('Set User Id Error: ${snapshot.error}');
                  } else {
                    return FutureBuilder<bool>(
                        future: Snowplow().logPageView("test"),
                        builder: (BuildContext context,
                            AsyncSnapshot<bool> snapshot) {
                          switch (snapshot.connectionState) {
                            case ConnectionState.waiting:
                              return const CircularProgressIndicator();
                            default:
                              if (snapshot.hasError) {
                                return Text(
                                    'Load Page View Failed: Error: ${snapshot.error}');
                              } else {
                                return FutureBuilder<bool>(
                                    future: Snowplow().trackEvent(
                                      category: "Category 1",
                                      action: "Open 1",
                                      label: "Label 1",
                                      property: "Property 1",
                                    ),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<bool> snapshot) {
                                      switch (snapshot.connectionState) {
                                        case ConnectionState.waiting:
                                          return const CircularProgressIndicator();
                                        default:
                                          if (snapshot.hasError) {
                                            return Text(
                                                'Track Event Error: ${snapshot.error}');
                                          } else {
                                            return FutureBuilder<bool>(
                                                future:
                                                    Snowplow().trackCustomEvent(
                                                  customScheme: "a",
                                                  eventMap: {"a": "value"},
                                                ),
                                                builder: (BuildContext context,
                                                    AsyncSnapshot<bool>
                                                        snapshot) {
                                                  switch (snapshot
                                                      .connectionState) {
                                                    case ConnectionState
                                                        .waiting:
                                                      return const CircularProgressIndicator();
                                                    default:
                                                      if (snapshot.hasError) {
                                                        return Text(
                                                            'Track Event Error: ${snapshot.error}');
                                                      } else {
                                                        return Text(
                                                            "setUserId(), logPageView(), trackEvent() and trackCustomEvent() worked just fine");
                                                      }
                                                  }
                                                });
                                          }
                                      }
                                    });
                              }
                          }
                        });
                  }
              }
            }),
      ),
    );
  }
}
