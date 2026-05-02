import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kGrey),
              const SizedBox(height: 12),
              const Text('Could not load bookings'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(myBookingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: kGrey),
                  SizedBox(height: 16),
                  Text('No bookings yet',
                      style: TextStyle(color: kGrey, fontSize: 16)),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(bookingRepositoryProvider).cancel(widget.booking.id);
      ref.invalidate(myBookingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not cancel: $e')),
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
          const SnackBar(content: Text('Payment successful!')),
        );
      }
    } on StripeException catch (e) {
      if (mounted && e.error.code != FailureCode.Canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.error.localizedMessage ?? 'Payment failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
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
              const SnackBar(content: Text('Review submitted! Thank you.')),
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
                    booking.listingTitle ?? 'Booking',
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
                    tooltip: 'Chat with host',
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
              '${booking.nightCount} night${booking.nightCount == 1 ? '' : 's'}  ·  ${booking.totalPrice.toStringAsFixed(0)} KGS',
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
                          : const Text('Cancel',
                              style: TextStyle(color: Colors.red)),
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
                          : const Text('Pay now'),
                    ),
                  ],
                  if (canReview)
                    OutlinedButton.icon(
                      onPressed: _handleReview,
                      icon: const Icon(Icons.star_outline, size: 16),
                      label: const Text('Leave review'),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  static const _config = {
    'PENDING': (label: 'Pending', color: Colors.amber),
    'CONFIRMED': (label: 'Confirmed', color: Colors.green),
    'REJECTED': (label: 'Rejected', color: kGrey),
    'CANCELLED': (label: 'Cancelled', color: kGrey),
    'PAID': (label: 'Paid', color: kTeal),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[status] ?? (label: status, color: kGrey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        cfg.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cfg.color,
        ),
      ),
    );
  }
}
