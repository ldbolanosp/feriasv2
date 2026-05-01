import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/factura.dart';
import '../utils/formatters.dart';
import 'status_badge.dart';

class FacturaListItem extends StatelessWidget {
  const FacturaListItem({
    super.key,
    required this.factura,
    this.showUserName = false,
    this.onTap,
  });

  final Factura factura;
  final bool showUserName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cliente = factura.esPublicoGeneral
        ? (factura.nombrePublico?.trim().isNotEmpty ?? false)
              ? factura.nombrePublico!.trim()
              : 'Publico general'
        : factura.participante?.nombre ?? 'Participante no disponible';

    final consecutivo = factura.consecutivo?.trim().isNotEmpty == true
        ? factura.consecutivo!.trim()
        : 'Borrador';

    final fecha =
        factura.fechaEmision ?? factura.createdAt ?? factura.updatedAt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      cliente,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        consecutivo,
                        if (fecha != null) AppFormatters.formatDateTime(fecha),
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (showUserName &&
                        (factura.user?.name.trim().isNotEmpty ??
                            false)) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        factura.user!.name.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    AppFormatters.formatMoney(factura.subtotal),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  StatusBadge(status: factura.estadoLabel ?? factura.estado),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
