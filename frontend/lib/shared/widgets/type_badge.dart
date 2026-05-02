import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Displays a listing type (HOUSE / CAR / ACTIVITY) as a small badge.
///
/// Use [filled] = true for image overlays (white text on coloured background).
/// Use [filled] = false (default) for inline tags (coloured border + text).
class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type, this.filled = false});

  final String type;
  final bool filled;

  static const _labels = {
    'HOUSE': 'House',
    'CAR': 'Car',
    'ACTIVITY': 'Activity',
  };

  static const _colors = {
    'HOUSE': kNavy,
    'CAR': kTeal,
    'ACTIVITY': Color(0xFFE65100),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[type] ?? kNavy;
    final label = _labels[type] ?? type;

    if (filled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kLight,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
