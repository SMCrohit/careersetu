import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/notification_model.dart';
import '../../../jobs/data/jobs_repository.dart'; // To get apiClientProvider

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final response = await apiClient.get('/users/me/notifications');
      return (response.data as List).map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.put('/users/me/notifications/$id/read');
      // Update local state
      if (state.value != null) {
        state = AsyncData(state.value!.map((n) {
          if (n.id == id) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              message: n.message,
              isRead: true,
              time: n.time,
            );
          }
          return n;
        }).toList());
      }
    } catch (e) {
      // Handle error implicitly
    }
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});
