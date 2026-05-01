import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'status_badge.dart';

class ListMenuAction<T> {
  const ListMenuAction({required this.value, required this.label});

  final T value;
  final String label;
}

class AdminListCard<T> extends StatelessWidget {
  const AdminListCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.extraLines = const <Widget>[],
    this.chips = const <Widget>[],
    this.onTap,
    this.onLongPress,
    this.menuActions = const [],
    this.onMenuSelected,
  });

  final String title;
  final String subtitle;
  final List<Widget> extraLines;
  final List<Widget> chips;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<ListMenuAction<T>> menuActions;
  final ValueChanged<T>? onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle),
                        if (extraLines.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          for (
                            var index = 0;
                            index < extraLines.length;
                            index++
                          ) ...<Widget>[
                            extraLines[index],
                            if (index < extraLines.length - 1)
                              const SizedBox(height: 4),
                          ],
                        ],
                      ],
                    ),
                  ),
                  if (menuActions.isNotEmpty)
                    PopupMenuButton<T>(
                      onSelected: onMenuSelected,
                      itemBuilder: (context) => menuActions
                          .map(
                            (action) => PopupMenuItem<T>(
                              value: action.value,
                              child: Text(action.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                ],
              ),
              if (chips.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: chips),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OperationListCard<T> extends StatelessWidget {
  const OperationListCard({
    super.key,
    required this.title,
    required this.amount,
    required this.metaPrimary,
    this.metaSecondary,
    this.status,
    this.inlineActions = const <Widget>[],
    this.chips = const <Widget>[],
    this.footer,
    this.menuActions = const [],
    this.onMenuSelected,
    this.onTap,
  });

  final String title;
  final Widget amount;
  final Widget metaPrimary;
  final Widget? metaSecondary;
  final String? status;
  final List<Widget> inlineActions;
  final List<Widget> chips;
  final Widget? footer;
  final List<ListMenuAction<T>> menuActions;
  final ValueChanged<T>? onMenuSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  amount,
                  if (menuActions.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 4),
                    PopupMenuButton<T>(
                      onSelected: onMenuSelected,
                      itemBuilder: (context) => menuActions
                          .map(
                            (action) => PopupMenuItem<T>(
                              value: action.value,
                              child: Text(action.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Flexible(child: metaPrimary),
                  if (metaSecondary != null) ...<Widget>[
                    Text('  ·  ', style: Theme.of(context).textTheme.bodySmall),
                    Flexible(child: metaSecondary!),
                  ],
                ],
              ),
              if (status != null || inlineActions.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    if (status != null) StatusBadge(status: status!),
                    ...inlineActions.expand(
                      (action) => <Widget>[const SizedBox(width: 8), action],
                    ),
                  ],
                ),
              ],
              if (chips.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(spacing: 12, runSpacing: 10, children: chips),
              ],
              if (footer != null) ...<Widget>[
                const SizedBox(height: 12),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
