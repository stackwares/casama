import 'dart:async';
import 'dart:math' as math;

import 'package:casama_sdk/casama_sdk.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pasteboard/pasteboard.dart';

import '../../core/analytics.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/avatar_cropper.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/form_sheet.dart';
import '../../ui/toast.dart';

/// Bot pictures in the app (docs/BOT-PICTURES-PLAN.md §2–§8): every way a picture comes in (camera,
/// photos, files, a drop, a paste, a chat picture, a drawn one) goes through the same cropper and
/// the same upload, which shows the new picture at once, offers Undo, and keeps the bytes for Try
/// again if the upload fails.

/// A picture cropped on this device: shown at once where it was made while it uploads, and after,
/// until the bot moves on to another picture, so the new picture never flickers.
@immutable
class BotPicturePreview {
  const BotPicturePreview(this.png, {this.uploading = true, this.avatar});
  final Uint8List png;
  final bool uploading;

  /// The bot's `avatar_url` once saved.
  final String? avatar;
}

class BotPicturePreviews extends Notifier<Map<String, BotPicturePreview>> {
  @override
  Map<String, BotPicturePreview> build() => const {};

  void set(String botId, BotPicturePreview? p) {
    final next = {...state};
    p == null ? next.remove(botId) : next[botId] = p;
    state = next;
  }
}

final botPicturePreviewProvider =
    NotifierProvider<BotPicturePreviews, Map<String, BotPicturePreview>>(
      BotPicturePreviews.new,
    );

/// The bytes to show for [bot] right now, if it has a fresh picture from this device.
Uint8List? botPicturePreviewOf(WidgetRef ref, Bot bot) {
  final p = ref.watch(botPicturePreviewProvider)[bot.id];
  if (p == null) return null;
  return p.uploading || p.avatar == bot.avatarUrl ? p.png : null;
}

bool get _hasCamera =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Where a picture came from, as analytics names it (catalog: bot_picture_set.source).
typedef PictureSource = String;

/// Asks the system for a picture: the camera or the photo library on phones, a file elsewhere.
/// Big enough to zoom into (2,048 px); phones shrink and re-encode larger photos themselves.
Future<({Uint8List bytes, PictureSource source})?> pickPicture({
  required bool camera,
  bool selfie = false,
}) async {
  final x = await ImagePicker().pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
    maxWidth: 2048,
    maxHeight: 2048,
    imageQuality: 92,
    requestFullMetadata: false,
  );
  if (x == null) return null;
  return (
    bytes: await x.readAsBytes(),
    source: camera ? 'camera' : (_hasCamera ? 'library' : 'file'),
  );
}

/// The original goes up with the crop (for Re-crop) when it's a JPEG, PNG or WebP of reasonable
/// size; anything else only loses Re-crop, not the picture.
Uint8List? _originalFor(Uint8List bytes) {
  if (bytes.length > 3_500_000 || bytes.length < 12) return null;
  final jpeg = bytes[0] == 0xff && bytes[1] == 0xd8;
  final png = bytes[0] == 0x89 && bytes[1] == 0x50;
  final webp = bytes[0] == 0x52 && bytes[8] == 0x57;
  return jpeg || png || webp ? bytes : null;
}

AvatarCrop? _fromApi(BotPictureCrop? c) => c == null
    ? null
    : AvatarCrop(
        x: c.x.toDouble(),
        y: c.y.toDouble(),
        scale: c.scale.toDouble(),
        turns: c.rotation,
        mirror: c.mirror,
        background: switch (c.background) {
          BotPictureCropBackgroundEnum.bot => CropBackground.accent,
          BotPictureCropBackgroundEnum.white => CropBackground.white,
          BotPictureCropBackgroundEnum.black => CropBackground.black,
          _ => CropBackground.none,
        },
      );

BotPictureCrop _toApi(AvatarCrop c) => BotPictureCrop(
  x: c.x.clamp(-10.0, 10.0),
  y: c.y.clamp(-10.0, 10.0),
  scale: c.scale.clamp(0.01, 100.0),
  rotation: c.turns % 4,
  mirror: c.mirror,
  background: switch (c.background) {
    CropBackground.accent => BotPictureCropBackgroundEnum.bot,
    CropBackground.white => BotPictureCropBackgroundEnum.white,
    CropBackground.black => BotPictureCropBackgroundEnum.black,
    CropBackground.none => BotPictureCropBackgroundEnum.none,
  },
);

/// Crops [bytes] for [bot] and makes it the bot's picture. [onAvatar] hears the bot's new
/// `avatar_url` (a screen with unsaved edits keeps it in step). Returns whether it was used.
Future<bool> cropAndSetBotPicture(
  BuildContext context,
  WidgetRef ref,
  Bot bot,
  Uint8List bytes, {
  required PictureSource source,
  AvatarCrop? initial,
  ValueChanged<String?>? onAvatar,
}) async {
  final cropped = await showAvatarCropper(
    context,
    bytes: bytes,
    shape: AvatarShape.bot,
    name: bot.name,
    accent: botPalette(bot.name),
    initial: initial,
  );
  if (cropped == null) {
    Analytics.log('bot_picture_crop_cancelled', {'source': source});
    return false;
  }
  if (!context.mounted) return false;
  await _upload(
    context,
    ref,
    bot,
    cropped,
    original: _originalFor(bytes),
    source: source,
    onAvatar: onAvatar,
  );
  return true;
}

Future<void> _upload(
  BuildContext context,
  WidgetRef ref,
  Bot bot,
  CroppedAvatar cropped, {
  required Uint8List? original,
  required PictureSource source,
  ValueChanged<String?>? onAvatar,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final previews = ref.read(botPicturePreviewProvider.notifier);
  final backend = ref.read(backendProvider);
  final before = bot.avatarUrl;
  previews.set(bot.id, BotPicturePreview(cropped.png));
  try {
    final saved = await backend.setBotPicture(
      bot.id,
      cropped.png,
      original: original,
      crop: _toApi(cropped.crop),
      source: source == 'chat' ? 'chat' : 'upload',
    );
    previews.set(
      bot.id,
      BotPicturePreview(cropped.png, uploading: false, avatar: saved.avatarUrl),
    );
    ref.read(botsProvider.notifier).put(saved);
    onAvatar?.call(saved.avatarUrl);
    HapticsHelper.success();
    Analytics.log('bot_picture_set', {
      'source': source,
      'transparent': cropped.transparent,
      'rotated': cropped.turned,
      'zoomed': cropped.zoomed,
    });
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      toastSnackBar(
        context,
        l10n.botPictureUpdated,
        kind: ToastKind.success,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => unawaited(_undo(ref, saved, before, onAvatar)),
        ),
      ),
    );
  } catch (e) {
    previews.set(bot.id, null);
    HapticsHelper.error();
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      toastSnackBar(
        context,
        '${l10n.botPictureFailed}. ${errorText(context, e)}',
        kind: ToastKind.error,
        duration: const Duration(seconds: 12),
        // The cropped picture is still here: no need to pick and crop again.
        action: SnackBarAction(
          label: l10n.retry,
          onPressed: () {
            if (context.mounted) {
              unawaited(
                _upload(
                  context,
                  ref,
                  bot,
                  cropped,
                  original: original,
                  source: source,
                  onAvatar: onAvatar,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

/// Puts the bot's previous look back: its previous picture, mascot or initials.
Future<void> _undo(
  WidgetRef ref,
  Bot now,
  String? before,
  ValueChanged<String?>? onAvatar,
) async {
  final backend = ref.read(backendProvider);
  final previous = BotPictureRef.parse(before);
  try {
    final Bot restored;
    if (previous != null) {
      restored = await backend.useBotPicture(now.id, previous.id);
    } else {
      await backend.updateBot(now.id, avatarUrl: before ?? '');
      restored = Bot.fromJson({...now.toJson(), 'avatar_url': before});
    }
    ref.read(botPicturePreviewProvider.notifier).set(now.id, null);
    ref.read(botsProvider.notifier).put(restored);
    onAvatar?.call(restored.avatarUrl);
    HapticsHelper.light();
    Analytics.log('bot_picture_undone', const {});
  } catch (_) {
    // The picture stays; the Recent row still has the old one.
  }
}

/// What the picture sheet asked for.
sealed class _Ask {
  const _Ask();
}

class _AskCamera extends _Ask {
  const _AskCamera();
}

class _AskLibrary extends _Ask {
  const _AskLibrary();
}

class _AskPaste extends _Ask {
  const _AskPaste(this.bytes);
  final Uint8List bytes;
}

class _AskDraw extends _Ask {
  const _AskDraw();
}

class _AskRecrop extends _Ask {
  const _AskRecrop(this.picture);
  final BotPicture picture;
}

class _AskUse extends _Ask {
  const _AskUse(this.picture);
  final BotPicture picture;
}

class _AskMascot extends _Ask {
  const _AskMascot();
}

class _AskRemove extends _Ask {
  const _AskRemove();
}

/// The bot's picture choices: its picture big, its recent pictures, and every way to get a new
/// one. [onMascot] scrolls the mascot picker into view ("Use a Mascot Instead").
Future<void> openBotPictureSheet(
  BuildContext context,
  WidgetRef ref,
  Bot bot, {
  ValueChanged<String?>? onAvatar,
  VoidCallback? onMascot,
}) async {
  final clip = await readClipboardPicture();
  if (!context.mounted) return;
  final ask = await showAdaptiveSheet<_Ask>(
    context: context,
    contentPadsBottom: true,
    dialogMaxWidth: 480,
    builder: (_) => _PictureSheet(
      botId: bot.id,
      clipboard: clip,
      canMascot: onMascot != null,
    ),
  );
  if (ask == null || !context.mounted) return;
  final fresh = ref.read(botProvider(bot.id)) ?? bot;
  switch (ask) {
    case _AskCamera() || _AskLibrary():
      final picked = await runGuarded(
        context,
        () => pickPicture(camera: ask is _AskCamera),
      );
      if (picked == null || !context.mounted) return;
      await cropAndSetBotPicture(
        context,
        ref,
        fresh,
        picked.bytes,
        source: picked.source,
        onAvatar: onAvatar,
      );
    case _AskPaste(:final bytes):
      await cropAndSetBotPicture(
        context,
        ref,
        fresh,
        bytes,
        source: 'paste',
        onAvatar: onAvatar,
      );
    case _AskDraw():
      await showBotPictureDraw(context, ref, fresh, onAvatar: onAvatar);
    case _AskRecrop(:final picture):
      final original = await runGuarded(
        context,
        () =>
            ref.read(backendProvider).botPictureOriginal(fresh.id, picture.id),
      );
      if (original == null || !context.mounted) return;
      await cropAndSetBotPicture(
        context,
        ref,
        fresh,
        original,
        source: 'recrop',
        initial: _fromApi(picture.crop),
        onAvatar: onAvatar,
      );
    case _AskUse(:final picture):
      final before = fresh.avatarUrl;
      final saved = await runGuarded(
        context,
        () => ref.read(backendProvider).useBotPicture(fresh.id, picture.id),
      );
      if (saved == null || !context.mounted) return;
      ref.read(botPicturePreviewProvider.notifier).set(fresh.id, null);
      ref.read(botsProvider.notifier).put(saved);
      onAvatar?.call(saved.avatarUrl);
      HapticsHelper.success();
      Analytics.log('bot_picture_set', {
        'source': 'recent',
        'transparent': false,
        'rotated': false,
        'zoomed': false,
      });
      _undoToast(
        context,
        ref,
        saved,
        before,
        onAvatar,
        context.l10n.botPictureUpdated,
      );
    case _AskMascot():
      onMascot?.call();
    case _AskRemove():
      final before = fresh.avatarUrl;
      final saved = await runGuarded(
        context,
        () => ref.read(backendProvider).removeBotPicture(fresh.id),
      );
      if (saved == null || !context.mounted) return;
      ref.read(botPicturePreviewProvider.notifier).set(fresh.id, null);
      ref.read(botsProvider.notifier).put(saved);
      onAvatar?.call(saved.avatarUrl);
      HapticsHelper.light();
      Analytics.log('bot_picture_removed', {
        'to': saved.avatarUrl == null ? 'initials' : 'mascot',
      });
      _undoToast(
        context,
        ref,
        saved,
        before,
        onAvatar,
        context.l10n.botPictureRemoved,
      );
  }
}

void _undoToast(
  BuildContext context,
  WidgetRef ref,
  Bot saved,
  String? before,
  ValueChanged<String?>? onAvatar,
  String message,
) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    toastSnackBar(
      context,
      message,
      kind: ToastKind.success,
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: context.l10n.undo,
        onPressed: () => unawaited(_undo(ref, saved, before, onAvatar)),
      ),
    ),
  );
}

/// A picture on the clipboard, or null (no picture, or a platform without clipboard pictures).
/// Replaced in tests.
@visibleForTesting
Future<Uint8List?> Function() readClipboardPicture = () async {
  try {
    final bytes = await Pasteboard.image;
    return bytes == null || bytes.isEmpty ? null : bytes;
  } catch (_) {
    return null;
  }
};

class _PictureSheet extends ConsumerWidget {
  const _PictureSheet({
    required this.botId,
    required this.clipboard,
    required this.canMascot,
  });
  final String botId;
  final Uint8List? clipboard;
  final bool canMascot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final bot = ref.watch(botProvider(botId));
    if (bot == null) return const SizedBox(height: 200);
    final current = BotPictureRef.parse(bot.avatarUrl);
    final pictures = ref.watch(_recentPicturesProvider(botId));
    final recent = pictures.value ?? const <BotPicture>[];
    final inUse = recent.where((p) => p.inUse).firstOrNull;
    void ask(_Ask a) {
      HapticsHelper.selection();
      Navigator.of(context).pop(a);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.xl,
        0,
        AppSpace.xl,
        BottomPadding.of(context, minimum: AppSpace.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: BotAvatar(
              name: bot.name,
              avatar: bot.avatarUrl,
              preview: botPicturePreviewOf(ref, bot),
              size: 96,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            l10n.botPictureTitle(bot.name),
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          // Recent pictures: one tap back to any of them.
          AnimatedSize(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.curve,
            child: recent.where((p) => !p.inUse).isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpace.xs,
                      children: [
                        Text(
                          l10n.botPictureRecent,
                          style: context.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(
                          height: 56,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final p in recent.where((p) => !p.inUse))
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: AppSpace.sm,
                                  ),
                                  child: Semantics(
                                    button: true,
                                    label: l10n.botPictureRecent,
                                    child: InkWell(
                                      key: Key('botPictureRecent-${p.id}'),
                                      borderRadius: BorderRadius.circular(
                                        52 * 0.32,
                                      ),
                                      onTap: () => ask(_AskUse(p)),
                                      child: BotAvatar(
                                        name: bot.name,
                                        avatar: p.avatarUrl,
                                        size: 52,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpace.lg),
          GroupedCard(
            children: [
              if (_hasCamera)
                GroupedTile(
                  key: const Key('botPictureCamera'),
                  icon: LucideIcons.camera,
                  title: l10n.photoTake,
                  showChevron: false,
                  onTap: () => ask(const _AskCamera()),
                ),
              GroupedTile(
                key: const Key('botPictureLibrary'),
                icon: LucideIcons.image,
                title: l10n.photoChoose,
                showChevron: false,
                onTap: () => ask(const _AskLibrary()),
              ),
              if (clipboard != null)
                GroupedTile(
                  key: const Key('botPicturePaste'),
                  icon: LucideIcons.clipboardPaste,
                  title: l10n.botPicturePaste,
                  showChevron: false,
                  onTap: () => ask(_AskPaste(clipboard!)),
                ),
              GroupedTile(
                key: const Key('botPictureDraw'),
                icon: LucideIcons.sparkles,
                title: l10n.botPictureDraw,
                subtitle: l10n.botPictureDrawHelp,
                showChevron: false,
                onTap: () => ask(const _AskDraw()),
              ),
              if (current != null && inUse != null && inUse.hasOriginal)
                GroupedTile(
                  key: const Key('botPictureRecrop'),
                  icon: LucideIcons.crop,
                  title: l10n.botPictureRecrop,
                  showChevron: false,
                  onTap: () => ask(_AskRecrop(inUse)),
                ),
              if (canMascot)
                GroupedTile(
                  key: const Key('botPictureMascot'),
                  icon: LucideIcons.cloud,
                  title: l10n.botPictureMascot,
                  showChevron: false,
                  onTap: () => ask(const _AskMascot()),
                ),
              if (current != null)
                GroupedTile(
                  key: const Key('botPictureRemove'),
                  icon: LucideIcons.trash2,
                  title: l10n.botPictureRemove,
                  destructive: true,
                  showChevron: false,
                  onTap: () => ask(const _AskRemove()),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

final _recentPicturesProvider = FutureProvider.autoDispose
    .family<List<BotPicture>, String>(
      (ref, botId) => ref.watch(backendProvider).botPictures(botId),
    );

final _candidatePicturesProvider = FutureProvider.autoDispose
    .family<List<BotPicture>, String>(
      (ref, botId) =>
          ref.watch(backendProvider).botPictures(botId, candidates: true),
    );

// --- Make one with AI (§8) ---------------------------------------------------------------------

typedef _Style = ({
  BotPictureStyle style,
  IconData icon,
  String Function(BuildContext) label,
});

final List<_Style> _styles = [
  (
    style: BotPictureStyle.cloud,
    icon: LucideIcons.cloud,
    label: (c) => c.l10n.botDrawStyleCloud,
  ),
  (
    style: BotPictureStyle.soft3d,
    icon: LucideIcons.box,
    label: (c) => c.l10n.botDrawStyleSoft3d,
  ),
  (
    style: BotPictureStyle.watercolor,
    icon: LucideIcons.brush,
    label: (c) => c.l10n.botDrawStyleWatercolor,
  ),
  (
    style: BotPictureStyle.flat,
    icon: LucideIcons.shapes,
    label: (c) => c.l10n.botDrawStyleFlat,
  ),
  (
    style: BotPictureStyle.pixel,
    icon: LucideIcons.grid3x3,
    label: (c) => c.l10n.botDrawStylePixel,
  ),
  (
    style: BotPictureStyle.line,
    icon: LucideIcons.penLine,
    label: (c) => c.l10n.botDrawStyleLine,
  ),
  (
    style: BotPictureStyle.photo,
    icon: LucideIcons.camera,
    label: (c) => c.l10n.botDrawStylePhoto,
  ),
];

/// "Make one with AI": pick a look, say what it shows (or not), get two to choose from.
Future<void> showBotPictureDraw(
  BuildContext context,
  WidgetRef ref,
  Bot bot, {
  ValueChanged<String?>? onAvatar,
}) async {
  final chosen = await showAdaptiveSheet<BotPicture>(
    context: context,
    contentPadsBottom: true,
    builder: (_) => _DrawSheet(bot: bot),
  );
  if (chosen == null || !context.mounted) return;
  Uint8List? previewPng;
  if (chosen.hasOriginal) {
    // Drawn pictures come centred; the cropper is there for a nudge. Done without changes just uses it.
    final original = await runGuarded(
      context,
      () => ref.read(backendProvider).botPictureOriginal(bot.id, chosen.id),
    );
    if (original == null || !context.mounted) return;
    final cropped = await showAvatarCropper(
      context,
      bytes: original,
      shape: AvatarShape.bot,
      name: bot.name,
      accent: botPalette(bot.name),
    );
    if (cropped == null || !context.mounted) return;
    final c = cropped.crop;
    final untouched =
        !cropped.zoomed &&
        !cropped.turned &&
        (c.x - 0.5).abs() < 0.01 &&
        (c.y - 0.5).abs() < 0.01;
    if (!untouched) {
      await _upload(
        context,
        ref,
        bot,
        cropped,
        original: _originalFor(original),
        source: 'generated',
        onAvatar: onAvatar,
      );
      ref.invalidate(_recentPicturesProvider(bot.id));
      ref.invalidate(_candidatePicturesProvider(bot.id));
      return;
    }
    previewPng = cropped.png;
  }
  final before = bot.avatarUrl;
  if (previewPng != null) {
    ref
        .read(botPicturePreviewProvider.notifier)
        .set(bot.id, BotPicturePreview(previewPng));
  }
  final saved = await runGuarded(
    context,
    () => ref.read(backendProvider).useBotPicture(bot.id, chosen.id),
  );
  if (saved == null) {
    if (previewPng != null) {
      ref.read(botPicturePreviewProvider.notifier).set(bot.id, null);
    }
    return;
  }
  if (previewPng != null) {
    ref
        .read(botPicturePreviewProvider.notifier)
        .set(
          bot.id,
          BotPicturePreview(
            previewPng,
            uploading: false,
            avatar: saved.avatarUrl,
          ),
        );
  }
  ref.read(botsProvider.notifier).put(saved);
  ref.invalidate(_recentPicturesProvider(bot.id));
  ref.invalidate(_candidatePicturesProvider(bot.id));
  onAvatar?.call(saved.avatarUrl);
  HapticsHelper.success();
  Analytics.log('bot_picture_set', {
    'source': 'generated',
    'transparent': false,
    'rotated': false,
    'zoomed': false,
  });
  if (context.mounted) {
    _undoToast(
      context,
      ref,
      saved,
      before,
      onAvatar,
      context.l10n.botPictureUpdated,
    );
  }
}

class _DrawSheet extends ConsumerStatefulWidget {
  const _DrawSheet({required this.bot});
  final Bot bot;

  @override
  ConsumerState<_DrawSheet> createState() => _DrawSheetState();
}

class _DrawSheetState extends ConsumerState<_DrawSheet> {
  var _style = BotPictureStyle.cloud;
  final _describe = TextEditingController();
  final _drawn = <BotPicture>[];
  var _busy = false;

  @override
  void dispose() {
    _describe.dispose();
    super.dispose();
  }

  Future<void> _make() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticsHelper.light();
    final made = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .drawBotPictures(
            widget.bot.id,
            style: _style,
            description: _describe.text,
          ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (made != null) _drawn.insertAll(0, made);
    });
    if (made != null) HapticsHelper.success();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final saved = ref.watch(_candidatePicturesProvider(widget.bot.id)).asData?.value ?? const <BotPicture>[];
    final seen = <String>{};
    final pictures = <BotPicture>[
      for (final p in [..._drawn, ...saved])
        if (seen.add(p.id)) p,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            0,
            AppSpace.xl,
            AppSpace.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                l10n.botDrawTitle(widget.bot.name),
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                l10n.botDrawIntro,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.xs,
              AppSpace.xl,
              BottomPadding.of(context, minimum: AppSpace.lg),
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: [
                  for (final s in _styles)
                    ChoiceChip(
                      key: Key('botDrawStyle-${s.style.value}'),
                      avatar: Icon(s.icon, size: 16),
                      label: Text(s.label(context)),
                      selected: _style == s.style,
                      showCheckmark: false,
                      onSelected: _busy
                          ? null
                          : (_) {
                              HapticsHelper.selection();
                              setState(() => _style = s.style);
                            },
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                key: const Key('botDrawDescribe'),
                controller: _describe,
                enabled: !_busy,
                maxLength: 400,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _make(),
                decoration: InputDecoration(
                  labelText: l10n.botDrawDescribe,
                  hintText: l10n.botDrawHint,
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              FilledButton.icon(
                key: const Key('botDrawMake'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: const StadiumBorder(),
                ),
                onPressed: _busy ? null : _make,
                icon: _busy
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const Icon(LucideIcons.sparkles, size: 18),
                label: Text(
                  _busy
                      ? l10n.botDrawWorking
                      : (pictures.isEmpty ? l10n.botDrawMake : l10n.botDrawMore),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.botDrawCost,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (_busy || pictures.isNotEmpty) ...[
                const SizedBox(height: AppSpace.lg),
                if (pictures.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: Text(
                      l10n.botDrawPick,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, c) {
                    final side = math.min(
                      220.0,
                      (c.maxWidth - AppSpace.md) / 2,
                    );
                    return Wrap(
                      spacing: AppSpace.md,
                      runSpacing: AppSpace.md,
                      children: [
                        if (_busy)
                          for (var i = 0; i < 2; i++)
                            SkeletonScope(
                              child: SkeletonBone(
                                width: side,
                                height: side,
                                radius: side * 0.32,
                              ),
                            ),
                        for (final p in pictures)
                          Semantics(
                            button: true,
                            label: l10n.botDrawPick,
                            child: InkWell(
                              key: Key('botDrawn-${p.id}'),
                              borderRadius: BorderRadius.circular(side * 0.32),
                              onTap: () {
                                HapticsHelper.selection();
                                Navigator.of(context).pop(p);
                              },
                              child: BotAvatar(
                                name: widget.bot.name,
                                avatar: p.avatarUrl,
                                size: side,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- the editable avatar -----------------------------------------------------------------------

/// The bot's big avatar where its picture is changed (the bot's profile): a camera badge, a ring
/// while a new picture uploads, a pop when it lands, a drop target for pictures dragged onto it
/// (desktop, web, iPad), and Cmd/Ctrl+V while it has focus.
class EditableBotAvatar extends ConsumerStatefulWidget {
  const EditableBotAvatar({
    super.key,
    required this.bot,
    required this.avatar,
    this.size = 112,
    this.ringColor,
    this.onAvatar,
    this.onMascot,
  });

  final Bot bot;

  /// What to show: the screen's own (perhaps unsaved) choice.
  final String? avatar;
  final double size;
  final Color? ringColor;
  final ValueChanged<String?>? onAvatar;
  final VoidCallback? onMascot;

  @override
  ConsumerState<EditableBotAvatar> createState() => _EditableBotAvatarState();
}

class _EditableBotAvatarState extends ConsumerState<EditableBotAvatar>
    with SingleTickerProviderStateMixin {
  var _dragging = false;
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  final _focus = FocusNode(debugLabel: 'botPicture');

  @override
  void dispose() {
    _pop.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open() => unawaited(
    openBotPictureSheet(
      context,
      ref,
      widget.bot,
      onAvatar: widget.onAvatar,
      onMascot: widget.onMascot,
    ),
  );

  Future<void> _dropped(DropDoneDetails d) async {
    setState(() => _dragging = false);
    final file = d.files.where((f) => _isPicture(f.name)).firstOrNull;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await cropAndSetBotPicture(
      context,
      ref,
      widget.bot,
      bytes,
      source: 'drop',
      onAvatar: widget.onAvatar,
    );
  }

  Future<void> _paste() async {
    final bytes = await readClipboardPicture();
    if (bytes == null || !mounted) return;
    await cropAndSetBotPicture(
      context,
      ref,
      widget.bot,
      bytes,
      source: 'paste',
      onAvatar: widget.onAvatar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final size = widget.size;
    final preview = ref.watch(botPicturePreviewProvider)[widget.bot.id];
    final showPreview =
        preview != null &&
        (preview.uploading || preview.avatar == widget.avatar);
    final uploading = preview?.uploading ?? false;
    // Pop when an upload lands.
    ref.listen(
      botPicturePreviewProvider.select((m) => m[widget.bot.id]?.uploading),
      (was, now) {
        if (was == true &&
            now == false &&
            !MediaQuery.disableAnimationsOf(context)) {
          _pop.forward(from: 0);
        }
      },
    );
    final badge = math.max(30.0, size * 0.3);
    Widget avatar = AnimatedBuilder(
      animation: _pop,
      builder: (context, child) {
        final t = _pop.value;
        final s = 1 + 0.06 * math.sin(t * math.pi);
        return Transform.scale(scale: _dragging ? 1.06 : s, child: child);
      },
      child: SizedBox(
        width: size + 10,
        height: size + 10,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            BotAvatar(
              name: widget.bot.name,
              avatar: widget.avatar,
              preview: showPreview ? preview.png : null,
              size: size,
              ringColor: widget.ringColor,
            ),
            if (uploading)
              SizedBox(
                width: size + 10,
                height: size + 10,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: scheme.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
            if (_dragging)
              IgnorePointer(
                child: Container(
                  width: size + 8,
                  height: size + 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      BotAvatar.radiusFor(size + 8),
                    ),
                    border: Border.all(color: scheme.primary, width: 2.5),
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
                ),
              ),
            PositionedDirectional(
              end: -2,
              bottom: -2,
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.ringColor ?? scheme.surface,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.camera,
                  size: badge * 0.46,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    avatar = Semantics(
      button: true,
      label: context.l10n.botPictureChange(widget.bot.name),
      child: Tooltip(
        message: context.l10n.botPictureChange(widget.bot.name),
        child: InkResponse(
          key: const Key('botPictureEdit'),
          focusNode: _focus,
          radius: size / 2 + 12,
          onTap: uploading ? null : _open,
          child: avatar,
        ),
      ),
    );
    avatar = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): () =>
            unawaited(_paste()),
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): () =>
            unawaited(_paste()),
      },
      child: avatar,
    );
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      avatar = DropTarget(
        onDragEntered: (_) {
          HapticsHelper.selection();
          setState(() => _dragging = true);
        },
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (d) => unawaited(_dropped(d)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            AnimatedSize(
              duration: AppMotion.of(context, AppMotion.fast),
              child: _dragging
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpace.xs),
                      child: Text(
                        context.l10n.botPictureDrop(widget.bot.name),
                        style: context.textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox(width: 0),
            ),
          ],
        ),
      );
    }
    return avatar;
  }
}

bool _isPicture(String name) {
  final n = name.toLowerCase();
  return const [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.heic',
    '.heif',
    '.bmp',
  ].any(n.endsWith);
}

// --- from a picture somewhere else (chat, Library) ---------------------------------------------

/// Offers [bytes] (a picture from a chat or the Library) as a bot's picture: straight to the
/// cropper when there's one bot, else asks which.
Future<void> useAsBotPicture(
  BuildContext context,
  WidgetRef ref,
  Uint8List bytes, {
  String? botId,
}) async {
  final bots = ref.read(botsProvider).value ?? const <Bot>[];
  Bot? bot = botId == null
      ? null
      : bots.where((b) => b.id == botId).firstOrNull;
  if (bot == null && bots.length == 1) bot = bots.first;
  if (bot == null) {
    if (bots.isEmpty) return;
    final pick = await showChoiceSheet<Bot>(
      context,
      icon: LucideIcons.imagePlus,
      title: context.l10n.botPictureWhichBot,
      choices: [
        for (final b in bots)
          Choice(
            key: Key('pictureForBot-${b.id}'),
            value: b,
            label: b.name,
            leading: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 32),
          ),
      ],
    );
    bot = pick?.value;
  }
  if (bot == null || !context.mounted) return;
  await cropAndSetBotPicture(context, ref, bot, bytes, source: 'chat');
}

// --- a bot being made --------------------------------------------------------------------------

/// A picture chosen for a bot that doesn't exist yet: cropped now, saved right after the bot is.
class NewBotPicture {
  const NewBotPicture({
    required this.bytes,
    required this.cropped,
    required this.source,
  });

  /// The picture as picked (Re-crop starts from it).
  final Uint8List bytes;
  final CroppedAvatar cropped;
  final PictureSource source;

  /// Saves it as [botId]'s picture; returns the bot with it.
  Future<Bot> save(WidgetRef ref, String botId) async {
    final saved = await ref
        .read(backendProvider)
        .setBotPicture(
          botId,
          cropped.png,
          original: _originalFor(bytes),
          crop: _toApi(cropped.crop),
        );
    Analytics.log('bot_picture_set', {
      'source': source,
      'transparent': cropped.transparent,
      'rotated': cropped.turned,
      'zoomed': cropped.zoomed,
    });
    return saved;
  }
}

/// Picks and crops a picture for a bot being made, or re-crops [current].
Future<NewBotPicture?> pickNewBotPicture(
  BuildContext context, {
  required String name,
  NewBotPicture? current,
}) async {
  final l10n = context.l10n;
  final clip = await readClipboardPicture();
  if (!context.mounted) return null;
  final choice = await showChoiceSheet<String>(
    context,
    icon: LucideIcons.imagePlus,
    title: l10n.botPictureTitle(name),
    choices: [
      if (_hasCamera)
        Choice(
          key: const Key('newPictureCamera'),
          value: 'camera',
          icon: LucideIcons.camera,
          label: l10n.photoTake,
        ),
      Choice(
        key: const Key('newPictureLibrary'),
        value: 'library',
        icon: LucideIcons.image,
        label: l10n.photoChoose,
      ),
      if (clip != null)
        Choice(
          key: const Key('newPicturePaste'),
          value: 'paste',
          icon: LucideIcons.clipboardPaste,
          label: l10n.botPicturePaste,
        ),
      if (current != null)
        Choice(
          key: const Key('newPictureRecrop'),
          value: 'recrop',
          icon: LucideIcons.crop,
          label: l10n.botPictureRecrop,
        ),
    ],
  );
  if (choice == null || !context.mounted) return null;
  final ({Uint8List bytes, PictureSource source})? picked =
      switch (choice.value) {
        'paste' => (bytes: clip!, source: 'paste'),
        'recrop' => (bytes: current!.bytes, source: current.source),
        _ => await runGuarded<({Uint8List bytes, PictureSource source})?>(
          context,
          () => pickPicture(camera: choice.value == 'camera'),
        ),
      };
  if (picked == null || !context.mounted) return null;
  final cropped = await showAvatarCropper(
    context,
    bytes: picked.bytes,
    shape: AvatarShape.bot,
    name: name,
    accent: botPalette(name),
    initial: choice.value == 'recrop' ? current!.cropped.crop : null,
  );
  if (cropped == null) {
    Analytics.log('bot_picture_crop_cancelled', {'source': picked.source});
    return null;
  }
  return NewBotPicture(
    bytes: picked.bytes,
    cropped: cropped,
    source: picked.source,
  );
}
