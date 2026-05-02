class SearchParams {
  const SearchParams({
    required this.lat,
    required this.lon,
    required this.radiusKm,
    required this.sort,
    required this.page,
    this.type,
    this.minPrice,
    this.maxPrice,
    this.minGuests,
    this.city,
    this.checkIn,
    this.checkOut,
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
  final double? minPrice;
  final double? maxPrice;
  final int? minGuests;
  final String? city;
  final DateTime? checkIn;
  final DateTime? checkOut;

  /// Number of active filter values (excludes type, which has its own chips).
  int get activeFilterCount {
    int n = 0;
    if (minPrice != null) n++;
    if (maxPrice != null) n++;
    if (minGuests != null) n++;
    if (city != null && city!.isNotEmpty) n++;
    if (checkIn != null) n++;
    if (checkOut != null) n++;
    if (sort != 'distance') n++;
    return n;
  }

  SearchParams copyWith({
    double? lat,
    double? lon,
    double? radiusKm,
    String? sort,
    int? page,
    // Use sentinel so callers can explicitly pass null to CLEAR an optional filter.
    Object? type = _sentinel,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    Object? minGuests = _sentinel,
    Object? city = _sentinel,
    Object? checkIn = _sentinel,
    Object? checkOut = _sentinel,
  }) {
    return SearchParams(
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      radiusKm: radiusKm ?? this.radiusKm,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      type: type == _sentinel ? this.type : type as String?,
      minPrice: minPrice == _sentinel ? this.minPrice : minPrice as double?,
      maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as double?,
      minGuests: minGuests == _sentinel ? this.minGuests : minGuests as int?,
      city: city == _sentinel ? this.city : city as String?,
      checkIn: checkIn == _sentinel ? this.checkIn : checkIn as DateTime?,
      checkOut: checkOut == _sentinel ? this.checkOut : checkOut as DateTime?,
    );
  }
}

// Sentinel object used by copyWith to distinguish "not passed" from "explicitly null".
const _sentinel = Object();
