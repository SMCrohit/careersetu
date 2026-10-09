/// One bookable slot. [status] is 'available', 'full', 'past' or 'booked' (already yours).
class AvailableSlot {
  final String time;
  final String status;

  const AvailableSlot({required this.time, required this.status});

  bool get isAvailable => status == 'available';
  bool get isMine => status == 'booked';

  factory AvailableSlot.fromJson(Map<String, dynamic> j) =>
      AvailableSlot(time: j['time']?.toString() ?? '', status: j['status']?.toString() ?? 'available');
}

/// A date on which the professional has open slots.
class AvailableDate {
  final DateTime date;
  final String weekday;
  final List<AvailableSlot> slots;

  const AvailableDate({required this.date, required this.weekday, required this.slots});

  int get openCount => slots.where((s) => s.isAvailable).length;
  int get mineCount => slots.where((s) => s.isMine).length;

  /// Sent to the API as "YYYY-MM-DD".
  String get isoDate =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static AvailableDate? fromJson(Map<String, dynamic> j) {
    final date = DateTime.tryParse(j['date']?.toString() ?? '');
    if (date == null) return null;
    return AvailableDate(
      date: date,
      weekday: j['weekday']?.toString() ?? '',
      slots: (j['slots'] as List? ?? []).whereType<Map>().map((s) => AvailableSlot.fromJson(Map<String, dynamic>.from(s))).toList(),
    );
  }
}
