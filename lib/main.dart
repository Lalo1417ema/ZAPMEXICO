import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zap_mexico/presentation/screens/home/favorites_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'config/routes/app_routes.dart';

import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/business_provider.dart';
import 'presentation/providers/admin_provider.dart';
import 'presentation/providers/municipal_event_provider.dart';
import 'presentation/providers/catalog_provider.dart';
import 'presentation/providers/marketplace_provider.dart';

import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/visitor_setup_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/auth/account_blocked_screen.dart';
import 'presentation/screens/auth/profile_screen.dart';

import 'presentation/screens/home/business_detail_screen.dart';
import 'presentation/screens/home/business_request_screen.dart';
import 'presentation/screens/home/municipality_businesses_screen.dart';
import 'presentation/screens/home/marketplace_screen.dart';
import 'presentation/screens/admin/admin_dashboard_screen.dart';
import 'presentation/screens/admin/monetization_mock_screen.dart';

import 'presentation/screens/admin/admin_guard.dart';
import 'presentation/screens/home/edit_business_screen.dart';
import 'presentation/screens/admin/admin_statistics_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa Firebase antes de correr la app
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ZapMexicoApp());
}

class ZapMexicoApp extends StatelessWidget {
  const ZapMexicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => MunicipalEventProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
        builder: (context, child) => Consumer<AuthProvider>(
          builder: (context, auth, _) => auth.isBlocked
              ? const AccountBlockedScreen()
              : child ?? const SizedBox.shrink(),
        ),
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.visitorSetup: (_) => const VisitorSetupScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.marketplace: (_) => const MarketplaceScreen(),
          AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
          AppRoutes.resetPassword: (_) => const ResetPasswordScreen(),
          AppRoutes.municipalityBusinesses: (_) =>
              const MunicipalityBusinessesScreen(),
          AppRoutes.businessDetail: (_) => const BusinessDetailScreen(),
          AppRoutes.businessRequest: (_) => const BusinessRequestScreen(),
          AppRoutes.adminDashboard: (_) =>
              const AdminGuard(child: AdminDashboardScreen()),
          AppRoutes.monetization: (_) =>
              const AdminGuard(child: MonetizationMockScreen()),
          AppRoutes.editBusiness: (_) =>
              const AdminGuard(child: EditBusinessScreen()),
          AppRoutes.favorites: (_) => const FavoritesScreen(),
          AppRoutes.adminStatistics: (_) =>
              const AdminGuard(child: AdminStatisticsScreen()),
        },
      ),
    );
  }
}
