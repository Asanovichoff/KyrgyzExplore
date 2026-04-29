import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/listing_provider.dart';

class AvailabilityCalendar extends ConsumerStatefulWidget {
  const AvailabilityCalendar({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<AvailabilityCalendar> createState() =>
      _AvailabilityCalendarState();
}

class _AvailabilityCalendarState
    extends ConsumerState<AvailabilityCalendar> {
  late int _year;
  late int _month;

  static const _dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prev() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _next() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final availability = ref.watch(
      availabilityProvider((id: widget.listingId, year: _year, month: _month)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month navigation header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _prev,
            ),
            Text(
              '${_monthNames[_month]} $_year',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _next,
            ),
          ],
        ),
        // Day-of-week labels
        Row(
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
        const SizedBox(height: 4),
        availability.when(
          loading: () => _CalendarSkeleton(),
          error: (_, __) => const SizedBox(
            height: 80,
            child: Center(
              child: Text('Could not load availability',
                  style: TextStyle(color: kGrey)),
            ),
          ),
          data: (blockedDates) => _CalendarGrid(
            year: _year,
            month: _month,
            blockedDates: blockedDates.toSet(),
          ),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.blockedDates,
  });

  final int year;
  final int month;
  final Set<String> blockedDates;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    // Monday = 1 ... Sunday = 7; offset to make Monday column 0
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

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
            '$year-${month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
        final isBlocked = blockedDates.contains(dateStr);
        final isPast = DateTime(year, month, dayNumber)
            .isBefore(DateTime.now().subtract(const Duration(days: 1)));

        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isBlocked
                ? Colors.grey.shade300
                : isPast
                    ? Colors.transparent
                    : kLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 12,
                color: isBlocked || isPast ? kGrey : kDark,
                decoration:
                    isBlocked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CalendarSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: 35,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
