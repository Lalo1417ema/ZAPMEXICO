import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class MonetizationMockScreen extends StatelessWidget {
  const MonetizationMockScreen({super.key});

  Widget statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monetización futura'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            statCard('Negocios registrados', '128', Icons.store),
            statCard('Usuarios activos', '542', Icons.people),
            statCard('Visitas mensuales', '3,200', Icons.visibility),
            statCard('Ingresos estimados', '\$12,450', Icons.attach_money),
          ],
        ),
      ),
    );
  }
}