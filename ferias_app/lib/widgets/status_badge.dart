import 'package:flutter/material.dart';

import '../config/theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final String status;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final baseColor = AppTheme.statusColor(status);
    final backgroundColor = AppTheme.statusBackgroundColor(status);
    final normalized = status.trim();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: baseColor,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
