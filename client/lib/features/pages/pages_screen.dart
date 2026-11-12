import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// Pages (D-092, D-119): web pages bots publish. The app never embeds them: they open in the
/// system's in-app browser (Safari View Controller, Chrome Custom Tabs), the default browser on
/// desktop, or a new tab on the web, through a single-use view link.
final pagesProvider = FutureProvider.autoDispose.family<List<BotPage>, String?>((ref, botId) async {
  // Every bot's pages show in the Inbox: kept when it closes, so it opens with what it showed (it
  // refreshes them as it opens).
  if (botId == null) ref.keepAlive();
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).pages(org.id, botId: botId);
});

/// Opens a page link; replaced in tests.
final pageOpenerProvider = Provider<Future<void> Function(Uri url)>((ref) => openInAppBrowser);

Future<void> openInAppBrowser(Uri url) async {
  final mobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  await launchUrl(url, mode: mobile ? LaunchMode.inAppBrowserView : LaunchMode.externalApplication, webOnlyWindowName: '_blank');
}

/// Opens [page] through a single-use view link (or its PDF), never inside the app.
Future<void> openBotPage(BuildContext context, WidgetRef ref, BotPage page, {bool pdf = false}) async {
  final url = await runGuarded(context, () => ref.read(backendProvider).pageViewLink(page.id, pdf: pdf));
  if (url != null) await ref.read(pageOpenerProvider)(Uri.parse(url));
}

class PagesScreen extends ConsumerWidget {
  const PagesScreen({super.key, this.botId});
  final String? botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    return SubPage(
      title: context.l10n.pages,
      subtitle: botId == null ? null : bots.where((b) => b.id == botId).firstOrNull?.name ?? '',
      body: PagesList(botId: botId),
    );
  }
}

/// The pages list with its open, share and delete actions (the Pages screen and the Inbox's Pages filter).
class PagesList extends ConsumerWidget {
  const PagesList({super.key, this.botId});
  final String? botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    String botName(String id) => bots.where((b) => b.id == id).firstOrNull?.name ?? '';

    Future<void> open(BotPage p, {bool pdf = false}) => openBotPage(context, ref, p, pdf: pdf);

    Future<void> setVisibility(BotPage p, BotPageVisibilityEnum v) async {
      if (v == BotPageVisibilityEnum.public) {
        final ok = await showConfirm(
          context: context,
          title: l10n.pageMakePublicTitle,
          message: l10n.pageMakePublicBody,
          confirmLabel: l10n.pageMakePublic,
          icon: LucideIcons.globe,
          confirmKey: const Key('confirmPublic'),
        );
        if (!ok || !context.mounted) return;
      }
      final link = await runGuarded(context, () => backend.setPageVisibility(p.id, v));
      ref.invalidate(pagesProvider(botId));
      if (link != null && context.mounted) {
        unawaited(Clipboard.setData(ClipboardData(text: link)).catchError((Object _) {}));
        await showAdaptiveSheet<void>(context: context, builder: (_) => _PublicLink(url: link));
      }
    }

    Future<void> delete(BotPage p) async {
      final ok = await showConfirm(context: context, title: l10n.deletePageTitle(p.title), confirmLabel: l10n.delete, destructive: true, confirmKey: const Key('confirmDeletePage'));
      if (!ok || !context.mounted) return;
      await runGuarded(context, () => backend.deletePage(p.id));
      ref.invalidate(pagesProvider(botId));
    }

    return AsyncView(
        value: ref.watch(pagesProvider(botId)),
        onRetry: () => ref.invalidate(pagesProvider(botId)),
        loading: const _PagesSkeleton(),
        data: (items) => items.isEmpty
            ? EmptyState(icon: LucideIcons.fileText, title: l10n.noPages, message: l10n.pagesHelp)
            : PageColumn(
                children: [
                  FormNote(l10n.pagesHelp),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(
                    children: [
                      for (final p in items)
                        GroupedTile(
                          key: Key('page-${p.id}'),
                          icon: switch (p.visibility) {
                            BotPageVisibilityEnum.public => LucideIcons.globe,
                            BotPageVisibilityEnum.workspace => LucideIcons.users,
                            _ => LucideIcons.lock,
                          },
                          title: p.title,
                          subtitle: [
                            if (botId == null) botName(p.botId),
                            switch (p.visibility) {
                              BotPageVisibilityEnum.public => l10n.pagePublic,
                              BotPageVisibilityEnum.workspace => l10n.pageWorkspace,
                              _ => l10n.pagePrivate,
                            },
                            if (p.refreshRoutineId != null) l10n.pageRefreshes,
                            l10n.pageUpdated(p.updatedAt.toLocal().formattedDate(context)),
                          ].where((s) => s.isNotEmpty).join(' · '),
                          onTap: () => open(p),
                          trailing: PopupMenuButton<String>(
                            key: Key('pageMenu-${p.id}'),
                            icon: const Icon(LucideIcons.ellipsis, size: 18),
                            onSelected: (v) => switch (v) {
                              'pdf' => open(p, pdf: true),
                              'delete' => delete(p),
                              _ => setVisibility(p, BotPageVisibilityEnum.values.byName(v)),
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'pdf', child: Text(l10n.exportPdf)),
                              if (p.canManage) ...[
                                const PopupMenuDivider(),
                                CheckedPopupMenuItem(value: 'private', checked: p.visibility == BotPageVisibilityEnum.private, child: Text(l10n.pagePrivate)),
                                CheckedPopupMenuItem(value: 'workspace', checked: p.visibility == BotPageVisibilityEnum.workspace, child: Text(l10n.pageWorkspace)),
                                CheckedPopupMenuItem(value: 'public', checked: p.visibility == BotPageVisibilityEnum.public, child: Text(l10n.pagePublic)),
                                const PopupMenuDivider(),
                                PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
    );
  }
}

/// The pages list still loading: the help note, then a card of page rows with their menu button.
class _PagesSkeleton extends StatelessWidget {
  const _PagesSkeleton();

  static const _titles = [0.5, 0.38, 0.6, 0.44];
  static const _subtitles = [0.82, 0.7, 0.9, 0.66];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SkeletonPage(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(top: 1), child: SkeletonBone(width: 16, height: 16, radius: 8)),
            const SizedBox(width: 6),
            Expanded(child: SkeletonText(style: text.bodySmall?.copyWith(height: 1.35), lines: 2, widthFactor: 0.8)),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        SkeletonGroupedCard(
          rows: [
            for (var i = 0; i < _titles.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 12),
                child: Row(
                  children: [
                    const SkeletonBone(width: 32, height: 32, radius: AppRadius.icon),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SkeletonText(style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600), widthFactor: _titles[i]),
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: SkeletonText(style: text.bodySmall?.copyWith(height: 1.3), widthFactor: _subtitles[i]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    const SizedBox(width: 48, height: 48, child: Center(child: SkeletonBone(width: 18, height: 6, radius: 3))),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PublicLink extends StatelessWidget {
  const _PublicLink({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.globe,
      title: l10n.pagePublicLinkTitle,
      subtitle: l10n.pagePublicLinkBody,
      submitLabel: l10n.close,
      onSubmit: () async => Navigator.pop(context),
      children: [SelectableText(url, key: const Key('publicPageUrl'))],
    );
  }
}
