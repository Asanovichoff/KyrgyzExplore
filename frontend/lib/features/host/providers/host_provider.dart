import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/listing_model.dart';
import '../repositories/host_repository.dart';

final myListingsProvider = FutureProvider.autoDispose<List<ListingModel>>(
  (ref) => ref.read(hostRepositoryProvider).myListings(),
);
