import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/search_params.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.current,
    required this.onApply,
  });

  final SearchParams current;
  final void Function(SearchParams) onApply;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _sort;
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  int? _minGuests;
  DateTime? _checkIn;
  DateTime? _checkOut;

  @override
  void initState() {
    super.initState();
    final p = widget.current;
    _sort = p.sort;
    _minPriceCtrl.text = p.minPrice?.toStringAsFixed(0) ?? '';
    _maxPriceCtrl.text = p.maxPrice?.toStringAsFixed(0) ?? '';
    _cityCtrl.text = p.city ?? '';
    _minGuests = p.minGuests;
    _checkIn = p.checkIn;
    _checkOut = p.checkOut;
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _sort = 'distance';
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      _cityCtrl.clear();
      _minGuests = null;
      _checkIn = null;
      _checkOut = null;
    });
  }

  void _apply() {
    final updated = widget.current.copyWith(
      sort: _sort,
      minPrice: _minPriceCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_minPriceCtrl.text.trim()),
      maxPrice: _maxPriceCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_maxPriceCtrl.text.trim()),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      minGuests: _minGuests,
      checkIn: _checkIn,
      checkOut: _checkOut,
      page: 0,
    );
    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final firstDate =
        isCheckIn ? now : (_checkIn ?? now).add(const Duration(days: 1));
    final initial = isCheckIn ? (_checkIn ?? now) : (_checkOut ?? firstDate);

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
        if (_checkOut != null && !_checkOut!.isAfter(picked)) {
          _checkOut = null;
        }
      } else {
        _checkOut = picked;
      }
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Text('Filters',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset all',
                      style: TextStyle(color: kGrey)),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // ── Sort ─────────────────────────────────────────────
                const _SectionLabel('Sort by'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: const [
                    ('distance', 'Nearest'),
                    ('price_asc', 'Price ↑'),
                    ('price_desc', 'Price ↓'),
                    ('rating', 'Top rated'),
                  ].map((entry) {
                    final (value, label) = entry;
                    return ChoiceChip(
                      label: Text(label),
                      selected: _sort == value,
                      selectedColor: kTeal.withValues(alpha: 0.15),
                      checkmarkColor: kTeal,
                      onSelected: (_) => setState(() => _sort = value),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Price ─────────────────────────────────────────────
                const _SectionLabel('Price per night/day (KGS)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('–', style: TextStyle(color: kGrey)),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _maxPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Guests ────────────────────────────────────────────
                const _SectionLabel('Minimum guests'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: (_minGuests ?? 0) > 1
                          ? () => setState(() => _minGuests = _minGuests! - 1)
                          : _minGuests == 1
                              ? () => setState(() => _minGuests = null)
                              : null,
                      color: kTeal,
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        _minGuests != null ? '$_minGuests' : 'Any',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: (_minGuests ?? 0) < 20
                          ? () =>
                              setState(() => _minGuests = (_minGuests ?? 0) + 1)
                          : null,
                      color: kTeal,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── City ──────────────────────────────────────────────
                const _SectionLabel('City'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Bishkek, Karakol',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Dates ─────────────────────────────────────────────
                const _SectionLabel('Availability'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DateTile(
                        label: 'Check-in',
                        value: _checkIn != null ? _fmtDate(_checkIn!) : null,
                        onTap: () => _pickDate(isCheckIn: true),
                        onClear: _checkIn != null
                            ? () => setState(() {
                                  _checkIn = null;
                                  _checkOut = null;
                                })
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateTile(
                        label: 'Check-out',
                        value: _checkOut != null ? _fmtDate(_checkOut!) : null,
                        onTap: _checkIn != null
                            ? () => _pickDate(isCheckIn: false)
                            : null,
                        onClear: _checkOut != null
                            ? () => setState(() => _checkOut = null)
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Apply button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  child: const Text('Apply filters'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: value != null ? kTeal : kGrey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: kGrey)),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Select',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: value != null ? kDark : kGrey,
                          fontWeight: value != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 14, color: kGrey),
              ),
          ],
        ),
      ),
    );
  }
}
