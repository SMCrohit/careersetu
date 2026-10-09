/// Filters for the student job list. Mirrors the admin "Advanced Filters", minus admin-only fields.
class JobFilterState {
  final String? type;
  final String? workModel;
  final String? city;

  /// One of [experienceOptions].
  final String? experience;
  final int? minSalary;
  final int? maxSalary;
  final int? postedWithinDays;

  const JobFilterState({
    this.type,
    this.workModel,
    this.city,
    this.experience,
    this.minSalary,
    this.maxSalary,
    this.postedWithinDays,
  });

  static const experienceOptions = ['Fresher (0 yrs)', '1-3 Years', '3-5 Years', '5+ Years'];
  static const postedOptions = {1: 'Last 24 hours', 7: 'Last 7 days', 30: 'Last 30 days'};

  /// Upper end of the salary slider (₹50L); a max at this value means "no upper limit".
  static const salaryCap = 5000000;

  bool get hasSalary => (minSalary ?? 0) > 0 || (maxSalary != null && maxSalary! < salaryCap);

  int get activeCount => [type, workModel, city, experience, postedWithinDays].where((v) => v != null).length + (hasSalary ? 1 : 0);

  Map<String, dynamic> toQuery() => {
        if (type != null) 'type': type,
        if (workModel != null) 'work_model': workModel,
        if (city != null) 'city': city,
        if (experience != null) 'experience': experience,
        if ((minSalary ?? 0) > 0) 'min_salary': minSalary,
        if (maxSalary != null && maxSalary! < salaryCap) 'max_salary': maxSalary,
        if (postedWithinDays != null) 'posted_within_days': postedWithinDays,
      };

  JobFilterState copyWith({
    String? type,
    String? workModel,
    String? city,
    String? experience,
    int? minSalary,
    int? maxSalary,
    int? postedWithinDays,
    bool clearType = false,
    bool clearWorkModel = false,
    bool clearCity = false,
    bool clearExperience = false,
    bool clearSalary = false,
    bool clearPosted = false,
  }) {
    return JobFilterState(
      type: clearType ? null : type ?? this.type,
      workModel: clearWorkModel ? null : workModel ?? this.workModel,
      city: clearCity ? null : city ?? this.city,
      experience: clearExperience ? null : experience ?? this.experience,
      minSalary: clearSalary ? null : minSalary ?? this.minSalary,
      maxSalary: clearSalary ? null : maxSalary ?? this.maxSalary,
      postedWithinDays: clearPosted ? null : postedWithinDays ?? this.postedWithinDays,
    );
  }
}
