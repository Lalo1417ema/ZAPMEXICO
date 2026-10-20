import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/michoacan_municipalities.dart';
import '../../providers/business_provider.dart';
import '../../providers/catalog_provider.dart';

class AdminCatalogScreen extends StatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  State<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends State<AdminCatalogScreen> {
  final _categoryController = TextEditingController();
  String selectedMunicipality = michoacanMunicipalities.first;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final catalog = context.read<CatalogProvider>();
    try {
      await catalog.loadCatalogs();
      await catalog.loadRequests();
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'No se pudo cargar el catálogo.');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => isLoading = true);
    try {
      await action();
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'No se pudo guardar el cambio.');
    } on ArgumentError catch (error) {
      _showMessage(error.message.toString());
    } on StateError catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final businesses = context.watch<BusinessProvider>().businesses;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Municipios disponibles',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedMunicipality,
          decoration: const InputDecoration(
            labelText: 'Municipio oficial de Michoacán',
            border: OutlineInputBorder(),
          ),
          items: michoacanMunicipalities
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => selectedMunicipality = value);
          },
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: isLoading
              ? null
              : () => _run(() => catalog.addMunicipality(selectedMunicipality)),
          icon: const Icon(Icons.add_location_alt),
          label: const Text('Agregar municipio'),
        ),
        Text('${catalog.municipalities.length} municipios disponibles'),
        const Divider(height: 32),
        Text(
          'Categorías disponibles',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Nueva categoría',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: isLoading
              ? null
              : () => _run(() async {
                  await catalog.addCategory(_categoryController.text);
                  _categoryController.clear();
                }),
          icon: const Icon(Icons.add),
          label: const Text('Agregar categoría'),
        ),
        Text('${catalog.categories.length} categorías disponibles'),
        const Divider(height: 32),
        Text(
          'Solicitudes por revisar (${catalog.requests.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (catalog.requests.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No hay propuestas pendientes.'),
          ),
        ...catalog.requests.map((request) {
          final business = businesses.cast<Map<String, dynamic>?>().firstWhere(
            (item) => item?['id'] == request['businessId'],
            orElse: () => null,
          );
          final type = request['type'] == 'municipality'
              ? 'Municipio'
              : 'Categoría';
          final value = request['value']?.toString() ?? '';
          return Card(
            child: ListTile(
              title: Text('$type: $value'),
              subtitle: Text(
                'Negocio: ${business?['name'] ?? request['businessId']}\n'
                '${request['municipality']} • ${request['category']}',
              ),
              isThreeLine: true,
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Aprobar y agregar',
                    onPressed: isLoading
                        ? null
                        : () => _run(
                            () => catalog.reviewRequest(
                              requestId: request['id'].toString(),
                              approve: true,
                            ),
                          ),
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  IconButton(
                    tooltip: 'Rechazar',
                    onPressed: isLoading
                        ? null
                        : () => _run(
                            () => catalog.reviewRequest(
                              requestId: request['id'].toString(),
                              approve: false,
                            ),
                          ),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }),
        if (isLoading || catalog.isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
