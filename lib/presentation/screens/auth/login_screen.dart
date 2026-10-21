import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _biometricEnabledForSession = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadSavedEmail();
      await _tryAutomaticBiometricLogin();
    });
  }

  Future<void> _loadSavedEmail() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedEmail = preferences.getString('last_login_email');
      if (!mounted || emailController.text.isNotEmpty || savedEmail == null) {
        return;
      }
      emailController.text = savedEmail;
    } on Exception catch (error) {
      debugPrint('No se pudo cargar el correo recordado: $error');
    }
  }

  Future<void> _rememberEmail(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('last_login_email', normalizedEmail);
    } on Exception catch (error) {
      debugPrint('No se pudo recordar el correo de acceso: $error');
    }
  }

  Future<void> _tryAutomaticBiometricLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (!await auth.isBiometricLoginEnabled()) return;
      if (mounted) {
        setState(() => _biometricEnabledForSession = true);
      }
      await auth.loadCurrentUser();
      if (!mounted || !auth.isLoggedIn) return;
      await _unlockWithBiometrics(auth);
    } on LocalAuthException catch (error) {
      if (!mounted) return;
      _showError(error.description ?? 'No se pudo verificar la huella.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showError(error.message ?? 'No se pudo cargar tu sesión guardada.');
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showError(error.message ?? 'No se pudo verificar la huella.');
    }
  }

  Future<void> _unlockWithBiometrics(AuthProvider auth) async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final authenticated = await auth.authenticateWithBiometrics();
      if (!mounted) return;
      if (authenticated) {
        await _routeAuthenticatedSession(auth, useSavedProfile: true);
      }
    } on LocalAuthException catch (error) {
      if (!mounted) return;
      _showError(error.description ?? 'No se pudo verificar la huella.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showError(error.message ?? 'No se pudo cargar tu sesión guardada.');
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showError(error.message ?? 'No se pudo verificar la huella.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
            'abrir Zap México más rápido la próxima vez? No se guardará tu '
            'contraseña y la sesión de Google/Firebase permanecerá activa.',
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
      if (enable != true || !mounted) return;
      await auth.enableBiometricLogin();
      if (mounted) setState(() => _biometricEnabledForSession = true);
    } on LocalAuthException catch (error) {
      if (mounted) {
        _showError(error.description ?? 'No se pudo comprobar la biometría.');
      }
    } on StateError catch (error) {
      if (mounted) _showError(error.message);
    } on PlatformException catch (error) {
      if (mounted) {
        _showError(error.message ?? 'No se pudo activar la biometría.');
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'El correo o la contraseña no son correctos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Revisa tu conexión a internet.';
      default:
        return error.message ?? 'No se pudo iniciar sesión.';
    }
  }

  Future<void> _finishSignIn() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await _offerBiometricLogin(auth);
    if (!mounted) return;
    await _routeAuthenticatedSession(auth);
  }

  Future<void> _routeAuthenticatedSession(
    AuthProvider auth, {
    bool useSavedProfile = false,
  }) async {
    if (!mounted) return;
    if (auth.needsProfileCompletion) {
      final profile = auth.currentUserModel ?? const <String, dynamic>{};
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.register,
        arguments: {
          'googleAccount': true,
          'name': profile['name']?.toString() ?? '',
          'email': profile['email']?.toString() ?? '',
        },
      );
      return;
    }
    if (auth.isAdmin) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.adminDashboard,
        (_) => false,
      );
      return;
    }
    final profile = auth.currentUserModel;
    final city = profile?['city']?.toString().trim() ?? '';
    final availableMunicipalities = context
        .read<CatalogProvider>()
        .municipalities;
    if (city.isNotEmpty && availableMunicipalities.contains(city)) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.municipalityBusinesses,
        (_) => false,
        arguments: {
          'municipality': city,
          'visitorName': profile?['name']?.toString() ?? '',
        },
      );
      return;
    }
    if (useSavedProfile && city.isNotEmpty) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.visitorSetup,
        arguments: {
          'municipality': city,
          'visitorName': profile?['name'] ?? '',
        },
      );
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.visitorSetup);
  }

  Future<void> _signInWithEmail() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      _showError('Escribe tu correo y contraseña.');
      return;
    }

    setState(() => isLoading = true);
    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(email: emailController.text, password: passwordController.text);
      await _rememberEmail(emailController.text);
      TextInput.finishAutofillContext(shouldSave: true);
      await _finishSignIn();
    } on FirebaseAuthException catch (error) {
      _showError(_authErrorMessage(error));
    } on FirebaseException catch (error) {
      _showError(error.message ?? 'No se pudo cargar tu cuenta.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final signedIn = await auth.loginWithGoogle();
      if (!signedIn && mounted) {
        _showError('No se completó el inicio de sesión con Google.');
        return;
      }
      if (signedIn) {
        final profile = auth.currentUserModel ?? const <String, dynamic>{};
        final email = profile['email']?.toString() ?? '';
        await _rememberEmail(email);
        if (!mounted) return;
        if (auth.needsProfileCompletion) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.register,
            arguments: {
              'googleAccount': true,
              'name': profile['name']?.toString() ?? '',
              'email': email,
            },
          );
        } else {
          await _offerBiometricLogin(auth);
          if (mounted) await _routeAuthenticatedSession(auth);
        }
      }
    } on FirebaseAuthException catch (error) {
      _showError(_authErrorMessage(error));
    } on FirebaseException catch (error) {
      _showError(error.message ?? 'No se pudo iniciar sesión con Google.');
    } on PlatformException catch (error) {
      _showError(
        error.message ?? 'No se pudo completar la selección de cuenta Google.',
      );
    } on Exception catch (error) {
      debugPrint('Error inesperado al iniciar sesión con Google: $error');
      _showError('No se pudo completar el inicio de sesión con Google.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget buildLogo() {
    return Image.asset(
      'assets/images/icon.png',
      width: 180,
      height: 180,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: AutofillGroup(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  buildLogo(),
                  const SizedBox(height: 30),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.email,
                      AutofillHints.username,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    onSubmitted: (_) => _signInWithEmail(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.forgotPassword,
                      ),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    CustomButton(text: 'INGRESAR', onPressed: _signInWithEmail),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.g_mobiledata, size: 32),
                    label: const Text('Continuar con Google'),
                    onPressed: isLoading ? null : _signInWithGoogle,
                  ),
                  if (_biometricEnabledForSession) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: const Icon(Icons.fingerprint, size: 28),
                      label: const Text('Entrar con huella'),
                      onPressed: isLoading
                          ? null
                          : () => _unlockWithBiometrics(
                              Provider.of<AuthProvider>(context, listen: false),
                            ),
                    ),
                  ],
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('Crear una cuenta'),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.pushNamed(
                            context,
                            AppRoutes.visitorSetup,
                          ),
                    child: const Text('Continuar como visitante'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
