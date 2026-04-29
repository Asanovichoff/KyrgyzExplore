import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../explore/repositories/explore_repository.dart';
import '../../explore/models/listing_model.dart';
import '../models/review_model.dart';

final listingDetailProvider = FutureProvider.autoDispose
    .family<ListingModel, String>((ref, id) =>
        ref.read(exploreRepositoryProvider).getById(id));

// Record type as family key — Dart 3 records implement == and hashCode
// automatically, so this works perfectly as a provider cache key.
final availabilityProvider = FutureProvider.autoDispose
    .family<List<String>, ({String id, int year, int month})>(
        (ref, args) => ref
            .read(exploreRepositoryProvider)
            .getAvailability(args.id, args.year, args.month));

final listingReviewsProvider = FutureProvider.autoDispose
    .family<List<ReviewModel>, String>((ref, id) =>
        ref.read(exploreRepositoryProvider).getReviews(id));
