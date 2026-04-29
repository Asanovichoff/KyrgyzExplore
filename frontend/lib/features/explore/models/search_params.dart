class SearchParams {
  const SearchParams({
    required this.lat,
    required this.lon,
    required this.radiusKm,
    required this.sort,
    required this.page,
    this.type,
  });

  // Bishkek city centre — used as the default until real GPS is wired up.
  factory SearchParams.defaultBishkek() => const SearchParams(
        lat: 42.8746,
        lon: 74.5698,
        radiusKm: 50,
        sort: 'distance',
        page: 0,
      );

  final double lat;
  final double lon;
  final double radiusKm;
  final String sort;
  final int page;

  /// null = all types; "HOUSE" | "CAR" | "ACTIVITY"
  final String? type;

  SearchParams copyWith({
    double? lat,
    double? lon,
    double? radiusKm,
    String? sort,
    int? page,
    Object? type = _sentinel,
  }) {
    return SearchParams(
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      radiusKm: radiusKm ?? this.radiusKm,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      // Special sentinel so callers can explicitly pass type: null to clear the filter
      type: type == _sentinel ? this.type : type as String?,
    );
  }
}

// Sentinel object to distinguish "not passed" from "explicitly null"
const _sentinel = Object();
