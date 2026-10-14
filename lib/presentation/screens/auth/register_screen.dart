import 'package:flutter/material.dart';
import '../../../config/routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final userController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CustomTextField(
                hint: 'NOMBRE',
                icon: Icons.person,
                controller: nameController,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                hint: 'USUARIO',
                icon: Icons.account_circle,
                controller: userController,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                hint: 'CORREO',
                icon: Icons.email,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                hint: 'CONTRASEÑA',
                icon: Icons.lock,
                controller: passController,
                obscureText: true,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                hint: 'CONFIRMAR CONTRASEÑA',
                icon: Icons.lock_outline,
                controller: confirmController,
                obscureText: true,
              ),
              CustomTextField(
                hint: 'TELÉFONO',
                icon: Icons.phone,
                controller: phoneController,
              ),

              SizedBox(height: 16),

              CustomTextField(
                hint: 'CIUDAD',
                icon: Icons.location_city,
                controller: cityController,
              ),

              const SizedBox(height: 30),

              CustomButton(
                text: 'REGISTRARSE',
                onPressed: () async {
                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );

                  final success = await auth.register(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passController.text.trim(),
                    phone: phoneController.text.trim(),
                    city: cityController.text.trim(),
                  );

                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.visitorSetup,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
