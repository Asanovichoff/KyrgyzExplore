import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../repositories/booking_repository.dart';

class HostBookingsScreen extends ConsumerWidget {
  const HostBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(hostBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Bookings')),
      body: bookingsAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading bookings...'),
                  ],
                ),
              ),
              error: (err, _) {
                String message;
                if (err is DioException && err.error is ServerException) {
                  message = (err.error as ServerException).message;
                } else if (err is DioException && err.error is NetworkException) {
                  message = 'No connection to server';
                } else {
                  message = err.toString();
                }
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: kGrey),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(message, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(hostBookingsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: kGrey),
                        SizedBox(height: 16),
                        Text('No bookings yet',
                            style: TextStyle(color: kGrey, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(hostBookingsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _HostBookingCard(
                      booking: bookings[i],
                      onRefresh: () => ref.invalidate(hostBookingsProvider),
                    ),
                  ),
                );
              },
      ),
    );
  }
}

class _HostBookingCard extends ConsumerStatefulWidget {
  const _HostBookingCard({
    required this.booking,
    required this.onRefresh,
  });

  final BookingModel booking;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_HostBookingCard> createState() => _HostBookingCardState();
}

class _HostBookingCardState extends ConsumerState<_HostBookingCard> {
  bool _loading = false;

  String get _dateRange {
    final ci = widget.booking.checkInDate;
    final co = widget.booking.checkOutDate;
    return '${ci.day}/${ci.month}/${ci.year} → ${co.day}/${co.month}/${co.year}';
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await ref.read(bookingRepositoryProvider).confirm(widget.booking.id);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(bookingRepositoryProvider)
          .reject(widget.booking.id, reason);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject booking'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Give a reason (required)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isPending = booking.status == 'PENDING';
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
                    booking.listingTitle ?? 'Listing',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (canChat)
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    tooltip: 'Chat with guest',
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
            const SizedBox(height: 6),
            Text(
              _dateRange,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: kGrey),
            ),
            Text(
              '${booking.numberOfGuests} guest${booking.numberOfGuests == 1 ? '' : 's'}  ·  ${booking.totalPrice.toStringAsFixed(0)} KGS',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: kGrey),
            ),
            if (booking.guestMessage != null &&
                booking.guestMessage!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '"${booking.guestMessage}"',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_loading)
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    OutlinedButton(
                      onPressed: _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal,
                          foregroundColor: Colors.white),
                      child: const Text('Confirm'),
                    ),
                  ],
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
