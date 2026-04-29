import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_model.dart';
import '../models/search_params.dart';
import '../repositories/explore_repository.dart';

/// Holds the active filter/search state. Updating this provider
/// automatically triggers searchResultsProvider to re-fetch.
final searchParamsProvider = StateProvider<SearchParams>(
  (_) => SearchParams.defaultBishkek(),
);

/// Fetches listings whenever searchParamsProvider changes.
/// autoDispose: clears the cache when no screen is watching — saves memory
/// when the user navigates away and comes back fresh.
final searchResultsProvider =
    FutureProvider.autoDispose<List<ListingModel>>((ref) {
  final params = ref.watch(searchParamsProvider);
  return ref.read(exploreRepositoryProvider).search(params);
});
