import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../repositories/booking_repository.dart';

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
              itemBuilder: (context, i) => _BookingCard(
                booking: bookings[i],
                onCancel: () async {
                  await ref
                      .read(bookingRepositoryProvider)
                      .cancel(bookings[i].id);
                  ref.invalidate(myBookingsProvider);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  const _BookingCard({required this.booking, required this.onCancel});

  final BookingModel booking;
  final Future<void> Function() onCancel;

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _cancelling = false;

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
            child:
                const Text('Cancel booking', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await widget.onCancel();
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

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final canCancel =
        booking.status == 'PENDING' || booking.status == 'CONFIRMED';

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
                Text(
                  _dateRange,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                _StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${booking.nightCount} night${booking.nightCount == 1 ? '' : 's'}  ·  ${booking.totalPrice.toStringAsFixed(0)} KGS',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: kGrey),
            ),
            if (canCancel) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _cancelling ? null : _handleCancel,
                  child: _cancelling
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cancel',
                          style: TextStyle(color: Colors.red)),
                ),
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
