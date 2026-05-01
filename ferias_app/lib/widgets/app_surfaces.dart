import 'package:flutter/material.dart';

import '../config/theme.dart';

class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.maxWidth = 420,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(width: maxWidth, child: child),
      actions: actions,
    );
  }
}

class AppDialogActions extends StatelessWidget {
  const AppDialogActions({
    super.key,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
    required this.submitLabel,
    this.cancelLabel = 'Cancelar',
  });

  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return OverflowBar(
      spacing: 8,
      children: <Widget>[
        TextButton(
          onPressed: isSubmitting ? null : onCancel,
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: isSubmitting ? null : onSubmit,
          child: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(submitLabel),
        ),
      ],
    );
  }
}

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 120,
                    maxWidth: 320,
                  ),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing case final Widget trailingWidget) trailingWidget,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class AppDetailSheet extends StatelessWidget {
  const AppDetailSheet({
    super.key,
    required this.title,
    required this.status,
    required this.children,
  });

  final String title;
  final Widget status;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            status,
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class AppDetailRow extends StatelessWidget {
  const AppDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.useCard = true,
  });

  final String label;
  final String value;
  final bool useCard;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppTheme.mutedTextColor),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: useCard
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: content,
            )
          : content,
    );
  }
}
