import 'package:casama_sdk/casama_sdk.dart'
    show
        GalleryPack,
        GalleryPackKindEnum,
        Pack,
        PackInstallItemStatusEnum,
        PackItemKind,
        PackPreview,
        PackReach,
        PackSource,
        PackSourceKindEnum;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/lucide_names.dart';

/// The Packs shelf (docs/PLUGINS-AND-PACKS-PLAN.md B.9): reviewed packs and starter sets,
/// packs before starter sets, featured first, then by name. An offline gallery is an empty shelf.
final galleryPacksProvider = FutureProvider.autoDispose<List<GalleryPack>>((ref) async {
  final list = await ref.watch(backendProvider).galleryPacks();
  return [...list]..sort((a, b) {
    final aPack = a.kind == GalleryPackKindEnum.pack;
    if (aPack != (b.kind == GalleryPackKindEnum.pack)) return aPack ? -1 : 1;
    if (a.featured != b.featured) return a.featured ? -1 : 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
});

/// The packs the current workspace installed.
final installedPacksProvider = FutureProvider.autoDispose<List<Pack>>((ref) async {
  final org = ref.watch(currentOrgIdProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).packs(org);
});

/// A pack's icon: its Lucide name, else a package.
IconData packIcon(String? name) => lucideByName(name) ?? LucideIcons.package;

/// "2 bots · 3 skills · 1 routine" for what a pack holds; empty counts are left out.
String packContentsLine(
  AppLocalizations l10n, {
  int bots = 0,
  int skills = 0,
  int routines = 0,
  int apps = 0,
  int looks = 0,
  int tools = 0,
}) => [
  if (bots > 0) l10n.packCountBots(bots),
  if (skills > 0) l10n.packCountSkills(skills),
  if (routines > 0) l10n.packCountRoutines(routines),
  if (apps > 0) l10n.packCountApps(apps),
  if (looks > 0) l10n.packCountLooks(looks),
  if (tools > 0) l10n.packCountTools(tools),
].join(' · ');

/// What a preview holds, in one line.
String packPreviewContents(AppLocalizations l10n, PackPreview p) => packContentsLine(
  l10n,
  bots: p.bots.length,
  skills: p.skills.length,
  routines: p.routines.length,
  apps: p.apps.length,
  looks: p.looks.length,
  tools: p.servers.length,
);

/// Where a pack lives, for the detail's quiet line: the repository and short commit, or how it
/// came (a file, a shared link).
String packSourceLine(AppLocalizations l10n, PackSource source, String? commit) {
  final where = switch (source.kind) {
    PackSourceKindEnum.upload => l10n.packFromFile,
    PackSourceKindEnum.share => l10n.packFromShare,
    _ => [
      source.repo ?? source.galleryId ?? source.url ?? '',
      if (source.path case final p? when p.isNotEmpty) p,
    ].where((s) => s.isNotEmpty).join('/'),
  };
  if (commit == null || commit.length < 7 || source.kind == PackSourceKindEnum.upload) return where;
  return l10n.packSource(where, commit.substring(0, 7));
}

/// What a pack can reach, one plain line each (docs/PLUGINS-AND-PACKS-PLAN.md C.15).
List<({IconData icon, String text})> packReachRows(AppLocalizations l10n, PackReach r) => [
  if (r.runsCode) (icon: LucideIcons.code, text: l10n.packReachRunsCode),
  if (r.computer) (icon: LucideIcons.monitor, text: l10n.packReachComputer),
  r.hosts.isEmpty
      ? (icon: LucideIcons.globe, text: l10n.packReachNoHosts)
      : (icon: LucideIcons.globe, text: l10n.packReachHosts(r.hosts.join(', '))),
  if (r.secrets.isNotEmpty) (icon: LucideIcons.keyRound, text: l10n.packReachSecrets(r.secrets.join(', '))),
  (icon: LucideIcons.calendarClock, text: l10n.packReachRuns(r.runsPerWeek.round())),
];

/// An install result row's status in words.
String packStatusLabel(AppLocalizations l10n, PackInstallItemStatusEnum s) => switch (s) {
  PackInstallItemStatusEnum.installed => l10n.packStatusInstalled,
  PackInstallItemStatusEnum.approvalPending => l10n.packStatusPending,
  PackInstallItemStatusEnum.skipped => l10n.packStatusSkipped,
  PackInstallItemStatusEnum.failed => l10n.packStatusFailed,
  PackInstallItemStatusEnum.device => l10n.packStatusDevice,
};

IconData packKindIcon(PackItemKind kind) => switch (kind) {
  PackItemKind.bot => LucideIcons.bot,
  PackItemKind.skill => LucideIcons.sparkles,
  PackItemKind.routine => LucideIcons.repeat,
  PackItemKind.app => LucideIcons.blocks,
  PackItemKind.look => LucideIcons.palette,
  PackItemKind.tools => LucideIcons.wrench,
  PackItemKind.include => LucideIcons.store,
};

String packKindTitle(AppLocalizations l10n, PackItemKind kind) => switch (kind) {
  PackItemKind.bot => l10n.packSectionBots,
  PackItemKind.skill => l10n.packSectionSkills,
  PackItemKind.routine => l10n.packSectionRoutines,
  PackItemKind.app => l10n.packSectionApps,
  PackItemKind.look => l10n.packSectionLooks,
  PackItemKind.tools => l10n.packSectionTools,
  PackItemKind.include => l10n.packSectionIncludes,
};

/// A GitHub link someone pasted, trimmed; null when it isn't one.
String? packGitHubUrl(String text) {
  final t = text.trim();
  final uri = Uri.tryParse(t);
  if (uri == null || uri.scheme != 'https') return null;
  if (uri.host != 'github.com' && uri.host != 'www.github.com') return null;
  if (uri.pathSegments.where((s) => s.isNotEmpty).length < 2) return null;
  return t;
}
