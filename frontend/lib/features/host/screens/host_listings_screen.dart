import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/l10n/l10n_extension.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/listing_model.dart';
import '../providers/host_provider.dart';
import '../repositories/host_repository.dart';

class HostListingsScreen extends ConsumerWidget {
  const HostListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myListings)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('host-listings-new'),
        child: const Icon(Icons.add),
      ),
      body: listingsAsync.when(
        loading: () => const _ListingsListSkeleton(),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kGrey),
              const SizedBox(height: 12),
              Text(context.l10n.couldNotLoadListings),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(myListingsProvider),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_work_outlined, size: 64, color: kGrey),
                  const SizedBox(height: 16),
                  Text(context.l10n.noListingsYet,
                      style: const TextStyle(color: kGrey, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(context.l10n.tapToCreateFirstListing,
                      style: const TextStyle(color: kGrey, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.pushNamed('host-listings-new'),
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.createListing),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myListingsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ListingTile(
                listing: listings[i],
                onManageDates: () => context.pushNamed(
                  'host-availability',
                  pathParameters: {'id': listings[i].id},
                  extra: listings[i],
                ),
                onEdit: () => context.pushNamed(
                  'host-listings-edit',
                  pathParameters: {'id': listings[i].id},
                  extra: listings[i],
                ),
                onDelete: () async {
                  final confirmed = await _confirmDelete(context);
                  if (!confirmed) return;
                  try {
                    await ref
                        .read(hostRepositoryProvider)
                        .delete(listings[i].id);
                    ref.invalidate(myListingsProvider);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.couldNotDelete)),
                      );
                    }
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(context.l10n.deleteListingTitle),
            content: Text(context.l10n.deleteListingContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(context.l10n.delete),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _ListingsListSkeleton extends StatelessWidget {
  const _ListingsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 160, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 11, width: 120, color: Colors.white),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    3,
                    (_) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
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

class _ListingTile extends StatelessWidget {
  const _ListingTile({
    required this.listing,
    required this.onManageDates,
    required this.onEdit,
    required this.onDelete,
  });

  final ListingModel listing;
  final VoidCallback onManageDates;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final typeLabels = {
      'HOUSE': context.l10n.typeHouse,
      'CAR': context.l10n.typeCar,
      'ACTIVITY': context.l10n.typeActivity,
    };

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Text(
          listing.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${typeLabels[listing.type] ?? listing.type}  ·  '
          '${listing.currency} ${listing.pricePerUnit.toStringAsFixed(0)}'
          '${listing.city != null ? '  ·  ${listing.city}' : ''}',
          style: const TextStyle(color: kGrey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined, color: kNavy),
              tooltip: context.l10n.manageDates,
              onPressed: onManageDates,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: kTeal),
              tooltip: context.l10n.edit,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: context.l10n.delete,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
