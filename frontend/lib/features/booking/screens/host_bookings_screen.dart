import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/l10n/l10n_extension.dart';
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
      appBar: AppBar(title: Text(context.l10n.manageBookings)),
      body: bookingsAsync.when(
              loading: () => const _BookingsListSkeleton(),
              error: (err, _) {
                String message;
                if (err is DioException && err.error is ServerException) {
                  message = (err.error as ServerException).message;
                } else if (err is DioException && err.error is NetworkException) {
                  message = context.l10n.checkConnectionAndRetry;
                } else {
                  message = context.l10n.couldNotLoadBookings;
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
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  ),
                );
              },
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 64, color: kGrey),
                        const SizedBox(height: 16),
                        Text(context.l10n.noBookingsYet,
                            style: const TextStyle(color: kGrey, fontSize: 16)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.somethingWentWrong)),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.reject}: $e')),
        );
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
        title: Text(context.l10n.rejectBookingTitle),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: context.l10n.giveReasonRequired,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.reject),
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
                    booking.listingTitle ?? context.l10n.myListings,
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
                    tooltip: context.l10n.chatWithGuest,
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
              '${context.l10n.guestCount(booking.numberOfGuests)}  ·  ${booking.totalPrice.toStringAsFixed(0)} KGS',
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
                      child: Text(context.l10n.reject),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal,
                          foregroundColor: Colors.white),
                      child: Text(context.l10n.confirm),
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
        itemBuilder: (_, __) => Card(
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
