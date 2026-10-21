import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/business_catalog.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/registration_required_dialog.dart';

class BusinessRequestScreen extends StatefulWidget {
  const BusinessRequestScreen({super.key});

  @override
  State<BusinessRequestScreen> createState() => _BusinessRequestScreenState();
}

class _BusinessRequestScreenState extends State<BusinessRequestScreen> {
  final nameController = TextEditingController();
  final ownerController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();
  final addressController = TextEditingController();
  final scheduleController = TextEditingController();
  final descriptionController = TextEditingController();
  final facebookController = TextEditingController();
  final instagramController = TextEditingController();
  final websiteController = TextEditingController();
  final requestedCategoryController = TextEditingController();
  final requestedMunicipalityController = TextEditingController();

  String selectedCategory = businessCategories.first;
  String selectedMunicipality = regionMunicipalities.first;
  bool requestNewCategory = false;
  bool requestNewMunicipality = false;
  final ImagePicker imagePicker = ImagePicker();
  File? selectedLogoImage;
  final List<File> selectedGalleryImages = [];
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadCatalogs);
  }

  Future<void> _loadCatalogs() async {
    try {
      final catalogs = context.read<CatalogProvider>();
      await catalogs.loadCatalogs();
      if (!mounted) return;
      setState(() {
        if (!catalogs.municipalities.contains(selectedMunicipality)) {
          selectedMunicipality = catalogs.municipalities.first;
        }
        if (!catalogs.categories.contains(selectedCategory)) {
          selectedCategory = catalogs.categories.first;
        }
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'No se pudieron cargar municipios y categorías.',
          ),
        ),
      );
    }
  }

  Future<void> _pickLogo() async {
    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;
    setState(() => selectedLogoImage = File(image.path));
  }

  Future<void> _pickGalleryImages() async {
    final remaining = 20 - selectedGalleryImages.length;
    if (remaining <= 0) return;
    final images = await imagePicker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (!mounted || images.isEmpty) return;
    setState(() {
      selectedGalleryImages.addAll(
        images.take(remaining).map((image) => File(image.path)),
      );
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    ownerController.dispose();
    emailController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    addressController.dispose();
    scheduleController.dispose();
    descriptionController.dispose();
    facebookController.dispose();
    instagramController.dispose();
    websiteController.dispose();
    requestedCategoryController.dispose();
    requestedMunicipalityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BusinessProvider>(context);
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    if (auth.isVisitor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registrar negocio')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Necesitas una cuenta para registrar un negocio.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => showRegistrationRequiredDialog(context),
                  child: const Text('Registrarme'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final catalogs = context.watch<CatalogProvider>();
    final categories = catalogs.categories;
    final municipalities = catalogs.municipalities;
    final municipality = requestNewMunicipality
        ? requestedMunicipalityController.text.trim()
        : selectedMunicipality;
    final category = requestNewCategory
        ? requestedCategoryController.text.trim()
        : selectedCategory;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Agregar negocio' : 'Solicitud de registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CustomTextField(
              hint: 'NOMBRE DEL NEGOCIO',
              controller: nameController,
              icon: Icons.store,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              hint: 'NOMBRE DEL ENCARGADO',
              controller: ownerController,
              icon: Icons.person,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              hint: 'CORREO',
              controller: emailController,
              icon: Icons.email,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              hint: 'TELÉFONO',
              controller: phoneController,
              icon: Icons.phone,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              hint: 'WHATSAPP',
              controller: whatsappController,
              icon: Icons.message,
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: municipalities.contains(selectedMunicipality)
                  ? selectedMunicipality
                  : null,
              decoration: const InputDecoration(
                labelText: 'Municipio de Michoacán',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              items: municipalities
                  .map(
                    (city) => DropdownMenuItem(value: city, child: Text(city)),
                  )
                  .toList(),
              onChanged: requestNewMunicipality
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => selectedMunicipality = value);
                      }
                    },
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: requestNewMunicipality,
              title: const Text('No encuentro el municipio'),
              subtitle: const Text(
                'Solicita agregar un municipio oficial de Michoacán.',
              ),
              onChanged: (value) =>
                  setState(() => requestNewMunicipality = value ?? false),
            ),
            if (requestNewMunicipality)
              CustomTextField(
                hint: 'MUNICIPIO DESEADO',
                controller: requestedMunicipalityController,
                icon: Icons.edit_location_alt,
              ),

            const SizedBox(height: 14),

            CustomTextField(
              hint: 'DIRECCIÓN',
              controller: addressController,
              icon: Icons.location_on,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              hint: 'HORARIO',
              controller: scheduleController,
              icon: Icons.access_time,
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: requestNewCategory
                      ? null
                      : (categories.contains(selectedCategory)
                            ? selectedCategory
                            : null),
                  hint: const Text('Selecciona una categoría disponible'),
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: requestNewCategory
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => selectedCategory = value);
                          }
                        },
                ),
              ),
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: requestNewCategory,
              title: const Text('No encuentro la categoría'),
              subtitle: const Text(
                'El administrador revisará tu propuesta antes de agregarla.',
              ),
              onChanged: (value) =>
                  setState(() => requestNewCategory = value ?? false),
            ),
            if (requestNewCategory)
              CustomTextField(
                hint: 'CATEGORÍA DESEADA',
                controller: requestedCategoryController,
                icon: Icons.category,
              ),

            const SizedBox(height: 14),

            CustomTextField(
              hint: 'DESCRIPCIÓN',
              controller: descriptionController,
              icon: Icons.description,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              hint: 'FACEBOOK (OPCIONAL)',
              controller: facebookController,
              icon: Icons.facebook,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              hint: 'INSTAGRAM (OPCIONAL)',
              controller: instagramController,
              icon: Icons.camera_alt,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              hint: 'SITIO WEB (OPCIONAL)',
              controller: websiteController,
              icon: Icons.language,
            ),

            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Logo del negocio (opcional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickLogo,
              icon: const Icon(Icons.store),
              label: Text(
                selectedLogoImage == null ? 'Seleccionar logo' : 'Cambiar logo',
              ),
            ),
            if (selectedLogoImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    selectedLogoImage!,
                    height: 110,
                    width: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Fotos para el carrusel (mínimo 3)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickGalleryImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Seleccionar fotos'),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${selectedGalleryImages.length}/20 fotos seleccionadas',
                style: const TextStyle(color: AppColors.greyText),
              ),
            ),
            const SizedBox(height: 24),

            provider.isLoading || isSubmitting
                ? const CircularProgressIndicator()
                : CustomButton(
                    text: isAdmin ? 'SUBIR NEGOCIO' : 'ENVIAR SOLICITUD',
                    onPressed: () async {
                      final requiredFields = [
                        nameController.text,
                        phoneController.text,
                        municipality,
                        addressController.text,
                        scheduleController.text,
                        descriptionController.text,
                      ];
                      if (requiredFields.any((value) => value.trim().isEmpty) ||
                          category.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Completa los datos requeridos y elige o solicita municipio y categoría.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (selectedGalleryImages.length < 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Selecciona al menos 3 fotos para la galería.',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => isSubmitting = true);
                      try {
                        final suggestions = <Map<String, String>>[
                          if (requestNewMunicipality)
                            {'type': 'municipality', 'value': municipality},
                          if (requestNewCategory)
                            {'type': 'category', 'value': category},
                        ];
                        await provider.submitBusinessRequest(
                          name: nameController.text.trim(),
                          owner: ownerController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                          whatsapp: whatsappController.text.trim(),
                          city: municipality,
                          address: addressController.text.trim(),
                          schedule: scheduleController.text.trim(),
                          category: category,
                          description: descriptionController.text.trim(),
                          facebook: facebookController.text.trim(),
                          instagram: instagramController.text.trim(),
                          website: websiteController.text.trim(),
                          logoImage: selectedLogoImage,
                          galleryImages: selectedGalleryImages,
                          catalogProvider: catalogs,
                          catalogSuggestions: suggestions,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAdmin
                                  ? 'Ficha creada. Quedó pendiente de aprobación.'
                                  : 'Solicitud enviada correctamente',
                            ),
                          ),
                        );
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
                        if (mounted) setState(() => isSubmitting = false);
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
