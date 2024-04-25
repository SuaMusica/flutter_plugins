import 'package:flutter/material.dart';

class SMAdsButton extends StatelessWidget {
  const SMAdsButton({
    super.key,
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: MaterialButton(
        child: Text(title),
        color: Colors.blueAccent,
        onPressed: onPressed,
      ),
    );
  }
}
