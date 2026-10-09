import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/notification_model.dart';

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    final response = await ref.read(apiClientProvider).get('/users/me/notifications');
    return (response.data as List? ?? [])
        .whereType<Map>()
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  void _setRead(Set<String> ids) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([for (final n in list) ids.contains(n.id) ? n.copyWith(isRead: true) : n]);
  }

  Future<void> markAsRead(String id) async {
    _setRead({id});
    try {
      await ref.read(apiClientProvider).put('/users/me/notifications/$id/read');
    } catch (_) {
      // Reading a notification is low-stakes; it syncs on the next refresh.
    }
  }

  Future<void> markAllRead() async {
    final unread = (state.value ?? []).where((n) => !n.isRead).map((n) => n.id).toSet();
    if (unread.isEmpty) return;
    _setRead(unread);
    await Future.wait(unread.map((id) async {
      try {
        await ref.read(apiClientProvider).put('/users/me/notifications/$id/read');
      } catch (_) {}
    }));
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(NotificationsNotifier.new);
