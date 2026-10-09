/// Student filters for the professionals list.
class ProfessionalFilterState {
  final String? profession;
  final String? city;
  final String? consultationMode;
  final int? minFee;
  final int? maxFee;

  /// One of [experienceOptions] keys.
  final String? experience;
  final String? language;

  /// 'Mon'..'Sun'.
  final String? availableDay;
  final double? minRating;
  final bool featuredOnly;

  const ProfessionalFilterState({
    this.profession,
    this.city,
    this.consultationMode,
    this.minFee,
    this.maxFee,
    this.experience,
    this.language,
    this.availableDay,
    this.minRating,
    this.featuredOnly = false,
  });

  static const experienceOptions = {'0-5': '0–5 yrs', '5-10': '5–10 yrs', '10+': '10+ yrs'};
  static const ratingOptions = [3.5, 4.0, 4.5];
  static const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool get hasFee => minFee != null || maxFee != null;

  int get activeCount =>
      [profession, city, consultationMode, experience, language, availableDay, minRating].where((v) => v != null).length +
      (hasFee ? 1 : 0) +
      (featuredOnly ? 1 : 0);

  Map<String, dynamic> toQuery() => {
        if (profession != null) 'profession': profession,
        if (city != null) 'city': city,
        if (consultationMode != null) 'consultation_mode': consultationMode,
        if (minFee != null) 'min_fee': minFee,
        if (maxFee != null) 'max_fee': maxFee,
        if (experience != null) 'experience': experience,
        if (language != null) 'language': language,
        if (availableDay != null) 'available_day': availableDay,
        if (minRating != null) 'min_rating': minRating,
        if (featuredOnly) 'featured': true,
      };

  ProfessionalFilterState copyWith({
    String? profession,
    String? city,
    String? consultationMode,
    int? minFee,
    int? maxFee,
    String? experience,
    String? language,
    String? availableDay,
    double? minRating,
    bool? featuredOnly,
    bool clearProfession = false,
    bool clearCity = false,
    bool clearMode = false,
    bool clearFee = false,
    bool clearExperience = false,
    bool clearLanguage = false,
    bool clearDay = false,
    bool clearRating = false,
  }) {
    return ProfessionalFilterState(
      profession: clearProfession ? null : profession ?? this.profession,
      city: clearCity ? null : city ?? this.city,
      consultationMode: clearMode ? null : consultationMode ?? this.consultationMode,
      minFee: clearFee ? null : minFee ?? this.minFee,
      maxFee: clearFee ? null : maxFee ?? this.maxFee,
      experience: clearExperience ? null : experience ?? this.experience,
      language: clearLanguage ? null : language ?? this.language,
      availableDay: clearDay ? null : availableDay ?? this.availableDay,
      minRating: clearRating ? null : minRating ?? this.minRating,
      featuredOnly: featuredOnly ?? this.featuredOnly,
    );
  }
}
