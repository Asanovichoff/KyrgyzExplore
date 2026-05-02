import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../listing/repositories/review_repository.dart';

class ReviewBottomSheet extends ConsumerStatefulWidget {
  const ReviewBottomSheet({
    super.key,
    required this.bookingId,
    required this.onSuccess,
  });

  final String bookingId;
  final VoidCallback onSuccess;

  @override
  ConsumerState<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends ConsumerState<ReviewBottomSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;

    setState(() => _submitting = true);
    try {
      await ref.read(reviewRepositoryProvider).createReview(
            bookingId: widget.bookingId,
            rating: _rating,
            comment: _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('ALREADY_REVIEWED')
            ? "You've already reviewed this booking."
            : 'Could not submit review. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kGrey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Rate your experience',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // Star rating row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starIndex = i + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          starIndex <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 40,
                          color: starIndex <= _rating
                              ? Colors.amber
                              : kGrey,
                        ),
                      ),
                    );
                  }),
                ),

                if (_rating > 0) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _ratingLabel(_rating),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: kGrey),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                TextFormField(
                  controller: _commentCtrl,
                  maxLines: 5,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience (optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_rating == 0 || _submitting) ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit review'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int r) => switch (r) {
        1 => 'Poor',
        2 => 'Fair',
        3 => 'Good',
        4 => 'Very good',
        5 => 'Excellent',
        _ => '',
      };
}
