import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  NotificationModel copyWith({bool? isRead}) =>
      NotificationModel(id: id, title: title, message: message, isRead: isRead ?? this.isRead, createdAt: createdAt);

  bool get isToday {
    if (createdAt == null) return false;
    final now = DateTime.now();
    return createdAt!.year == now.year && createdAt!.month == now.month && createdAt!.day == now.day;
  }

  /// "now", "5m", "3h", "2d" or a date for older ones.
  String get time {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${createdAt!.day} ${months[createdAt!.month - 1]}';
  }

  /// Icon picked from what the notification is about.
  IconData get icon {
    final t = '$title $message'.toLowerCase();
    if (t.contains('appointment') || t.contains('booking') || t.contains('consult')) return Icons.event_available_rounded;
    if (t.contains('job') || t.contains('application') || t.contains('interview')) return Icons.work_outline_rounded;
    if (t.contains('test') || t.contains('result') || t.contains('score')) return Icons.quiz_outlined;
    if (t.contains('offer') || t.contains('discount') || t.contains('coupon')) return Icons.local_offer_outlined;
    if (t.contains('resume') || t.contains('profile')) return Icons.description_outlined;
    return Icons.notifications_none_rounded;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_datetime']?.toString() ?? '')?.toLocal(),
    );
  }
}
