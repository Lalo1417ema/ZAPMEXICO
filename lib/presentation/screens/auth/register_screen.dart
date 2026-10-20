import 'package:flutter/material.dart';
import '../../../config/routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
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
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    userController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmController.dispose();
    phoneController.dispose();
    cityController.dispose();
    super.dispose();
  }

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
                isLoading: isLoading,
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      emailController.text.trim().isEmpty ||
                      passController.text.isEmpty ||
                      cityController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Completa nombre, correo, contraseña y ciudad.',
                        ),
                      ),
                    );
                    return;
                  }
                  if (passController.text != confirmController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Las contraseñas no coinciden.'),
                      ),
                    );
                    return;
                  }
                  setState(() => isLoading = true);
                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );

                  try {
                    await auth.register(
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      password: passController.text,
                      phone: phoneController.text.trim(),
                      city: cityController.text.trim(),
                    );
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.visitorSetup,
                    );
                  } on FirebaseAuthException catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error.message ?? 'No se pudo crear la cuenta.',
                        ),
                      ),
                    );
                  } on FirebaseException catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error.message ?? 'No se pudo guardar el perfil.',
                        ),
                      ),
                    );
                  } finally {
                    if (mounted) setState(() => isLoading = false);
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
