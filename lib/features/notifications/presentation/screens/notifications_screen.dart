import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../domain/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final unread = async.value?.where((n) => !n.isRead).length ?? 0;

    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryText,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notifications', style: AppText.screenTitle),
              if (async.hasValue) Text(unread > 0 ? '$unread unread' : 'All caught up', style: AppText.label),
            ],
          ),
          actions: [
            if (unread > 0)
              TextButton(
                onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
                child: const Text('Mark all read', style: AppText.link),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          color: AppUi.accent,
          onRefresh: () => ref.refresh(notificationsProvider.future),
          child: async.when(
            skipLoadingOnRefresh: true,
            loading: () => ListView(padding: const EdgeInsets.all(16), children: List.generate(5, (_) => const _SkeletonTile())),
            error: (e, _) => _message(
              Icons.cloud_off_rounded,
              "Couldn't load notifications",
              e is ApiException ? e.message : 'Please check your connection.',
              action: ('Try again', () => ref.invalidate(notificationsProvider)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return _message(Icons.notifications_none_rounded, "You're all caught up",
                    'Updates about your bookings, applications and tests will appear here.');
              }
              final today = list.where((n) => n.isToday).toList();
              final earlier = list.where((n) => !n.isToday).toList();
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + MediaQuery.of(context).padding.bottom),
                children: [
                  if (today.isNotEmpty) ...[_header('Today'), ...today.map((n) => _NotificationCard(notification: n))],
                  if (earlier.isNotEmpty) ...[_header('Earlier'), ...earlier.map((n) => _NotificationCard(notification: n))],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
        child: Text(text, style: AppText.sectionTitle),
      );

  Widget _message(IconData icon, String title, String subtitle, {(String, VoidCallback)? action}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 90, 32, 24),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(gradient: AppUi.accentGradient, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: AppText.screenTitle),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: AppText.subtitle.copyWith(height: 1.4)),
        if (action != null) ...[
          const SizedBox(height: 20),
          Center(child: SecondaryButton(text: action.$1, width: 200, onPressed: action.$2)),
        ],
      ],
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notification;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: n.isRead ? Colors.white : AppUi.softBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppUi.cardShadow,
        border: n.isRead ? null : Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: n.isRead ? null : () => ref.read(notificationsProvider.notifier).markAsRead(n.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: n.isRead ? null : AppUi.accentGradient,
                    color: n.isRead ? AppUi.iconTile : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(n.icon, size: 22, color: n.isRead ? AppUi.accent : Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(n.title,
                                style: AppText.cardTitle.copyWith(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Text(n.time, style: AppText.label.copyWith(color: n.isRead ? AppColors.secondaryText : AppColors.primaryBrand)),
                          if (!n.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppUi.accent, shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                      if (n.message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(n.message, style: AppText.subtitle.copyWith(height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) =>
        Container(width: w, height: h, decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(6)));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppUi.card(),
      child: Row(children: [
        bar(42, 42),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bar(160, 14), const SizedBox(height: 8), bar(double.infinity, 12)])),
      ]),
    );
  }
}
