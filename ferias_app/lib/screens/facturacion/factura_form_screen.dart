import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../models/factura.dart';
import '../../models/feria.dart';
import '../../models/participante.dart';
import '../../models/producto.dart';
import '../../providers/factura_provider.dart';
import '../../providers/feria_provider.dart';
import '../../providers/printer_provider.dart';
import '../../services/participante_service.dart';
import '../../services/producto_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_modals.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/form_field_custom.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/money_text.dart';
import '../../widgets/search_input.dart';
import '../../widgets/status_badge.dart';

class FacturaFormScreen extends StatefulWidget {
  const FacturaFormScreen({super.key, this.facturaId});

  final int? facturaId;

  @override
  State<FacturaFormScreen> createState() => _FacturaFormScreenState();
}

class _FacturaFormScreenState extends State<FacturaFormScreen> {
  static const Map<String, String> _tipoIdentificacionOptions =
      <String, String>{
        'fisica': 'Cédula Física',
        'juridica': 'Cédula Jurídica',
        'dimex': 'DIMEX',
        'nite': 'NITE',
      };

  final ParticipanteService _participanteService = ParticipanteService();
  final ProductoService _productoService = ProductoService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombrePublicoController =
      TextEditingController();
  final TextEditingController _tipoPuestoController = TextEditingController();
  final TextEditingController _numeroPuestoController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();
  final TextEditingController _montoPagoController = TextEditingController();

  bool _isInitializing = false;
  bool _isSubmitting = false;
  bool _hasChanges = false;
  bool _esPublicoGeneral = false;
  Factura? _loadedFactura;
  Participante? _selectedParticipante;
  Producto? _selectedProducto;
  double _selectedCantidad = 1;
  List<_FacturaLineaDraft> _lineas = <_FacturaLineaDraft>[];
  Map<String, String> _fieldErrors = <String, String>{};

  @override
  void initState() {
    super.initState();
    _nombrePublicoController.addListener(_markDirty);
    _tipoPuestoController.addListener(_markDirty);
    _numeroPuestoController.addListener(_markDirty);
    _observacionesController.addListener(_markDirty);
    _montoPagoController.addListener(_markDirty);

    if (widget.facturaId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFactura();
      });
    }
  }

  @override
  void dispose() {
    _nombrePublicoController.dispose();
    _tipoPuestoController.dispose();
    _numeroPuestoController.dispose();
    _observacionesController.dispose();
    _montoPagoController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _lineas.fold<double>(0, (sum, item) => sum + item.subtotalLinea);
  }

  double? get _montoPago {
    final normalized = _montoPagoController.text.replaceAll(',', '.').trim();

    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  double? get _cambio {
    final montoPago = _montoPago;

    if (montoPago == null) {
      return null;
    }

    return montoPago - _subtotal;
  }

  bool get _isEditable {
    return _loadedFactura == null || _loadedFactura!.estado == 'borrador';
  }

  Future<void> _loadFactura() async {
    setState(() {
      _isInitializing = true;
      _fieldErrors = <String, String>{};
    });

    try {
      final factura = await context.read<FacturaProvider>().obtener(
        widget.facturaId!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loadedFactura = factura;
        _esPublicoGeneral = factura.esPublicoGeneral;
        _selectedParticipante = factura.participante;
        _nombrePublicoController.text = factura.nombrePublico ?? '';
        _tipoPuestoController.text = factura.tipoPuesto ?? '';
        _numeroPuestoController.text = factura.numeroPuesto ?? '';
        _observacionesController.text = factura.observaciones ?? '';
        _montoPagoController.text = factura.montoPago?.toString() ?? '';
        _lineas = factura.detalles
            .map(
              (detalle) => _FacturaLineaDraft(
                producto:
                    detalle.producto ??
                    Producto(
                      id: detalle.productoId,
                      codigo: '',
                      descripcion: detalle.descripcionProducto,
                      activo: true,
                      precio: detalle.precioUnitario,
                    ),
                cantidad: detalle.cantidad,
              ),
            )
            .toList(growable: true);
        _hasChanges = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _markDirty() {
    if (!_hasChanges && mounted) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _togglePublicoGeneral(bool? value) {
    final enabled = value ?? false;

    setState(() {
      _esPublicoGeneral = enabled;
      _fieldErrors.remove('participante_id');
      _fieldErrors.remove('nombre_publico');

      if (enabled) {
        _selectedParticipante = null;
      } else {
        _nombrePublicoController.clear();
      }

      _hasChanges = true;
    });
  }

  void _selectParticipante(Participante participante) {
    setState(() {
      _selectedParticipante = participante;
      _fieldErrors.remove('participante_id');
      _hasChanges = true;
    });
  }

  void _selectProducto(Producto producto) {
    setState(() {
      _selectedProducto = producto;
      _selectedCantidad = 1;
      _fieldErrors.remove('detalles');
      _hasChanges = true;
    });
  }

  void _agregarProducto() {
    final producto = _selectedProducto;
    final cantidad = _selectedCantidad;

    if (producto == null) {
      setState(() {
        _fieldErrors['detalles'] = 'Seleccione un producto para agregar.';
      });
      return;
    }

    if (producto.precio == null) {
      setState(() {
        _fieldErrors['detalles'] =
            'El producto seleccionado no tiene precio configurado.';
      });
      return;
    }

    if (cantidad < 1 || ((cantidad * 10) % 5 != 0)) {
      setState(() {
        _fieldErrors['detalles'] =
            'La cantidad debe ser mínimo 1 y avanzar en incrementos de 0.5.';
      });
      return;
    }

    setState(() {
      _lineas.add(_FacturaLineaDraft(producto: producto, cantidad: cantidad));
      _selectedProducto = null;
      _selectedCantidad = 1;
      _fieldErrors.remove('detalles');
      _hasChanges = true;
    });
  }

  void _removeLinea(_FacturaLineaDraft linea) {
    setState(() {
      _lineas.remove(linea);
      _hasChanges = true;
    });
  }

  Future<void> _handleCancelar() async {
    if (!_hasChanges) {
      if (mounted) {
        context.go(AppRoutes.facturacion);
      }
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Descartar cambios',
      message: 'Hay cambios sin guardar. ¿Desea salir de la factura?',
      confirmLabel: 'Descartar',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      context.go(AppRoutes.facturacion);
    }
  }

  Future<void> _guardar({required bool facturarDespues}) async {
    final feriaActiva = context.read<FeriaProvider>().feriaActiva;

    if (feriaActiva == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una feria para continuar.')),
      );
      return;
    }

    final localErrors = <String, String>{};

    if (!_esPublicoGeneral && _selectedParticipante == null) {
      localErrors['participante_id'] = 'Debe seleccionar un participante.';
    }

    if (_esPublicoGeneral && _nombrePublicoController.text.trim().isEmpty) {
      localErrors['nombre_publico'] =
          'Ingrese el nombre del cliente para público general.';
    }

    if (_lineas.isEmpty) {
      localErrors['detalles'] = 'Agregue al menos un producto a la factura.';
    }

    if (_montoPago != null && _montoPago! < 0) {
      localErrors['monto_pago'] = 'El monto de pago no puede ser negativo.';
    }

    if (facturarDespues && _cambio != null && _cambio! < 0) {
      localErrors['monto_pago'] =
          'El monto de pago debe cubrir el total antes de facturar.';
    }

    if (localErrors.isNotEmpty ||
        !(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _fieldErrors = localErrors;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _fieldErrors = <String, String>{};
    });

    try {
      final provider = context.read<FacturaProvider>();
      final payload = <String, dynamic>{
        'es_publico_general': _esPublicoGeneral,
        'nombre_publico': _esPublicoGeneral
            ? _nombrePublicoController.text.trim()
            : null,
        'participante_id': _esPublicoGeneral ? null : _selectedParticipante?.id,
        'tipo_puesto': _nullableValue(_tipoPuestoController.text),
        'numero_puesto': _nullableValue(_numeroPuestoController.text),
        'monto_pago': _montoPago,
        'observaciones': _nullableValue(_observacionesController.text),
        'detalles': _lineas
            .map(
              (item) => <String, dynamic>{
                'producto_id': item.producto.id,
                'cantidad': item.cantidad,
              },
            )
            .toList(growable: false),
      };

      final factura = widget.facturaId == null
          ? await provider.crear(payload)
          : await provider.actualizar(widget.facturaId!, payload);

      if (!mounted) {
        return;
      }

      setState(() {
        _loadedFactura = factura;
      });

      if (!facturarDespues) {
        setState(() {
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Borrador guardado correctamente.')),
        );
        return;
      }

      final facturaEmitida = await provider.facturar(factura.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _loadedFactura = facturaEmitida;
        _hasChanges = false;
      });

      await context.read<PrinterProvider>().printFactura(
        facturaEmitida,
        feriaActiva.descripcion,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Factura emitida e impresa correctamente.'),
        ),
      );
      context.go(AppRoutes.facturacion);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _fieldErrors = _extractFieldErrors(error);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmGuardar({required bool facturarDespues}) async {
    final confirmed = await showConfirmDialog(
      context,
      title: facturarDespues ? 'Emitir factura' : 'Guardar borrador',
      message: facturarDespues
          ? 'Se guardará la factura, se emitirá el consecutivo y se imprimirá el ticket.'
          : 'Se guardará la factura en estado borrador para seguir editándola después.',
      confirmLabel: facturarDespues ? 'Facturar' : 'Guardar',
      isDestructive: false,
    );

    if (confirmed && mounted) {
      await _guardar(facturarDespues: facturarDespues);
    }
  }

  Future<void> _openParticipantePicker() async {
    final participante = await showAppBottomSheet<Participante>(
      context,
      builder: (context) => _ParticipantePickerSheet(
        participanteService: _participanteService,
        selectedParticipanteId: _selectedParticipante?.id,
      ),
    );

    if (participante != null && mounted) {
      _selectParticipante(participante);
    }
  }

  Future<void> _openProductoPicker() async {
    final producto = await showAppBottomSheet<Producto>(
      context,
      builder: (context) => _ProductoPickerSheet(
        productoService: _productoService,
        selectedProductoId: _selectedProducto?.id,
        excludedProductIds: _lineas.map((item) => item.producto.id).toSet(),
      ),
    );

    if (producto != null && mounted) {
      _selectProducto(producto);
    }
  }

  void _increaseSelectedCantidad() {
    setState(() {
      _selectedCantidad += 0.5;
      _hasChanges = true;
    });
  }

  void _decreaseOrClearSelectedProducto() {
    setState(() {
      if (_selectedCantidad <= 1) {
        _selectedProducto = null;
        _selectedCantidad = 1;
      } else {
        _selectedCantidad -= 0.5;
      }
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final feriaActiva = context.watch<FeriaProvider>().feriaActiva;
    final title = widget.facturaId == null ? 'Nueva factura' : 'Editar factura';

    return AppScaffold(
      title: title,
      currentRoute: AppRoutes.facturacion,
      showBottomNavigation: false,
      showFeriaSwitcher: false,
      appBarSubtitle: feriaActiva == null
          ? 'Sin feria activa'
          : '${feriaActiva.codigo} · ${feriaActiva.descripcion}',
      body: SafeArea(
        child: _isInitializing
            ? const LoadingWidget()
            : Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (_loadedFactura != null)
                              StatusBadge(
                                status:
                                    _loadedFactura!.estadoLabel ??
                                    _loadedFactura!.estado,
                              ),
                            if (!_isEditable) ...<Widget>[
                              const SizedBox(height: 16),
                              Card(
                                color: Colors.amber.shade50,
                                child: const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Esta factura ya no se puede editar. Solo los borradores permiten cambios antes de emitirse.',
                                  ),
                                ),
                              ),
                            ] else ...<Widget>[
                              const SizedBox(height: 16),
                              _buildHeaderSection(feriaActiva),
                              const SizedBox(height: 16),
                              _buildProductosSection(),
                              const SizedBox(height: 16),
                              _buildObservacionesSection(),
                              const SizedBox(height: 16),
                              _buildResumenSection(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isEditable)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed:
                                    _isSubmitting ||
                                        (_cambio != null && _cambio! < 0)
                                    ? null
                                    : () => _confirmGuardar(
                                        facturarDespues: true,
                                      ),
                                child: const Text('Facturar'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(40),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                    ),
                                    onPressed: _isSubmitting
                                        ? null
                                        : _handleCancelar,
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(40),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                    ),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => _confirmGuardar(
                                            facturarDespues: false,
                                          ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Guardar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderSection(Feria? feriaActiva) {
    final canUsePublicoGeneral = feriaActiva?.facturacionPublico ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Cliente',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (!_esPublicoGeneral && _selectedParticipante == null)
                  TextButton(
                    onPressed: _openParticipantePicker,
                    child: const Text('+ Cliente'),
                  )
                else if (!_esPublicoGeneral)
                  IconButton(
                    tooltip: 'Cambiar cliente',
                    onPressed: _openParticipantePicker,
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            if (canUsePublicoGeneral) ...<Widget>[
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Público general'),
                subtitle: const Text(
                  'Active esta opción para cobrar sin participante registrado.',
                ),
                value: _esPublicoGeneral,
                onChanged: _togglePublicoGeneral,
              ),
            ],
            if (_esPublicoGeneral) ...<Widget>[
              const SizedBox(height: 8),
              FormFieldCustom(
                label: 'Nombre público',
                isRequired: true,
                errorText: _fieldErrors['nombre_publico'],
                child: TextFormField(
                  controller: _nombrePublicoController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ej. Cliente de contado',
                  ),
                ),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 8),
              if (_selectedParticipante == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _fieldErrors['participante_id'] != null
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No hay cliente seleccionado.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _selectedParticipante!.nombre,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_tipoIdentificacionLabel(_selectedParticipante!.tipoIdentificacion)} · ${_selectedParticipante!.numeroIdentificacion}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if ((_selectedParticipante!.telefono ?? '')
                          .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          _selectedParticipante!.telefono!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if ((_selectedParticipante!.correoElectronico ?? '')
                          .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          _selectedParticipante!.correoElectronico!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              if (_fieldErrors['participante_id'] != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _fieldErrors['participante_id']!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 620;

                final tipoPuestoField = FormFieldCustom(
                  label: 'Tipo puesto',
                  errorText: _fieldErrors['tipo_puesto'],
                  child: TextFormField(
                    controller: _tipoPuestoController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ej. Frutas y verduras',
                    ),
                  ),
                );
                final numeroPuestoField = FormFieldCustom(
                  label: 'Número puesto',
                  errorText: _fieldErrors['numero_puesto'],
                  child: TextFormField(
                    controller: _numeroPuestoController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ej. B-14',
                    ),
                  ),
                );

                if (stacked) {
                  return Column(
                    children: <Widget>[
                      tipoPuestoField,
                      const SizedBox(height: 16),
                      numeroPuestoField,
                    ],
                  );
                }

                return Row(
                  children: <Widget>[
                    Expanded(child: tipoPuestoField),
                    const SizedBox(width: 12),
                    Expanded(child: numeroPuestoField),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservacionesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Observaciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FormFieldCustom(
              label: 'Observaciones',
              errorText: _fieldErrors['observaciones'],
              child: TextFormField(
                controller: _observacionesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Notas internas o detalles del cobro',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductosSection() {
    final productoSubtotal =
        (_selectedProducto?.precio ?? 0) * _selectedCantidad;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Productos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Agregue los productos facturados y verifique el subtotal por línea.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (_selectedProducto == null)
                  TextButton(
                    onPressed: _openProductoPicker,
                    child: const Text('+ Producto'),
                  )
                else
                  IconButton(
                    tooltip: 'Cambiar producto',
                    onPressed: _openProductoPicker,
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedProducto == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _fieldErrors['detalles'] != null
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No hay producto seleccionado.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _selectedProducto!.descripcion,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedProducto!.codigo} · ${AppFormatters.formatMoney(_selectedProducto!.precio ?? 0)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        _QuantityActionButton(
                          icon: _selectedCantidad <= 1
                              ? Icons.delete_outline
                              : Icons.remove,
                          onPressed: _decreaseOrClearSelectedProducto,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Cantidad',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatCantidad(_selectedCantidad),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      'Subtotal',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppFormatters.formatMoney(
                                        productoSubtotal,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _QuantityActionButton(
                          icon: Icons.add,
                          onPressed: _increaseSelectedCantidad,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _selectedProducto == null ? null : _agregarProducto,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ),
            if (_fieldErrors['detalles'] != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _fieldErrors['detalles']!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            if (_lineas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Agregue al menos un producto para continuar.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Column(
                children: _lineas
                    .map(
                      (linea) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          title: Text(linea.producto.descripcion),
                          subtitle: Text(
                            '${linea.cantidad.toStringAsFixed(1)} x ${AppFormatters.formatMoney(linea.precioUnitario)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                AppFormatters.formatMoney(linea.subtotalLinea),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                onPressed: () => _removeLinea(linea),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenSection() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Resumen', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text('Total', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                MoneyText(
                  _subtotal,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FormFieldCustom(
              label: 'Monto pago',
              errorText: _fieldErrors['monto_pago'],
              child: TextFormField(
                controller: _montoPagoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese el monto recibido',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _cambio != null && _cambio! < 0
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Cambio', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.formatMoney(_cambio ?? 0),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _cambio != null && _cambio! < 0
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _extractFieldErrors(Object error) {
    if (error is DioException && error.response?.statusCode == 422) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final errors = data['errors'];

        if (errors is Map<String, dynamic>) {
          return errors.map((key, value) {
            if (value is List && value.isNotEmpty) {
              return MapEntry(key, value.first.toString());
            }

            return MapEntry(key, value.toString());
          });
        }
      }
    }

    return <String, String>{};
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString();

        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
      }

      return error.message ?? 'No se pudo completar la operación.';
    }

    return 'No se pudo completar la operación.';
  }

  String? _nullableValue(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _tipoIdentificacionLabel(String value) {
    return _tipoIdentificacionOptions[value] ?? value.toUpperCase();
  }

  String _formatCantidad(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _FacturaLineaDraft {
  const _FacturaLineaDraft({required this.producto, required this.cantidad});

  final Producto producto;
  final double cantidad;

  double get precioUnitario => producto.precio ?? 0;
  double get subtotalLinea => cantidad * precioUnitario;
}

class _ParticipantePickerSheet extends StatefulWidget {
  const _ParticipantePickerSheet({
    required this.participanteService,
    this.selectedParticipanteId,
  });

  final ParticipanteService participanteService;
  final int? selectedParticipanteId;

  @override
  State<_ParticipantePickerSheet> createState() =>
      _ParticipantePickerSheetState();
}

class _ParticipantePickerSheetState extends State<_ParticipantePickerSheet> {
  List<Participante> _participantes = <Participante>[];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadParticipantes();
  }

  Future<void> _loadParticipantes([String query = '']) async {
    setState(() {
      _isLoading = true;
      _query = query;
    });

    try {
      final participantes = await widget.participanteService
          .getParticipantesPorFeria(search: query);

      if (!mounted) {
        return;
      }

      setState(() {
        _participantes = participantes;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _participantes = <Participante>[];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppSheetHeader(title: 'Seleccionar cliente'),
            const SizedBox(height: 12),
            SearchInput(
              hintText: 'Buscar participante',
              initialValue: _query,
              onChanged: _loadParticipantes,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const LoadingWidget()
                  : _participantes.isEmpty
                  ? const Center(
                      child: Text('No se encontraron participantes.'),
                    )
                  : ListView.separated(
                      itemCount: _participantes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final participante = _participantes[index];
                        final isSelected =
                            participante.id == widget.selectedParticipanteId;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                Navigator.of(context).pop(participante),
                            child: Ink(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          participante.nombre,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          participante.numeroIdentificacion,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                        if ((participante.telefono ?? '')
                                            .isNotEmpty) ...<Widget>[
                                          const SizedBox(height: 2),
                                          Text(
                                            participante.telefono!,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductoPickerSheet extends StatefulWidget {
  const _ProductoPickerSheet({
    required this.productoService,
    required this.excludedProductIds,
    this.selectedProductoId,
  });

  final ProductoService productoService;
  final Set<int> excludedProductIds;
  final int? selectedProductoId;

  @override
  State<_ProductoPickerSheet> createState() => _ProductoPickerSheetState();
}

class _ProductoPickerSheetState extends State<_ProductoPickerSheet> {
  List<Producto> _productos = <Producto>[];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos([String query = '']) async {
    setState(() {
      _isLoading = true;
      _query = query;
    });

    try {
      final productos = await widget.productoService.getProductosPorFeria(
        search: query,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _productos = productos
            .where(
              (producto) =>
                  !widget.excludedProductIds.contains(producto.id) ||
                  producto.id == widget.selectedProductoId,
            )
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _productos = <Producto>[];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppSheetHeader(title: 'Seleccionar producto'),
            const SizedBox(height: 12),
            SearchInput(
              hintText: 'Buscar producto',
              initialValue: _query,
              onChanged: _loadProductos,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const LoadingWidget()
                  : _productos.isEmpty
                  ? const Center(child: Text('No se encontraron productos.'))
                  : ListView.separated(
                      itemCount: _productos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final producto = _productos[index];
                        final isSelected =
                            producto.id == widget.selectedProductoId;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.of(context).pop(producto),
                            child: Ink(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          producto.descripcion,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${producto.codigo} · ${AppFormatters.formatMoney(producto.precio ?? 0)}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityActionButton extends StatelessWidget {
  const _QuantityActionButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 20)),
      ),
    );
  }
}
