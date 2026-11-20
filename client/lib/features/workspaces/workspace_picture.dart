import 'dart:async';
import 'dart:math' as math;

import 'package:casama_sdk/casama_sdk.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

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
import '../../ui/toast.dart';
import '../bots/bot_picture.dart' show clipboardPictureBytes, pickPicture;
import 'spaces.dart';

const _maxOriginalBytes = 3 * 1024 * 1024;
const _maxPickBytes = 20 * 1024 * 1024;

/// A workspace's picture held in memory while it uploads or until the server's copy takes over.
@immutable
class WorkspacePicturePreview {
  const WorkspacePicturePreview(this.bytes, {this.uploading = true, this.avatar});
  final Uint8List bytes;
  final bool uploading;
  final String? avatar;
}

class _WorkspacePicturePreviews extends Notifier<Map<String, WorkspacePicturePreview>> {
  @override
  Map<String, WorkspacePicturePreview> build() => const {};

  void set(String orgId, WorkspacePicturePreview? preview) {
    final next = Map<String, WorkspacePicturePreview>.of(state);
    if (preview == null) {
      next.remove(orgId);
    } else {
      next[orgId] = preview;
    }
    state = next;
  }
}

final workspacePicturePreviewProvider =
    NotifierProvider<_WorkspacePicturePreviews, Map<String, WorkspacePicturePreview>>(
      _WorkspacePicturePreviews.new,
    );

Uint8List? workspacePicturePreviewOf(WidgetRef ref, OrganizationWithRole org) {
  final p = ref.watch(workspacePicturePreviewProvider)[org.id];
  if (p == null) return null;
  if (p.avatar != null && p.avatar != org.avatarUrl) return null;
  return p.bytes;
}

final _recentWorkspacePicturesProvider = FutureProvider.autoDispose
    .family<List<BotPicture>, String>(
      (ref, orgId) => ref.watch(backendProvider).workspacePictures(orgId),
    );

final _candidateWorkspacePicturesProvider = FutureProvider.autoDispose
    .family<List<BotPicture>, String>(
      (ref, orgId) => ref.watch(backendProvider).workspacePictures(orgId, candidates: true),
    );

bool get _hasCamera =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

BotPictureCrop _toContractCrop(AvatarCrop c) => BotPictureCrop(
  x: c.x,
  y: c.y,
  scale: c.scale,
  rotation: c.turns,
  mirror: c.mirror,
  background: switch (c.background) {
    CropBackground.none => BotPictureCropBackgroundEnum.none,
    CropBackground.accent => BotPictureCropBackgroundEnum.bot,
    CropBackground.white => BotPictureCropBackgroundEnum.white,
    CropBackground.black => BotPictureCropBackgroundEnum.black,
  },
);

AvatarCrop _fromContractCrop(BotPictureCrop c) => AvatarCrop(
  x: c.x.toDouble(),
  y: c.y.toDouble(),
  scale: c.scale.toDouble(),
  turns: c.rotation,
  mirror: c.mirror,
  background: switch (c.background) {
    BotPictureCropBackgroundEnum.none => CropBackground.none,
    BotPictureCropBackgroundEnum.bot => CropBackground.accent,
    BotPictureCropBackgroundEnum.white => CropBackground.white,
    BotPictureCropBackgroundEnum.black => CropBackground.black,
  },
);

Uint8List? _originalFor(Uint8List? bytes) =>
    bytes == null || bytes.isEmpty || bytes.length > _maxOriginalBytes ? null : bytes;

List<Color> _workspaceAccent(BuildContext context, OrganizationWithRole org) {
  final raw = org.color;
  if (raw != null && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(raw)) {
    final c = Color(int.parse('ff${raw.substring(1)}', radix: 16));
    return [c, Color.lerp(c, context.colorScheme.secondary, 0.35)!];
  }
  return [context.colorScheme.primary, context.colorScheme.tertiary];
}

Uint8List? _checkSize(BuildContext context, Uint8List bytes) {
  if (bytes.isEmpty) return null;
  if (bytes.length > _maxPickBytes) {
    if (context.mounted) showError(context, context.l10n.cropTooBig);
    return null;
  }
  return bytes;
}

/// Crops [bytes] for [org] and uploads the result with optimistic preview and Undo.
Future<void> editAndUploadWorkspacePicture(
  BuildContext context,
  WidgetRef ref,
  OrganizationWithRole org,
  Uint8List bytes, {
  required String analyticsSource,
  AvatarCrop? initial,
}) async {
  final cropped = await showAvatarCropper(
    context,
    bytes: bytes,
    shape: AvatarShape.workspace,
    name: org.name,
    accent: _workspaceAccent(context, org),
    initial: initial,
  );
  if (cropped == null) {
    Analytics.log('workspace_picture_crop_cancelled', {'source': analyticsSource});
    return;
  }
  if (!context.mounted) return;
  await _upload(
    context,
    ref,
    org,
    cropped,
    original: _originalFor(bytes),
    analyticsSource: analyticsSource,
  );
}

Future<void> _upload(
  BuildContext context,
  WidgetRef ref,
  OrganizationWithRole org,
  CroppedAvatar cropped, {
  required Uint8List? original,
  required String analyticsSource,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final before = org.avatarUrl;
  final previews = ref.read(workspacePicturePreviewProvider.notifier);
  previews.set(org.id, WorkspacePicturePreview(cropped.png));
  try {
    final saved = await ref
        .read(backendProvider)
        .setWorkspacePicture(
          org.id,
          cropped.png,
          original: original,
          crop: original == null ? null : _toContractCrop(cropped.crop),
        );
    previews.set(
      org.id,
      WorkspacePicturePreview(cropped.png, uploading: false, avatar: saved.avatarUrl),
    );
    ref.invalidate(organizationsProvider);
    ref.invalidate(_recentWorkspacePicturesProvider(org.id));
    ref.invalidate(_candidateWorkspacePicturesProvider(org.id));
    HapticsHelper.success();
    Analytics.log('workspace_picture_set', {
      'source': analyticsSource,
      'transparent': cropped.transparent,
      'rotated': cropped.turned,
      'zoomed': cropped.zoomed,
    });
    if (!context.mounted) return;
    _undoToast(context, ref, org.id, before, context.l10n.botPictureUpdated);
  } catch (e) {
    previews.set(org.id, null);
    if (!context.mounted) return;
    final l10n = context.l10n;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      toastSnackBar(
        context,
        '${l10n.botPictureFailed}. ${errorText(context, e)}',
        kind: ToastKind.error,
        duration: const Duration(seconds: 12),
        action: SnackBarAction(
          label: l10n.tryAgain,
          onPressed: () {
            if (context.mounted) {
              unawaited(
                _upload(
                  context,
                  ref,
                  org,
                  cropped,
                  original: original,
                  analyticsSource: analyticsSource,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

void _undoToast(
  BuildContext context,
  WidgetRef ref,
  String orgId,
  String? before,
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
        onPressed: () => unawaited(_undo(context, ref, orgId, before)),
      ),
    ),
  );
}

Future<void> _undo(
  BuildContext context,
  WidgetRef ref,
  String orgId,
  String? before,
) async {
  final prev = BotPictureRef.parse(before);
  final saved = await runGuarded(
    context,
    () => prev != null
        ? ref.read(backendProvider).useWorkspacePicture(orgId, prev.id)
        : ref.read(backendProvider).removeWorkspacePicture(orgId),
  );
  if (saved == null) return;
  ref.read(workspacePicturePreviewProvider.notifier).set(orgId, null);
  ref.invalidate(organizationsProvider);
  ref.invalidate(_recentWorkspacePicturesProvider(orgId));
  Analytics.log('workspace_picture_undone', const {});
}

enum _WsAction { camera, library, paste, draw, remove }

/// Opens the workspace picture sheet: Recent, Camera, Library/Files, Paste, AI Draw, Re-crop, Remove.
Future<void> showWorkspacePictureSheet(
  BuildContext context,
  WidgetRef ref,
  OrganizationWithRole org,
) async {
  Uint8List? clipboard;
  try {
    clipboard = await clipboardPictureBytes();
  } catch (_) {}
  if (!context.mounted) return;
  final result = await showAdaptiveSheet<Object>(
    context: context,
    contentPadsBottom: true,
    builder: (_) => _WorkspacePictureSheet(org: org, hasClipboard: clipboard != null),
  );
  if (result == null || !context.mounted) return;
  switch (result) {
    case _WsAction.camera:
      final picked = await pickPicture(camera: true);
      if (picked != null && context.mounted) {
        final bytes = _checkSize(context, picked.bytes);
        if (bytes != null) {
          await editAndUploadWorkspacePicture(context, ref, org, bytes, analyticsSource: picked.source);
        }
      }
    case _WsAction.library:
      final picked = await pickPicture(camera: false);
      if (picked != null && context.mounted) {
        final bytes = _checkSize(context, picked.bytes);
        if (bytes != null) {
          await editAndUploadWorkspacePicture(context, ref, org, bytes, analyticsSource: picked.source);
        }
      }
    case _WsAction.paste:
      final bytes = clipboard ?? await clipboardPictureBytes();
      if (bytes != null && context.mounted) {
        await editAndUploadWorkspacePicture(context, ref, org, bytes, analyticsSource: 'paste');
      }
    case _WsAction.draw:
      await showWorkspacePictureDraw(context, ref, org);
    case (:final BotPicture picture, recrop: true):
      final original = await runGuarded(
        context,
        () => ref.read(backendProvider).workspacePictureOriginal(org.id, picture.id),
      );
      if (original != null && context.mounted) {
        await editAndUploadWorkspacePicture(
          context,
          ref,
          org,
          original,
          analyticsSource: 'recrop',
          initial: picture.crop == null ? null : _fromContractCrop(picture.crop!),
        );
      }
    case BotPicture():
      final before = org.avatarUrl;
      final saved = await runGuarded(
        context,
        () => ref.read(backendProvider).useWorkspacePicture(org.id, result.id),
      );
      if (saved == null) return;
      ref.read(workspacePicturePreviewProvider.notifier).set(org.id, null);
      ref.invalidate(organizationsProvider);
      ref.invalidate(_recentWorkspacePicturesProvider(org.id));
      HapticsHelper.success();
      Analytics.log('workspace_picture_set', {
        'source': 'recent',
        'transparent': false,
        'rotated': false,
        'zoomed': false,
      });
      if (context.mounted) {
        _undoToast(context, ref, org.id, before, context.l10n.botPictureUpdated);
      }
    case _WsAction.remove:
      final before = org.avatarUrl;
      final saved = await runGuarded(
        context,
        () => ref.read(backendProvider).removeWorkspacePicture(org.id),
      );
      if (saved == null) return;
      ref.read(workspacePicturePreviewProvider.notifier).set(org.id, null);
      ref.invalidate(organizationsProvider);
      ref.invalidate(_recentWorkspacePicturesProvider(org.id));
      HapticsHelper.success();
      Analytics.log('workspace_picture_removed', const {});
      if (context.mounted) {
        _undoToast(context, ref, org.id, before, context.l10n.botPictureRemoved);
      }
  }
}

class _WorkspacePictureSheet extends ConsumerWidget {
  const _WorkspacePictureSheet({required this.org, required this.hasClipboard});
  final OrganizationWithRole org;
  final bool hasClipboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final hasPicture = BotPictureRef.parse(org.avatarUrl) != null;
    final recent =
        ref.watch(_recentWorkspacePicturesProvider(org.id)).asData?.value ?? const <BotPicture>[];
    final current = recent.where((p) => p.inUse).firstOrNull;
    final others = [for (final p in recent) if (!p.inUse) p];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.xl,
        0,
        AppSpace.xl,
        BottomPadding.of(context, minimum: AppSpace.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SpaceAvatar(
              name: org.name,
              icon: org.icon,
              color: org.color,
              avatarUrl: org.avatarUrl,
              preview: workspacePicturePreviewOf(ref, org),
              size: 76,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            l10n.botPictureTitle(org.name),
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              l10n.botPictureRecent,
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: others.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
                itemBuilder: (context, i) {
                  final p = others[i];
                  return InkWell(
                    key: Key('workspacePictureRecent-${p.id}'),
                    borderRadius: BorderRadius.circular(52 * 0.30),
                    onTap: () {
                      HapticsHelper.selection();
                      Navigator.of(context).pop<Object>(p);
                    },
                    child: SpaceAvatar(
                      name: org.name,
                      color: org.color,
                      avatarUrl: p.avatarUrl,
                      size: 52,
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          GroupedCard(
            children: [
              if (_hasCamera)
                GroupedTile(
                  key: const Key('workspacePictureCamera'),
                  icon: LucideIcons.camera,
                  title: l10n.photoTake,
                  onTap: () => Navigator.of(context).pop<Object>(_WsAction.camera),
                ),
              GroupedTile(
                key: const Key('workspacePictureLibrary'),
                icon: LucideIcons.image,
                title: l10n.photoChoose,
                onTap: () => Navigator.of(context).pop<Object>(_WsAction.library),
              ),
              if (hasClipboard)
                GroupedTile(
                  key: const Key('workspacePicturePaste'),
                  icon: LucideIcons.clipboardPaste,
                  title: l10n.botPicturePaste,
                  onTap: () => Navigator.of(context).pop<Object>(_WsAction.paste),
                ),
              GroupedTile(
                key: const Key('workspacePictureDraw'),
                icon: LucideIcons.sparkles,
                title: l10n.botPictureDraw,
                subtitle: l10n.botPictureDrawHelp,
                onTap: () => Navigator.of(context).pop<Object>(_WsAction.draw),
              ),
              if (current != null && current.hasOriginal)
                GroupedTile(
                  key: const Key('workspacePictureRecrop'),
                  icon: LucideIcons.crop,
                  title: l10n.botPictureRecrop,
                  onTap: () => Navigator.of(context).pop<Object>((picture: current, recrop: true)),
                ),
              if (hasPicture)
                GroupedTile(
                  key: const Key('workspacePictureRemove'),
                  icon: LucideIcons.trash2,
                  title: l10n.botPictureRemove,
                  onTap: () => Navigator.of(context).pop<Object>(_WsAction.remove),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Make one with AI ---------------------------------------------------------------------------

typedef _Style = ({
  BotPictureStyle style,
  IconData icon,
  String Function(BuildContext) label,
});

final List<_Style> _styles = [
  (style: BotPictureStyle.cloud, icon: LucideIcons.cloud, label: (c) => c.l10n.botDrawStyleCloud),
  (style: BotPictureStyle.soft3d, icon: LucideIcons.box, label: (c) => c.l10n.botDrawStyleSoft3d),
  (
    style: BotPictureStyle.watercolor,
    icon: LucideIcons.brush,
    label: (c) => c.l10n.botDrawStyleWatercolor,
  ),
  (style: BotPictureStyle.flat, icon: LucideIcons.shapes, label: (c) => c.l10n.botDrawStyleFlat),
  (
    style: BotPictureStyle.pixel,
    icon: LucideIcons.grid3x3,
    label: (c) => c.l10n.botDrawStylePixel,
  ),
  (style: BotPictureStyle.line, icon: LucideIcons.penLine, label: (c) => c.l10n.botDrawStyleLine),
  (style: BotPictureStyle.photo, icon: LucideIcons.camera, label: (c) => c.l10n.botDrawStylePhoto),
];

Future<void> showWorkspacePictureDraw(
  BuildContext context,
  WidgetRef ref,
  OrganizationWithRole org,
) async {
  final chosen = await showAdaptiveSheet<BotPicture>(
    context: context,
    contentPadsBottom: true,
    builder: (_) => _WorkspaceDrawSheet(org: org),
  );
  if (chosen == null || !context.mounted) return;
  Uint8List? previewPng;
  if (chosen.hasOriginal) {
    final original = await runGuarded(
      context,
      () => ref.read(backendProvider).workspacePictureOriginal(org.id, chosen.id),
    );
    if (original == null || !context.mounted) return;
    final cropped = await showAvatarCropper(
      context,
      bytes: original,
      shape: AvatarShape.workspace,
      name: org.name,
      accent: _workspaceAccent(context, org),
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
        org,
        cropped,
        original: _originalFor(original),
        analyticsSource: 'generated',
      );
      return;
    }
    previewPng = cropped.png;
  }
  final before = org.avatarUrl;
  if (previewPng != null) {
    ref
        .read(workspacePicturePreviewProvider.notifier)
        .set(org.id, WorkspacePicturePreview(previewPng));
  }
  final saved = await runGuarded(
    context,
    () => ref.read(backendProvider).useWorkspacePicture(org.id, chosen.id),
  );
  if (saved == null) {
    if (previewPng != null) {
      ref.read(workspacePicturePreviewProvider.notifier).set(org.id, null);
    }
    return;
  }
  if (previewPng != null) {
    ref
        .read(workspacePicturePreviewProvider.notifier)
        .set(
          org.id,
          WorkspacePicturePreview(previewPng, uploading: false, avatar: saved.avatarUrl),
        );
  }
  ref.invalidate(organizationsProvider);
  ref.invalidate(_recentWorkspacePicturesProvider(org.id));
  ref.invalidate(_candidateWorkspacePicturesProvider(org.id));
  HapticsHelper.success();
  Analytics.log('workspace_picture_set', {
    'source': 'generated',
    'transparent': false,
    'rotated': false,
    'zoomed': false,
  });
  if (context.mounted) {
    _undoToast(context, ref, org.id, before, context.l10n.botPictureUpdated);
  }
}

class _WorkspaceDrawSheet extends ConsumerStatefulWidget {
  const _WorkspaceDrawSheet({required this.org});
  final OrganizationWithRole org;

  @override
  ConsumerState<_WorkspaceDrawSheet> createState() => _WorkspaceDrawSheetState();
}

class _WorkspaceDrawSheetState extends ConsumerState<_WorkspaceDrawSheet> {
  var _style = BotPictureStyle.flat;
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
          .drawWorkspacePictures(
            widget.org.id,
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
    final saved =
        ref.watch(_candidateWorkspacePicturesProvider(widget.org.id)).asData?.value ??
        const <BotPicture>[];
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
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                l10n.botDrawTitle(widget.org.name),
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
                        key: Key('workspaceDrawStyle-${s.style.value}'),
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
                  key: const Key('workspaceDrawDescribe'),
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
                  key: const Key('workspaceDrawMake'),
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
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
                      final side = math.min(220.0, (c.maxWidth - AppSpace.md) / 2);
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
                                  radius: side * 0.30,
                                ),
                              ),
                          for (final p in pictures)
                            Semantics(
                              button: true,
                              label: l10n.botDrawPick,
                              child: InkWell(
                                key: Key('workspaceDrawn-${p.id}'),
                                borderRadius: BorderRadius.circular(side * 0.30),
                                onTap: () {
                                  HapticsHelper.selection();
                                  Navigator.of(context).pop(p);
                                },
                                child: SpaceAvatar(
                                  name: widget.org.name,
                                  color: widget.org.color,
                                  avatarUrl: p.avatarUrl,
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

/// Editable workspace avatar for Workspace Settings: camera badge, drag-and-drop, and Cmd/Ctrl+V paste.
class EditableWorkspaceAvatar extends ConsumerStatefulWidget {
  const EditableWorkspaceAvatar({super.key, required this.org, this.size = 56});
  final OrganizationWithRole org;
  final double size;

  @override
  ConsumerState<EditableWorkspaceAvatar> createState() => _EditableWorkspaceAvatarState();
}

class _EditableWorkspaceAvatarState extends ConsumerState<EditableWorkspaceAvatar> {
  final _focus = FocusNode(debugLabel: 'workspacePicture');
  var _dragging = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final bytes = await clipboardPictureBytes();
    if (bytes == null || !mounted) return;
    await editAndUploadWorkspacePicture(context, ref, widget.org, bytes, analyticsSource: 'paste');
  }

  Future<void> _dropped(DropDoneDetails d) async {
    setState(() => _dragging = false);
    final file = d.files.firstOrNull;
    if (file == null || !mounted) return;
    final raw = await file.readAsBytes();
    if (!mounted) return;
    final bytes = _checkSize(context, raw);
    if (bytes == null) return;
    await editAndUploadWorkspacePicture(context, ref, widget.org, bytes, analyticsSource: 'drop');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final preview = ref.watch(workspacePicturePreviewProvider)[widget.org.id];
    final uploading = preview?.uploading ?? false;
    final badge = math.max(20.0, widget.size * 0.36);

    final avatar = Tooltip(
      message: context.l10n.botPictureChange(widget.org.name),
      child: InkWell(
        key: const Key('workspacePictureEdit'),
        borderRadius: BorderRadius.circular(widget.size * 0.30),
        onTap: () => showWorkspacePictureSheet(context, ref, widget.org),
        child: AnimatedScale(
          scale: _dragging ? 1.06 : 1,
          duration: AppMotion.of(context, AppMotion.fast),
          child: SizedBox.square(
            dimension: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SpaceAvatar(
                  name: widget.org.name,
                  icon: widget.org.icon,
                  color: widget.org.color,
                  avatarUrl: widget.org.avatarUrl,
                  preview: workspacePicturePreviewOf(ref, widget.org),
                  size: widget.size,
                ),
                if (uploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.size * 0.30),
                        border: Border.all(color: scheme.primary, width: 2.5),
                      ),
                    ),
                  ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: badge,
                    height: badge,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(LucideIcons.camera, size: badge * 0.56, color: scheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final pasteable = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): _paste,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): _paste,
      },
      child: Focus(focusNode: _focus, child: avatar),
    );

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: _dropped,
        child: pasteable,
      );
    }
    return pasteable;
  }
}
