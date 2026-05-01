import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/item_diagnostico.dart';
import 'app_modals.dart';
import 'form_field_custom.dart';

class ItemDiagnosticoFormSheet extends StatefulWidget {
  const ItemDiagnosticoFormSheet({
    super.key,
    required this.onSubmit,
    this.item,
  });

  final ItemDiagnostico? item;
  final Future<void> Function(String nombre) onSubmit;

  @override
  State<ItemDiagnosticoFormSheet> createState() =>
      _ItemDiagnosticoFormSheetState();
}

class _ItemDiagnosticoFormSheetState extends State<ItemDiagnosticoFormSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item?.nombre ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    final nombre = _controller.text.trim();

    if (nombre.isEmpty) {
      setState(() {
        _errorText = 'Debe ingresar un nombre para el item.';
        _isSubmitting = false;
      });
      return;
    }

    try {
      await widget.onSubmit(nombre);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (error is DioException) {
        final data = error.response?.data;

        if (data is Map) {
          if (data['errors'] is Map) {
            final errors = Map<String, dynamic>.from(data['errors'] as Map);

            for (final messages in errors.values) {
              if (messages is List && messages.isNotEmpty) {
                setState(() {
                  _errorText = messages.first.toString();
                  _isSubmitting = false;
                });
                return;
              }
            }
          }

          if (data['message'] != null) {
            setState(() {
              _errorText = data['message'].toString();
              _isSubmitting = false;
            });
            return;
          }
        }
      }

      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return AppSheetContainer(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSheetHeader(
            title: isEditing
                ? 'Editar item de diagnóstico'
                : 'Nuevo item de diagnóstico',
          ),
          const SizedBox(height: 20),
          FormFieldCustom(
            label: 'Nombre',
            isRequired: true,
            errorText: _errorText,
            child: TextField(
              controller: _controller,
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ej. Uso correcto de uniforme',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.neutralSoftColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              'Las inspecciones guardadas conservan el nombre histórico del item aunque luego se edite o elimine del catálogo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
          AppSheetActions(
            isSubmitting: _isSubmitting,
            submitLabel: isEditing ? 'Guardar cambios' : 'Crear item',
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}
