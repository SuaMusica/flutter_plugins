import 'package:equalizer/equalizer_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EqualizerBandSlideGroup extends StatelessWidget {
  EqualizerBandSlideGroup(this.controller);

  final EqualizerController controller;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BandData>(
      future: controller.getBandData(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return Container();
        }

        final bandData = snapshot.data;
        final bandLevelRange = bandData.bandLevelRange;
        final divisions =
            bandLevelRange.max.toInt() - bandLevelRange.min.toInt();

        final centerBandFrequencyList = bandData.centerBandFrequencyList;
        final width = (MediaQuery.of(context).size.width - 128) /
            centerBandFrequencyList.length;
        var bandIdCount = 0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 14),
              child: Container(
                height: 168,
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        child: Align(
                          child: Text(
                            "${bandLevelRange.max.toInt()}dB",
                            style: TextStyle(fontSize: 12),
                          ),
                          alignment: Alignment.topRight,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        child: Align(
                          child: Text(
                            "0dB",
                            style: TextStyle(fontSize: 12),
                          ),
                          alignment: Alignment.centerRight,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        child: Align(
                          child: Text(
                            "${bandLevelRange.min.toInt()}dB",
                            style: TextStyle(fontSize: 12),
                          ),
                          alignment: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 8,
            ),
            SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...centerBandFrequencyList.map((freq) {
                    final bandId = bandIdCount++;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BandSlideItem(
                          min: bandLevelRange.min,
                          max: bandLevelRange.max,
                          width: width,
                          divisions: divisions,
                          bandId: bandId,
                          onChangeEnd: (value) {
                            controller.setBandLevel(bandId, value.toInt());
                          },
                        ),
                        Text(
                          _formatFreq(freq),
                          style: TextStyle(fontSize: 12),
                        )
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatFreq(int freq, {int count = 0}) {
    if (freq >= 1000) {
      return _formatFreq(freq ~/ 1000, count: ++count);
    } else {
      var freqUnit = "";
      switch (count) {
        case 2:
          freqUnit = "k";
          break;
        case 3:
          freqUnit = "G";
          break;
      }

      return '$freq$freqUnit';
    }
  }
}

class BandSlideItem extends StatelessWidget {
  BandSlideItem({
    Key key,
    this.min = 0.0,
    this.max = 1.0,
    this.width = 40,
    this.bandId,
    this.divisions,
    this.onChanged,
    this.onChangeEnd,
  }) : super(key: key);

  final Function(double) onChanged;
  final Function(double) onChangeEnd;
  final double min, max, width;
  final int divisions, bandId;

  @override
  Widget build(BuildContext context) {
    final enabled = context.select((ValueNotifier<bool> n) => n.value);
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: 200,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                height: 16,
              ),
              for (var i = 0; i < (divisions / 2) + 1; i++)
                Divider(
                  thickness: 1,
                  color: enabled ? theme.dividerColor : theme.disabledColor,
                  height: 15.2,
                ),
            ],
          ),
          RotatedBox(
            quarterTurns: 3,
            child: Selector<ValueNotifier<List<int>>, int>(
                selector: (_, notifier) =>
                    notifier.value.length > bandId ? notifier.value[bandId] : 0,
                builder: (context, data, _) {
                  return SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      disabledActiveTrackColor: theme.disabledColor,
                      disabledInactiveTrackColor: theme.disabledColor,
                      disabledThumbColor: theme.disabledColor,
                    ),
                    child: Slider(
                      min: min,
                      max: max,
                      value: data.toDouble(),
                      onChanged: enabled
                          ? (value) {
                              final notifier =
                                  context.read<ValueNotifier<List<int>>>();
                              final levels =
                                  notifier.value.map((e) => e).toList();
                              levels[bandId] = value.toInt();
                              notifier.value = levels;
                            }
                          : null,
                      onChangeEnd: enabled
                          ? (value) {
                              onChangeEnd?.call(value);
                            }
                          : null,
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
