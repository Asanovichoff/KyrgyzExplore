import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/navigation/main_shell.dart';
import '../../../core/theme/app_colors.dart';
import '../models/search_params.dart';
import '../providers/explore_provider.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/listing_card.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  static const _filterTypes = <String?>[null, 'HOUSE', 'CAR', 'ACTIVITY'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params  = ref.watch(searchParamsProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.home),
        actions: [
          const NotificationBellAction(),
          Badge(
            isLabelVisible: params.activeFilterCount > 0,
            label: Text('${params.activeFilterCount}'),
            child: IconButton(
              icon: const Icon(Icons.tune),
              tooltip: context.l10n.filtersTooltip,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => FilterBottomSheet(
                  current: params,
                  onApply: (updated) =>
                      ref.read(searchParamsProvider.notifier).state = updated,
                ),
              ),
            ),
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
              error: (err, _) => _ErrorView(
                  onRetry: () => ref.invalidate(searchResultsProvider)),
              data: (listings) {
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(searchResultsProvider),
                  child: listings.isEmpty
                      ? const CustomScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyView(),
                            ),
                          ],
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount =
                                constraints.maxWidth > 600 ? 2 : 1;
                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: listings.length,
                              itemBuilder: (context, index) => ListingCard(
                                listing: listings[index],
                                onTap: () => context.pushNamed(
                                  'listing-detail',
                                  pathParameters: {
                                    'listingId': listings[index].id
                                  },
                                ),
                              ),
                            );
                          },
                        ),
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
          children: ExploreScreen._filterTypes.map((type) {
            final selected = current.type == type;
            final label = switch (type) {
              null       => context.l10n.filterAll,
              'HOUSE'    => context.l10n.filterHouses,
              'CAR'      => context.l10n.filterCars,
              'ACTIVITY' => context.l10n.filterActivities,
              _          => type,
            };
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: selected,
                selectedColor: kTeal.withValues(alpha: 0.15),
                checkmarkColor: kTeal,
                onSelected: (_) => onChanged(
                  current.copyWith(type: type, page: 0),
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
            context.l10n.couldNotLoadListings,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.checkConnectionAndRetry,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: kGrey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.retry),
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
            context.l10n.noListingsFound,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.tryDifferentFilter,
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
