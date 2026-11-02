import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../config/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_drawer.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _timestamp(dynamic value) {
    if (value is! Timestamp) return '';
    final date = value.toDate().toLocal();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} · $hour:$minute';
  }

  IconData _iconFor(String type) => switch (type) {
    'business_approved' => Icons.check_circle_outline,
    'business_rejected' => Icons.cancel_outlined,
    'admin_new_request' => Icons.assignment_add,
    'marketplace_expired' => Icons.hourglass_disabled,
    _ => Icons.notifications_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () async {
                try {
                  await provider.markAllAsRead();
                } on FirebaseException catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.message ?? 'No se pudieron marcar como leídas.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Marcar todas leídas'),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  provider.errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : provider.notifications.isEmpty
          ? const Center(
              child: Text(
                'Todavía no tienes notificaciones.',
                style: TextStyle(color: AppColors.greyText),
              ),
            )
          : ListView.separated(
              itemCount: provider.notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = provider.notifications[index];
                final isUnread = item['readAt'] == null;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isUnread
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : AppColors.surface,
                    child: Icon(
                      _iconFor(item['type']?.toString() ?? ''),
                      color: isUnread ? AppColors.primary : AppColors.greyText,
                    ),
                  ),
                  title: Text(
                    item['title']?.toString() ?? 'Notificación',
                    style: TextStyle(
                      fontWeight: isUnread
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['body']?.toString() ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        _timestamp(item['createdAt']),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    try {
                      if (isUnread) {
                        await provider.markAsRead(item['id'].toString());
                      }
                      if (!context.mounted) return;
                      if (item['type'] == 'admin_new_request' &&
                          context.read<AuthProvider>().isAdmin) {
                        Navigator.pushNamed(context, AppRoutes.adminDashboard);
                      } else if (item['type'] == 'business_approved' ||
                          item['type'] == 'business_rejected') {
                        final referenceId = item['referenceId']?.toString();
                        if (referenceId == null || referenceId.isEmpty) return;
                        final listing = await FirebaseFirestore.instance
                            .collection('businesses')
                            .doc(referenceId)
                            .get();
                        if (!context.mounted || !listing.exists) return;
                        Navigator.pushNamed(
                          context,
                          AppRoutes.businessDetail,
                          arguments: {...listing.data()!, 'id': listing.id},
                        );
                      }
                    } on FirebaseException catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error.message ??
                                'No se pudo abrir la notificación.',
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
