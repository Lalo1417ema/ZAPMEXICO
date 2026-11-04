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
    final municipalities = context.watch<CatalogProvider>().municipalities;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isGoogleRegistration ? 'Completa tu cuenta' : 'Crear cuenta',
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Icon(
                    isGoogleRegistration
                        ? Icons.account_circle_outlined
                        : Icons.person_add_alt_1,
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isGoogleRegistration ? 'Un paso más' : 'Únete a Zap México',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isGoogleRegistration
                        ? 'Completa tus datos para encontrar negocios cerca de ti.'
                        : 'Crea tu cuenta para descubrir y guardar negocios locales.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionLabel(context, 'Tus datos'),
                  const SizedBox(height: 12),
                  CustomTextField(
                    hint: 'Nombre completo',
                    icon: Icons.person_outline,
                    controller: nameController,
                    keyboardType: TextInputType.name,
                  ),
                  if (!isGoogleRegistration) ...[
                    const SizedBox(height: 14),
                    CustomTextField(
                      hint: 'Nombre de usuario',
                      icon: Icons.alternate_email,
                      controller: userController,
                    ),
                  ],
                  const SizedBox(height: 14),
                  CustomTextField(
                    hint: 'Correo electrónico',
                    icon: Icons.email_outlined,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: isGoogleRegistration,
                  ),
                  if (!isGoogleRegistration) ...[
                    const SizedBox(height: 14),
                    CustomTextField(
                      hint: 'Contraseña',
                      icon: Icons.lock_outline,
                      controller: passController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      hint: 'Confirmar contraseña',
                      icon: Icons.lock_reset,
                      controller: confirmController,
                      obscureText: true,
                    ),
                  ],
                  const SizedBox(height: 14),
                  CustomTextField(
                    hint: 'Teléfono (opcional)',
                    icon: Icons.phone_outlined,
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel(context, 'Tu ubicación'),
                  const SizedBox(height: 12),
                  if (isGoogleRegistration)
                    DropdownButtonFormField<String>(
                      initialValue: selectedGoogleMunicipality,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Municipio',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Selecciona tu municipio'),
                      items: municipalities
                          .map(
                            (municipality) => DropdownMenuItem(
                              value: municipality,
                              child: Text(
                                municipality,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (municipality) {
                        setState(
                          () => selectedGoogleMunicipality = municipality,
                        );
                      },
                    )
                  else
                    CustomTextField(
                      hint: 'Ciudad o municipio',
                      icon: Icons.location_city_outlined,
                      controller: cityController,
                    ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: isGoogleRegistration ? 'CONTINUAR' : 'CREAR CUENTA',
                    isLoading: isLoading,
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty ||
                          emailController.text.trim().isEmpty ||
                          (!isGoogleRegistration &&
                              passController.text.isEmpty) ||
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
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
