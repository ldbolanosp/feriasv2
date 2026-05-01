import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';

class SearchInput extends StatefulWidget {
  const SearchInput({
    super.key,
    this.hintText = 'Buscar...',
    this.initialValue,
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  final String hintText;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final Duration debounceDuration;

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged(value.trim());
    });

    setState(() {});
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: AppTheme.borderColor.withValues(alpha: 0.85),
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: TextField(
          controller: _controller,
          onChanged: _handleChanged,
          textInputAction: TextInputAction.search,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          decoration: const InputDecoration().copyWith(
            filled: false,
            fillColor: Colors.transparent,
            hintText: widget.hintText,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.search_rounded, size: 22),
            ),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: _clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 21,
            ),
          ),
        ),
      ),
    );
  }
}
