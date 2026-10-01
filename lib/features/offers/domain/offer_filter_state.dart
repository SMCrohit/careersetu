class OfferFilterState {
  final String? city;
  final String? category;

  OfferFilterState({this.city, this.category});

  OfferFilterState copyWith({
    String? city,
    String? category,
    bool clearCity = false,
    bool clearCategory = false,
  }) {
    return OfferFilterState(
      city: clearCity ? null : (city ?? this.city),
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  bool get hasFilters => city != null || category != null;
}
