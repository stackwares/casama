import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/date_format.dart';
import '../../core/number_format.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import 'gallery_data.dart';
import 'gallery_logic.dart';

String _sentence(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// The rows of what an item can touch, in plain words.
List<({IconData icon, String text})> galleryAccessRows(
  AppLocalizations l10n,
  GalleryAccess access,
) => [
  if (access.reads.isNotEmpty)
    (
      icon: LucideIcons.eye,
      text: l10n.galleryAccessReads(access.reads.join(', ')),
    ),
  for (final w in access.writes) (icon: LucideIcons.pencil, text: _sentence(w)),
  if (access.runsCode)
    (icon: LucideIcons.code, text: l10n.galleryAccessRunsCode),
  if (access.computer)
    (icon: LucideIcons.monitor, text: l10n.galleryAccessComputer),
  if (access.isEmpty)
    (icon: LucideIcons.shieldCheck, text: l10n.galleryAccessNothing),
];

String? galleryCreditsLabel(AppLocalizations l10n, String? credits) =>
    switch (credits) {
      'none' => l10n.galleryCreditsNone,
      'low' => l10n.galleryCreditsLow,
      'medium' => l10n.galleryCreditsMedium,
      'high' => l10n.galleryCreditsHigh,
      _ => null,
    };

/// "What it can access": reads, writes, code, a computer and how many credits it tends to use.
class GalleryAccessCard extends StatelessWidget {
  const GalleryAccessCard({super.key, required this.access});
  final GalleryAccess access;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final credits = galleryCreditsLabel(l10n, access.credits);
    return Column(
      key: const Key('galleryAccess'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(l10n.galleryAccessTitle),
        GroupedCard(
          children: [
            for (final row in galleryAccessRows(l10n, access))
              GroupedTile(icon: row.icon, title: row.text),
            if (credits != null)
              GroupedTile(icon: LucideIcons.coins, title: credits),
          ],
        ),
      ],
    );
  }
}

/// Opens a chat with [prompt] typed in, ready to send.
void galleryOpenChat(BuildContext context, String prompt) {
  final router = GoRouter.of(context);
  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  router.push(
    Uri(path: '/quick-ask', queryParameters: {'text': prompt}).toString(),
  );
}

/// "Try it": sample prompts that open a chat with the prompt.
class GalleryTryIt extends StatelessWidget {
  const GalleryTryIt({super.key, required this.examples, this.onTry});
  final List<String> examples;

  /// Defaults to opening a chat with the prompt.
  final ValueChanged<String>? onTry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const Key('galleryTryIt'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(l10n.galleryTryIt),
        GroupedCard(
          children: [
            for (final (i, e) in examples.indexed)
              GroupedTile(
                key: Key('galleryTry-$i'),
                icon: LucideIcons.messageSquare,
                title: e,
                showChevron: true,
                onTap: () =>
                    onTry != null ? onTry!(e) : galleryOpenChat(context, e),
              ),
          ],
        ),
      ],
    );
  }
}

/// "Used by 120 people · 96% of runs finish", or nothing.
String? galleryStatsText(AppLocalizations l10n, GalleryStats? stats) {
  final line = galleryStatsLine(stats);
  if (line == null) return null;
  return [
    if (line.people != null)
      l10n.galleryUsedBy(
        line.people!,
        line.people!.humanizedCount(l10n.localeName),
      ),
    if (line.successPercent != null)
      l10n.galleryRunsFinish(line.successPercent!),
  ].join(' · ');
}

/// Who made it and how it has changed: made by (Casama, community, or reviewed when its tests
/// pass), version and last update with the changelog, what it remixes, and the author's page.
class GalleryProvenance extends ConsumerWidget {
  const GalleryProvenance({super.key, required this.item, this.onOpenItem});
  final GalleryItem item;

  /// Opens another gallery item (the original of a remix).
  final ValueChanged<GalleryItem>? onOpenItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final casama = item.authorName == 'Casama' || item.authorName.isEmpty;
    final reviewed =
        item.tested != null && item.tested!.version == item.version;
    final updated = DateTime.tryParse(item.updated ?? item.added ?? '');
    final remix = item.remixOf;
    final original = remix == null
        ? null
        : ref.watch(galleryCatalogProvider).value?.find(remix.type, remix.id);
    final author = galleryAuthorKey(item);
    return Column(
      key: const Key('galleryProvenance'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(l10n.galleryAbout),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('galleryMadeBy'),
              icon: reviewed
                  ? LucideIcons.badgeCheck
                  : (casama ? LucideIcons.house : LucideIcons.users),
              title: reviewed
                  ? l10n.galleryMadeReviewed
                  : (casama
                        ? l10n.galleryMadeByCasama
                        : l10n.galleryMadeByCommunity),
              subtitle: reviewed
                  ? l10n.galleryReviewedHelp
                  : (casama ? null : l10n.galleryBy(item.authorName)),
            ),
            if (!casama && author.isNotEmpty)
              GroupedTile(
                key: const Key('galleryAuthorLink'),
                icon: LucideIcons.user,
                title: l10n.galleryMoreFrom(item.authorName),
                showChevron: true,
                onTap: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push(
                    '/settings/gallery/author/${Uri.encodeComponent(author)}',
                  );
                },
              ),
            GroupedTile(
              key: const Key('galleryVersion'),
              icon: LucideIcons.history,
              title: l10n.galleryVersion(item.version),
              subtitle: updated == null
                  ? null
                  : l10n.galleryUpdatedOn(updated.formattedDate(context)),
              showChevron: item.changelog.isNotEmpty,
              onTap: item.changelog.isEmpty
                  ? null
                  : () => showGalleryChangelog(
                      context,
                      item.name,
                      item.changelog,
                    ),
            ),
            if (remix != null)
              GroupedTile(
                key: const Key('galleryRemixOf'),
                icon: LucideIcons.gitFork,
                title: l10n.galleryRemixOf(original?.name ?? remix.id),
                showChevron: original != null && onOpenItem != null,
                onTap: original == null || onOpenItem == null
                    ? null
                    : () => onOpenItem!(original),
              ),
          ],
        ),
      ],
    );
  }
}

/// An item's changes, newest first.
Future<void> showGalleryChangelog(
  BuildContext context,
  String name,
  List<GalleryChange> changes,
) => _showInfo(
  context,
  title: context.l10n.galleryChangesTitle(name),
  child: GalleryChangeList(changes: changes),
);

/// The changelog entries as a list.
class GalleryChangeList extends StatelessWidget {
  const GalleryChangeList({super.key, required this.changes});
  final List<GalleryChange> changes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in changes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    l10n.galleryVersion(c.version),
                    if (DateTime.tryParse(c.date) case final DateTime d)
                      d.formattedDate(context),
                    if (c.breaking) l10n.galleryBreaking,
                  ].join(' · '),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: c.breaking ? context.colorScheme.error : muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(c.note, style: context.textTheme.bodyMedium),
              ],
            ),
          ),
      ],
    );
  }
}

/// A plain dialog with a title, content and Close, for read-only things.
Future<void> _showInfo(
  BuildContext context, {
  required String title,
  required Widget child,
}) => showDialog<void>(
  context: context,
  useRootNavigator: true,
  builder: (c) => AlertDialog(
    title: Text(title),
    content: SizedBox(width: 420, child: SingleChildScrollView(child: child)),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(c).pop(),
        child: Text(MaterialLocalizations.of(c).closeButtonLabel),
      ),
    ],
  ),
);

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xs, top: AppSpace.md),
    child: Text(
      text,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
