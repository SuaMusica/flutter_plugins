import 'package:flutter/material.dart';

class SMAdsTile extends StatelessWidget {
  const SMAdsTile({
    super.key,
    required this.title,
    required this.onTap,
    required this.icon,
  });

  final String title;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: onTap,
      );
}
