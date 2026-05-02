import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/listing_model.dart';

/// Horizontal scrollable row of image thumbnails for a listing form.
/// Shows existing (saved) images, pending (locally picked) images, and an
/// "Add photo" button.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({
    super.key,
    required this.existingImages,
    required this.pendingImages,
    required this.uploading,
    required this.onAdd,
    required this.onDeleteExisting,
    required this.onDeletePending,
  });

  final List<ListingImageModel> existingImages;
  final List<XFile> pendingImages;

  /// Keys are indices into [pendingImages]; true = upload in progress.
  final Map<int, bool> uploading;

  final VoidCallback onAdd;
  final void Function(ListingImageModel) onDeleteExisting;
  final void Function(int index) onDeletePending;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...existingImages.map(
            (img) => ImageTile(
              onDelete: () => onDeleteExisting(img),
              child: Image.network(img.url, fit: BoxFit.cover),
            ),
          ),
          ...List.generate(pendingImages.length, (i) {
            return ImageTile(
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

/// A fixed-size thumbnail tile used inside [PhotoStrip].
class ImageTile extends StatelessWidget {
  const ImageTile({
    super.key,
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
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
