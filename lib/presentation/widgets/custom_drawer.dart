import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../config/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final user = auth.currentUserModel;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 50)),

            const SizedBox(height: 16),

            Text(
              user?['name'] ?? 'Usuario',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              user?['email'] ?? '',
              style: const TextStyle(color: AppColors.greyText),
            ),

            const SizedBox(height: 6),

            Text(
              user?['city'] ?? '',
              style: const TextStyle(color: AppColors.greyText),
            ),

            const SizedBox(height: 24),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                final municipality = user?['city']?.toString();
                if (municipality == null || municipality.isEmpty) {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.visitorSetup,
                  );
                  return;
                }

                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.municipalityBusinesses,
                  arguments: {
                    'municipality': municipality,
                    'visitorName': user?['name']?.toString() ?? '',
                  },
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Mis Favoritos'),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.favorites);
              },
            ),

            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Registrar negocio'),

              onTap: () {
                Navigator.pushNamed(context, AppRoutes.businessRequest);
              },
            ),
            if (auth.isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Administrador'),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.adminDashboard);
                },
              ),

            if (auth.isAdmin)
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Monetización'),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.monetization);
                },
              ),

            const Spacer(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                try {
                  await auth.logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                } on FirebaseException catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.message ?? 'No se pudo cerrar sesión.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
