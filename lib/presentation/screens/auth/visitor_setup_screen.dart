import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/business_catalog.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class VisitorSetupScreen extends StatefulWidget {
  const VisitorSetupScreen({super.key});

  @override
  State<VisitorSetupScreen> createState() => _VisitorSetupScreenState();
}

class _VisitorSetupScreenState extends State<VisitorSetupScreen> {
  final nameController = TextEditingController();
  String? selectedMunicipality;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void continueToMunicipality() {
    final name = nameController.text.trim();
    final municipality = selectedMunicipality;
    if (name.isEmpty || municipality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe tu nombre y elige un municipio.'),
        ),
      );
      return;
    }

    Provider.of<AuthProvider>(
      context,
      listen: false,
    ).setVisitorProfile(name: name, municipality: municipality);
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.municipalityBusinesses,
      arguments: {'municipality': municipality, 'visitorName': name},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenido a Zap México')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Antes de comenzar',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escribe tu nombre y elige el municipio donde quieres buscar negocios.',
                style: TextStyle(color: AppColors.greyText),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                hint: 'TU NOMBRE',
                icon: Icons.person,
                controller: nameController,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedMunicipality,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Municipio',
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text('Selecciona un municipio'),
                items: regionMunicipalities
                    .map(
                      (municipality) => DropdownMenuItem(
                        value: municipality,
                        child: Text(municipality),
                      ),
                    )
                    .toList(),
                onChanged: (municipality) {
                  setState(() => selectedMunicipality = municipality);
                },
              ),
              const Spacer(),
              CustomButton(
                text: 'CONTINUAR',
                onPressed: continueToMunicipality,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
