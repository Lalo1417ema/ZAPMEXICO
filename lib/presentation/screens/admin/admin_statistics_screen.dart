import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../providers/admin_provider.dart';
import '../../providers/business_provider.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  @override
  void initState() {
    super.initState();

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final businesses = Provider.of<BusinessProvider>(context, listen: false);
    Future.microtask(() async {
      try {
        await businesses.fetchAllBusinessesForAdmin();
        await provider.loadStatistics(businesses);
      } on FirebaseException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'No se pudieron cargar las estadísticas.',
            ),
          ),
        );
      }
    });
  }

  Widget buildCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),

            const SizedBox(height: 10),

            Text(title, textAlign: TextAlign.center),

            const SizedBox(height: 10),

            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Estadísticas del Sistema',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        Card(
          child: ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Usuarios registrados'),
            trailing: Text(
              provider.totalUsers.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Negocios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Aprobados'),
                  trailing: Text(provider.approvedBusinesses.toString()),
                ),

                ListTile(
                  leading: const Icon(Icons.pending, color: Colors.orange),
                  title: const Text('Pendientes'),
                  trailing: Text(provider.pendingBusinesses.toString()),
                ),

                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: const Text('Rechazados'),
                  trailing: Text(provider.rejectedBusinesses.toString()),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Reseñas'),
            trailing: Text(
              provider.totalReviews.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text('Favoritos'),
            trailing: Text(
              provider.totalFavorites.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
