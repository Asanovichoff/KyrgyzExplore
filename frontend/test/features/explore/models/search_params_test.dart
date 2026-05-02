import 'package:flutter_test/flutter_test.dart';
import 'package:kyrgyz_explore/features/explore/models/search_params.dart';

void main() {
  // A base SearchParams with no optional filters set
  const base = SearchParams(
    lat: 42.87,
    lon: 74.59,
    radiusKm: 10,
    sort: 'distance',
    page: 0,
  );

  group('activeFilterCount', () {
    test('is 0 when no optional filters are set and sort is distance', () {
      expect(base.activeFilterCount, 0);
    });

    test('counts minPrice as 1 active filter', () {
      final p = base.copyWith(minPrice: 500.0);
      expect(p.activeFilterCount, 1);
    });

    test('counts maxPrice separately from minPrice', () {
      final p = base.copyWith(minPrice: 100.0, maxPrice: 1000.0);
      expect(p.activeFilterCount, 2);
    });

    test('counts non-distance sort as 1 active filter', () {
      final p = base.copyWith(sort: 'price_asc');
      expect(p.activeFilterCount, 1);
    });

    test('accumulates all filters', () {
      final p = base.copyWith(
        minPrice: 100.0,
        maxPrice: 2000.0,
        minGuests: 2,
        city: 'Bishkek',
        sort: 'rating',
      );
      // minPrice + maxPrice + minGuests + city + sort = 5
      expect(p.activeFilterCount, 5);
    });
  });

  group('copyWith clears filters with sentinel null', () {
    test('clears minPrice when null is passed explicitly', () {
      final withPrice = base.copyWith(minPrice: 500.0);
      expect(withPrice.minPrice, 500.0);

      // Pass null explicitly through the sentinel pattern
      final cleared = withPrice.copyWith(minPrice: null);
      expect(cleared.minPrice, isNull);
    });

    test('preserves existing values when no argument is passed', () {
      final withFilters = base.copyWith(minPrice: 200.0, city: 'Osh');
      final copy = withFilters.copyWith(sort: 'price_asc');

      expect(copy.minPrice, 200.0); // unchanged
      expect(copy.city, 'Osh');     // unchanged
      expect(copy.sort, 'price_asc'); // new value
    });
  });
}
