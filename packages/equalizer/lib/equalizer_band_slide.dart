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

        // null-aware operation "!" cria um warning no app, como sei que ele nunca será null fiz esse tratamento para evitar isso.
        final bandData = snapshot.data ?? BandData([], BandLevelRange(0, 0));
        final bandLevelRange = bandData.bandLevelRange;
        final divisions =
            bandLevelRange.max.toInt() - bandLevelRange.min.toInt();

        final centerBandFrequencyList = bandData.centerBandFrequencyList;
        final width = (MediaQuery.of(context).size.width - 128) /
            centerBandFrequencyList.length;
        var bandIdCount = 0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
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
                          centerFreq: freq,
                          onChangeEnd: (value) {
                            controller.setBandLevel(bandId, value.toInt());
                          },
                        ),
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
}

class BandSlideItem extends StatelessWidget {
  BandSlideItem({
    Key? key,
    this.min = 0.0,
    this.max = 1.0,
    this.width = 40,
    required this.bandId,
    required this.centerFreq,
    required this.divisions,
    this.onChanged,
    required this.onChangeEnd,
  }) : super(key: key);

  final Function(double)? onChanged;
  final Function(double) onChangeEnd;
  final double min, max, width;
  final int divisions, bandId, centerFreq;

  @override
  Widget build(BuildContext context) {
    final enabled = context.select((ValueNotifier<bool> n) => n.value);
    final theme = Theme.of(context);
    final over = max.toInt().isEven ? 3 : 1;
    final totalDivider = (divisions / 2) + over;
    final double slideHeight = 200;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bandId == 0)
              SizedBox(
                width: 44,
                child: _buildRangeFrequency(min, max),
              ),
            if (bandId == 0)
              SizedBox(
                width: 8,
              ),
            SizedBox(
              width: width,
              height: slideHeight,
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var i = 0; i < totalDivider; i++)
                        Expanded(
                          child: (i == 0 || i == (totalDivider - 1))
                              ? Container()
                              : Divider(
                                  thickness: 1,
                                  color: enabled
                                      ? theme.dividerColor
                                      : theme.disabledColor,
                                ),
                          flex: 1,
                        ),
                    ],
                  ),
                  RotatedBox(
                    quarterTurns: 3,
                    child: Selector<ValueNotifier<List<int>>, int>(
                        selector: (_, notifier) =>
                            notifier.value.length > bandId
                                ? notifier.value[bandId]
                                : 0,
                        builder: (context, data, _) {
                          return Slider(
                            min: min,
                            max: max,
                            value: data.toDouble(),
                            onChanged: enabled
                                ? (value) {
                                    final notifier = context
                                        .read<ValueNotifier<List<int>>>();
                                    final levels =
                                        notifier.value.map((e) => e).toList();
                                    levels[bandId] = value.toInt();
                                    notifier.value = levels;
                                  }
                                : null,
                            onChangeEnd: enabled
                                ? (value) {
                                    onChangeEnd.call(value);
                                  }
                                : null,
                          );
                        }),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            SizedBox(width: bandId == 0 ? 52 : 0),
            Text(
              _formatFreq(centerFreq),
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
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

  Widget _buildRangeFrequency(double min, double max) {
    return Container(
      height: 160,
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              child: Align(
                child: Text(
                  "${max.toInt()}dB",
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
                  "${min.toInt()}dB",
                  style: TextStyle(fontSize: 12),
                ),
                alignment: Alignment.bottomRight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
