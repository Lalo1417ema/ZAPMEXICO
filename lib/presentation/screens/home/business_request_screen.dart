import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/business_catalog.dart';
import '../../providers/business_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

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
  final cityController = TextEditingController();
  final addressController = TextEditingController();
  final scheduleController = TextEditingController();
  final descriptionController = TextEditingController();
  final facebookController = TextEditingController();
  final instagramController = TextEditingController();
  final websiteController = TextEditingController();

  String selectedCategory = businessCategories.first;
  final categories = businessCategories;

  @override
  void dispose() {
    nameController.dispose();
    ownerController.dispose();
    emailController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    cityController.dispose();
    addressController.dispose();
    scheduleController.dispose();
    descriptionController.dispose();
    facebookController.dispose();
    instagramController.dispose();
    websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de registro')),
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

            CustomTextField(
              hint: 'MUNICIPIO',
              controller: cityController,
              icon: Icons.location_on,
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
                  value: selectedCategory,
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
              ),
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

            provider.isLoading
                ? const CircularProgressIndicator()
                : CustomButton(
                    text: 'ENVIAR SOLICITUD',
                    onPressed: () async {
                      final requiredFields = [
                        nameController.text,
                        phoneController.text,
                        cityController.text,
                        addressController.text,
                        scheduleController.text,
                        descriptionController.text,
                      ];
                      if (requiredFields.any((value) => value.trim().isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Completa nombre, teléfono, municipio, dirección, horario y descripción.',
                            ),
                          ),
                        );
                        return;
                      }
                      await provider.submitBusinessRequest(
                        name: nameController.text.trim(),
                        owner: ownerController.text.trim(),
                        email: emailController.text.trim(),
                        phone: phoneController.text.trim(),
                        whatsapp: whatsappController.text.trim(),
                        city: cityController.text.trim(),
                        address: addressController.text.trim(),
                        schedule: scheduleController.text.trim(),
                        category: selectedCategory,
                        description: descriptionController.text.trim(),
                        facebook: facebookController.text.trim(),
                        instagram: instagramController.text.trim(),
                        website: websiteController.text.trim(),
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Solicitud enviada correctamente'),
                          ),
                        );

                        Navigator.pop(context);
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
