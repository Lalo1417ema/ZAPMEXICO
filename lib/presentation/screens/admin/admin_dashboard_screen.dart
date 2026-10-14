import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_drawer.dart';

import '../../../config/routes/app_routes.dart';
import '../../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();

    // Carga el contenido local disponible para el panel de demostración.
    final provider = Provider.of<BusinessProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    Future.microtask(() async {
      await provider.fetchPendingBusinesses();

      await provider.fetchApprovedBusinesses();

      await provider.fetchRejectedBusinesses();

      await adminProvider.loadStatistics();
    });
  }

  // PASO 8 — Tarjeta reutilizable y adaptativa según el estado del negocio
  Widget buildBusinessCard(
    Map<String, dynamic> business,
    BusinessProvider provider,
  ) {
    final status = business['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: ListTile(
        title: Text(
          business['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${business['category']} • ${business['city']}'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: provider.getStatusColor(status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: provider.getStatusColor(status),
                  width: 0.5,
                ),
              ),
              child: Text(
                status.toString().toUpperCase(),
                style: TextStyle(
                  color: provider.getStatusColor(status),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón Ver Detalle incorporado nativamente en la acción
            IconButton(
              icon: const Icon(Icons.visibility_rounded, color: Colors.blue),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.businessDetail,
                  arguments: business,
                );
              },
            ),
            // Acciones de aprobación/rechazo condicionales (Solo si está pendiente)
            if (status == 'pending') ...[
              IconButton(
                onPressed: () async {
                  try {
                    await provider.approveBusiness(business['id']);
                  } on StateError catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
                  }
                },
                icon: const Icon(Icons.check_circle, color: Colors.green),
              ),
              IconButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  final comment = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Motivo del rechazo'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Escribe observación',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, controller.text),
                            child: const Text('Guardar'),
                          ),
                        ],
                      );
                    },
                  );

                  if (comment != null && comment.isNotEmpty) {
                    await provider.rejectBusiness(business['id'], comment);
                  }
                },
                icon: const Icon(Icons.cancel, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares para construir el cuerpo de cada pestaña (PASO 7)
  Widget buildPendingTab(BusinessProvider provider) {
    return provider.pendingBusinesses.isEmpty
        ? const Center(child: Text('No hay negocios pendientes'))
        : ListView.builder(
            itemCount: provider.pendingBusinesses.length,
            key: const PageStorageKey('pending_tab'),
            itemBuilder: (context, index) =>
                buildBusinessCard(provider.pendingBusinesses[index], provider),
          );
  }

  Widget buildApprovedTab(BusinessProvider provider) {
    return provider.businesses.isEmpty
        ? const Center(child: Text('No hay negocios aprobados'))
        : ListView.builder(
            itemCount: provider.businesses.length,
            key: const PageStorageKey('approved_tab'),
            itemBuilder: (context, index) =>
                buildBusinessCard(provider.businesses[index], provider),
          );
  }

  Widget buildRejectedTab(BusinessProvider provider) {
    return provider.rejectedBusinesses.isEmpty
        ? const Center(child: Text('No hay negocios rechazados'))
        : ListView.builder(
            itemCount: provider.rejectedBusinesses.length,
            itemBuilder: (context, index) {
              return buildBusinessCard(
                provider.rejectedBusinesses[index],
                provider,
              );
            },
          );
  }

  Widget buildStatisticsTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, child) {
        if (admin.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Estadísticas del Sistema',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Usuarios registrados'),
                trailing: Text(
                  admin.totalUsers.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: const Text('Aprobados'),
                    trailing: Text(admin.approvedBusinesses.toString()),
                  ),

                  ListTile(
                    leading: const Icon(Icons.pending, color: Colors.orange),
                    title: const Text('Pendientes'),
                    trailing: Text(admin.pendingBusinesses.toString()),
                  ),

                  ListTile(
                    leading: const Icon(Icons.cancel, color: Colors.red),
                    title: const Text('Rechazados'),
                    trailing: Text(admin.rejectedBusinesses.toString()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Reseñas'),
                trailing: Text(
                  admin.totalReviews.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Favoritos'),
                trailing: Text(
                  admin.totalFavorites.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessProvider>(context);

    // PASO 6 — Proveer el controlador de pestañas envolviendo el Scaffold
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        drawer: const CustomDrawer(),
        appBar: AppBar(
          title: const Text('Panel Administrador'),
          // PASO 5 — Inyección del TabBar en la parte inferior del AppBar
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'Aprobados'),
              Tab(text: 'Rechazados'),
              Tab(text: 'Estadísticas'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        // PASO 7 — Despliegue de las vistas asíncronas sincronizadas con el TabBar
        body: businessProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  buildPendingTab(businessProvider),

                  buildApprovedTab(businessProvider),

                  buildRejectedTab(businessProvider),

                  buildStatisticsTab(),
                ],
              ),
      ),
    );
  }
}
