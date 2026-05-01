import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/listing_model.dart';
import '../repositories/host_repository.dart';

class ManageAvailabilityScreen extends ConsumerStatefulWidget {
  const ManageAvailabilityScreen({super.key, required this.listing});

  final ListingModel listing;

  @override
  ConsumerState<ManageAvailabilityScreen> createState() =>
      _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState
    extends ConsumerState<ManageAvailabilityScreen> {
  late int _year;
  late int _month;

  // Dates fetched from server for current month
  Set<String> _serverBlocked = {};

  // Pending local changes the host made but hasn't saved yet
  final Set<String> _pendingBlock = {};
  final Set<String> _pendingUnblock = {};

  bool _fetching = true;
  bool _saving = false;

  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _fetching = true);
    try {
      final blocked = await ref
          .read(hostRepositoryProvider)
          .getAvailability(widget.listing.id, _year, _month);
      if (mounted) setState(() => _serverBlocked = blocked.toSet());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load availability: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
    _loadMonth();
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
    _loadMonth();
  }

  void _toggleDate(String dateStr) {
    setState(() {
      if (_pendingBlock.contains(dateStr)) {
        // Was going to block it — undo
        _pendingBlock.remove(dateStr);
      } else if (_pendingUnblock.contains(dateStr)) {
        // Was going to unblock it — undo
        _pendingUnblock.remove(dateStr);
      } else if (_serverBlocked.contains(dateStr)) {
        // Currently blocked → mark for unblocking
        _pendingUnblock.add(dateStr);
      } else {
        // Currently open → mark for blocking
        _pendingBlock.add(dateStr);
      }
    });
  }

  bool get _hasChanges => _pendingBlock.isNotEmpty || _pendingUnblock.isNotEmpty;

  Future<void> _save() async {
    if (!_hasChanges) return;
    setState(() => _saving = true);
    try {
      await ref.read(hostRepositoryProvider).updateAvailability(
            listingId: widget.listing.id,
            blockedDates: _pendingBlock.toList(),
            unblockedDates: _pendingUnblock.toList(),
          );
      // Apply changes locally so the calendar updates without a full re-fetch
      setState(() {
        _serverBlocked.addAll(_pendingBlock);
        _serverBlocked.removeAll(_pendingUnblock);
        _pendingBlock.clear();
        _pendingUnblock.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listing.title),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Legend
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: kLight, label: 'Available'),
                SizedBox(width: 16),
                _LegendDot(color: Color(0xFFB0BEC5), label: 'Blocked'),
                SizedBox(width: 16),
                _LegendDot(color: Color(0xFFFFF176), label: 'Pending change'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(
                  '${_monthNames[_month]} $_year',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Day-of-week headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _dayLabels
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: kGrey),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Calendar grid
          if (_fetching)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildGrid(),
            ),

          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                '${_pendingBlock.length + _pendingUnblock.length} unsaved change${(_pendingBlock.length + _pendingUnblock.length) == 1 ? '' : 's'} — tap Save in the top right',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: kGrey),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final firstDay = DateTime(_year, _month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final now = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final dayNumber = index - startOffset + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final dateStr =
            '$_year-${_month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
        final isPast = DateTime(_year, _month, dayNumber)
            .isBefore(DateTime(now.year, now.month, now.day));
        final isServerBlocked = _serverBlocked.contains(dateStr);
        final isPendingBlock = _pendingBlock.contains(dateStr);
        final isPendingUnblock = _pendingUnblock.contains(dateStr);
        final isPending = isPendingBlock || isPendingUnblock;

        // Effective visual state
        final effectivelyBlocked =
            (isServerBlocked && !isPendingUnblock) || isPendingBlock;

        Color bgColor;
        if (isPending) {
          bgColor = const Color(0xFFFFF176); // yellow = unsaved
        } else if (effectivelyBlocked) {
          bgColor = const Color(0xFFB0BEC5); // grey = blocked
        } else if (isPast) {
          bgColor = Colors.transparent;
        } else {
          bgColor = kLight;
        }

        return GestureDetector(
          onTap: isPast ? null : () => _toggleDate(dateStr),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 12,
                  color: isPast ? kGrey : kDark,
                  decoration: effectivelyBlocked && !isPendingUnblock
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: kGrey.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: kGrey)),
      ],
    );
  }
}
