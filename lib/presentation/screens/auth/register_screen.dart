import 'package:flutter/material.dart';
import '../../../config/routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';

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
  String? selectedGoogleMunicipality;
  bool isLoading = false;
  bool isGoogleRegistration = false;
  bool _routeInitialized = false;

  Future<void> _offerBiometricLogin(AuthProvider auth) async {
    try {
      if (!await auth.canUseBiometrics ||
          await auth.isBiometricLoginEnabled() ||
          !mounted) {
        return;
      }
      final enable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Acceso biométrico'),
          content: const Text(
            '¿Quieres usar la biometría configurada en este dispositivo para '
            'abrir Zap México más rápido? No se guardará tu contraseña.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Activar'),
            ),
          ],
        ),
      );
      if (enable == true && mounted) await auth.enableBiometricLogin();
    } on LocalAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.description ?? 'No se pudo comprobar la biometría.',
          ),
        ),
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'No se pudo activar la huella.'),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeInitialized) return;
    _routeInitialized = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map && arguments['googleAccount'] == true) {
      isGoogleRegistration = true;
      final profile = context.read<AuthProvider>().currentUserModel;
      nameController.text =
          arguments['name']?.toString() ?? profile?['name']?.toString() ?? '';
      emailController.text =
          arguments['email']?.toString() ?? profile?['email']?.toString() ?? '';
      final profileCity = profile?['city']?.toString();
      if (context.read<CatalogProvider>().municipalities.contains(
        profileCity,
      )) {
        selectedGoogleMunicipality = profileCity;
      }
    }
  }

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
        title: Text(isGoogleRegistration ? 'Completa tu cuenta' : 'Registro'),
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

              if (!isGoogleRegistration) ...[
                CustomTextField(
                  hint: 'USUARIO',
                  icon: Icons.account_circle,
                  controller: userController,
                ),
                const SizedBox(height: 16),
              ],

              CustomTextField(
                hint: 'CORREO',
                icon: Icons.email,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                readOnly: isGoogleRegistration,
              ),
              const SizedBox(height: 16),

              if (!isGoogleRegistration) ...[
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
              ],
              CustomTextField(
                hint: 'TELÉFONO',
                icon: Icons.phone,
                controller: phoneController,
              ),

              SizedBox(height: 16),

              if (isGoogleRegistration)
                DropdownButtonFormField<String>(
                  initialValue: selectedGoogleMunicipality,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'MUNICIPIO',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Selecciona tu municipio'),
                  items: context
                      .watch<CatalogProvider>()
                      .municipalities
                      .map(
                        (municipality) => DropdownMenuItem(
                          value: municipality,
                          child: Text(municipality),
                        ),
                      )
                      .toList(),
                  onChanged: (municipality) {
                    setState(() => selectedGoogleMunicipality = municipality);
                  },
                )
              else
                CustomTextField(
                  hint: 'CIUDAD',
                  icon: Icons.location_city,
                  controller: cityController,
                ),

              const SizedBox(height: 30),

              CustomButton(
                text: isGoogleRegistration ? 'CONTINUAR' : 'REGISTRARSE',
                isLoading: isLoading,
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      emailController.text.trim().isEmpty ||
                      (!isGoogleRegistration && passController.text.isEmpty) ||
                      (isGoogleRegistration
                          ? selectedGoogleMunicipality == null
                          : cityController.text.trim().isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isGoogleRegistration
                              ? 'Completa nombre, correo y ciudad.'
                              : 'Completa nombre, correo, contraseña y ciudad.',
                        ),
                      ),
                    );
                    return;
                  }
                  if (!isGoogleRegistration &&
                      passController.text != confirmController.text) {
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
                    if (isGoogleRegistration) {
                      await auth.completeGoogleProfile(
                        name: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        city: selectedGoogleMunicipality!,
                      );
                      await _offerBiometricLogin(auth);
                    } else {
                      await auth.register(
                        name: nameController.text.trim(),
                        username: userController.text.trim(),
                        email: emailController.text.trim(),
                        password: passController.text,
                        phone: phoneController.text.trim(),
                        city: cityController.text.trim(),
                      );
                    }
                    if (!context.mounted) return;
                    if (isGoogleRegistration) {
                      final municipality = selectedGoogleMunicipality!;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.municipalityBusinesses,
                        (_) => false,
                        arguments: {
                          'municipality': municipality,
                          'visitorName': nameController.text.trim(),
                        },
                      );
                    } else {
                      Navigator.pushReplacementNamed(
                        context,
                        auth.isAdmin
                            ? AppRoutes.adminDashboard
                            : AppRoutes.visitorSetup,
                      );
                    }
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
                  } on StateError catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
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
