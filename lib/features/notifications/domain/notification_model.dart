class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String time;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.time,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final dt = DateTime.parse(json['created_datetime']).toLocal();
    final diff = DateTime.now().difference(dt);
    String timeStr = '';
    if (diff.inDays > 0) {
      timeStr = '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      timeStr = '${diff.inHours}h';
    } else {
      timeStr = '${diff.inMinutes}m';
    }

    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      time: timeStr,
    );
  }
}
