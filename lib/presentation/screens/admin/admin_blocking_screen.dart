import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';

class AdminBlockingScreen extends StatefulWidget {
  const AdminBlockingScreen({super.key});

  @override
  State<AdminBlockingScreen> createState() => _AdminBlockingScreenState();
}

class _AdminBlockingScreenState extends State<AdminBlockingScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadUsers);
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      await context.read<AdminProvider>().loadUsers();
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'No se pudieron cargar los usuarios.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleUser(Map<String, dynamic> user) async {
    final uid = user['uid'].toString();
    final blocked = user['blocked'] == true;
    final adminProvider = context.read<AdminProvider>();
    if (uid == context.read<AuthProvider>().user) {
      _showMessage('No puedes bloquear tu propia cuenta administradora.');
      return;
    }
    final confirmed = await _confirm(
      title: blocked ? 'Desbloquear usuario' : 'Bloquear usuario',
      message: blocked
          ? 'El usuario podrá volver a utilizar la aplicación.'
          : 'Se suspenderá el acceso del usuario a la aplicación.',
      action: blocked ? 'Desbloquear' : 'Bloquear',
    );
    if (confirmed != true || !mounted) return;

    try {
      await adminProvider.setUserBlocked(userId: uid, blocked: !blocked);
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'No se pudo actualizar el usuario.');
    }
  }

  Future<void> _toggleBusiness(Map<String, dynamic> business) async {
    final blocked = business['blocked'] == true;
    final businessProvider = context.read<BusinessProvider>();
    final confirmed = await _confirm(
      title: blocked ? 'Desbloquear negocio' : 'Bloquear negocio',
      message: blocked
          ? 'El negocio volverá a aparecer en el directorio.'
          : 'El negocio dejará de aparecer para los usuarios.',
      action: blocked ? 'Desbloquear' : 'Bloquear',
    );
    if (confirmed != true || !mounted) return;

    try {
      await businessProvider.setBusinessBlocked(
        businessId: business['id'].toString(),
        blocked: !blocked,
      );
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'No se pudo actualizar el negocio.');
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String action,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final businessProvider = context.watch<BusinessProvider>();
    final businesses = [
      ...businessProvider.approvedBusinesses,
      ...businessProvider.pendingBusinesses,
      ...businessProvider.rejectedBusinesses,
    ];

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Negocios'),
              Tab(text: 'Usuarios'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                businesses.isEmpty
                    ? const Center(child: Text('No hay negocios registrados'))
                    : ListView.builder(
                        itemCount: businesses.length,
                        itemBuilder: (context, index) {
                          final business = businesses[index];
                          final blocked = business['blocked'] == true;
                          return ListTile(
                            leading: Icon(
                              blocked
                                  ? Icons.store_mall_directory
                                  : Icons.store,
                              color: blocked ? Colors.red : null,
                            ),
                            title: Text(
                              (business['name'] ?? 'Negocio').toString(),
                            ),
                            subtitle: Text(
                              '${business['city'] ?? ''} • ${business['status'] ?? ''}',
                            ),
                            trailing: IconButton(
                              tooltip: blocked
                                  ? 'Desbloquear negocio'
                                  : 'Bloquear negocio',
                              onPressed: () => _toggleBusiness(business),
                              icon: Icon(
                                blocked ? Icons.lock_open : Icons.block,
                                color: blocked ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                adminProvider.users.isEmpty
                    ? const Center(child: Text('No hay usuarios registrados'))
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          itemCount: adminProvider.users.length,
                          itemBuilder: (context, index) {
                            final user = adminProvider.users[index];
                            final blocked = user['blocked'] == true;
                            final isCurrentUser =
                                user['uid'] ==
                                context.read<AuthProvider>().user;
                            return ListTile(
                              leading: Icon(
                                blocked ? Icons.person_off : Icons.person,
                                color: blocked ? Colors.red : null,
                              ),
                              title: Text(
                                (user['name'] ?? 'Usuario').toString(),
                              ),
                              subtitle: Text(
                                (user['email'] ?? user['city'] ?? '')
                                    .toString(),
                              ),
                              trailing: IconButton(
                                tooltip: blocked
                                    ? 'Desbloquear usuario'
                                    : 'Bloquear usuario',
                                onPressed: isCurrentUser
                                    ? null
                                    : () => _toggleUser(user),
                                icon: Icon(
                                  blocked ? Icons.lock_open : Icons.block,
                                  color: blocked ? Colors.green : Colors.red,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
