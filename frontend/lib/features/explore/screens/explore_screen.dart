import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/search_params.dart';
import '../providers/explore_provider.dart';
import '../widgets/listing_card.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  static const _filters = [
    (label: 'All',        type: null),
    (label: 'Houses',     type: 'HOUSE'),
    (label: 'Cars',       type: 'CAR'),
    (label: 'Activities', type: 'ACTIVITY'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params  = ref.watch(searchParamsProvider);
    final results = ref.watch(searchResultsProvider);
    final user    = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          if (user?.isHost == true)
            IconButton(
              icon: const Icon(Icons.dashboard_outlined),
              tooltip: 'Manage Bookings',
              onPressed: () => context.push('/host/bookings'),
            ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'My Bookings',
            onPressed: () => context.push('/bookings'),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterChips(current: params, onChanged: (updated) {
            ref.read(searchParamsProvider.notifier).state = updated;
          }),
          Expanded(
            child: results.when(
              loading: () => _LoadingGrid(),
              error: (err, _) => _ErrorView(onRetry: () => ref.invalidate(searchResultsProvider)),
              data: (listings) {
                if (listings.isEmpty) {
                  return const _EmptyView();
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(searchResultsProvider),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: listings.length,
                        itemBuilder: (context, index) => ListingCard(
                          listing: listings[index],
                          onTap: () => context.push('/listings/${listings[index].id}'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.current, required this.onChanged});

  final SearchParams current;
  final void Function(SearchParams) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: ExploreScreen._filters.map((f) {
            final selected = current.type == f.type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.label),
                selected: selected,
                selectedColor: kTeal.withValues(alpha: 0.15),
                checkmarkColor: kTeal,
                onSelected: (_) => onChanged(
                  current.copyWith(type: f.type, page: 0),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const ListingCardSkeleton(),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: kGrey),
          const SizedBox(height: 12),
          Text(
            'Could not load listings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Check your connection and try again',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: kGrey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: kGrey),
          const SizedBox(height: 12),
          Text(
            'No listings found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different filter or area',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: kGrey),
          ),
        ],
      ),
    );
  }
}
