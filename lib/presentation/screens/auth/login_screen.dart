import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
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
    Navigator.pushReplacementNamed(
      context,
      auth.isAdmin ? AppRoutes.adminDashboard : AppRoutes.visitorSetup,
    );
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
      final signedIn = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).loginWithGoogle();
      if (signedIn) await _finishSignIn();
    } on FirebaseAuthException catch (error) {
      _showError(_authErrorMessage(error));
    } on FirebaseException catch (error) {
      _showError(error.message ?? 'No se pudo iniciar sesión con Google.');
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
            child: Column(
              children: [
                const SizedBox(height: 30),
                buildLogo(),
                const SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  onSubmitted: (_) => _signInWithEmail(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.forgotPassword),
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
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pushNamed(context, AppRoutes.register),
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
    );
  }
}
