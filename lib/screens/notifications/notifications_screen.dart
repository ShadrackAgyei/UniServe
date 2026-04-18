import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/notifications_provider.dart';
import '../../services/haptics_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsProvider>().loadNotifications();
    });
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Transport':
        return Icons.directions_bus_outlined;
      case 'Maintenance':
        return Icons.build_outlined;
      case 'Safety':
        return Icons.shield_outlined;
      case 'Events':
        return Icons.event_outlined;
      case 'Academic':
        return Icons.school_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Transport':   return AppTheme.resolved;
      case 'Maintenance': return const Color(0xFF886633);
      case 'Safety':      return AppTheme.danger;
      case 'Events':      return const Color(0xFF775588);
      case 'Academic':    return AppTheme.found;
      default:            return const Color(0xFF666666);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTIFICATIONS', style: TextStyle(letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: cs.secondary,
                strokeWidth: 2,
              ),
            );
          }
          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: cs.secondary),
                  const SizedBox(height: 16),
                  Text('No notifications',
                      style: TextStyle(
                          fontSize: 18, color: cs.secondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              final color = _categoryColor(notification.category);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline),
                ),
                child: InkWell(
                  onTap: () {
                    if (!notification.isRead && notification.id != null) {
                      provider.markAsRead(notification.id!);
                      HapticsService.confirm(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_categoryIcon(notification.category), color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
                                        fontSize: 14,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (!notification.isRead)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: cs.onSurface,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(notification.message,
                                  style: TextStyle(color: cs.secondary, fontSize: 12)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      notification.category.toUpperCase(),
                                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(notification.createdAt),
                                    style: TextStyle(color: cs.secondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
