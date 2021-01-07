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
        var bandId = 0;
        return SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...bandData.centerBandFrequencyList.map((freq) =>
                  _buildBandItem(
                      bandLevelRange, divisions, freq, bandId++, context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBandItem(BandLevelRange bandLevelRange,
      int divisions,
      int freq,
      int bandId,
      BuildContext context,) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BandSlideItem(
          min: bandLevelRange.min,
          max: bandLevelRange.max,
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
    this.bandId,
    this.divisions,
    this.onChanged,
    this.onChangeEnd,
  }) : super(key: key);

  final Function(double) onChanged;
  final Function(double) onChangeEnd;
  final double min, max;
  final int divisions, bandId;

  @override
  Widget build(BuildContext context) {
    final enabled = context.select((ValueNotifier<bool> n) => n.value);

    return RotatedBox(
      quarterTurns: 3,
      child: Selector<ValueNotifier<List<int>>, int>(
        selector: (_, notifier) => notifier.value[bandId],
        builder: (context, data, _) {
          return Slider(
            label: "${data.toInt()} db",
            min: min,
            max: max,
            divisions: divisions,
            value: data.toDouble(),
            onChanged: enabled
                ? (value) {
              final notifier = context.read<ValueNotifier<List<int>>>();
              final levels = notifier.value.map((e) => e).toList();
              levels[bandId] = value.toInt();
              notifier.value = levels;
            }
                : null,
            onChangeEnd: enabled
                ? (value) {
              onChangeEnd?.call(value);
            }
                : null,
          );
        }
      ),
    );
  }
}