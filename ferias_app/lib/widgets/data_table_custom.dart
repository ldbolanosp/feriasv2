import 'package:flutter/material.dart';

import 'empty_state.dart';
import 'loading_widget.dart';

typedef DataCellBuilder<T> = Widget Function(BuildContext context, T item);

class DataTableColumn<T> {
  const DataTableColumn({
    required this.label,
    required this.cellBuilder,
    this.numeric = false,
  });

  final String label;
  final DataCellBuilder<T> cellBuilder;
  final bool numeric;
}

class DataTableCustom<T> extends StatelessWidget {
  const DataTableCustom({
    super.key,
    required this.items,
    required this.columns,
    this.isLoading = false,
    this.onRefresh,
    this.currentPage = 1,
    this.hasPreviousPage = false,
    this.hasNextPage = false,
    this.onPreviousPage,
    this.onNextPage,
    this.emptyTitle = 'No se encontraron registros',
    this.emptySubtitle,
    this.emptyActionLabel,
    this.onEmptyActionPressed,
    this.horizontalMargin = 16,
    this.columnSpacing = 24,
  });

  final List<T> items;
  final List<DataTableColumn<T>> columns;
  final bool isLoading;
  final Future<void> Function()? onRefresh;
  final int currentPage;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final String emptyTitle;
  final String? emptySubtitle;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyActionPressed;
  final double horizontalMargin;
  final double columnSpacing;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingWidget();
    }

    if (items.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel: emptyActionLabel,
        onActionPressed: onEmptyActionPressed,
      );
    }

    final table = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: horizontalMargin,
              columnSpacing: columnSpacing,
              columns: columns
                  .map(
                    (column) => DataColumn(
                      label: Text(column.label),
                      numeric: column.numeric,
                    ),
                  )
                  .toList(growable: false),
              rows: items
                  .map(
                    (item) => DataRow(
                      cells: columns
                          .map(
                            (column) =>
                                DataCell(column.cellBuilder(context, item)),
                          )
                          .toList(growable: false),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
        if (hasPreviousPage || hasNextPage) ...<Widget>[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: hasPreviousPage ? onPreviousPage : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Anterior'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Página $currentPage'),
              ),
              FilledButton.icon(
                onPressed: hasNextPage ? onNextPage : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Siguiente'),
              ),
            ],
          ),
        ],
      ],
    );

    if (onRefresh == null) {
      return table;
    }

    return RefreshIndicator(onRefresh: onRefresh!, child: table);
  }
}
