import 'package:casama_sdk/casama_sdk.dart'
    show Bot, BotStatusEnum, Canvas, CanvasGrant, CanvasPlacement, CanvasPlacementPlatformEnum, CanvasStatusEnum, CanvasUpdateStatusEnum;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' hide Canvas;

import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../app_lock/app_lock.dart';
import 'canvas_sync.dart';
import 'canvas_view.dart';
import 'glance_sync.dart';
import 'widget_settings.dart';

/// The widgets, in the order the plan lists them (D-405 §0), with the Android provider each one is.
enum WidgetKind {
  needsYou('NeedsYouWidget'),
  bot('BotStatusWidget'),
  ask('AskWidget'),
  routines('RoutinesWidget'),
  today('TodayWidget'),
  brief('BriefWidget'),
  library('LibraryWidget'),
  tasks('TasksWidget'),
  credits('CreditsWidget'),
  // Bot widgets (docs/BOT-WIDGET-PLAN.md): what bots put there.
  canvas('CanvasWidget');

  const WidgetKind(this.androidProvider);
  final String androidProvider;

  String title(AppLocalizations l10n) => switch (this) {
    needsYou => l10n.widgetNeedsYou,
    bot => l10n.widgetNameBot,
    ask => l10n.widgetAsk,
    routines => l10n.widgetNameRoutines,
    today => l10n.widgetToday,
    brief => l10n.widgetBrief,
    library => l10n.widgetLibrary,
    tasks => l10n.widgetTasks,
    credits => l10n.widgetCredits,
    canvas => l10n.widgetNameCanvas,
  };

  String description(AppLocalizations l10n) => switch (this) {
    needsYou => l10n.widgetDescNeedsYou,
    bot => l10n.widgetDescBot,
    ask => l10n.widgetDescAsk,
    routines => l10n.widgetDescRoutines,
    today => l10n.widgetDescToday,
    brief => l10n.widgetDescBrief,
    library => l10n.widgetDescLibrary,
    tasks => l10n.widgetDescTasks,
    credits => l10n.widgetDescCredits,
    canvas => l10n.widgetDescCanvas,
  };
}

/// Whether this Android launcher lets the app place a widget (Android 8 and later, where the
/// launcher supports it). Overridden in tests.
final pinWidgetSupportedProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    return await HomeWidget.isRequestPinWidgetSupported() ?? false;
  } catch (_) {
    return false;
  }
});

/// Places a widget or a bot on the Home screen. Overridden in tests.
final widgetPinnerProvider = Provider<WidgetPinner>((ref) => const WidgetPinner());

class WidgetPinner {
  const WidgetPinner();
  Future<bool> pin(WidgetKind kind) => pinWidget(kind.androidProvider);
  Future<bool> pinBot(Bot bot) => pinBotShortcut(bot);
}

/// Settings → Widgets (D-405 §6.8): each widget with a small picture and how to add it, the
/// Lock Screen and controls on iPhone, **Show details in widgets**, and on Android a bot pinned to
/// the Home screen.
class WidgetsScreen extends ConsumerWidget {
  const WidgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final platform = kIsWeb ? null : defaultTargetPlatform;
    final android = platform == TargetPlatform.android;
    final ios = platform == TargetPlatform.iOS;
    final mac = platform == TargetPlatform.macOS;
    final canPin = android && (ref.watch(pinWidgetSupportedProvider).value ?? false);
    final bots = [
      for (final b in ref.watch(botsProvider).value ?? const <Bot>[])
        if (b.status != BotStatusEnum.disabled) b,
    ];
    return SubPage(
      title: l10n.widgetsTitle,
      children: [
        FormNote(l10n.widgetsIntro, icon: LucideIcons.layoutGrid),
        if (ios || mac || (android && !canPin)) ...[
          SectionHeader(title: l10n.widgetsHowToAdd),
          Text(
            ios ? l10n.widgetsHowToIos : (mac ? l10n.widgetsHowToMac : l10n.widgetsPinUnsupported),
            key: const Key('widgetsHowTo'),
            style: context.textTheme.bodyMedium,
          ),
        ],
        SectionHeader(title: l10n.widgetsTitle),
        for (final kind in WidgetKind.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _WidgetCard(kind: kind, canPin: canPin),
          ),
        const _FromYourBots(),
        if (ios) ...[
          SectionHeader(title: l10n.widgetsLockScreen),
          Text(l10n.widgetsLockScreenHelp, style: context.textTheme.bodyMedium),
          const SizedBox(height: AppSpace.sm),
          Text(l10n.widgetsControlsHelp, style: context.textTheme.bodyMedium),
        ],
        SectionHeader(title: l10n.appLockPrivacySection),
        const GroupedCard(children: [_ShowDetailsTile()]),
        if (android && bots.isNotEmpty) ...[
          SectionHeader(title: l10n.widgetsPinBot),
          FormNote(l10n.widgetsPinBotHelp),
          const SizedBox(height: AppSpace.xs),
          GroupedCard(
            children: [
              for (final b in bots)
                GroupedTile(
                  key: Key('pinBot-${b.id}'),
                  icon: LucideIcons.bot,
                  leading: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 32),
                  title: b.name,
                  trailing: TextButton(
                    onPressed: () async {
                      HapticsHelper.light();
                      final ok = await ref.read(widgetPinnerProvider).pinBot(b);
                      if (!ok && context.mounted) showMessage(context, l10n.widgetsPinUnsupported);
                    },
                    child: Text(l10n.widgetsPin),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.xl),
      ],
    );
  }
}

class _WidgetCard extends ConsumerWidget {
  const _WidgetCard({required this.kind, required this.canPin});
  final WidgetKind kind;
  final bool canPin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Card(
      key: Key('widget-${kind.name}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.sm),
        child: Row(
          children: [
            ExcludeSemantics(child: WidgetPreview(kind: kind)),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(kind.title(l10n), style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(kind.description(l10n), style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant)),
                  if (canPin) ...[
                    const SizedBox(height: AppSpace.xs),
                    FilledButton.tonal(
                      key: Key('addWidget-${kind.name}'),
                      onPressed: () async {
                        HapticsHelper.light();
                        final ok = await ref.read(widgetPinnerProvider).pin(kind);
                        if (!ok && context.mounted) showMessage(context, l10n.widgetsPinUnsupported);
                      },
                      child: Text(l10n.widgetsAddToHome),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// **From your bots** (bot widgets, docs/BOT-WIDGET-PLAN.md §11.2): each canvas a bot keeps on the
/// widgets, with **Hide on a locked phone**, **Pause** and **Clear**, then each bot that may write,
/// with its switch. Hidden while it loads, and on a server from before bot widgets.
class _FromYourBots extends ConsumerWidget {
  const _FromYourBots();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(canvasListProvider).value;
    if (list == null || list.version.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.widgetsFromBots),
        if (list.items.isEmpty) FormNote(l10n.widgetsFromBotsEmpty, icon: LucideIcons.sparkles),
        for (final c in list.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _CanvasCard(canvas: c, placed: list.placed),
          ),
        if (list.grants.isNotEmpty) ...[
          SectionHeader(title: l10n.canvasAllowedBots),
          GroupedCard(children: [for (final g in list.grants) _GrantTile(grant: g)]),
        ],
      ],
    );
  }
}

/// Where a Canvas widget is placed, by device name.
String canvasDevices(AppLocalizations l10n, List<CanvasPlacement> placed) => {
  for (final p in placed)
    (p.label ?? '').trim().isNotEmpty
        ? p.label!.trim()
        : switch (p.platform) {
            CanvasPlacementPlatformEnum.ios => l10n.canvasDeviceIos,
            CanvasPlacementPlatformEnum.android => l10n.canvasDeviceAndroid,
            CanvasPlacementPlatformEnum.macos => l10n.canvasDeviceMac,
          },
}.join(', ');

class _CanvasCard extends ConsumerWidget {
  const _CanvasCard({required this.canvas, required this.placed});
  final Canvas canvas;
  final List<CanvasPlacement> placed;

  Future<void> _change(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    HapticsHelper.light();
    final ok = await runGuarded(context, () async {
      await action();
      return true;
    });
    if (ok == true) canvasesChanged(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    final muted = context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant);
    final status = switch (canvas.status) {
      CanvasStatusEnum.paused => l10n.canvasPausedLine,
      CanvasStatusEnum.waiting => l10n.canvasWaitingLine,
      CanvasStatusEnum.shown => placed.isEmpty ? l10n.canvasNoWidget : l10n.canvasOnDevices(canvasDevices(l10n, placed)),
    };
    return Card(
      key: Key('canvas-${canvas.id}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: SizedBox.square(dimension: 96, child: FittedBox(child: CanvasView(canvas: canvas))),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(canvas.name, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Row(
                        spacing: 6,
                        children: [
                          BotAvatar(name: canvas.bot, avatar: canvas.botAvatar.isEmpty ? null : canvas.botAvatar, size: 18),
                          Flexible(child: Text(canvas.bot, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodyMedium)),
                        ],
                      ),
                      Text(l10n.canvasSetAt(relativeTime(canvas.setAt, context)), style: muted),
                      Text(status, key: Key('canvasStatus-${canvas.id}'), style: muted),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                Expanded(child: Text(l10n.canvasHideLocked, style: context.textTheme.bodyMedium)),
                Switch(
                  key: Key('canvasHide-${canvas.id}'),
                  value: canvas.hideWhenLocked,
                  onChanged: (on) => _change(context, ref, () => backend.updateCanvas(canvas.id, hideWhenLocked: on)),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpace.sm,
              children: [
                if (canvas.status == CanvasStatusEnum.waiting)
                  FilledButton.tonal(
                    key: Key('canvasAllow-${canvas.id}'),
                    onPressed: () => _change(context, ref, () => backend.setCanvasGrant(canvas.botId, true)),
                    child: Text(l10n.canvasShow),
                  )
                else
                  OutlinedButton(
                    key: Key('canvasPause-${canvas.id}'),
                    onPressed: () => _change(
                      context,
                      ref,
                      () => backend.updateCanvas(
                        canvas.id,
                        status: canvas.status == CanvasStatusEnum.paused ? CanvasUpdateStatusEnum.shown : CanvasUpdateStatusEnum.paused,
                      ),
                    ),
                    child: Text(canvas.status == CanvasStatusEnum.paused ? l10n.canvasResume : l10n.canvasPause),
                  ),
                TextButton(
                  key: Key('canvasClear-${canvas.id}'),
                  onPressed: () async {
                    final yes = await showConfirm(
                      context: context,
                      title: l10n.canvasClearTitle(canvas.name),
                      message: l10n.canvasClearMessage(canvas.bot),
                      confirmLabel: l10n.canvasClear,
                      destructive: true,
                      confirmKey: const Key('canvasClearConfirm'),
                    );
                    if (yes && context.mounted) await _change(context, ref, () => backend.clearCanvas(canvas.id));
                  },
                  child: Text(l10n.canvasClear),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One bot that may write: **May show things on your widgets**. Off clears what it showed, after a
/// confirm.
class _GrantTile extends ConsumerWidget {
  const _GrantTile({required this.grant});
  final CanvasGrant grant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final avatar = ref.watch(botsProvider).value?.where((b) => b.id == grant.botId).firstOrNull?.avatarUrl;
    return GroupedTile(
      key: Key('canvasGrant-${grant.botId}'),
      icon: LucideIcons.bot,
      leading: BotAvatar(name: grant.bot, avatar: avatar, size: 32),
      title: grant.bot,
      subtitle: l10n.canvasMayShow,
      trailing: Switch(
        key: Key('canvasGrantSwitch-${grant.botId}'),
        value: true,
        onChanged: (on) async {
          if (on) return;
          final yes = await showConfirm(
            context: context,
            title: l10n.canvasStopTitle(grant.bot),
            message: l10n.canvasStopMessage(grant.bot),
            confirmLabel: l10n.canvasStop,
            destructive: true,
            confirmKey: const Key('canvasStopConfirm'),
          );
          if (!yes || !context.mounted) return;
          HapticsHelper.light();
          final ok = await runGuarded(context, () async {
            await ref.read(backendProvider).setCanvasGrant(grant.botId, false);
            return true;
          });
          if (ok == true) canvasesChanged(ref);
        },
      ),
    );
  }
}

/// **Show details in widgets** (§10): only meaningful while the app lock is on, and locked off by
/// a workspace that requires the lock.
class _ShowDetailsTile extends ConsumerWidget {
  const _ShowDetailsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.watch(signedInProvider);
    final lockOn = ref.watch(appLockSettingsProvider).activeFor(ref.watch(backendProvider).userId);
    final requiredBy = ref.watch(appLockRequiredByProvider);
    final on = ref.watch(widgetDetailsProvider);
    final enabled = lockOn && requiredBy == null;
    return GroupedTile(
      icon: LucideIcons.eye,
      title: l10n.widgetsShowDetails,
      subtitle: requiredBy != null
          ? l10n.widgetsShowDetailsRequired(requiredBy)
          : (lockOn ? l10n.widgetsShowDetailsHelp : l10n.widgetsShowDetailsNoLock),
      trailing: Switch(
        key: const Key('widgetsShowDetails'),
        value: requiredBy == null && on,
        onChanged: enabled ? hapticOnChanged(ref.read(widgetDetailsProvider.notifier).set) : null,
      ),
    );
  }
}

/// A small drawn picture of a widget, in the mockups' look (docs/media/widgets-mockups.html):
/// plain card, orange for "needs you", green for "working", the brand colour on the one main
/// button. Placeholder bars stand in for text, so it never shows anyone's words.
class WidgetPreview extends StatelessWidget {
  const WidgetPreview({super.key, required this.kind});
  final WidgetKind kind;

  bool get _wide => const {WidgetKind.today, WidgetKind.brief, WidgetKind.tasks}.contains(kind);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final l10n = context.l10n;
    final fill = scheme.surfaceContainerHighest;
    Widget bar(double w, {double h = 6, Color? color}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: color ?? fill, borderRadius: BorderRadius.circular(h)),
    );
    Widget pill(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, maxLines: 1, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: fg)),
    );
    final small = TextStyle(fontSize: 9, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600);
    final content = switch (kind) {
      WidgetKind.needsYou => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('2', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.waiting, height: 1)),
          Text(l10n.widgetNeedsYou, style: small),
          const Spacer(),
          bar(52),
        ],
      ),
      WidgetKind.bot => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BotAvatar(name: 'Milo', avatar: 'mascot:milo', size: 26),
          const Spacer(),
          bar(40, h: 7, color: scheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(height: 4),
          Row(spacing: 3, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.working, shape: BoxShape.circle)),
            Flexible(child: Text(l10n.widgetWorking, style: small.copyWith(color: colors.working), overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ),
      WidgetKind.ask => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BotAvatar(name: 'Milo', avatar: 'mascot:milo', size: 22),
          const Spacer(),
          Row(children: [
            Expanded(
              child: Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(20)),
                child: Text(l10n.widgetAsk, style: small),
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(radius: 10, backgroundColor: scheme.primary, child: Icon(LucideIcons.mic, size: 11, color: scheme.onPrimary)),
          ]),
        ],
      ),
      WidgetKind.routines => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('7:00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: scheme.onSurface, height: 1)),
          const SizedBox(height: 4),
          bar(50),
          const Spacer(),
          pill(l10n.widgetRunNow, scheme.primary, scheme.onPrimary),
        ],
      ),
      WidgetKind.today || WidgetKind.brief || WidgetKind.tasks => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kind.title(l10n), style: small),
          const SizedBox(height: 6),
          if (kind == WidgetKind.today) ...[
            Row(spacing: 4, children: [bar(8, h: 8, color: colors.waiting), bar(70)]),
            const SizedBox(height: 5),
            Row(spacing: 4, children: [bar(8, h: 8, color: colors.working), bar(56)]),
          ] else if (kind == WidgetKind.tasks)
            Row(
              spacing: 6,
              children: [
                for (final n in const ['3', '2', '1', '0'])
                  Text(n, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: scheme.onSurface)),
              ],
            )
          else ...[
            bar(110),
            const SizedBox(height: 4),
            bar(96),
            const SizedBox(height: 4),
            bar(70),
          ],
          const Spacer(),
          bar(60),
        ],
      ),
      WidgetKind.library => GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        physics: const NeverScrollableScrollPhysics(),
        children: [for (var i = 0; i < 4; i++) Container(decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(6)))],
      ),
      WidgetKind.canvas => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📖', style: TextStyle(fontSize: 16, height: 1)),
          const Spacer(),
          bar(56, h: 7, color: scheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(height: 4),
          bar(40),
        ],
      ),
      WidgetKind.credits => Center(
        child: SizedBox(
          width: 52,
          height: 52,
          child: CircularProgressIndicator(value: 0.4, strokeWidth: 6, backgroundColor: fill, color: scheme.primary),
        ),
      ),
    };
    return Container(
      width: _wide ? 150 : 84,
      height: 84,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.hairline),
      ),
      // A drawing, not text to read: it keeps its size with large text, like the widget itself.
      child: MediaQuery.withNoTextScaling(child: content),
    );
  }
}
