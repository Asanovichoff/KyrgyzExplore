import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  // Pre-selected location (passed when editing an existing listing).
  final LatLng? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Default to Bishkek city centre if no initial location is given.
  static const _bishkek = LatLng(42.8746, 74.5698);

  late LatLng _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial ?? _bishkek;
  }

  void _onTap(LatLng pos) => setState(() => _selected = pos);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: kTeal,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selected,
              zoom: 14,
            ),
            onTap: _onTap,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selected,
                draggable: true,
                onDragEnd: (pos) => setState(() => _selected = pos),
              ),
            },
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          // Instruction banner at the top
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Text(
                'Tap the map or drag the pin to set your listing location',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kDark),
              ),
            ),
          ),
          // Coordinates display at the bottom
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                'Lat: ${_selected.latitude.toStringAsFixed(6)}   '
                'Lon: ${_selected.longitude.toStringAsFixed(6)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: kGrey, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
