import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zap_mexico/presentation/providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final userController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomTextField(
              hint: 'USUARIO / CORREO',
              icon: Icons.mail,
              controller: userController,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'ENVIAR',
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);

                await auth.resetPassword(userController.text.trim());

                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Correo enviado')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
