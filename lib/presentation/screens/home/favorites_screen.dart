import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';

import '../../../config/routes/app_routes.dart'; // Asegúrate de ajustar esta ruta según tu proyecto
import '../../../core/constants/app_colors.dart'; // Ajusta según tus constantes de diseño
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/registration_required_dialog.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BusinessProvider>(context, listen: false);

    Future.microtask(() {
      provider.fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BusinessProvider>(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Favoritos'), centerTitle: true),
      body: auth.isVisitor
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Regístrate o inicia sesión para guardar y consultar favoritos.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => showRegistrationRequiredDialog(context),
                      child: const Text('Crear cuenta'),
                    ),
                  ],
                ),
              ),
            )
          : provider.favoriteBusinesses.isEmpty
          ? const Center(
              child: Text(
                'No tienes negocios favoritos aún.',
                style: TextStyle(color: AppColors.greyText, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: provider.favoriteBusinesses.length,
              itemBuilder: (context, index) {
                final business = provider.favoriteBusinesses[index];
                final imageBytes = business['logoBytes'] is Uint8List
                    ? business['logoBytes'] as Uint8List
                    : null;
                final imageUrl = (business['logoUrl'] ?? '').toString();

                // 👈 SE REEMPLAZÓ POR CARD CON MARGIN CORREGIDO
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: AppColors.surface,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),

                    // 🖼️ LEADING: Muestra el logo desde Cloudinary o el fallback de tienda
                    leading: imageBytes != null && imageBytes.isNotEmpty
                        ? CircleAvatar(
                            radius: 25,
                            backgroundImage: MemoryImage(imageBytes),
                          )
                        : imageUrl.isNotEmpty
                        ? CircleAvatar(
                            radius: 25,
                            backgroundImage: imageUrl.startsWith('assets/')
                                ? AssetImage(imageUrl)
                                : NetworkImage(imageUrl),
                          )
                        : const CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.store, color: Colors.white),
                          ),

                    // 🏷️ TITLE: Nombre del negocio
                    title: Text(
                      business['name'] ?? 'Negocio',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),

                    // 📋 SUBTITLE: Ciudad y Rating en formato de columna estructurada
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (business['imageIsIllustrative'] == true)
                            const Text(
                              'Imagen ilustrativa',
                              style: TextStyle(
                                color: AppColors.greyText,
                                fontSize: 12,
                              ),
                            ),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: AppColors.greyText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                business['city'] ?? '',
                                style: const TextStyle(
                                  color: AppColors.greyText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${((business['rating'] ?? 0) as num).toDouble()}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 🔀 BOTÓN RÁPIDO PARA ELIMINAR DE FAVORITOS DIRECTAMENTE DESDE LA LISTA
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () async {
                        try {
                          await provider.toggleFavorite(
                            business['id'].toString(),
                          );
                        } on FirebaseException catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.message ??
                                    'No se pudo actualizar favoritos.',
                              ),
                            ),
                          );
                        } on StateError catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      },
                    ),

                    // 🚀 NAVEGACIÓN: Al pulsar te lleva directo al detalle del negocio
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.businessDetail,
                        arguments: business,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
