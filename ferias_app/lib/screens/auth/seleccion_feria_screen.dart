import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/feria_provider.dart';

class SeleccionFeriaScreen extends StatelessWidget {
  const SeleccionFeriaScreen({super.key});

  Future<void> _selectFeria(BuildContext context, int feriaId) async {
    final feriaProvider = context.read<FeriaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final feria = feriaProvider.ferias.firstWhere((item) => item.id == feriaId);

    try {
      await feriaProvider.setFeriaActiva(feria);

      if (!context.mounted) {
        return;
      }

      context.go(AppRoutes.dashboard);
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'No fue posible seleccionar la feria.';

      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No fue posible seleccionar la feria.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feriaProvider = context.watch<FeriaProvider>();
    final ferias = feriaProvider.ferias;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 8),
              Text(
                'Seleccione la feria',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Elija la feria en la que desea trabajar hoy.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedTextColor,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ferias.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No hay ferias disponibles para este usuario.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: ferias.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final feria = ferias[index];
                          final isActive =
                              feriaProvider.feriaActiva?.id == feria.id;

                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFFE8F0FF)
                                      : const Color(0xFFF4F7FB),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isActive
                                      ? Icons.check_circle
                                      : Icons.storefront_outlined,
                                  color: isActive
                                      ? AppTheme.primaryColor
                                      : AppTheme.mutedTextColor,
                                ),
                              ),
                              title: Text(
                                feria.codigo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(feria.descripcion),
                              ),
                              trailing: feriaProvider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.chevron_right_rounded),
                              onTap: feriaProvider.isLoading
                                  ? null
                                  : () => _selectFeria(context, feria.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
