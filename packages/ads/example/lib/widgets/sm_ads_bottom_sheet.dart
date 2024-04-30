import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smads/smads.dart';
import 'package:smads_example/main.dart';
import 'package:smads_example/widgets/widgets.dart';

class SMAdsBottomSheet extends StatelessWidget {
  const SMAdsBottomSheet({
    super.key,
    required this.controller,
  });

  final PreRollController controller;

  @override
  Widget build(BuildContext context) {
    final preRollNotifier = context.read<PreRollNotifier>();

    return PopScope(
      onPopInvoked: (onPop) {
        controller.play();
      },
      child: Wrap(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView(
                shrinkWrap: true,
                children: [
                  SMAdsTile(
                    icon: Icons.video_call_rounded,
                    title: 'Load video',
                    onTap: () {
                      loadAds(
                        preRollNotifier: preRollNotifier,
                        target: audioTarget,
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
                    title: 'play',
                    icon: Icons.play_arrow_rounded,
                    onTap: () {
                      controller.play();
                    },
                  ),
                  SMAdsTile(
                    title: 'pause',
                    icon: Icons.pause_rounded,
                    onTap: () {
                      controller.pause();
                    },
                  ),
                  SMAdsTile(
                    title: 'skip',
                    icon: Icons.skip_next_rounded,
                    onTap: () {
                      controller.skip();
                    },
                  ),
                  SMAdsTile(
                    title: 'dispose',
                    icon: Icons.delete_rounded,
                    onTap: () {
                      controller.dispose();
                    },
                  ),
                  Divider(),
                  SMAdsTile(
                    title: 'pop and play',
                    icon: Icons.back_hand_rounded,
                    onTap: () {
                      controller.play();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
