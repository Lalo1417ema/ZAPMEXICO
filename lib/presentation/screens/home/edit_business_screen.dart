import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../providers/business_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditBusinessScreen extends StatelessWidget {
  const EditBusinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EditBusinessView();
  }
}

class _EditBusinessView extends StatefulWidget {
  const _EditBusinessView();

  @override
  State<_EditBusinessView> createState() => _EditBusinessViewState();
}

class _EditBusinessViewState extends State<_EditBusinessView> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController phoneController;
  late TextEditingController cityController;
  late TextEditingController scheduleController;
  late TextEditingController addressController;
  late TextEditingController categoryController;
  late TextEditingController ownerController;
  late TextEditingController emailController;
  late TextEditingController whatsappController;
  late TextEditingController facebookController;
  late TextEditingController instagramController;
  late TextEditingController websiteController;

  late String businessId;
  late List<String> existingGallery;
  bool initialized = false;
  bool isSaving = false;

  File? selectedLogoImage;
  final List<File> selectedGalleryImages = [];
  final ImagePicker picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    final business =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    businessId = business['id'].toString();
    existingGallery = List<String>.from(business['gallery'] as List? ?? []);
    nameController = TextEditingController(
      text: business['name']?.toString() ?? '',
    );
    descriptionController = TextEditingController(
      text: business['description']?.toString() ?? '',
    );
    phoneController = TextEditingController(
      text: business['phone']?.toString() ?? '',
    );
    cityController = TextEditingController(
      text: business['city']?.toString() ?? '',
    );
    scheduleController = TextEditingController(
      text: business['schedule']?.toString() ?? '',
    );
    addressController = TextEditingController(
      text: business['address']?.toString() ?? '',
    );
    categoryController = TextEditingController(
      text: business['category']?.toString() ?? '',
    );
    ownerController = TextEditingController(
      text: business['owner']?.toString() ?? '',
    );
    emailController = TextEditingController(
      text: business['email']?.toString() ?? '',
    );
    whatsappController = TextEditingController(
      text: business['whatsapp']?.toString() ?? '',
    );
    facebookController = TextEditingController(
      text: business['facebook']?.toString() ?? '',
    );
    instagramController = TextEditingController(
      text: business['instagram']?.toString() ?? '',
    );
    websiteController = TextEditingController(
      text: business['website']?.toString() ?? '',
    );
    initialized = true;
  }

  // 🧹 Liberación de memoria indispensable
  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    cityController.dispose();
    scheduleController.dispose();
    addressController.dispose();
    categoryController.dispose();
    ownerController.dispose();
    emailController.dispose();
    whatsappController.dispose();
    facebookController.dispose();
    instagramController.dispose();
    websiteController.dispose();
    super.dispose();
  }

  Future<void> pickLogoImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    setState(() {
      selectedLogoImage = File(image.path);
    });
  }

  Future<void> pickGalleryImages() async {
    final remaining =
        20 - existingGallery.length - selectedGalleryImages.length;
    if (remaining <= 0) return;
    final images = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (images.isEmpty || !mounted) return;

    setState(() {
      selectedGalleryImages.addAll(
        images.take(remaining).map((image) => File(image.path)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BusinessProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar negocio')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: scheduleController,
              decoration: const InputDecoration(labelText: 'Horario'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ownerController,
              decoration: const InputDecoration(labelText: 'Encargado'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: whatsappController,
              decoration: const InputDecoration(labelText: 'WhatsApp'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: facebookController,
              decoration: const InputDecoration(labelText: 'Facebook'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: instagramController,
              decoration: const InputDecoration(labelText: 'Instagram'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: websiteController,
              decoration: const InputDecoration(labelText: 'Sitio web'),
            ),
            const SizedBox(height: 24),

            Text(
              'Logo del negocio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton.icon(
              onPressed: pickLogoImage,
              icon: const Icon(Icons.store),
              label: const Text('Cambiar logo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
              ),
            ),
            if (selectedLogoImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    selectedLogoImage!,
                    height: 110,
                    width: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 24),
            Text(
              'Fotos para el carrusel (mínimo 3)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton.icon(
              onPressed: pickGalleryImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Agregar fotos'),
            ),
            if (selectedGalleryImages.isNotEmpty)
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedGalleryImages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          selectedGalleryImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: IconButton.filled(
                          tooltip: 'Quitar foto',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(
                            () => selectedGalleryImages.removeAt(index),
                          ),
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Text(
              '${existingGallery.length + selectedGalleryImages.length}/20 fotos',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setState(() => isSaving = true);
                      try {
                        if (existingGallery.length +
                                selectedGalleryImages.length >
                            20) {
                          throw ArgumentError(
                            'La galería admite un máximo de 20 fotos.',
                          );
                        }
                        final gallery = [...existingGallery];
                        for (final image in selectedGalleryImages) {
                          gallery.add(
                            await provider.uploadGalleryImage(
                              businessId: businessId,
                              imageFile: image,
                            ),
                          );
                        }
                        final logoUrl = selectedLogoImage == null
                            ? null
                            : await provider.uploadBusinessLogo(
                                businessId: businessId,
                                imageFile: selectedLogoImage!,
                              );
                        await provider.updateBusiness(
                          businessId: businessId,
                          data: {
                            'name': nameController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'city': cityController.text.trim(),
                            'location': cityController.text.trim(),
                            'schedule': scheduleController.text.trim(),
                            'address': addressController.text.trim(),
                            'category': categoryController.text.trim(),
                            'owner': ownerController.text.trim(),
                            'email': emailController.text.trim(),
                            'whatsapp': whatsappController.text.trim(),
                            'facebook': facebookController.text.trim(),
                            'instagram': instagramController.text.trim(),
                            'website': websiteController.text.trim(),
                            'logoUrl': ?logoUrl,
                            'imageIsIllustrative': ?(logoUrl == null
                                ? null
                                : false),
                            if (selectedGalleryImages.isNotEmpty)
                              'gallery': gallery,
                          },
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);
                      } on FirebaseException catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.message ?? 'No se pudo guardar el negocio.',
                            ),
                          ),
                        );
                      } on StateError catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error.message)));
                      } on ArgumentError catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.message.toString())),
                        );
                      } finally {
                        if (mounted) setState(() => isSaving = false);
                      }
                    },
              child: isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
