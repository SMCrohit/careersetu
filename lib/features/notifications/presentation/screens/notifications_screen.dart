import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: AppColors.primaryText)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(notificationsProvider.future);
        },
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Container(
                  height: MediaQuery.of(context).size.height - kToolbarHeight,
                  alignment: Alignment.center,
                  child: const Text('No notifications yet', style: TextStyle(color: AppColors.secondaryText)),
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final bool isRead = notification.isRead;

                return InkWell(
                  onTap: () {
                    if (!isRead) {
                      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                    }
                  },
                  child: Container(
                    color: isRead ? AppColors.white : const Color(0xFFE8F3FF),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: isRead ? AppColors.backgroundLight : AppColors.primaryBrand,
                          radius: 24,
                          child: Icon(
                            Icons.notifications, // fallback icon
                            color: isRead ? AppColors.secondaryText : AppColors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    notification.time,
                                    style: TextStyle(fontSize: 12, color: isRead ? AppColors.secondaryText : AppColors.primaryBrand),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isRead ? AppColors.secondaryText : AppColors.primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading notifications')),
        ),
      ),
    );
  }
}
