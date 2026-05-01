import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'money_text.dart';

class AppSheetContainer extends StatelessWidget {
  const AppSheetContainer({
    super.key,
    required this.child,
    this.bottomInset,
    this.scrollable = false,
  });

  final Widget child;
  final double? bottomInset;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final inset = bottomInset ?? MediaQuery.of(context).viewInsets.bottom;
    final content = Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, inset + 16),
      child: child,
    );

    return SafeArea(
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }
}

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: builder,
  );
}

class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class AppPriceSummaryCard extends StatelessWidget {
  const AppPriceSummaryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.amount,
    this.total,
    this.highlightColor,
  });

  final IconData icon;
  final String label;
  final double amount;
  final double? total;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        highlightColor ?? Theme.of(context).colorScheme.primaryContainer;

    return Card(
      margin: EdgeInsets.zero,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      MoneyText(
                        amount,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (total != null) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  MoneyText(
                    total!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppSheetActions extends StatelessWidget {
  const AppSheetActions({
    super.key,
    required this.isSubmitting,
    required this.submitLabel,
    required this.onSubmit,
    this.cancelLabel = 'Cancelar',
    this.onCancel,
  });

  final bool isSubmitting;
  final String submitLabel;
  final VoidCallback onSubmit;
  final String cancelLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: isSubmitting
                ? null
                : (onCancel ?? () => Navigator.of(context).pop()),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(submitLabel),
          ),
        ),
      ],
    );
  }
}

Future<String?> showTextEntryDialog(
  BuildContext context, {
  required String title,
  String hintText = '',
  String cancelLabel = 'Cancelar',
  required String confirmLabel,
  bool isDestructive = false,
  int maxLines = 3,
}) {
  return showDialog<String?>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();

      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: maxLines,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
