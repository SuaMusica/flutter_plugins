import 'package:flutter/material.dart';
import 'package:smads/sm.dart';

class SMAdsBottomSheet extends StatelessWidget {
  const SMAdsBottomSheet({
    super.key,
    required this.controller,
  });

  final PreRollController controller;

  @override
  Widget build(BuildContext context) {
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
                  ListTile(
                    title: Text('play'),
                    leading: Icon(Icons.play_arrow),
                    onTap: () {
                      controller.play();
                    },
                  ),
                  ListTile(
                    title: Text('pause'),
                    leading: Icon(Icons.pause),
                    onTap: () {
                      controller.pause();
                    },
                  ),
                  ListTile(
                    title: Text('skip'),
                    leading: Icon(Icons.skip_next),
                    onTap: () {
                      controller.skip();
                    },
                  ),
                  ListTile(
                    title: Text('dispose'),
                    leading: Icon(Icons.delete),
                    onTap: () {
                      controller.dispose();
                    },
                  ),
                  Divider(),
                  ListTile(
                    title: Text('pop and play'),
                    leading: Icon(Icons.back_hand),
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
