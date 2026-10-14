import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final newPassController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva contraseña'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomTextField(
              hint: 'NUEVA CONTRASEÑA',
              icon: Icons.lock,
              controller: newPassController,
              obscureText: true,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              hint: 'CONFIRMAR CONTRASEÑA',
              icon: Icons.lock_outline,
              controller: confirmController,
              obscureText: true,
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: 'CAMBIAR',
              onPressed: () {
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}