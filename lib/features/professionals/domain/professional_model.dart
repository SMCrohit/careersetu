String _str(dynamic v) => v == null ? '' : v.toString().trim();
double _double(dynamic v, [double fallback = 0]) => v is num ? v.toDouble() : double.tryParse(_str(v)) ?? fallback;
int _int(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : int.tryParse(_str(v)) ?? fallback;
List<String> _strings(dynamic v) => v is List ? v.map(_str).where((e) => e.isNotEmpty).toList() : const [];

/// The professional's next open slot, shown on cards.
class NextSlot {
  final DateTime date;
  final String weekday;
  final String time;

  const NextSlot({required this.date, required this.weekday, required this.time});

  static NextSlot? fromJson(dynamic j) {
    if (j is! Map) return null;
    final date = DateTime.tryParse(_str(j['date']));
    if (date == null) return null;
    return NextSlot(date: date, weekday: _str(j['weekday']), time: _str(j['time']));
  }

  /// "Today, 10:00 AM", "Tomorrow, 2:00 PM" or "Mon 12, 2:00 PM".
  String get label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(date.year, date.month, date.day).difference(today).inDays;
    final day = diff == 0 ? 'Today' : (diff == 1 ? 'Tomorrow' : '$weekday ${date.day}');
    return '$day, ${time.replaceFirst(RegExp(r'^0'), '')}';
  }
}

class Professional {
  final String id;
  final String name;
  final String profession;
  final String specialty;
  final String? qualification;
  final String clinic;
  final String locationCity;
  final int experienceYears;
  final String experienceString;
  final double rating;
  final double defaultRating;
  final int reviews;
  final int consultationFee;
  final String? imageUrl;
  final String? description;

  /// Sorted by time, e.g. ["10:00 AM", "02:00 PM"].
  final List<String> timeSlots;

  /// Weekdays in order, e.g. ["Mon", "Wed"].
  final List<String> availableDays;
  final bool isFeatured;
  final List<String> consultationMode;
  final List<String> languagesSpoken;
  final NextSlot? nextAvailable;

  Professional({
    required this.id,
    required this.name,
    required this.profession,
    required this.specialty,
    this.qualification,
    required this.clinic,
    this.locationCity = '',
    required this.experienceYears,
    required this.experienceString,
    required this.rating,
    required this.defaultRating,
    required this.reviews,
    required this.consultationFee,
    this.imageUrl,
    this.description,
    this.timeSlots = const [],
    this.availableDays = const [],
    this.isFeatured = false,
    this.consultationMode = const [],
    this.languagesSpoken = const [],
    this.nextAvailable,
  });

  bool get isDoctor => profession.toLowerCase() == 'doctor';

  /// Two-letter initials, ignoring titles like "Dr.".
  String get initials {
    final parts = name.replaceAll(RegExp(r'^(dr|ca|adv|prof)\.?\s+', caseSensitive: false), '').split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  /// A real photo, or null for missing/placeholder images (the UI shows initials instead).
  String? get photoUrl {
    final url = imageUrl ?? '';
    if (url.isEmpty || url.contains('placeholder') || url.contains('ui-avatars.com')) return null;
    return url;
  }

  String get feeLabel => consultationFee > 0 ? '₹$consultationFee' : 'Free';
  String get experienceLabel => experienceYears > 0 ? '$experienceYears+ yrs' : (experienceString.isNotEmpty ? experienceString : 'New');
  String get ratingLabel => rating > 0 ? rating.toStringAsFixed(1) : 'New';
  String get subtitle => [profession, specialty].where((e) => e.isNotEmpty).join(' · ');

  /// "Mon, Wed, Fri" or "Mon–Fri" when consecutive.
  String get daysLabel {
    const order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final idx = availableDays.map(order.indexOf).where((i) => i >= 0).toList()..sort();
    if (idx.isEmpty) return '';
    final consecutive = idx.length > 2 && idx.last - idx.first == idx.length - 1;
    return consecutive ? '${order[idx.first]}–${order[idx.last]}' : idx.map((i) => order[i]).join(', ');
  }

  factory Professional.fromJson(Map<String, dynamic> json) {
    final years = _int(json['years_experience_numeric']);
    return Professional(
      id: _str(json['id']),
      name: _str(json['name']),
      profession: _str(json['profession']).isNotEmpty ? _str(json['profession']) : 'Professional',
      specialty: _str(json['specialty']),
      qualification: _str(json['qualification']).isEmpty ? null : _str(json['qualification']),
      clinic: _str(json['clinic']),
      locationCity: _str(json['location_city']),
      experienceYears: years,
      experienceString: _str(json['experience']).isNotEmpty ? _str(json['experience']) : '$years Years',
      rating: _double(json['rating'] ?? json['default_rating']),
      defaultRating: _double(json['default_rating']),
      reviews: _int(json['reviews']),
      consultationFee: _double(json['consultation_fee'] ?? json['consultationFee']).round(),
      imageUrl: _str(json['image_url'] ?? json['imageUrl']).isEmpty ? null : _str(json['image_url'] ?? json['imageUrl']),
      description: _str(json['description']).isEmpty ? null : _str(json['description']),
      timeSlots: _sortSlots(_strings(json['time_slots'])),
      availableDays: _strings(json['available_days']),
      isFeatured: json['is_featured'] == true,
      consultationMode: _strings(json['consultation_mode']),
      languagesSpoken: _strings(json['languages_spoken']),
      nextAvailable: NextSlot.fromJson(json['next_available']),
    );
  }

  /// Sorts "02:00 PM" style times chronologically; unparseable ones go last.
  static List<String> _sortSlots(List<String> slots) {
    int minutes(String s) {
      final m = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$').firstMatch(s.trim());
      if (m == null) return 99999;
      var h = int.parse(m.group(1)!) % 12;
      if ((m.group(3) ?? '').toUpperCase() == 'PM') h += 12;
      if (m.group(3) == null) h = int.parse(m.group(1)!);
      return h * 60 + int.parse(m.group(2)!);
    }

    return [...slots]..sort((a, b) => minutes(a).compareTo(minutes(b)));
  }
}
