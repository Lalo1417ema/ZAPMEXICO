import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  late String businessId;

  // 📁 Variables de estado movidas al lugar correcto
  File? selectedGalleryImage;
  final ImagePicker picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final business =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    businessId = business['id'];
    nameController = TextEditingController(text: business['name'] ?? '');
    descriptionController = TextEditingController(
      text: business['description'] ?? '',
    );
    phoneController = TextEditingController(text: business['phone'] ?? '');
    cityController = TextEditingController(text: business['city'] ?? '');
    scheduleController = TextEditingController(
      text: business['schedule'] ?? '',
    );
  }

  // 🧹 Liberación de memoria indispensable
  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    cityController.dispose();
    scheduleController.dispose();
    super.dispose();
  }

  // 📸 Método corregido con el setState del estado
  Future<void> pickGalleryImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      selectedGalleryImage = File(image.path);
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
            const SizedBox(height: 24),

            // 🖼️ BOTÓN SELECCIONAR IMAGEN (Sacado del onPressed e integrado a la UI)
            ElevatedButton.icon(
              onPressed: pickGalleryImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Agregar foto a galería'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
              ),
            ),

            // Vista previa de la imagen seleccionada
            if (selectedGalleryImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    selectedGalleryImage!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // 💾 BOTÓN GUARDAR (Puramente lógico)
            ElevatedButton(
              onPressed: () async {
                // 1. Actualizar los textos del negocio
                await provider.updateBusiness(
                  businessId: businessId,
                  data: {
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'city': cityController.text.trim(),
                    'schedule': scheduleController.text.trim(),
                  },
                );

                // 2. Si hay imagen en cola, subirla a la galería
                if (selectedGalleryImage != null) {
                  await provider.addGalleryImage(
                    businessId: businessId,
                    imageFile: selectedGalleryImage!,
                  );
                }

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
