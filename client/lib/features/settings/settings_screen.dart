import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../voice/call_tools_sheet.dart';
import '../chat/chat_detail.dart';
import '../../core/fold/fold.dart';
import '../../core/analytics.dart';
import '../../core/billing.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/mac_bridge.dart';
import '../island/island_settings.dart';
import '../../core/updater.dart';
import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../core/link_browser.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/advanced_section.dart';
import '../../ui/form_sheet.dart';
import '../voice/wake_word.dart';
import '../voice/wake_word_sheet.dart';
import '../../ui/page.dart';
import 'about_you_screen.dart';
import 'appearance_screen.dart';
import 'me_avatar.dart';
import 'version_indicator.dart';
import '../../ui/app_card.dart';
import '../../ui/shell_header.dart';
import '../admin/admin_screen.dart';
import '../link/link_screen.dart';
import '../link/pair_device_sheet.dart';
import '../notifications/email_tips.dart';
import '../notifications/gallery_digest.dart';
import '../notifications/newsletter.dart';
import '../app_lock/app_lock.dart';
import '../notifications/push_prefs.dart';
import '../notifications/quiet_hours.dart';
import '../voice/full_screen_calls.dart';
import '../companion/companion.dart';
import '../referrals/invite_friends.dart';
import '../sites/domains_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.pane = false, this.current = ''});

  /// The list beside an open settings page on wide windows: one column, the open page highlighted,
  /// and rows swap the page next to it instead of stacking a new one.
  final bool pane;

  /// The location of the page open next to the pane.
  final String current;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Search settings: filters the rows by their title, subtitle, section and [_settingsSearchWords].
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pane = widget.pane;
    final current = widget.current;
    final l10n = context.l10n;
    final backend = ref.watch(backendProvider);
    final org = ref.watch(currentOrgProvider);
    final orgs = ref.watch(organizationsProvider).value ?? const <OrganizationWithRole>[];
    final month = ref.watch(usageMonthProvider).value;
    final isAdmin = org != null && org.role != OrgRole.member;
    final billing = ref.watch(billingProvider).value;
    final referral = ref.watch(referralProvider).value;
    final scheme = context.colorScheme;
    final email = backend.userEmail ?? '';
    final colors = context.appColors;
    void open(String path) => pane ? context.go(path) : context.pushOnce(path);
    bool sel(String path) => pane && current.startsWith(path);
    Future<void> setOpenAtLogin(bool v) async {
      await runGuarded(context, () => setLaunchAtLogin(v));
      ref.invalidate(launchAtLoginProvider);
    }

    // Search settings: every word typed must appear in a row's title, subtitle, section name or its
    // extra search words (what its page holds), so "dark mode" finds Appearance.
    final tokens = _search.text.trim().toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final searching = tokens.isNotEmpty;
    final words = _settingsSearchWords(l10n, orgName: org?.name);
    bool hit(String text) {
      final haystack = text.toLowerCase();
      return tokens.every(haystack.contains);
    }

    String? rowTitle(Widget row) => switch (row) {
      GroupedTile(:final title) => title,
      _Find(:final title) => title,
      _ => null,
    };
    String rowText(Widget row) => switch (row) {
      GroupedTile(:final title, :final subtitle) => '$title ${subtitle ?? ''}',
      _Find(:final title, :final subtitle) => '$title $subtitle',
      _ => '',
    };
    // A section's header and card, or only the rows that match while searching (nothing when none do).
    List<Widget> section(String? header, List<Widget> rows, {double gapAbove = 0}) {
      final shown = !searching
          ? rows
          : [
              for (final row in rows)
                if (rowTitle(row) case final title? when hit('${header ?? ''} ${rowText(row)} ${words[title] ?? ''}')) row,
            ];
      if (shown.isEmpty) return const [];
      return [
        if (gapAbove > 0) SizedBox(height: gapAbove),
        if (header != null) SectionHeader(title: header),
        GroupedCard(children: shown),
      ];
    }

    return Scaffold(
      // Opened from the person's avatar, not a tab (D-176): phones always get a way back.
      appBar: ShellHeader(title: l10n.settings, phoneFallback: pane ? null : '/bots'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Wide windows: the groups sit in two columns instead of one long, narrow list.
          // Search results read as one list.
          final twoColumns = !pane && !searching && constraints.maxWidth >= kTwoColumnMinWidth;
          final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: twoColumns ? kWidePageMaxWidth : kPageMaxWidth);
          // About you (D-169): the name bots use, and the way into the profile.
          final name = ref.watch(aboutYouProvider).value?.name ?? '';
          final profile = AppCard(
                key: const Key('settingsAboutYou'),
                onTap: () => open('/settings/about-you'),
                padding: const EdgeInsets.all(AppSpace.md),
                child: Row(
                  children: [
                    const MeAvatar(size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (name.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(l10n.aboutYouRow, style: context.textTheme.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  ],
                ),
              );
          // Most-used first (D-176): the workspace, how the app behaves, what bots connect to, then
          // sign-in and security, with the rarely needed options folded under Advanced (D-182). Two
          // columns on wide windows.
          final left = <Widget>[
              ...section(l10n.workspace, [
                  GroupedTile(
                    icon: LucideIcons.boxes,
                    title: org?.name ?? l10n.workspace,
                    subtitle: [if (org != null) _roleLabel(context, org.role), if (orgs.length > 1) l10n.switchWorkspace].join(' · '),
                    trailing: orgs.length > 1
                        ? PopupMenuButton<String>(
                            tooltip: l10n.switchWorkspace,
                            icon: Icon(LucideIcons.chevronsUpDown, color: scheme.onSurfaceVariant),
                            onSelected: (id) => ref.read(selectedOrgIdProvider.notifier).select(id),
                            itemBuilder: (_) => [for (final o in orgs) PopupMenuItem(value: o.id, child: Text(o.name))],
                          )
                        : null,
                  ),
                  GroupedTile(
                    key: const Key('settingsPeople'),
                    icon: isAdmin ? LucideIcons.userPlus : LucideIcons.users,
                    title: l10n.people,
                    subtitle: isAdmin ? l10n.peopleRow : null,
                    showChevron: true,
                    onTap: () => open('/settings/people'), selected: sel('/settings/people'),
                  ),
                  GroupedTile(
                    key: const Key('settingsWorkspace'),
                    icon: LucideIcons.palette,
                    title: l10n.workspaceSettings,
                    subtitle: l10n.workspaceSettingsHelp,
                    showChevron: true,
                    onTap: () => open('/settings/workspace'), selected: sel('/settings/workspace'),
                  ),
                  // Domains (SITES-AND-DOMAINS-PLAN §7.16): admins, when the server connects domains.
                  if (isAdmin && ref.watch(customDomainsProvider))
                    GroupedTile(
                      key: const Key('settingsDomains'),
                      icon: LucideIcons.globe,
                      title: l10n.settingsDomains,
                      subtitle: l10n.settingsDomainsHelp,
                      showChevron: true,
                      onTap: () => open('/settings/domains'), selected: sel('/settings/domains'),
                    ),
                  GroupedTile(
                    key: const Key('settingsUsage'),
                    icon: LucideIcons.banknote,
                    iconColor: colors.positive,
                    onTap: () => open('/settings/usage'), selected: sel('/settings/usage'),
                    showChevron: true,
                    title: l10n.usage,
                    trailing: Text(
                      formatUsd(month?.totalCostUsd ?? 0, context.l10n.localeName),
                      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppText.tabular),
                    ),
                    subtitle: l10n.usageSubtitle,
                  ),
                  if (billing?.enabled ?? false)
                    GroupedTile(
                      key: const Key('settingsBilling'),
                      icon: LucideIcons.gem,
                      iconColor: colors.warning,
                      title: l10n.billing,
                      subtitle: billing!.planName,
                      onTap: () => open('/settings/billing'), selected: sel('/settings/billing'),
                    ),
                  // Invite friends (D-211): Casama Cloud only.
                  if (referral?.enabled ?? false)
                    GroupedTile(
                      key: const Key('settingsInvite'),
                      icon: LucideIcons.gift,
                      iconColor: scheme.primary,
                      title: l10n.inviteFriends,
                      subtitle: referral!.rewardUsd > 0
                          ? l10n.inviteFriendsRow(creditLabel(context, referral.rewardUsd))
                          : l10n.inviteFriendsRowPlain,
                      showChevron: true,
                      onTap: () => open('/settings/invite'), selected: sel('/settings/invite'),
                    ),
                  if (ref.watch(adminOverviewProvider).value != null)
                    GroupedTile(key: const Key('settingsAdmin'), icon: LucideIcons.shieldUser, title: l10n.adminConsole, subtitle: l10n.adminRowHelp, onTap: () => open('/settings/admin'), selected: sel('/settings/admin')),
              ]),
              ...section(l10n.settingsAppSection, [
                  GroupedTile(
                    key: const Key('settingsAppearance'),
                    icon: LucideIcons.swatchBook,
                    title: l10n.appearance,
                    subtitle: appearanceSummary(context, ref),
                    onTap: () => open('/settings/appearance'), selected: sel('/settings/appearance'),
                  ),
                  GroupedTile(
                    key: const Key('settingsQuietHours'),
                    icon: LucideIcons.moon,
                    title: l10n.quietHours,
                    subtitle: switch (ref.watch(quietHoursProvider).value) {
                      final q? => quietSummary(context, q),
                      null => l10n.off,
                    },
                    onTap: () => showQuietHours(context, ref),
                  ),
                  // Which kinds push (D-325).
                  _Find(title: l10n.pushPrefsTitle, child: const PushPrefsTile()),
                  // Bots' calls ringing on the full screen, when Android 14+ has it off (D-424).
                  _Find(title: l10n.callFullScreenTitle, child: const FullScreenCallsTile()),
                  // Live data cards: home city, units, sources (docs/RICH-CARDS-PLAN.md).
                  GroupedTile(
                    key: const Key('settingsCards'),
                    icon: LucideIcons.cloudSun,
                    title: l10n.cardsSettingsTitle,
                    subtitle: l10n.cardsSettingsRow,
                    onTap: () => open('/settings/cards'), selected: sel('/settings/cards'),
                  ),
                  // Widgets on the Home screen, Lock Screen and desktop (D-405).
                  if (!kIsWeb &&
                      const {TargetPlatform.iOS, TargetPlatform.android, TargetPlatform.macOS}.contains(defaultTargetPlatform))
                    GroupedTile(
                      key: const Key('settingsWidgets'),
                      icon: LucideIcons.layoutGrid,
                      title: l10n.widgetsTitle,
                      subtitle: l10n.widgetsRow,
                      onTap: () => open('/settings/widgets'), selected: sel('/settings/widgets'),
                    ),
                  // Apple Watch and Wear OS (D-410): on every platform, so watches can be managed
                  // and signed in with a code from the desktop and web apps too.
                  GroupedTile(
                    key: const Key('settingsWatch'),
                    icon: LucideIcons.watch,
                    title: l10n.watchPhoneTitle,
                    subtitle: l10n.watchPhoneRow,
                    onTap: () => open('/settings/watch'), selected: sel('/settings/watch'),
                  ),
                  // Tips and news by email (D-302); account emails have no switch.
                  _Find(title: l10n.emailTips, subtitle: l10n.emailTipsHelp, child: const EmailTipsTile()),
                  // Monthly gallery picks (D-315), opt-in.
                  _Find(title: l10n.galleryDigestEmails, subtitle: l10n.galleryDigestHelp, child: const GalleryDigestTile()),
                  // Casama's monthly email (D-408), opt-in, only where the server sends it.
                  _Find(title: l10n.newsletterTitle, subtitle: l10n.newsletterHelp, child: const NewsletterTile()),
                  // Wake word (D-144): desktop and Android.
                  if (wakeWordSupported)
                    GroupedTile(
                      key: const Key('settingsWakeWord'),
                      icon: LucideIcons.audioLines,
                      title: l10n.wakeWord,
                      subtitle: ref.watch(wakeWordProvider).enabled ? l10n.wakeWordOnRow(ref.watch(wakeWordProvider).phrase) : l10n.wakeWordRow,
                      onTap: () => showAdaptiveSheet<void>(context: context, builder: (_) => const WakeWordSheet()),
                    ),
                  // Off by default: chats show what the bot is doing, not each step (D-162).
                  GroupedTile(
                    icon: LucideIcons.listTree,
                    title: l10n.showBotSteps,
                    subtitle: l10n.showBotStepsHelp,
                    onTap: () {
                      HapticsHelper.light();
                      ref.read(showBotStepsProvider.notifier).set(!ref.read(showBotStepsProvider));
                    },
                    trailing: Switch(
                      key: const Key('showBotSteps'),
                      value: ref.watch(showBotStepsProvider),
                      onChanged: hapticOnChanged(ref.read(showBotStepsProvider.notifier).set),
                    ),
                  ),
                  // On by default: the bot's screen in a small card while it works on it (SCREEN-CARD-PLAN).
                  GroupedTile(
                    icon: LucideIcons.monitorPlay,
                    title: l10n.showScreenCard,
                    subtitle: l10n.showScreenCardHelp,
                    onTap: () {
                      HapticsHelper.light();
                      final on = !ref.read(showScreenCardProvider);
                      ref.read(showScreenCardProvider.notifier).set(on);
                      if (!on) Analytics.log('screen_card_hidden', {'how': 'setting'});
                    },
                    trailing: Switch(
                      key: const Key('showScreenCard'),
                      value: ref.watch(showScreenCardProvider),
                      onChanged: hapticOnChanged((on) {
                        ref.read(showScreenCardProvider.notifier).set(on);
                        if (!on) Analytics.log('screen_card_hidden', {'how': 'setting'});
                      }),
                    ),
                  ),
                  // Off by default: what each reply cost, in a line under it (D-307).
                  GroupedTile(
                    icon: LucideIcons.gauge,
                    title: l10n.showReplyUsage,
                    subtitle: l10n.showReplyUsageHelp,
                    onTap: () {
                      HapticsHelper.light();
                      ref.read(showReplyUsageProvider.notifier).set(!ref.read(showReplyUsageProvider));
                    },
                    trailing: Switch(
                      key: const Key('showReplyUsage'),
                      value: ref.watch(showReplyUsageProvider),
                      onChanged: hapticOnChanged(ref.read(showReplyUsageProvider.notifier).set),
                    ),
                  ),
                  // Phones: links open in the system's in-app browser or the default browser app.
                  if (linkBrowserChoiceShown)
                    GroupedTile(
                      icon: LucideIcons.globe,
                      title: l10n.openLinksInApp,
                      subtitle: l10n.openLinksInAppHelp,
                      onTap: () {
                        HapticsHelper.light();
                        ref.read(linkBrowserInAppProvider.notifier).set(!ref.read(linkBrowserInAppProvider));
                      },
                      trailing: Switch(
                        key: const Key('openLinksInApp'),
                        value: ref.watch(linkBrowserInAppProvider),
                        onChanged: hapticOnChanged(ref.read(linkBrowserInAppProvider.notifier).set),
                      ),
                    ),
                  // Desktop downloads update themselves (the stores update theirs); Linux is told.
                  if (selfUpdating || updateNoticeOnly)
                    _Find(title: l10n.checkForUpdates, subtitle: l10n.autoUpdates, child: const _UpdatesRows()),
                  // Mac: start with the system, ready for the quick-ask shortcut and the menu bar icon.
                  if (ref.watch(launchAtLoginProvider).value case final on?)
                    GroupedTile(
                      icon: LucideIcons.power,
                      title: l10n.openAtLogin,
                      subtitle: l10n.openAtLoginHelp,
                      onTap: () {
                        HapticsHelper.light();
                        setOpenAtLogin(!on);
                      },
                      trailing: Switch(key: const Key('openAtLogin'), value: on, onChanged: hapticOnChanged(setOpenAtLogin)),
                    ),
                  // Mac: the notch and how it opens (D-324).
                  // Phones: runs started on another device show here too (D-324, decision 11).
                  if (!kIsWeb &&
                      (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android))
                    GroupedTile(
                      icon: LucideIcons.smartphone,
                      title: l10n.islandStartElsewhere,
                      subtitle: l10n.islandStartElsewhereHelp,
                      onTap: () {
                        HapticsHelper.light();
                        ref.read(islandStartElsewhereProvider.notifier).set(!ref.read(islandStartElsewhereProvider));
                      },
                      trailing: Switch(
                        key: const Key('islandStartElsewhere'),
                        value: ref.watch(islandStartElsewhereProvider),
                        onChanged: hapticOnChanged(ref.read(islandStartElsewhereProvider.notifier).set),
                      ),
                    ),
                  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) ...[
                    GroupedTile(
                      icon: LucideIcons.panelTop,
                      title: l10n.showBotsInNotch,
                      subtitle: l10n.showBotsInNotchHelp,
                      onTap: () {
                        HapticsHelper.light();
                        ref.read(islandNotchOnProvider.notifier).set(!ref.read(islandNotchOnProvider));
                      },
                      trailing: Switch(
                        key: const Key('showBotsInNotch'),
                        value: ref.watch(islandNotchOnProvider),
                        onChanged: hapticOnChanged(ref.read(islandNotchOnProvider.notifier).set),
                      ),
                    ),
                    if (ref.watch(islandNotchOnProvider))
                      GroupedTile(
                        icon: LucideIcons.mousePointer2,
                        title: l10n.notchOnHover,
                        subtitle: l10n.notchOnHoverHelp,
                        onTap: () {
                          HapticsHelper.light();
                          ref.read(islandHoverOpensProvider.notifier).set(!ref.read(islandHoverOpensProvider));
                        },
                        trailing: Switch(
                          key: const Key('notchOnHover'),
                          value: ref.watch(islandHoverOpensProvider),
                          onChanged: hapticOnChanged(ref.read(islandHoverOpensProvider.notifier).set),
                        ),
                      ),
                  ],
                  GroupedTile(
                    icon: LucideIcons.languages,
                    title: l10n.language,
                    trailing: Text(_languageName(Localizations.localeOf(context)), style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
              ]),
          ];
          final advancedRows = <Widget>[
                  GroupedTile(key: const Key('settingsSecrets'), icon: LucideIcons.lock, title: l10n.secrets, subtitle: l10n.secretsRowHelp, onTap: () => open('/settings/secrets'), selected: sel('/settings/secrets')),
                  GroupedTile(key: const Key('settingsComputers'), icon: LucideIcons.monitor, title: l10n.computers, subtitle: l10n.computersRowHelp, onTap: () => open('/settings/computers'), selected: sel('/settings/computers')),
                  // Device connections (D-149): data this device shares with your bots.
                  GroupedTile(
                    key: const Key('settingsDevices'),
                    icon: LucideIcons.smartphone,
                    title: l10n.deviceConnections,
                    subtitle: l10n.deviceConnectionsRowHelp,
                    onTap: () => open('/settings/devices'), selected: sel('/settings/devices'),
                  ),
                  // System permissions on this device (D-376): what bots can use here.
                  GroupedTile(
                    key: const Key('settingsPermissions'),
                    icon: LucideIcons.shieldCheck,
                    title: l10n.permissionsScreenTitle,
                    subtitle: l10n.permissionsRowHelp,
                    onTap: () => open('/settings/permissions'), selected: sel('/settings/permissions'),
                  ),
                  // A phone that folds (D-411): what Casama sees of its screens, for checking a layout.
                  if (windowFold(context).hasStrip || windowFold(context).fold != null)
                    GroupedTile(
                      key: const Key('settingsFold'),
                      icon: LucideIcons.bookOpen,
                      title: l10n.foldScreenTitle,
                      subtitle: l10n.foldRowHelp,
                      onTap: () => open('/settings/fold'), selected: sel('/settings/fold'),
                    ),
                  if (ref.watch(companionProvider).supported)
                    GroupedTile(
                      key: const Key('settingsCompanion'),
                      icon: LucideIcons.laptop,
                      title: l10n.useThisComputer,
                      subtitle: l10n.companionRowHelp,
                      onTap: () => open('/settings/companion'), selected: sel('/settings/companion'),
                    ),
          ];
          final right = <Widget>[
              ...section(l10n.settingsConnectionsSection, [
                  GroupedTile(
                    key: const Key('settingsIntegrations'),
                    icon: LucideIcons.puzzle,
                    title: l10n.integrations,
                    subtitle: l10n.integrationsRowHelp,
                    onTap: () => open('/settings/integrations'), selected: sel('/settings/integrations'),
                  ),
                  GroupedTile(icon: LucideIcons.bookOpen, title: l10n.skills, subtitle: l10n.skillsRowHelp, onTap: () => open('/settings/skills'), selected: sel('/settings/skills')),
                  // Casama Link (D-296): the owner of a self-hosted server gives it an address a
                  // phone can reach. Casama Cloud itself has one already.
                  if (ref.watch(billingProvider).value?.enabled != true && ref.watch(remoteAccessAvailableProvider).value == true)
                    GroupedTile(
                      key: const Key('settingsCasamaLink'),
                      icon: LucideIcons.smartphone,
                      title: l10n.casamaLink,
                      subtitle: l10n.linkRow,
                      onTap: () => open('/settings/link'), selected: sel('/settings/link'),
                    ),
                  // Casama Cloud runs the models (D-188): only search, maps and data keys are left to add,
                  // unless own providers are enabled on this server.
                  if (ref.watch(billingProvider).value?.enabled == true) ...[
                    if (backend.ownProviders)
                      GroupedTile(icon: LucideIcons.keyRound, title: l10n.modelsTitle, subtitle: l10n.modelsRowHelp, onTap: () => open('/settings/keys'), selected: sel('/settings/keys'))
                    else if (ref.watch(backendProvider).keyProviders.cloud.isNotEmpty)
                      GroupedTile(icon: LucideIcons.keyRound, title: l10n.serviceKeys, subtitle: l10n.serviceKeysHelp, onTap: () => open('/settings/keys'), selected: sel('/settings/keys')),
                  ] else
                    GroupedTile(icon: LucideIcons.keyRound, title: l10n.modelKeys, subtitle: l10n.modelKeysHelp, onTap: () => open('/settings/keys'), selected: sel('/settings/keys')),
              ]),
              ...section(l10n.settingsSecuritySection, [
                  GroupedTile(
                    key: const Key('settingsAccount'),
                    icon: LucideIcons.circleUser,
                    title: l10n.account,
                    subtitle: backend.userEmail.orPlaceholder(l10n.accountRow),
                    onTap: () => open('/settings/account'), selected: sel('/settings/account'),
                  ),
                  GroupedTile(
                    key: const Key('settingsTwoStep'),
                    icon: LucideIcons.smartphone,
                    title: l10n.twoStepSignIn,
                    subtitle: org?.requireMfa == true && org?.role != OrgRole.member && !backend.twoStepVerified ? l10n.twoStepNeededForAdmin : l10n.twoStepHelp,
                    onTap: () => open('/settings/two-step'), selected: sel('/settings/two-step'),
                  ),
                  // Scan to sign in (D-296): a QR code another device scans to get into this account.
                  if (backend.signInCodes)
                    GroupedTile(
                      key: const Key('settingsPairDevice'),
                      icon: LucideIcons.scanQrCode,
                      title: l10n.pairDevice,
                      subtitle: l10n.pairDeviceRow,
                      onTap: () => showPairDevice(
                        context,
                        // On the computer that runs this server, a code a phone can't use yet leads
                        // to the switch that gives the server an address.
                        onTurnOnLink: ref.read(remoteAccessAvailableProvider).value == true ? () => open('/settings/link') : null,
                      ),
                    ),
                  // Passkeys (D-183): when the server has them and this device can make them.
                  if (ref.watch(authMethodsProvider).value?.passkeys == true)
                    GroupedTile(
                      key: const Key('settingsPasskeys'),
                      icon: LucideIcons.fingerprint,
                      title: l10n.passkeys,
                      subtitle: l10n.passkeysRow,
                      onTap: () => open('/settings/passkeys'), selected: sel('/settings/passkeys'),
                    ),
                  // The app lock (D-375): unlock to open Casama, and before risky actions.
                  GroupedTile(
                    key: const Key('settingsAppLock'),
                    icon: LucideIcons.scanFace,
                    title: l10n.appLock,
                    subtitle: ref.watch(appLockSettingsProvider).activeFor(backend.userId) ? l10n.appLockTurnedOn : l10n.appLockRow,
                    onTap: () => open('/settings/app-lock'), selected: sel('/settings/app-lock'),
                  ),
                  GroupedTile(key: const Key('settingsPrivacy'), icon: LucideIcons.shieldCheck, title: l10n.privacy, subtitle: l10n.privacyRowHelp, onTap: () => open('/settings/privacy'), selected: sel('/settings/privacy')),
              ]),
              // Everything most people never need, in one fold that stays open once opened (D-182).
              // While searching, its matching rows show as an ordinary section instead.
              if (searching)
                ...section(l10n.advanced, advancedRows)
              else
                AdvancedSection(
                  id: 'settings',
                  summary: l10n.settingsAdvancedSummary,
                  // Beside an open page inside it (wide windows), it stays open so the row shows.
                  forceOpen: const ['/settings/secrets', '/settings/computers', '/settings/devices', '/settings/permissions', '/settings/fold', '/settings/companion'].any(sel),
                  children: [GroupedCard(children: advancedRows)],
                ),
              // Help & support (D-298): Casama Help, the support team and the ids they ask for.
              ...section(null, gapAbove: AppSpace.lg, [
                GroupedTile(
                  key: const Key('settingsSupport'),
                  icon: LucideIcons.lifeBuoy,
                  title: l10n.helpAndSupport,
                  subtitle: l10n.helpAndSupportRow,
                  onTap: () => open('/settings/support'),
                  selected: sel('/settings/support'),
                ),
              ]),
              ...section(null, gapAbove: AppSpace.sm, [
                GroupedTile(
                  icon: LucideIcons.logOut,
                  title: l10n.signOut,
                  destructive: true,
                  showChevron: false,
                  onTap: () async {
                    final ok = await showConfirm(context: context, title: l10n.signOut, message: l10n.signOutConfirm, confirmLabel: l10n.signOut, destructive: true);
                    if (ok && context.mounted) await runGuarded(context, backend.signOut);
                  },
                ),
              ]),
          ];
          return ListView(
            padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: TextField(
                  key: const Key('settingsSearch'),
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.settingsSearchHint,
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('settingsSearchClear'),
                            tooltip: l10n.searchClear,
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (!searching || hit('${l10n.aboutYou} $name $email ${words[l10n.aboutYou]}')) profile,
              if (searching && left.isEmpty && right.isEmpty && !hit('${l10n.aboutYou} $name $email ${words[l10n.aboutYou]}'))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
                  child: Text(
                    l10n.settingsSearchNone(_search.text.trim()),
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              if (twoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
                    const SizedBox(width: AppSpace.xl),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
                  ],
                )
              else ...[...left, ...right],
              // The version and build, for bug reports (a tap copies it).
              const SizedBox(height: AppSpace.md),
              const Center(child: VersionIndicator()),
            ],
          );
        },
      ),
    );
  }
}

/// A settings row that isn't a [GroupedTile] (it builds its own), with the title and subtitle the
/// settings search matches.
class _Find extends StatelessWidget {
  const _Find({required this.title, this.subtitle = '', required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Extra words the settings search matches for each row, keyed by the row's title: what its page
/// holds and the other names people use for it. English, like the app (v1).
Map<String, String> _settingsSearchWords(AppLocalizations l10n, {String? orgName}) => {
  orgName ?? l10n.workspace: 'workspace switch change team organization org role',
  l10n.aboutYou: 'profile name photo picture avatar pronouns about me reply style facts memory',
  l10n.people: 'members invite team users admins roles invite link code join remove',
  l10n.workspaceSettings: 'workspace name icon logo encryption memory payments stripe card password managers bot to bot chrome extension gallery',
  l10n.settingsDomains: 'domain website custom dns buy connect sites',
  l10n.usage: 'cost spend spending money credits tokens limits',
  l10n.billing: 'plan subscription upgrade pro plus max payment invoice card pricing',
  l10n.inviteFriends: 'referral credit reward share',
  l10n.adminConsole: 'admin console',
  l10n.appearance: 'theme dark mode light mode night colors colours fonts font text size background wallpaper look style themes effects motion animations',
  l10n.quietHours: 'do not disturb dnd sleep mute silence notifications schedule',
  l10n.pushPrefsTitle: 'notifications push alerts replies sounds',
  l10n.callFullScreenTitle: 'calls phone ring ringing lock screen full screen incoming answer',
  l10n.emailTips: 'email newsletter tips news unsubscribe',
  l10n.galleryDigestEmails: 'email gallery digest monthly picks',
  l10n.newsletterTitle: 'email newsletter monthly news updates subscribe unsubscribe',
  l10n.wakeWord: 'voice hey hands free microphone mic listen',
  l10n.showBotSteps: 'steps tools details progress',
  l10n.showReplyUsage: 'cost tokens price usage per reply',
  l10n.checkForUpdates: 'update updates version upgrade download automatic',
  l10n.openAtLogin: 'startup launch login boot start automatically',
  l10n.islandStartElsewhere: 'live activity dynamic island lock screen other devices',
  l10n.showBotsInNotch: 'notch menu bar dynamic island',
  l10n.notchOnHover: 'notch hover mouse',
  l10n.language: 'language locale english translation',
  l10n.integrations: 'apps connect connections gmail google slack calendar plugins tools mcp',
  l10n.skills: 'skills catalog abilities instructions',
  l10n.casamaLink: 'remote access address tunnel self host phone',
  l10n.serviceKeys: 'api keys search maps data',
  l10n.modelsTitle: 'api keys openai anthropic openrouter gemini models providers ollama local models',
  l10n.modelKeys: 'api keys openai anthropic openrouter gemini models providers ollama local models',
  l10n.account: 'email change email password sign out everywhere login',
  l10n.twoStepSignIn: '2fa mfa two factor authenticator totp otp security code',
  l10n.pairDevice: 'qr code scan sign in pair phone another device',
  l10n.passkeys: 'passkey face id touch id fingerprint biometric',
  l10n.widgetsTitle: 'widgets home screen lock screen controls control center glance pin shortcut',
  l10n.cardsSettingsTitle: 'cards weather units celsius fahrenheit home city location currency stocks red green data sources',
  l10n.appLock: 'app lock pin passcode face id touch id fingerprint biometric windows hello screenshots privacy lock screen',
  l10n.privacy: 'data export download delete account analytics tracking history retention blocked people block',
  l10n.secrets: 'secrets passwords credentials vault environment variables',
  l10n.computers: 'computers machines docker sandbox desktop',
  l10n.deviceConnections: 'devices location health places folders watched apps browsers chrome extension phone permissions',
  l10n.useThisComputer: 'companion this computer mac local files',
  l10n.helpAndSupport: 'help support contact ticket bug report feedback docs',
  l10n.signOut: 'log out logout sign out',
};

String _languageName(Locale locale) => switch (locale.languageCode) {
  'en' => 'English',
  _ => locale.toLanguageTag(),
};

String _roleLabel(BuildContext context, OrgRole role) => switch (role) {
  OrgRole.owner => context.l10n.roleOwner,
  OrgRole.admin => context.l10n.roleAdmin,
  _ => context.l10n.roleMember,
};

/// A bot's read-aloud and dictation providers (each uses the workspace's own key).
class VoiceSettingsDialog extends ConsumerStatefulWidget {
  const VoiceSettingsDialog({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<VoiceSettingsDialog> createState() => _VoiceSettingsDialogState();
}

class _VoiceSettingsDialogState extends ConsumerState<VoiceSettingsDialog> {
  final _voice = TextEditingController();
  var _busy = false;
  var _callTools = <String>[];
  var _loaded = false;

  /// After each call, its card gets a short summary and next steps (call card plan); on unless off.
  var _summarize = true;

  @override
  void initState() {
    super.initState();
    // Start from the bot's current settings rather than Automatic.
    ref.read(backendProvider).loadBotVoice(widget.botId).then((v) {
      if (!mounted) return;
      setState(() {
        _voice.text = (v['tts_voice'] as String?) ?? '';
        _callTools = [for (final t in (v['call_tools'] as List?) ?? const []) '$t'];
        _summarize = v['summarize_calls'] != false;
        _loaded = true;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      // Read-aloud and calls are Gemini, dictation is OpenAI (D-260): there's no service to pick,
      // so a choice saved before is cleared. The bot's other voice settings are kept.
      await ref.read(backendProvider).updateBotVoice(widget.botId, {
        'tts_provider': null,
        'stt_provider': null,
        'tts_voice': _voice.text.trim().isEmpty ? null : _voice.text.trim(),
        // Stored only when off: on is the default.
        'summarize_calls': _summarize ? null : false,
      });
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cloud = ref.watch(billingProvider).value?.enabled == true;
    // The server's own keys cover voice, as on Casama Cloud, so there's no key to add.
    final serverVoice = ref.watch(backendProvider).serverVoice.isNotEmpty;
    return FormSheet(
      icon: LucideIcons.speech,
      title: l10n.voiceSettings,
      subtitle: l10n.voiceSettingsHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveVoice'),
      busy: _busy,
      onSubmit: _save,
      children: [
        if (cloud && !ref.watch(backendProvider).ownProviders)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Text(l10n.casamaCloudModelLocked),
          )
        else if (serverVoice)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Text(l10n.serverVoiceSetUp),
          ),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('callToolsRow'),
              icon: LucideIcons.wrench,
              title: l10n.callTools,
              subtitle: l10n.callToolsCount(_callTools.length),
              showChevron: true,
              onTap: !_loaded
                  ? null
                  : () async {
                      final chosen = await showAdaptiveSheet<List<String>>(
                        context: context,
                        builder: (_) => CallToolsSheet(botId: widget.botId, initial: _callTools),
                      );
                      if (chosen != null && mounted) setState(() => _callTools = chosen);
                    },
            ),
            GroupedTile(
              key: const Key('summarizeCallsRow'),
              icon: LucideIcons.notebookText,
              title: l10n.summarizeCalls,
              subtitle: l10n.summarizeCallsHelp,
              onTap: !_loaded ? null : () => setState(() => _summarize = !_summarize),
              trailing: Switch(
                key: const Key('summarizeCallsSwitch'),
                value: _summarize,
                onChanged: !_loaded ? null : (v) => setState(() => _summarize = v),
              ),
            ),
          ],
        ),
        TextField(
          controller: _voice,
          decoration: InputDecoration(labelText: l10n.voiceId, helperText: l10n.voiceIdHelp, prefixIcon: const Icon(LucideIcons.audioLines, size: 20)),
        ),
      ],
    );
  }
}

/// Updates for the desktop downloads: the version, "Check for updates" and automatic updates; on
/// Linux, a newer release when there is one.
class _UpdatesRows extends ConsumerWidget {
  const _UpdatesRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.watch(appVersionProvider).value ?? '';
    if (updateNoticeOnly) {
      final newer = ref.watch(newerReleaseProvider).value;
      return GroupedTile(
        key: const Key('settingsUpdates'),
        icon: LucideIcons.download,
        title: newer == null ? l10n.upToDate : l10n.updateReady(newer.version),
        subtitle: l10n.appVersion(version),
        showChevron: newer != null,
        onTap: newer == null ? null : () => launchUrl(newer.page, mode: LaunchMode.externalApplication),
      );
    }
    final auto = ref.watch(autoUpdateChecksProvider).value;
    Future<void> setAuto(bool v) async {
      await runGuarded(context, () => setAutoUpdateChecks(v));
      ref.invalidate(autoUpdateChecksProvider);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GroupedTile(
          key: const Key('settingsCheckUpdates'),
          icon: LucideIcons.download,
          title: l10n.checkForUpdates,
          subtitle: l10n.appVersion(version),
          showChevron: false,
          onTap: () => runGuarded(context, checkForUpdatesNow),
        ),
        if (auto != null)
          GroupedTile(
            icon: LucideIcons.refreshCw,
            title: l10n.autoUpdates,
            subtitle: l10n.autoUpdatesHelp,
            onTap: () {
              HapticsHelper.light();
              setAuto(!auto);
            },
            trailing: Switch(key: const Key('autoUpdates'), value: auto, onChanged: hapticOnChanged(setAuto)),
          ),
      ],
    );
  }
}

