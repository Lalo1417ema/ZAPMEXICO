import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/business_field_value.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/review_dialog.dart';
import '../../providers/business_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessDetailScreen extends StatefulWidget {
  const BusinessDetailScreen({super.key});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  int _currentGalleryPage = 0;

  // --- HELPERS DE LANZAMIENTO URL ---
  Future<void> launchPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> launchWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> launchWebsite(String url) async {
    if (url.isEmpty) return;

    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }

    final uri = Uri.parse(formattedUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> launchExternal(String url) async {
    if (url.isEmpty) return;

    String formattedUrl = url;
    if (!url.startsWith('http')) {
      formattedUrl = 'https://$url';
    }

    final uri = Uri.parse(formattedUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> launchMaps(String address, String city) async {
    final location = [
      address,
      city,
    ].where((part) => part.trim().isNotEmpty).join(', ');
    if (location.isEmpty) return;

    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': location,
    });
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps')),
      );
    }
  }

  Widget _galleryImageFallback() => Container(
    width: double.infinity,
    color: AppColors.surface,
    child: const Icon(Icons.broken_image, color: AppColors.primary),
  );

  @override
  Widget build(BuildContext context) {
    final business =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String businessId = (business['id'] ?? '').toString();

    // 👈 Escucha activa del proveedor para repintar el corazón reactivamente
    final provider = Provider.of<BusinessProvider>(context);

    // Datos del negocio seleccionado.
    final String image = (business['logoUrl'] ?? '').toString();
    final imageBytes = business['logoBytes'] is Uint8List
        ? business['logoBytes'] as Uint8List
        : null;
    final String name = (business['name'] ?? 'Negocio').toString();
    final String city = (business['city'] ?? 'Sin ciudad').toString();
    final String location = (business['location'] ?? city).toString();
    final String schedule = businessFieldValue(business, 'schedule');
    final String description = businessFieldValue(business, 'description');
    final String category = businessFieldValue(business, 'category');
    final String sourceUrl = (business['sourceUrl'] ?? '').toString().trim();

    // --- LEER TODOS LOS DATOS ADICIONALES DE CONTACTO ---
    final phone = (business['phone'] ?? '').toString();
    final whatsapp = (business['whatsapp'] ?? '').toString();
    final email = (business['email'] ?? '').toString();
    final address = (business['address'] ?? '').toString();
    final facebook = (business['facebook'] ?? '').toString();
    final instagram = (business['instagram'] ?? '').toString();
    final website = (business['website'] ?? '').toString();

    // Declaración segura de la lista de la galería
    final galleryBytes = business['galleryBytes'] is List
        ? (business['galleryBytes'] as List).whereType<Uint8List>().toList()
        : <Uint8List>[];
    final gallery = business['gallery'] is List
        ? business['gallery'] as List
        : <dynamic>[];

    final double rating = (business['rating'] is num)
        ? (business['rating'] as num).toDouble()
        : 0.0;

    final fallback = Container(
      height: 260,
      width: double.infinity,
      color: AppColors.surface,
      child: const Icon(
        Icons.store_rounded,
        size: 100,
        color: AppColors.primary,
      ),
    );
    final headerImage = imageBytes != null && imageBytes.isNotEmpty
        ? Image.memory(
            imageBytes,
            height: 260,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : image.startsWith('assets/')
        ? Image.asset(
            image,
            height: 260,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : Image.network(
            image,
            height: 260,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          );

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Imagen de cabecera con validación de errores
            image.isNotEmpty ? headerImage : fallback,
            if (business['imageIsIllustrative'] == true)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.greyText,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Imagen ilustrativa; no es una foto del negocio.',
                      style: TextStyle(color: AppColors.greyText, fontSize: 12),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Envoltura en Row para poner el corazón junto al nombre
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Botón de favorito para los datos locales.
                      IconButton(
                        icon: Icon(
                          provider.isFavorite(businessId)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: provider.isFavorite(businessId)
                              ? Colors.red
                              : Colors.white,
                          size: 28,
                        ),
                        onPressed: () async {
                          await provider.toggleFavorite(businessId);

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 2),
                              content: Text(
                                provider.isFavorite(businessId)
                                    ? 'Agregado a favoritos'
                                    : 'Eliminado de favoritos',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(
                    category,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  RatingStars(rating: rating),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => launchMaps(address, location),
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: AppColors.greyText,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Abrir en Google Maps',
                        onPressed: () => launchMaps(address, location),
                        icon: const Icon(
                          Icons.map_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        schedule,
                        style: const TextStyle(color: AppColors.greyText),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Descripción',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    'Galería',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  galleryBytes.isEmpty && gallery.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Este negocio aún no tiene fotografías.',
                              style: TextStyle(color: AppColors.greyText),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 230,
                          child: Column(
                            children: [
                              Expanded(
                                child: PageView.builder(
                                  itemCount:
                                      galleryBytes.length + gallery.length,
                                  onPageChanged: (index) {
                                    setState(() => _currentGalleryPage = index);
                                  },
                                  itemBuilder: (context, index) {
                                    final image = index < galleryBytes.length
                                        ? Image.memory(
                                            galleryBytes[index],
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                _galleryImageFallback(),
                                          )
                                        : Image.network(
                                            gallery[index - galleryBytes.length]
                                                .toString(),
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                _galleryImageFallback(),
                                          );
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: image,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  galleryBytes.length + gallery.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: _currentGalleryPage == index
                                        ? 18
                                        : 7,
                                    height: 7,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _currentGalleryPage == index
                                          ? AppColors.primary
                                          : AppColors.greyText,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                  // 📱 SECCIÓN DE CONTACTO
                  const SizedBox(height: 30),
                  const Text(
                    'Contacto',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    margin: EdgeInsets.zero,
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.phone,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              businessFieldValue(business, 'phone'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: phone.isEmpty
                                ? null
                                : () => launchPhone(phone),
                          ),
                          if (email.isNotEmpty)
                            ListTile(
                              leading: const Icon(
                                Icons.email,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                email,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ListTile(
                            leading: const Icon(
                              Icons.map_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              businessFieldValue(business, 'address'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: address.isEmpty
                                ? null
                                : const Icon(
                                    Icons.open_in_new,
                                    color: AppColors.primary,
                                  ),
                            onTap: address.isEmpty
                                ? null
                                : () => launchMaps(address, city),
                          ),
                          if (sourceUrl.isNotEmpty)
                            ListTile(
                              leading: const Icon(
                                Icons.source_outlined,
                                color: AppColors.primary,
                              ),
                              title: const Text(
                                'Consultar fuente',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () => launchExternal(sourceUrl),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🎛️ BOTONES RÁPIDOS INTERACTIVOS (WRAP)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (phone.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => launchPhone(phone),
                          icon: const Icon(Icons.phone),
                          label: const Text('Llamar'),
                        ),
                      if (whatsapp.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => launchWhatsApp(whatsapp),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('WhatsApp'),
                        ),
                      if (website.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => launchWebsite(website),
                          icon: const Icon(Icons.language),
                          label: const Text('Sitio'),
                        ),
                      if (facebook.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => launchExternal(facebook),
                          icon: const Icon(Icons.facebook),
                          label: const Text('Facebook'),
                        ),
                      if (instagram.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => launchExternal(instagram),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Instagram'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // ✍️ SECCIÓN DE RESEÑAS Y BOTÓN DE ACCIÓN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reseñas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final provider = Provider.of<BusinessProvider>(
                            context,
                            listen: false,
                          );
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (_) => const ReviewDialog(),
                          );

                          if (result == null) return;

                          // 👈 CONTROL CON TRY-CATCH PARA CAPTURAR LA EXCEPCIÓN DEL PROVIDER
                          try {
                            await provider.addReview(
                              businessId: businessId,
                              rating: result['rating'],
                              comment: result['comment'],
                            );

                            await provider.fetchApprovedBusinesses();

                            if (!context.mounted) return;
                            Navigator.pop(context); // Éxito: Cierra y recarga
                          } catch (e) {
                            if (!context.mounted) return;

                            // 🚨 Alerta visual si el usuario ya tenía un comentario guardado
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: const Text('Calificar'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ⏳ DIAGNÓSTICO EN TIEMPO REAL (FUTUREBUILDER ACTUALIZADO)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: Provider.of<BusinessProvider>(
                      context,
                      listen: false,
                    ).fetchReviews(businessId),
                    builder: (context, snapshot) {
                      // Muestra un error de carga de reseñas si ocurre.
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SelectableText(
                            'No se pudieron cargar las reseñas: ${snapshot.error}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final reviews = snapshot.data!;

                      if (reviews.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Aún no hay reseñas. ¡Sé el primero en calificar!',
                            style: TextStyle(color: AppColors.greyText),
                          ),
                        );
                      }

                      return Column(
                        children: reviews.map((review) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: AppColors.surface,
                            child: ListTile(
                              title: Text(
                                review['userName'] ?? 'Usuario anónimo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(review['comment'] ?? ''),
                              trailing: Text(
                                '${review['rating']} ⭐',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
