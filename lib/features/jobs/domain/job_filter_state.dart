class JobFilterState {
  final String? type;
  final String? experience;
  final String? profession;
  final String? location;
  final String? salary;

  JobFilterState({
    this.type,
    this.experience,
    this.profession,
    this.location,
    this.salary,
  });

  JobFilterState copyWith({
    String? type,
    String? experience,
    String? profession,
    String? location,
    String? salary,
    bool clearType = false,
    bool clearExperience = false,
    bool clearProfession = false,
    bool clearLocation = false,
    bool clearSalary = false,
  }) {
    return JobFilterState(
      type: clearType ? null : type ?? this.type,
      experience: clearExperience ? null : experience ?? this.experience,
      profession: clearProfession ? null : profession ?? this.profession,
      location: clearLocation ? null : location ?? this.location,
      salary: clearSalary ? null : salary ?? this.salary,
    );
  }
}
