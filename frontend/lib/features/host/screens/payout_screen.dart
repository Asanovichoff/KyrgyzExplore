import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../models/payout_model.dart';
import '../repositories/host_repository.dart';

final _payoutsProvider = FutureProvider.autoDispose<List<PayoutModel>>((ref) {
  return ref.read(hostRepositoryProvider).getPayouts();
});

class PayoutScreen extends ConsumerWidget {
  const PayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPayouts = ref.watch(_payoutsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.earningsTitle)),
      body: asyncPayouts.when(
        loading: () => const _PayoutsSkeleton(),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kGrey),
              const SizedBox(height: 12),
              Text(context.l10n.couldNotLoadEarnings),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_payoutsProvider),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
        data: (payouts) {
          if (payouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.payments_outlined, size: 64, color: kGrey),
                  const SizedBox(height: 16),
                  Text(context.l10n.noEarningsYet,
                      style: const TextStyle(color: kGrey, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.completedBookingsWillAppear,
                    style: const TextStyle(color: kGrey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final total = payouts.fold(0.0, (sum, p) => sum + p.totalAmount);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_payoutsProvider),
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Card(
                    color: kTeal.withValues(alpha: 0.08),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: kTeal.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              color: kTeal, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.totalEarned,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: kGrey),
                              ),
                              Text(
                                '${total.toStringAsFixed(0)} KGS',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: kTeal,
                                    ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            context.l10n.bookingCount(payouts.length),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: kGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ...payouts.map((p) => _PayoutTile(payout: p)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PayoutsSkeleton extends StatelessWidget {
  const _PayoutsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        children: [
          // Summary card skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Row skeletons
          ...List.generate(
            6,
            (_) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 13, width: 160, color: Colors.white),
                        const SizedBox(height: 6),
                        Container(height: 11, width: 120, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(height: 13, width: 80, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 11, width: 50, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.payout});

  final PayoutModel payout;

  @override
  Widget build(BuildContext context) {
    final ci = payout.checkInDate;
    final co = payout.checkOutDate;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.payments_outlined, color: kTeal, size: 20),
      ),
      title: Text(
        payout.listingTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${ci.day}/${ci.month}/${ci.year} → ${co.day}/${co.month}/${co.year}'
        '  ·  ${context.l10n.nightCount(payout.nightCount)}',
        style: const TextStyle(color: kGrey, fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '+${payout.totalAmount.toStringAsFixed(0)} KGS',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            _fmtDate(payout.paidAt),
            style: const TextStyle(color: kGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
