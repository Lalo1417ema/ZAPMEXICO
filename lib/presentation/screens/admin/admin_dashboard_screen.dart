import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_drawer.dart';

import '../../../config/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalog_provider.dart';
import 'admin_blocking_screen.dart';
import 'admin_events_screen.dart';
import 'admin_catalog_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoggingOut = false;
  final _approvedSearchController = TextEditingController();
  final _rejectedSearchController = TextEditingController();
  String? _approvedCategory;
  String? _approvedCity;
  String? _rejectedCategory;
  String? _rejectedCity;

  @override
  void dispose() {
    _approvedSearchController.dispose();
    _rejectedSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final provider = Provider.of<BusinessProvider>(context, listen: false);
    Future.microtask(() async {
      await _loadAdminData(provider);
    });
  }

  Future<void> _loadAdminData(BusinessProvider provider) async {
    final catalogProvider = Provider.of<CatalogProvider>(
      context,
      listen: false,
    );
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    try {
      await provider.fetchAllBusinessesForAdmin();
      if (!mounted) return;
      await catalogProvider.loadCatalogs();
      if (!mounted) return;
      await adminProvider.loadStatistics(provider);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'No se pudieron cargar los datos del panel.',
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    final navigator = Navigator.of(context);
    try {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (!mounted) return;
      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'No se pudo cerrar sesión.')),
      );
    } on Exception catch (error) {
      debugPrint('Error al cerrar sesión de administrador: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar sesión. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Widget buildBusinessCard(
    Map<String, dynamic> business,
    BusinessProvider provider,
  ) {
    final status = business['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: ListTile(
        leading: _businessLogo(business),
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
            IconButton(
              tooltip: 'Editar negocio',
              icon: const Icon(Icons.edit, color: Colors.amber),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.editBusiness,
                  arguments: business,
                );
              },
            ),
            if (status == 'pending') ...[
              IconButton(
                onPressed: () async {
                  try {
                    await provider.approveBusiness(business['id']);
                  } on FirebaseException catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error.message ?? 'No se pudo aprobar el negocio.',
                        ),
                      ),
                    );
                  } on StateError catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
                  } finally {
                    if (mounted) await _loadAdminData(provider);
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
                    try {
                      await provider.rejectBusiness(business['id'], comment);
                      await _loadAdminData(provider);
                    } on FirebaseException catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error.message ?? 'No se pudo rechazar el negocio.',
                          ),
                        ),
                      );
                    } on ArgumentError catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.message.toString())),
                      );
                    }
                  }
                  controller.dispose();
                },
                icon: const Icon(Icons.cancel, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _businessLogo(Map<String, dynamic> business) {
    final logoUrl = (business['logoUrl'] ?? '').toString();
    final fallback = const CircleAvatar(child: Icon(Icons.store));
    if (logoUrl.isEmpty) return fallback;

    final image = logoUrl.startsWith('assets/')
        ? Image.asset(logoUrl, width: 48, height: 48, fit: BoxFit.cover)
        : Image.network(
            logoUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.store),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(width: 48, height: 48, child: image),
    );
  }

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
    return _buildFilteredTab(
      businesses: provider.approvedBusinesses,
      provider: provider,
      searchController: _approvedSearchController,
      selectedCategory: _approvedCategory,
      selectedCity: _approvedCity,
      onCategoryChanged: (value) => setState(() => _approvedCategory = value),
      onCityChanged: (value) => setState(() => _approvedCity = value),
      emptyMessage: 'No hay negocios aprobados',
      noMatchesMessage: 'No hay aprobados que coincidan con la búsqueda.',
      pageStorageKey: 'approved_tab',
    );
  }

  Widget buildRejectedTab(BusinessProvider provider) {
    return _buildFilteredTab(
      businesses: provider.rejectedBusinesses,
      provider: provider,
      searchController: _rejectedSearchController,
      selectedCategory: _rejectedCategory,
      selectedCity: _rejectedCity,
      onCategoryChanged: (value) => setState(() => _rejectedCategory = value),
      onCityChanged: (value) => setState(() => _rejectedCity = value),
      emptyMessage: 'No hay negocios rechazados',
      noMatchesMessage: 'No hay rechazados que coincidan con la búsqueda.',
      pageStorageKey: 'rejected_tab',
    );
  }

  Widget _buildFilteredTab({
    required List<Map<String, dynamic>> businesses,
    required BusinessProvider provider,
    required TextEditingController searchController,
    required String? selectedCategory,
    required String? selectedCity,
    required ValueChanged<String?> onCategoryChanged,
    required ValueChanged<String?> onCityChanged,
    required String emptyMessage,
    required String noMatchesMessage,
    required String pageStorageKey,
  }) {
    final catalogs = context.watch<CatalogProvider>();
    final query = searchController.text.trim().toLowerCase();
    final filteredBusinesses = businesses.where((business) {
      final matchesSearch =
          query.isEmpty ||
          [
            business['name'],
            business['category'],
            business['city'],
            business['address'],
            business['phone'],
          ].any((value) => value.toString().toLowerCase().contains(query));
      final matchesCategory =
          selectedCategory == null || business['category'] == selectedCategory;
      final matchesCity =
          selectedCity == null || business['city'] == selectedCity;
      return matchesSearch && matchesCategory && matchesCity;
    }).toList();

    if (businesses.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, dirección, teléfono...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 155,
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...catalogs.categories.map(
                      (category) => DropdownMenuItem<String?>(
                        value: category,
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: onCategoryChanged,
                ),
              ),
              SizedBox(
                width: 155,
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedCity,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Municipio',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...catalogs.municipalities.map(
                      (city) => DropdownMenuItem<String?>(
                        value: city,
                        child: Text(city, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: onCityChanged,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${filteredBusinesses.length} negocios'),
          ),
        ),
        Expanded(
          child: filteredBusinesses.isEmpty
              ? Center(child: Text(noMatchesMessage))
              : ListView.builder(
                  key: PageStorageKey(pageStorageKey),
                  itemCount: filteredBusinesses.length,
                  itemBuilder: (context, index) =>
                      buildBusinessCard(filteredBusinesses[index], provider),
                ),
        ),
      ],
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

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        drawer: const CustomDrawer(),
        appBar: AppBar(
          title: const Text('Panel Administrador'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'Aprobados'),
              Tab(text: 'Rechazados'),
              Tab(text: 'Estadísticas'),
              Tab(text: 'Eventos'),
              Tab(text: 'Bloqueos'),
              Tab(text: 'Catálogos'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Agregar negocio',
              icon: const Icon(Icons.add_business),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final provider = Provider.of<BusinessProvider>(
                  context,
                  listen: false,
                );
                await navigator.pushNamed(AppRoutes.businessRequest);
                if (!mounted) return;
                await _loadAdminData(provider);
              },
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _isLoggingOut ? null : _logout,
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
            ),
          ],
        ),
        body: businessProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  buildPendingTab(businessProvider),

                  buildApprovedTab(businessProvider),

                  buildRejectedTab(businessProvider),

                  buildStatisticsTab(),

                  const AdminEventsScreen(),

                  const AdminBlockingScreen(),

                  const AdminCatalogScreen(),
                ],
              ),
      ),
    );
  }
}
