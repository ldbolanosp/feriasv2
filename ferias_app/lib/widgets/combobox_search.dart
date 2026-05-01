import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'loading_widget.dart';

typedef ComboboxSearchRequest<T> = Future<List<T>> Function(String query);
typedef ComboboxSearchItemBuilder<T> =
    Widget Function(BuildContext context, T item, bool isSelected);

class ComboboxSearch<T> extends StatefulWidget {
  const ComboboxSearch({
    super.key,
    required this.onSearch,
    required this.displayStringForOption,
    required this.onSelected,
    this.itemBuilder,
    this.labelText,
    this.hintText = 'Buscar...',
    this.debounceDuration = const Duration(milliseconds: 300),
    this.minSearchLength = 2,
    this.noResultsText = 'No se encontraron resultados',
    this.initialValue,
    this.enabled = true,
  });

  final ComboboxSearchRequest<T> onSearch;
  final String Function(T item) displayStringForOption;
  final ValueChanged<T> onSelected;
  final ComboboxSearchItemBuilder<T>? itemBuilder;
  final String? labelText;
  final String hintText;
  final Duration debounceDuration;
  final int minSearchLength;
  final String noResultsText;
  final T? initialValue;
  final bool enabled;

  @override
  State<ComboboxSearch<T>> createState() => _ComboboxSearchState<T>();
}

class _ComboboxSearchState<T> extends State<ComboboxSearch<T>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  List<T> _results = <T>[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue == null
          ? ''
          : widget.displayStringForOption(widget.initialValue as T),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus && mounted) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() {
            _results = <T>[];
            _isLoading = false;
          });
        }
      });
    }
  }

  void _handleChanged(String value) {
    final query = value.trim();

    _debounce?.cancel();

    if (query.length < widget.minSearchLength) {
      setState(() {
        _results = <T>[];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(widget.debounceDuration, () async {
      setState(() {
        _isLoading = true;
      });

      try {
        final results = await widget.onSearch(query);

        if (!mounted) {
          return;
        }

        setState(() {
          _results = results;
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  void _handleSelected(T item) {
    _debounce?.cancel();
    _controller.text = widget.displayStringForOption(item);
    _focusNode.unfocus();

    setState(() {
      _results = <T>[];
    });

    widget.onSelected(item);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    _focusNode.requestFocus();
    setState(() {
      _results = <T>[];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowResults =
        _focusNode.hasFocus && (_isLoading || _results.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: AppTheme.softShadow,
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              onChanged: _handleChanged,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                labelText: widget.labelText,
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar',
                        onPressed: _clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        if (shouldShowResults) ...<Widget>[
          const SizedBox(height: 8),
          Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: _isLoading
                  ? const SizedBox(height: 96, child: LoadingWidget())
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _results[index];

                        return InkWell(
                          onTap: () => _handleSelected(item),
                          child:
                              widget.itemBuilder?.call(context, item, false) ??
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  widget.displayStringForOption(item),
                                ),
                              ),
                        );
                      },
                    ),
            ),
          ),
        ] else if (_focusNode.hasFocus &&
            !_isLoading &&
            _controller.text.trim().length >=
                widget.minSearchLength) ...<Widget>[
          const SizedBox(height: 8),
          Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(title: Text(widget.noResultsText)),
          ),
        ],
      ],
    );
  }
}
