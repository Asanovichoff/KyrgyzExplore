import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/l10n/l10n_extension.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/models/listing_model.dart';
import '../../explore/providers/explore_provider.dart';
import '../models/listing_form_models.dart';
import '../providers/host_provider.dart';
import '../repositories/host_repository.dart';
import '../widgets/photo_strip.dart';

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
            SnackBar(content: Text(context.l10n.locationPermissionDenied)),
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
          SnackBar(content: Text(context.l10n.couldNotGetLocation)),
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
            SnackBar(content: Text(context.l10n.couldNotDeleteImage)));
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
      ref.invalidate(searchResultsProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? context.l10n.listingUpdated : context.l10n.listingCreated),
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
        title: Text(_isEdit ? context.l10n.editListing : context.l10n.newListing),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Type ──────────────────────────────────────────────
              _SectionLabel(context.l10n.typeSectionLabel),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                      value: 'HOUSE',
                      label: Text(context.l10n.typeHouse),
                      icon: const Icon(Icons.house_outlined)),
                  ButtonSegment(
                      value: 'CAR',
                      label: Text(context.l10n.typeCar),
                      icon: const Icon(Icons.directions_car_outlined)),
                  ButtonSegment(
                      value: 'ACTIVITY',
                      label: Text(context.l10n.typeActivity),
                      icon: const Icon(Icons.hiking_outlined)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),

              const SizedBox(height: 20),

              // ── Basic info ────────────────────────────────────────
              _SectionLabel(context.l10n.basicInfo),
              const SizedBox(height: 8),
              _Field(controller: _title, label: context.l10n.titleFieldLabel, validator: _required),
              const SizedBox(height: 12),
              _Field(
                controller: _description,
                label: context.l10n.descriptionFieldLabel,
                maxLines: 4,
                validator: _required,
              ),

              const SizedBox(height: 20),

              // ── Pricing ───────────────────────────────────────────
              _SectionLabel(context.l10n.pricingSection),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _Field(
                      controller: _price,
                      label: context.l10n.pricePerNightDay,
                      keyboardType: TextInputType.number,
                      validator: _requiredNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(controller: _currency, label: context.l10n.currencyLabel),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _maxGuests,
                label: context.l10n.maxGuestsOptional,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              // ── Location ──────────────────────────────────────────
              _SectionLabel(context.l10n.locationSection),
              const SizedBox(height: 8),
              _Field(
                controller: _address,
                label: context.l10n.streetAddress,
                validator: _required,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _city,
                label: context.l10n.cityLabel,
                validator: _required,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _lat,
                      label: context.l10n.latitudeLabel,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: _requiredNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: _lon,
                      label: context.l10n.longitudeLabel,
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
                label: Text(context.l10n.useMyLocation),
              ),

              const SizedBox(height: 20),

              // ── Photos ────────────────────────────────────────────
              _SectionLabel(context.l10n.photosSection),
              const SizedBox(height: 8),
              PhotoStrip(
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
                      : Text(_isEdit ? context.l10n.saveChanges : context.l10n.createListing),
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
      (v == null || v.trim().isEmpty) ? context.l10n.required : null;

  String? _requiredNumber(String? v) {
    if (v == null || v.trim().isEmpty) return context.l10n.required;
    if (double.tryParse(v.trim()) == null) return context.l10n.mustBeNumber;
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

