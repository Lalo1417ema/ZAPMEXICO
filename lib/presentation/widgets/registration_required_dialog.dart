import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes/app_routes.dart';
import '../providers/auth_provider.dart';

Future<void> showRegistrationRequiredDialog(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final shouldRegister = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Crea una cuenta'),
      content: const Text(
        'Para registrar negocios, guardar favoritos o calificar necesitas '
        'iniciar sesión o crear una cuenta.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Registrarme'),
        ),
      ],
    ),
  );
  if (shouldRegister != true || !context.mounted) return;
  if (auth.isVisitor) {
    try {
      await auth.logout();
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'No se pudo continuar.')),
      );
      return;
    }
  }
  if (!context.mounted) return;
  Navigator.pushNamed(context, AppRoutes.register);
}
