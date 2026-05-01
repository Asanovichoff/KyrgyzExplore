import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(title: const Text('My Listings')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('host-listings-new'),
        child: const Icon(Icons.add),
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kGrey),
              const SizedBox(height: 12),
              const Text('Could not load listings'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(myListingsProvider),
                child: const Text('Retry'),
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
                  const Text('No listings yet',
                      style: TextStyle(color: kGrey, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Tap + to create your first listing',
                      style: TextStyle(color: kGrey, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.pushNamed('host-listings-new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create listing'),
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
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not delete: $e')),
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
            title: const Text('Delete listing?'),
            content: const Text(
                'This will remove the listing and cancel any pending bookings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
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

  static const _typeLabels = {
    'HOUSE': 'House',
    'CAR': 'Car',
    'ACTIVITY': 'Activity',
  };

  @override
  Widget build(BuildContext context) {
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
          '${_typeLabels[listing.type] ?? listing.type}  ·  '
          '${listing.currency} ${listing.pricePerUnit.toStringAsFixed(0)}'
          '${listing.city != null ? '  ·  ${listing.city}' : ''}',
          style: const TextStyle(color: kGrey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined, color: kNavy),
              tooltip: 'Manage dates',
              onPressed: onManageDates,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: kTeal),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
