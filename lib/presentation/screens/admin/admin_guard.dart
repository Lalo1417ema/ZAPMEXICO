import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../auth/visitor_setup_screen.dart';
import '../home/municipality_businesses_screen.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAdmin) {
      if (!auth.isLoggedIn) return const LoginScreen();
      final user = auth.currentUserModel;
      final municipality = user?['city']?.toString();
      if (municipality == null || municipality.trim().isEmpty) {
        return const VisitorSetupScreen();
      }
      return MunicipalityBusinessesScreen(
        municipality: municipality,
        visitorName: user?['name']?.toString() ?? '',
      );
    }

    return child;
  }
}
