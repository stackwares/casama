import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../ui/form_sheet.dart';
import '../../ui/person_avatar.dart';
import 'about_you_screen.dart';

/// The person's profile photo URL (D-202), or null when they have none.
String? myPhotoUrl(WidgetRef ref) {
  final id = ref.watch(aboutYouProvider).value?.photoId;
  return id == null ? null : ref.watch(backendProvider).photoUrl(id);
}

/// A big avatar with a camera badge; a tap offers take, choose, use the Google photo, or remove.
class ProfilePhotoEditor extends ConsumerStatefulWidget {
  const ProfilePhotoEditor({super.key, required this.label, this.size = 96});
  final String label;
  final double size;

  @override
  ConsumerState<ProfilePhotoEditor> createState() => _ProfilePhotoEditorState();
}

enum _PhotoAction { camera, gallery, google, remove }

class _ProfilePhotoEditorState extends ConsumerState<ProfilePhotoEditor> {
  var _busy = false;

  bool get _hasCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<void> _open() async {
    final l10n = context.l10n;
    final about = ref.read(aboutYouProvider).value;
    final action = (await showChoiceSheet<_PhotoAction>(
      context,
      icon: LucideIcons.camera,
      title: l10n.photoChange,
      choices: [
        if (_hasCamera) Choice(key: const Key('photoCamera'), value: _PhotoAction.camera, icon: LucideIcons.camera, label: l10n.photoTake),
        Choice(key: const Key('photoGallery'), value: _PhotoAction.gallery, icon: LucideIcons.image, label: l10n.photoChoose),
        if (about?.providerPhoto ?? false)
          Choice(key: const Key('photoGoogle'), value: _PhotoAction.google, icon: LucideIcons.circleUser, label: l10n.photoUseGoogle),
        if (about?.photoId != null)
          Choice(key: const Key('photoRemove'), value: _PhotoAction.remove, icon: LucideIcons.trash2, label: l10n.photoRemove, destructive: true),
      ],
    ))?.value;
    if (action == null || !mounted) return;
    final backend = ref.read(backendProvider);
    switch (action) {
      case _PhotoAction.camera || _PhotoAction.gallery:
        final x = await ImagePicker().pickImage(
          source: action == _PhotoAction.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          preferredCameraDevice: CameraDevice.front,
          // Phones shrink and compress the photo themselves; desktops hand back the file.
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
        if (x == null || !mounted) return;
        await _run(() async {
          final photo = await preparePhoto(await x.readAsBytes());
          if (photo == null) throw const PhotoUnreadable();
          return backend.setProfilePhoto(photo.bytes, photo.type);
        });
      case _PhotoAction.google:
        await _run(() => backend.importProfilePhoto(replace: true));
      case _PhotoAction.remove:
        await _run(backend.removeProfilePhoto);
    }
  }

  Future<void> _run(Future<AboutYouView> Function() change) async {
    setState(() => _busy = true);
    final l10n = context.l10n;
    final ok = await runGuarded(context, () async {
      try {
        await change();
      } on PhotoUnreadable {
        if (mounted) showError(context, l10n.photoUnreadable);
        return false;
      }
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      HapticsHelper.success();
      ref.invalidate(aboutYouProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final size = widget.size;
    return Semantics(
      button: true,
      label: context.l10n.photoChange,
      child: InkResponse(
        key: const Key('profilePhoto'),
        onTap: _busy ? null : _open,
        radius: size / 2 + 8,
        child: SizedBox(
          width: size + 8,
          height: size + 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PersonAvatar(
                label: widget.label,
                photoUrl: myPhotoUrl(ref),
                size: size,
              ),
              if (_busy)
                SizedBox(
                  width: size,
                  height: size,
                  child: const CircularProgressIndicator(strokeWidth: 3),
                ),
              PositionedDirectional(
                end: 0,
                bottom: 0,
                child: Container(
                  width: math.max(30, size * 0.32),
                  height: math.max(30, size * 0.32),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 3),
                  ),
                  child: Icon(
                    LucideIcons.camera,
                    size: math.max(14, size * 0.15),
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The picked file can't be read as a picture.
class PhotoUnreadable implements Exception {
  const PhotoUnreadable();
}

/// The type of a JPEG, PNG or WebP from its first bytes, or null.
String? sniffPhotoType(Uint8List b) {
  bool starts(List<int> sig, [int at = 0]) =>
      b.length >= at + sig.length &&
      [for (var i = 0; i < sig.length; i++) b[at + i] == sig[i]]
          .every((x) => x);
  if (starts([0xff, 0xd8, 0xff])) return 'image/jpeg';
  if (starts([0x89, 0x50, 0x4e, 0x47])) return 'image/png';
  if (starts('RIFF'.codeUnits) && starts('WEBP'.codeUnits, 8)) {
    return 'image/webp';
  }
  return null;
}

/// Ready to upload: a small JPEG, PNG or WebP goes as it is; anything bigger or in another format
/// (a desktop's full-size file, HEIC, GIF) is cropped to the middle square and redrawn as a
/// 384 px PNG. Null when it isn't a picture at all.
Future<({Uint8List bytes, String type})?> preparePhoto(
  Uint8List bytes, {
  int keepUnder = 400 * 1024,
  int side = 384,
}) async {
  final type = sniffPhotoType(bytes);
  if (type != null && bytes.length <= keepUnder) {
    return (bytes: bytes, type: type);
  }
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    final crop = math.min(image.width, image.height).toDouble();
    final src = Rect.fromCenter(
      center: Offset(image.width / 2, image.height / 2),
      width: crop,
      height: crop,
    );
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      src,
      Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final out = await recorder.endRecording().toImage(side, side);
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    out.dispose();
    if (data == null) return null;
    return (bytes: data.buffer.asUint8List(), type: 'image/png');
  } catch (_) {
    return null;
  }
}
