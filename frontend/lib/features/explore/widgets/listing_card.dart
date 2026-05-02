import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/listing_model.dart';
import '../../../shared/widgets/type_badge.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, this.onTap});

  final ListingModel listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoverImage(coverUrl: listing.coverUrl, type: listing.type),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _LocationRow(listing: listing),
                  const SizedBox(height: 6),
                  _PriceRatingRow(listing: listing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverUrl, required this.type});

  final String? coverUrl;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 140,
          width: double.infinity,
          child: coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const _ImagePlaceholder(),
                  placeholder: (_, __) => const _ImagePlaceholder(),
                )
              : const _ImagePlaceholder(),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: TypeBadge(type: type, filled: true),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kLight,
      child: const Center(
        child: Icon(Icons.image_outlined, color: kGrey, size: 40),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (listing.city != null) parts.add(listing.city!);
    if (listing.distanceKm != null) {
      parts.add('${listing.distanceKm!.toStringAsFixed(1)} km away');
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(Icons.location_on_outlined, size: 13, color: kGrey),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            parts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: kGrey),
          ),
        ),
      ],
    );
  }
}

class _PriceRatingRow extends StatelessWidget {
  const _PriceRatingRow({required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    final label = listing.type == 'CAR' ? '/day' : '/night';
    final price =
        '${listing.currency} ${listing.pricePerUnit.toStringAsFixed(0)}$label';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          price,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: kNavy,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (listing.averageRating != null && listing.averageRating! > 0)
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                listing.averageRating!.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (listing.reviewCount > 0)
                Text(
                  ' (${listing.reviewCount})',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: kGrey),
                ),
            ],
          ),
      ],
    );
  }
}

/// Shown while listings are loading — matches the real card layout.
class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 140, color: Colors.white),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 11, width: 100, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 11, width: 140, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
