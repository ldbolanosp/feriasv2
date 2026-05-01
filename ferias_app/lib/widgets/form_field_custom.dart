import 'package:flutter/material.dart';

class FormFieldCustom extends StatelessWidget {
  const FormFieldCustom({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.errorText,
  });

  final String label;
  final Widget child;
  final bool isRequired;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.labelLarge,
            children: <InlineSpan>[
              TextSpan(text: label),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: errorColor),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: errorColor),
          ),
        ],
      ],
    );
  }
}
