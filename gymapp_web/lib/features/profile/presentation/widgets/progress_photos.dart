import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';

import '../../../../l10n/app_localizations.dart';

/// A progress photo kept on the phone only (never uploaded).
class ProgressPhoto {
  const ProgressPhoto({required this.path, required this.takenAt});

  final String path;
  final DateTime takenAt;
}

/// Photos in the app's private folder; the file name carries the date.
abstract class ProgressPhotoStore {
  Future<List<ProgressPhoto>> list();
  Future<void> add(XFile picked);
  Future<void> delete(ProgressPhoto photo);
  Future<void> clearAll();
}

class FileProgressPhotoStore implements ProgressPhotoStore {
  Future<Directory> _dir() async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/progress_photos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static final _name = RegExp(r'^(\d{8})_(\d{6})\.jpg$');

  @override
  Future<List<ProgressPhoto>> list() async {
    final photos = <ProgressPhoto>[];
    await for (final f in (await _dir()).list()) {
      final m = _name.firstMatch(f.uri.pathSegments.last);
      if (f is! File || m == null) continue;
      final d = m.group(1)!, t = m.group(2)!;
      photos.add(ProgressPhoto(
        path: f.path,
        takenAt: DateTime(int.parse(d.substring(0, 4)), int.parse(d.substring(4, 6)), int.parse(d.substring(6)),
            int.parse(t.substring(0, 2)), int.parse(t.substring(2, 4)), int.parse(t.substring(4))),
      ));
    }
    return photos..sort((a, b) => a.takenAt.compareTo(b.takenAt));
  }

  @override
  Future<void> add(XFile picked) async {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    await picked.saveTo('${(await _dir()).path}/$stamp.jpg');
  }

  @override
  Future<void> delete(ProgressPhoto photo) => File(photo.path).delete();

  @override
  Future<void> clearAll() async {
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

/// Null on the web (no private file storage) — the card is not shown there.
final progressPhotoStoreProvider = Provider<ProgressPhotoStore?>((ref) => kIsWeb ? null : FileProgressPhotoStore());

final progressPhotosProvider = FutureProvider.autoDispose<List<ProgressPhoto>>(
  (ref) async => await ref.watch(progressPhotoStoreProvider)?.list() ?? const [],
);

/// "Progress photos": thumbnails, oldest → newest; tap to view or compare with the first.
class ProgressPhotosCard extends ConsumerWidget {
  const ProgressPhotosCard({super.key, this.picker});

  /// For tests.
  final Future<XFile?> Function(ImageSource source)? picker;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t.photoCamera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.photoGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await (picker ?? (s) => ImagePicker().pickImage(source: s, maxWidth: 1600, imageQuality: 85))(source);
    if (picked == null) return;
    await ref.read(progressPhotoStoreProvider)!.add(picked);
    ref.invalidate(progressPhotosProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(progressPhotoStoreProvider) == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final photos = ref.watch(progressPhotosProvider).value ?? const [];
    final locale = Localizations.localeOf(context).toString();

    return Card(
      key: const Key('photos.card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(t.progressPhotos, style: theme.textTheme.titleMedium)),
                IconButton(
                  key: const Key('photos.add'),
                  tooltip: t.addPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  onPressed: () => _add(context, ref),
                ),
              ],
            ),
            Text(t.progressPhotosPrivate, style: theme.textTheme.bodySmall),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  reverse: true, // newest first, on the right
                  itemCount: photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final photo = photos[photos.length - 1 - i];
                    return Semantics(
                      button: true,
                      label: t.photoOf(DateFormat.yMMMd(locale).format(photo.takenAt)),
                      child: InkWell(
                        key: Key('photo.$i'),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => PhotoViewerScreen(photos: photos, index: photos.indexOf(photo)),
                        )),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(photo.path), width: 72, height: 90, fit: BoxFit.cover, cacheWidth: 216),
                            ),
                            const SizedBox(height: 4),
                            Text(DateFormat.MMMd(locale).format(photo.takenAt), style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-size photo; "Compare" puts it next to the first one; delete.
class PhotoViewerScreen extends ConsumerStatefulWidget {
  const PhotoViewerScreen({super.key, required this.photos, required this.index});

  final List<ProgressPhoto> photos;
  final int index;

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late int _index = widget.index;
  late final _pages = PageController(initialPage: widget.index);
  bool _compare = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deletePhoto),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(progressPhotoStoreProvider)!.delete(widget.photos[_index]);
    ref.invalidate(progressPhotosProvider);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    String date(ProgressPhoto p) => DateFormat.yMMMd(locale).format(p.takenAt);
    final current = widget.photos[_index];
    final first = widget.photos.first;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(date(current)),
        actions: [
          if (widget.photos.length > 1)
            IconButton(
              key: const Key('photo.compare'),
              tooltip: t.comparePhotos,
              isSelected: _compare,
              icon: const Icon(Icons.compare),
              onPressed: () => setState(() => _compare = !_compare),
            ),
          IconButton(tooltip: t.delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: _compare
          ? Row(
              children: [
                for (final p in [first, current])
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: Image.file(File(p.path), fit: BoxFit.contain)),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(date(p), style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : PageView.builder(
              controller: _pages,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => InteractiveViewer(child: Center(child: Image.file(File(widget.photos[i].path)))),
            ),
    );
  }
}
