import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/listing_provider.dart';
import '../widgets/availability_calendar.dart';
import '../widgets/photo_gallery.dart';
import '../widgets/review_card.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(listingDetailProvider(listingId));

    return detailAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kGrey),
              const SizedBox(height: 12),
              const Text('Could not load listing'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(listingDetailProvider(listingId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (listing) {
        final priceLabel =
            listing.type == 'CAR' ? '/ day' : '/ night';

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Photo gallery as a SliverAppBar so it scrolls away naturally
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: PhotoGallery(images: listing.images),
                ),
                title: Text(
                  listing.title,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + type + location
                      Text(
                        listing.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _TypeBadge(type: listing.type),
                          const SizedBox(width: 8),
                          if (listing.city != null)
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: kGrey),
                                const SizedBox(width: 2),
                                Text(
                                  listing.city!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: kGrey),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Rating row
                      if (listing.averageRating != null &&
                          listing.averageRating! > 0)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              listing.averageRating!.toStringAsFixed(1),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '  (${listing.reviewCount} reviews)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: kGrey),
                            ),
                          ],
                        ),

                      const Divider(height: 32),

                      // Description
                      if (listing.description.isNotEmpty) ...[
                        Text('About',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          listing.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Divider(height: 32),
                      ],

                      // Availability calendar
                      Text('Availability',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      AvailabilityCalendar(listingId: listingId),

                      const Divider(height: 32),

                      // Reviews
                      _ReviewsSection(listingId: listingId),

                      // Bottom padding so content isn't hidden under the Book Now bar
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Book Now bar
          bottomNavigationBar: SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${listing.currency} ${listing.pricePerUnit.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: kNavy,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        priceLabel,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: kGrey),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push(
                        '/listings/$listingId/book',
                        extra: listing,
                      ),
                      child: const Text('Book Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(listingReviewsProvider(listingId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        reviewsAsync.when(
          loading: () => _ReviewsSkeleton(),
          error: (_, __) => const Text('Could not load reviews',
              style: TextStyle(color: kGrey)),
          data: (reviews) {
            if (reviews.isEmpty) {
              return const Text('No reviews yet',
                  style: TextStyle(color: kGrey));
            }
            return Column(
              children: reviews
                  .map((r) => ReviewCard(review: r))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  static const _labels = {
    'HOUSE': 'House',
    'CAR': 'Car',
    'ACTIVITY': 'Activity',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kLight,
        border: Border.all(color: kTeal),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _labels[type] ?? type,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: kTeal, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ReviewsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: 120, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 10, width: double.infinity, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
