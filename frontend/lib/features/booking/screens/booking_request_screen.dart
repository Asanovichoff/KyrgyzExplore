import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../explore/models/listing_model.dart';
import '../repositories/booking_repository.dart';

class BookingRequestScreen extends ConsumerStatefulWidget {
  const BookingRequestScreen({super.key, required this.listing});

  final ListingModel listing;

  @override
  ConsumerState<BookingRequestScreen> createState() =>
      _BookingRequestScreenState();
}

class _BookingRequestScreenState extends ConsumerState<BookingRequestScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  int get _nights =>
      (_checkIn != null && _checkOut != null)
          ? _checkOut!.difference(_checkIn!).inDays
          : 0;

  double get _total => _nights * widget.listing.pricePerUnit;

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final firstDate = isCheckIn ? now : (_checkIn ?? now).add(const Duration(days: 1));
    final initial = isCheckIn
        ? (_checkIn ?? now)
        : (_checkOut ?? firstDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked == null) return;

    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        // Clear check-out if it's no longer after the new check-in
        if (_checkOut != null && !_checkOut!.isAfter(picked)) {
          _checkOut = null;
        }
      } else {
        _checkOut = picked;
      }
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_checkIn == null || _checkOut == null) {
      setState(() => _error = 'Please select check-in and check-out dates.');
      return;
    }
    if (_nights < 1) {
      setState(() => _error = 'Check-out must be at least 1 day after check-in.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(bookingRepositoryProvider).create(
            listingId: widget.listing.id,
            checkInDate: _checkIn!,
            checkOutDate: _checkOut!,
            numberOfGuests: _guests,
            guestMessage: _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request sent! The host will confirm shortly.'),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final priceLabel = listing.type == 'CAR' ? 'day' : 'night';

    return Scaffold(
      appBar: AppBar(title: const Text('Request to Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Listing header
            Text(
              listing.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${listing.currency} ${listing.pricePerUnit.toStringAsFixed(0)} / $priceLabel',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: kTeal),
            ),

            const Divider(height: 32),

            // Date pickers
            Text('Dates',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: 'Check-in',
                    date: _checkIn,
                    onTap: () => _pickDate(isCheckIn: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTile(
                    label: 'Check-out',
                    date: _checkOut,
                    onTap: () => _pickDate(isCheckIn: false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Guest stepper
            Text('Guests',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _guests > 1
                      ? () => setState(() => _guests--)
                      : null,
                ),
                Text(
                  '$_guests',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _guests < 20
                      ? () => setState(() => _guests++)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Message
            Text('Message to host (optional)',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Tell the host about your plans...',
                border: OutlineInputBorder(),
              ),
            ),

            const Divider(height: 24),

            // Price summary
            if (_nights > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_nights ${_nights == 1 ? priceLabel : '${priceLabel}s'}  ×  ${listing.currency} ${listing.pricePerUnit.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${listing.currency} ${_total.toStringAsFixed(0)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Error banner
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Request to Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: date != null ? kTeal : kGrey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: kGrey)),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : 'Select',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: date != null ? kDark : kGrey,
                    fontWeight:
                        date != null ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
