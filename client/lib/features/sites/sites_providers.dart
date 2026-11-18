import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// The server's sites settings when it gives pages their own addresses (a zone is set); null
/// when it doesn't, so the Library shows no Publish to the Web.
final sitesConfigProvider = Provider<SitesConfig?>((ref) {
  final config = ref.watch(backendProvider).sitesConfig;
  return config?.zone == null ? null : config;
});

/// A workspace's published sites (`GET /v1/orgs/{id}/sites`), keyed by workspace id.
final orgSitesProvider = FutureProvider.autoDispose.family<List<Site>, String>(
  (ref, orgId) => ref.watch(backendProvider).sites(orgId),
);

/// What an address name has to look like (the server's SITE_LABEL_PATTERN).
final siteLabelPattern = RegExp(r'^[a-z0-9](?:[a-z0-9-]{1,38}[a-z0-9])$');

/// An address name made from a page's title: lowercase, hyphens between words, at most 40
/// characters. Empty when the title has no letters or numbers to use.
String siteLabelFrom(String title) {
  var s = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (s.length > 40) s = s.substring(0, 40).replaceAll(RegExp(r'-+$'), '');
  if (s.isEmpty) return '';
  if (s.length < 3) s = '$s-site';
  return s;
}

/// The words for a host's state; anything the app doesn't know yet needs attention.
String siteHostStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'active' => l10n.siteHostLive,
      'pending_dns' => l10n.siteHostWaitingForDns,
      'pending_cert' => l10n.siteHostGettingCertificate,
      'paused' => l10n.siteHostPaused,
      'suspended' => l10n.siteHostSuspended,
      _ => l10n.siteHostNeedsAttention,
    };
