class OfferFilterState {
  final String? city;
  final String? category;
  final String? redemptionType;
  final List<String> professions;
  final String? validityUpto;

  OfferFilterState({
    this.city,
    this.category,
    this.redemptionType,
    this.professions = const [],
    this.validityUpto,
  });

  OfferFilterState copyWith({
    String? city,
    String? category,
    String? redemptionType,
    List<String>? professions,
    String? validityUpto,
    bool clearCity = false,
    bool clearCategory = false,
    bool clearRedemptionType = false,
    bool clearProfessions = false,
    bool clearValidityUpto = false,
  }) {
    return OfferFilterState(
      city: clearCity ? null : (city ?? this.city),
      category: clearCategory ? null : (category ?? this.category),
      redemptionType: clearRedemptionType ? null : (redemptionType ?? this.redemptionType),
      professions: clearProfessions ? const [] : (professions ?? this.professions),
      validityUpto: clearValidityUpto ? null : (validityUpto ?? this.validityUpto),
    );
  }

  bool get hasFilters =>
      (city != null && city!.isNotEmpty && city != 'All') ||
      (category != null && category!.isNotEmpty && category != 'All') ||
      (redemptionType != null && redemptionType!.isNotEmpty && redemptionType != 'All') ||
      professions.isNotEmpty ||
      (validityUpto != null && validityUpto!.isNotEmpty);

  int get activeFiltersCount {
    int count = 0;
    if (city != null && city!.isNotEmpty && city != 'All') count++;
    if (category != null && category!.isNotEmpty && category != 'All') count++;
    if (redemptionType != null && redemptionType!.isNotEmpty && redemptionType != 'All') count++;
    if (professions.isNotEmpty) count++;
    if (validityUpto != null && validityUpto!.isNotEmpty) count++;
    return count;
  }
}

