import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../explore/models/listing_model.dart';
import '../providers/host_provider.dart';
import '../repositories/host_repository.dart';

class CreateEditListingScreen extends ConsumerStatefulWidget {
  const CreateEditListingScreen({super.key, this.listing});

  // null = create mode, non-null = edit mode
  final ListingModel? listing;

  @override
  ConsumerState<CreateEditListingScreen> createState() =>
      _CreateEditListingScreenState();
}

class _CreateEditListingScreenState
    extends ConsumerState<CreateEditListingScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _currency;
  late final TextEditingController _maxGuests;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _lat;
  late final TextEditingController _lon;

  String _type = 'HOUSE';
  bool _saving = false;
  bool _locating = false;
  String? _error;

  List<ListingImageModel> _existingImages = [];
  final List<XFile> _pendingImages = [];
  final Map<int, bool> _uploading = {};

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _type = l?.type ?? 'HOUSE';
    _title = TextEditingController(text: l?.title ?? '');
    _description = TextEditingController(text: l?.description ?? '');
    _price = TextEditingController(
        text: l != null ? l.pricePerUnit.toStringAsFixed(0) : '');
    _currency = TextEditingController(text: l?.currency ?? 'KGS');
    _maxGuests = TextEditingController(
        text: (l?.maxGuests != null && l!.maxGuests > 0)
            ? '${l.maxGuests}'
            : '');
    _address = TextEditingController(text: l?.address ?? '');
    _city = TextEditingController(text: l?.city ?? '');
    _lat = TextEditingController(
        text: l?.latitude?.toStringAsFixed(6) ?? '');
    _lon = TextEditingController(
        text: l?.longitude?.toStringAsFixed(6) ?? '');
    _existingImages = List.from(l?.images ?? []);
  }

  @override
  void dispose() {
    for (final c in [
      _title, _description, _price, _currency,
      _maxGuests, _address, _city, _lat, _lon,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isEdit => widget.listing != null;

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat.text = pos.latitude.toStringAsFixed(6);
        _lon.text = pos.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _pendingImages.add(file));
  }

  Future<void> _uploadPendingImages(String listingId) async {
    final repo = ref.read(hostRepositoryProvider);
    for (int i = 0; i < _pendingImages.length; i++) {
      setState(() => _uploading[i] = true);
      try {
        final bytes = await _pendingImages[i].readAsBytes();
        final presign = await repo.presignImage(listingId);
        await repo.uploadToS3(presign.uploadUrl, bytes);
        await repo.confirmImage(listingId, presign.s3Key);
      } finally {
        if (mounted) setState(() => _uploading.remove(i));
      }
    }
    _pendingImages.clear();
  }

  Future<void> _deleteExistingImage(ListingImageModel img) async {
    if (!_isEdit) return;
    try {
      await ref
          .read(hostRepositoryProvider)
          .deleteImage(widget.listing!.id, img.id);
      setState(() => _existingImages.remove(img));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete image: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final data = CreateListingData(
        type: _type,
        title: _title.text.trim(),
        description: _description.text.trim(),
        pricePerUnit: double.parse(_price.text.trim()),
        latitude: double.parse(_lat.text.trim()),
        longitude: double.parse(_lon.text.trim()),
        address: _address.text.trim(),
        city: _city.text.trim(),
        currency: _currency.text.trim().isEmpty ? 'KGS' : _currency.text.trim(),
        maxGuests: _maxGuests.text.trim().isEmpty
            ? null
            : int.tryParse(_maxGuests.text.trim()),
      );

      final repo = ref.read(hostRepositoryProvider);
      final String listingId;
      if (_isEdit) {
        await repo.update(widget.listing!.id, data);
        listingId = widget.listing!.id;
      } else {
        final created = await repo.create(data);
        listingId = created.id;
      }

      if (_pendingImages.isNotEmpty) {
        await _uploadPendingImages(listingId);
      }

      ref.invalidate(myListingsProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Listing updated!' : 'Listing created!'),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Listing' : 'New Listing'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Type ──────────────────────────────────────────────
              const _SectionLabel('Type'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'HOUSE',
                      label: Text('House'),
                      icon: Icon(Icons.house_outlined)),
                  ButtonSegment(
                      value: 'CAR',
                      label: Text('Car'),
                      icon: Icon(Icons.directions_car_outlined)),
                  ButtonSegment(
                      value: 'ACTIVITY',
                      label: Text('Activity'),
                      icon: Icon(Icons.hiking_outlined)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),

              const SizedBox(height: 20),

              // ── Basic info ────────────────────────────────────────
              const _SectionLabel('Basic info'),
              const SizedBox(height: 8),
              _Field(controller: _title, label: 'Title', validator: _required),
              const SizedBox(height: 12),
              _Field(
                controller: _description,
                label: 'Description',
                maxLines: 4,
                validator: _required,
              ),

              const SizedBox(height: 20),

              // ── Pricing ───────────────────────────────────────────
              const _SectionLabel('Pricing'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _Field(
                      controller: _price,
                      label: 'Price per night/day',
                      keyboardType: TextInputType.number,
                      validator: _requiredNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(controller: _currency, label: 'Currency'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _maxGuests,
                label: 'Max guests (optional)',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              // ── Location ──────────────────────────────────────────
              const _SectionLabel('Location'),
              const SizedBox(height: 8),
              _Field(
                controller: _address,
                label: 'Street address',
                validator: _required,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _city,
                label: 'City',
                validator: _required,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _lat,
                      label: 'Latitude',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: _requiredNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: _lon,
                      label: 'Longitude',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: _requiredNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _locating ? null : _useMyLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: const Text('Use my location'),
              ),

              const SizedBox(height: 20),

              // ── Photos ────────────────────────────────────────────
              const _SectionLabel('Photos'),
              const SizedBox(height: 8),
              _PhotoStrip(
                existingImages: _existingImages,
                pendingImages: _pendingImages,
                uploading: _uploading,
                onAdd: _pickImage,
                onDeleteExisting: _deleteExistingImage,
                onDeletePending: (i) =>
                    setState(() => _pendingImages.removeAt(i)),
              ),

              const SizedBox(height: 24),

              // ── Error ─────────────────────────────────────────────
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
                    style:
                        TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Save ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Create listing'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _requiredNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (double.tryParse(v.trim()) == null) return 'Must be a number';
    return null;
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.existingImages,
    required this.pendingImages,
    required this.uploading,
    required this.onAdd,
    required this.onDeleteExisting,
    required this.onDeletePending,
  });

  final List<ListingImageModel> existingImages;
  final List<XFile> pendingImages;
  final Map<int, bool> uploading;
  final VoidCallback onAdd;
  final void Function(ListingImageModel) onDeleteExisting;
  final void Function(int) onDeletePending;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...existingImages.map(
            (img) => _ImageTile(
              onDelete: () => onDeleteExisting(img),
              child: Image.network(img.url, fit: BoxFit.cover),
            ),
          ),
          ...List.generate(pendingImages.length, (i) {
            return _ImageTile(
              loading: uploading[i] == true,
              onDelete: uploading[i] == true ? null : () => onDeletePending(i),
              child: FutureBuilder<dynamic>(
                future: pendingImages[i].readAsBytes(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  return Image.memory(snap.data!, fit: BoxFit.cover);
                },
              ),
            );
          }),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: kLight,
                border: Border.all(color: kTeal),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: kTeal, size: 28),
                  SizedBox(height: 4),
                  Text('Add photo',
                      style: TextStyle(color: kTeal, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.child,
    this.onDelete,
    this.loading = false,
  });

  final Widget child;
  final VoidCallback? onDelete;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (loading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            if (!loading && onDelete != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
