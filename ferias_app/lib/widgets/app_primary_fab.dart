import 'package:flutter/material.dart';

class AppPrimaryFab extends StatelessWidget {
  const AppPrimaryFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
    this.heroTag,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      heroTag: heroTag,
      child: Icon(icon),
    );
  }
}
