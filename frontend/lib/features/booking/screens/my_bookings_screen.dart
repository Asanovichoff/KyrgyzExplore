import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/l10n/l10n_extension.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../repositories/booking_repository.dart';
import '../widgets/review_bottom_sheet.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myBookings)),
      body: bookingsAsync.when(
        loading: () => const _BookingsListSkeleton(),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kGrey),
              const SizedBox(height: 12),
              Text(context.l10n.couldNotLoadBookings),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(myBookingsProvider),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 64, color: kGrey),
                  const SizedBox(height: 16),
                  Text(context.l10n.noBookingsYet,
                      style: const TextStyle(color: kGrey, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myBookingsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _BookingCard(booking: bookings[i]),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  const _BookingCard({required this.booking});

  final BookingModel booking;

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _cancelling = false;
  bool _paying = false;

  String get _dateRange {
    final ci = widget.booking.checkInDate;
    final co = widget.booking.checkOutDate;
    return '${ci.day}/${ci.month}/${ci.year} → ${co.day}/${co.month}/${co.year}';
  }

  Future<void> _handleCancel() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.cancelBookingTitle),
        content: Text(l10n.cancelBookingContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepIt),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cancelBookingAction,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(bookingRepositoryProvider).cancel(widget.booking.id);
      ref.invalidate(myBookingsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotCancel)),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _handlePay() async {
    setState(() => _paying = true);
    try {
      final intent =
          await ref.read(bookingRepositoryProvider).pay(widget.booking.id);

      // Set the publishable key we got from the server — this is safer than
      // hardcoding it at app startup because it comes from the same call
      // that creates the PaymentIntent, so they always match.
      Stripe.publishableKey = intent.publishableKey;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'KyrgyzExplore',
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // presentPaymentSheet() throws StripeException on cancel or failure,
      // so reaching here means the payment was submitted successfully.
      // The backend webhook will mark the booking PAID asynchronously.
      ref.invalidate(myBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.paymentSuccessful)),
        );
      }
    } on StripeException catch (e) {
      if (mounted && e.error.code != FailureCode.Canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.error.localizedMessage ?? context.l10n.paymentFailed)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.paymentFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _handleReview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewBottomSheet(
        bookingId: widget.booking.id,
        onSuccess: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.reviewSubmitted)),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final canCancel =
        booking.status == 'PENDING' || booking.status == 'CONFIRMED';
    final canPay = booking.status == 'CONFIRMED';
    final canReview = booking.status == 'PAID';
    final canChat =
        booking.status == 'CONFIRMED' || booking.status == 'PAID';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.listingTitle ?? context.l10n.myBookings,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (canChat)
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    tooltip: context.l10n.chatWithHost,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.pushNamed(
                      'chat',
                      pathParameters: {'bookingId': booking.id},
                      extra: booking,
                    ),
                  ),
                _StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _dateRange,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: kGrey),
            ),
            const SizedBox(height: 2),
            Text(
              '${context.l10n.nightCount(booking.nightCount.toInt())}  ·  ${booking.totalPrice.toStringAsFixed(0)} KGS',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: kGrey),
            ),
            if (canPay || canCancel || canReview) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canCancel)
                    TextButton(
                      onPressed:
                          (_cancelling || _paying) ? null : _handleCancel,
                      child: _cancelling
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.cancel,
                              style: const TextStyle(color: Colors.red)),
                    ),
                  if (canPay) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: (_paying || _cancelling) ? null : _handlePay,
                      child: _paying
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(context.l10n.payNow),
                    ),
                  ],
                  if (canReview)
                    OutlinedButton.icon(
                      onPressed: _handleReview,
                      icon: const Icon(Icons.star_outline, size: 16),
                      label: Text(context.l10n.leaveReview),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookingsListSkeleton extends StatelessWidget {
  const _BookingsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => _BookingCardSkeleton(),
      ),
    );
  }
}

class _BookingCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 14, width: 160, color: Colors.white),
                Container(
                  height: 22,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 11, width: 140, color: Colors.white),
            const SizedBox(height: 6),
            Container(height: 11, width: 100, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  static const _colors = {
    'PENDING': Colors.amber,
    'CONFIRMED': Colors.green,
    'REJECTED': kGrey,
    'CANCELLED': kGrey,
    'PAID': kTeal,
  };

  String _label(BuildContext context) => switch (status) {
    'PENDING'   => context.l10n.statusPending,
    'CONFIRMED' => context.l10n.statusConfirmed,
    'REJECTED'  => context.l10n.statusRejected,
    'CANCELLED' => context.l10n.statusCancelled,
    'PAID'      => context.l10n.statusPaid,
    _           => status,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? kGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label(context),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
