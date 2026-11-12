import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/server_address.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../../ui/progressive_fade.dart';
import 'spaces.dart';
import '../../core/analytics.dart';

// --- reading invites (D-167) ------------------------------------------------------------------

/// Crockford base32: invite codes leave out I, L, O and U so they read out loud cleanly.
const _codeAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// What to send for whatever was pasted, typed or scanned: a link's token, an email invite token,
/// or a code as XXXX-XXXX (typed loosely: spaces, lower case, O for 0). Null: not an invite.
String? inviteFrom(String input) {
  final raw = input.trim();
  final token = RegExp(r'(kjoin_[A-Za-z0-9_-]{16,}|kinv_[A-Za-z0-9_-]{16,})')
      .firstMatch(raw);
  if (token != null) return token.group(1);
  final last = raw
      .replaceAll(RegExp(r'[?#].*$'), '')
      .replaceAll(RegExp(r'/+$'), '')
      .split('/')
      .last;
  final code = last
      .toUpperCase()
      .replaceAll(RegExp(r'[^0-9A-Z]'), '')
      .replaceAll('O', '0')
      .replaceAll(RegExp('[IL]'), '1')
      .replaceAll('U', 'V');
  if (code.length != 8 || code.split('').any((c) => !_codeAlphabet.contains(c))) {
    return null;
  }
  return '${code.substring(0, 4)}-${code.substring(4)}';
}

/// The server a pasted link points at (its origin), when it's a web address.
String? inviteServerFrom(String input) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null ||
      !(uri.scheme == 'https' || uri.scheme == 'http') ||
      uri.host.isEmpty) {
    return null;
  }
  return uri.origin;
}

/// The in-app path that previews an invite.
String joinPath(String invite, {String? server}) => Uri(
  path: '/join/${Uri.encodeComponent(invite)}',
  queryParameters: server == null ? null : {'server': server},
).toString();

/// Workspaces open to the signed-in person's verified email domain.
final joinableWorkspacesProvider = FutureProvider<List<JoinableWorkspace>>((
  ref,
) async {
  if (ref.watch(signedInProvider).value != true) return const [];
  ref.watch(organizationsProvider.select((o) => o.value?.length));
  try {
    return await ref.watch(backendProvider).joinableWorkspaces();
  } catch (_) {
    return const [];
  }
});

/// New people chose to start their own workspace instead of joining their team's.
final skipJoinTeamProvider = NotifierProvider<_Flag, bool>(_Flag.new);

class _Flag extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

// No automatic retries: a wrong invite should say so at once, not spin while retrying.
final _previewProvider = FutureProvider.autoDispose
    .family<InvitePreview, String>(
      (ref, invite) => ref.watch(backendProvider).previewInvite(invite),
      retry: (_, _) => null,
    );

// --- /join/<invite> -----------------------------------------------------------------------------

/// What an invite opens, before joining: the workspace, who invited you and your role. Works
/// signed out ("Sign in to join"); the invite is kept through sign-in.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, required this.invite, this.server});
  final String invite;

  /// The server the link came from (casama://app/join/…?server=…, or a pasted link's origin).
  final String? server;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  var _busy = false;
  String? _requestedFor;

  String get _invite => inviteFrom(widget.invite) ?? widget.invite;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(signedInProvider).value == true) {
        ref.read(pendingJoinTokenProvider.notifier).set(null);
      }
    });
  }

  /// Another server than the one the app uses, which may be why the invite isn't found here.
  String? get _otherServer {
    final s = widget.server;
    if (s == null || s.isEmpty) return null;
    final normalized = ServerAddress.normalize(s);
    final current = ServerAddress.normalize(ref.read(backendProvider).apiUrl);
    return normalized == current ? null : normalized;
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    final result = await runGuarded(
      context,
      () => ref.read(backendProvider).joinWithInvite(_invite),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result == null) return;
    Analytics.log('join_completed', {'status': result.status.value, 'via': 'link'});
    final org = result.organization;
    switch (result.status) {
      case JoinResultStatusEnum.requested:
        setState(() => _requestedFor = result.workspaceName);
      case JoinResultStatusEnum.joined:
      case JoinResultStatusEnum.member:
        ref.invalidate(organizationsProvider);
        if (org != null) {
          ref.read(selectedOrgIdProvider.notifier).select(org.id);
        }
        if (result.status == JoinResultStatusEnum.joined && org != null) {
          context.go('/joined/${org.id}');
        } else {
          context.go('/bots');
        }
    }
  }

  void _leave() {
    final signedIn = ref.read(signedInProvider).value == true;
    if (!signedIn) ref.read(pendingJoinTokenProvider.notifier).set(null);
    context.go(signedIn ? '/bots' : '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final signedIn = ref.watch(signedInProvider).value == true;
    final preview = ref.watch(_previewProvider(_invite));
    final Widget body;
    if (_requestedFor != null) {
      body = _JoinCard(
        key: const Key('joinRequested'),
        leading: const Icon(LucideIcons.mailCheck, size: 48),
        title: l10n.joinRequestSent,
        message: l10n.joinRequestSentHelp(_requestedFor!),
        actions: [
          FilledButton(
            key: const Key('joinDone'),
            onPressed: () => context.go('/bots'),
            child: Text(l10n.doneLabel),
          ),
        ],
      );
    } else {
      body = preview.when(
        loading: () => const SkeletonDetail(),
        error: (e, _) {
          final other = _otherServer;
          return _JoinCard(
            key: const Key('joinInvalid'),
            leading: Icon(
              LucideIcons.unlink,
              size: 48,
              color: context.colorScheme.onSurfaceVariant,
            ),
            title: l10n.inviteInvalid,
            message: other == null
                ? l10n.inviteInvalidHelp
                : l10n.inviteOtherServer(Uri.parse(other).host),
            actions: [
              if (other != null && onChangeServer != null)
                FilledButton(
                  key: const Key('switchServer'),
                  onPressed: () {
                    ref.read(pendingJoinTokenProvider.notifier).set(_invite);
                    onChangeServer!(other);
                  },
                  child: Text(l10n.switchToServer(Uri.parse(other).host)),
                ),
              TextButton(onPressed: _leave, child: Text(l10n.notNow)),
            ],
          );
        },
        data: (p) {
          final ws = p.workspace;
          final member = p.alreadyMember == true;
          final String label;
          if (!signedIn) {
            label = l10n.signInToJoin;
          } else if (member) {
            label = l10n.openWorkspace(ws.name);
          } else if (p.requiresApproval) {
            label = l10n.askToJoin;
          } else {
            label = l10n.joinWorkspaceNamed(ws.name);
          }
          return _JoinCard(
            key: const Key('joinPreview'),
            leading: SpaceAvatar(
              name: ws.name,
              icon: ws.icon,
              color: ws.color,
              size: 72,
            ),
            eyebrow: p.inviterName.isUsable
                ? l10n.invitedBy(p.inviterName!)
                : l10n.invitedToJoin,
            title: ws.name,
            message: [
              l10n.memberCount(ws.memberCount),
              p.role == InvitePreviewRoleEnum.admin
                  ? l10n.joinAsAdmin
                  : l10n.joinAsMember,
            ].join(' · '),
            notes: [
              if (member) l10n.alreadyMember,
              if (p.requiresApproval && !member) l10n.joinNeedsApproval,
              if (p.emailHint.isUsable) l10n.inviteSentTo(p.emailHint!),
            ],
            actions: [
              FilledButton(
                key: const Key('joinConfirm'),
                onPressed: _busy
                    ? null
                    : () {
                        if (signedIn) {
                          _join();
                          return;
                        }
                        ref
                            .read(pendingJoinTokenProvider.notifier)
                            .set(_invite);
                        context.go('/sign-in');
                      },
                child: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(label),
              ),
              TextButton(
                key: const Key('joinNotNow'),
                onPressed: _leave,
                child: Text(l10n.notNow),
              ),
            ],
          );
        },
      );
    }
    return Scaffold(body: SafeArea(top: false, bottom: false, child: body));
  }
}

/// The centered card the join screens share.
class _JoinCard extends StatelessWidget {
  const _JoinCard({
    super.key,
    required this.leading,
    required this.title,
    this.eyebrow,
    this.message,
    this.notes = const [],
    required this.actions,
  });
  final Widget leading;
  final String? eyebrow;
  final String title;
  final String? message;
  final List<String> notes;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final muted = context.colorScheme.onSurfaceVariant;
    final statusBar = MediaQuery.paddingOf(context).top;
    return ProgressiveFade(
      child: Center(
        child: SingleChildScrollView(
          // Starts under the status bar (the pages leave the top of their SafeArea to it), so the card dissolves there as it scrolls up.
          padding: EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.gutter + statusBar,
            AppSpace.gutter,
            BottomPadding.of(context, minimum: AppSpace.gutter),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                AppSpace.xxl,
                AppSpace.xl,
                AppSpace.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: leading),
                  const SizedBox(height: AppSpace.md),
                  if (eyebrow != null)
                    Text(
                      eyebrow!,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: muted,
                      ),
                    ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: muted,
                      ),
                    ),
                  ],
                  for (final n in notes) ...[
                    const SizedBox(height: AppSpace.sm),
                    FormNote(n),
                  ],
                  const SizedBox(height: AppSpace.xl),
                  ...actions.expand(
                    (a) => [a, const SizedBox(height: AppSpace.xs)],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- /joined/<org> --------------------------------------------------------------------------------

/// The first stop after joining: who's here and where to start.
class JoinedScreen extends ConsumerStatefulWidget {
  const JoinedScreen({super.key, required this.orgId});
  final String orgId;

  @override
  ConsumerState<JoinedScreen> createState() => _JoinedScreenState();
}

class _JoinedScreenState extends ConsumerState<JoinedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(organizationsProvider);
      ref.read(selectedOrgIdProvider.notifier).select(widget.orgId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final orgs =
        ref.watch(organizationsProvider).value ??
        const <OrganizationWithRole>[];
    final org = orgs.where((o) => o.id == widget.orgId).firstOrNull;
    final current = ref.watch(currentOrgProvider);
    final bots = current?.id == widget.orgId
        ? (ref.watch(botsProvider).value ?? const <Bot>[])
        : const <Bot>[];
    final name = org?.name ?? '';
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: _JoinCard(
          key: const Key('joinedWelcome'),
          leading: SpaceAvatar(
            name: name,
            icon: org?.icon,
            color: org?.color,
            size: 72,
          ),
          title: l10n.welcomeToWorkspace(name),
          message: bots.isEmpty ? l10n.joinedNoBots : l10n.joinedBotsHelp,
          actions: [
            if (bots.isNotEmpty)
              GroupedCard(
                children: [
                  for (final b in bots.take(5))
                    GroupedTile(
                      key: Key('joinedBot-${b.id}'),
                      icon: LucideIcons.bot,
                      leading: BotAvatar(
                        name: b.name,
                        avatar: b.avatarUrl,
                        size: 36,
                      ),
                      title: b.name,
                      showChevron: true,
                      onTap: () => context.go('/bots/${b.id}/chat'),
                    ),
                ],
              ),
            const SizedBox(height: AppSpace.xs),
            FilledButton(
              key: const Key('joinedStart'),
              onPressed: () => context.go('/bots'),
              child: Text(l10n.getStarted),
            ),
          ],
        ),
      ),
    );
  }
}

// --- /join-team: new people whose team is already here ------------------------------------------

class JoinTeamScreen extends ConsumerStatefulWidget {
  const JoinTeamScreen({super.key});

  @override
  ConsumerState<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends ConsumerState<JoinTeamScreen> {
  String? _busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final list =
        ref.watch(joinableWorkspacesProvider).value ??
        const <JoinableWorkspace>[];
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: _JoinCard(
          key: const Key('joinTeam'),
          leading: Icon(
            LucideIcons.usersRound,
            size: 48,
            color: context.colorScheme.primary,
          ),
          title: l10n.yourTeamIsHere,
          message: list.isEmpty
              ? null
              : l10n.yourTeamIsHereHelp(list.first.domain),
          actions: [
            GroupedCard(
              children: [
                for (final w in list)
                  GroupedTile(
                    key: Key('joinable-${w.id}'),
                    icon: LucideIcons.boxes,
                    leading: SpaceAvatar(
                      name: w.name,
                      icon: w.icon,
                      color: w.color,
                      size: 36,
                    ),
                    title: w.name,
                    subtitle: l10n.memberCount(w.memberCount),
                    trailing: FilledButton.tonal(
                      key: Key('joinDomain-${w.id}'),
                      onPressed: _busy != null ? null : () => _joinDomain(w),
                      child: Text(l10n.join),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            TextButton(
              key: const Key('startOwnWorkspace'),
              onPressed: () {
                ref.read(skipJoinTeamProvider.notifier).set(true);
                context.go('/welcome');
              },
              child: Text(l10n.startOwnWorkspace),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinDomain(JoinableWorkspace w) async {
    setState(() => _busy = w.id);
    final org = await runGuarded(
      context,
      () => ref.read(backendProvider).joinByDomain(w.id),
    );
    if (!mounted) return;
    setState(() => _busy = null);
    if (org == null) return;
    Analytics.log('join_completed', {'status': 'joined', 'via': 'domain'});
    ref.invalidate(organizationsProvider);
    ref.read(selectedOrgIdProvider.notifier).select(org.id);
    context.go('/joined/${org.id}');
  }
}

/// Domain workspaces in the workspace list, for people who already have one.
class JoinableWorkspacesSection extends ConsumerWidget {
  const JoinableWorkspacesSection({super.key, required this.onJoined});
  final VoidCallback onJoined;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list =
        ref.watch(joinableWorkspacesProvider).value ??
        const <JoinableWorkspace>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.workspacesYouCanJoin),
        GroupedCard(
          children: [
            for (final w in list)
              GroupedTile(
                key: Key('joinable-${w.id}'),
                icon: LucideIcons.boxes,
                leading: SpaceAvatar(
                  name: w.name,
                  icon: w.icon,
                  color: w.color,
                ),
                title: w.name,
                subtitle: l10n.openToDomain(w.domain),
                trailing: TextButton(
                  key: Key('joinDomain-${w.id}'),
                  onPressed: () async {
                    final org = await runGuarded(
                      context,
                      () => ref.read(backendProvider).joinByDomain(w.id),
                    );
                    if (org == null || !context.mounted) return;
                    ref.invalidate(organizationsProvider);
                    ref.read(selectedOrgIdProvider.notifier).select(org.id);
                    onJoined();
                    GoRouter.maybeOf(context)?.go('/joined/${org.id}');
                  },
                  child: Text(l10n.join),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// --- joining from inside the app ------------------------------------------------------------------

/// Phones scan an invite's QR code.
bool get canScanInvite =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Fills the field from the clipboard by itself only where reading it shows no system prompt
/// (Android, Windows, Linux); iOS, macOS and the web read it when Paste is tapped.
bool get _quietClipboard =>
    !kIsWeb &&
    const {
      TargetPlatform.android,
      TargetPlatform.windows,
      TargetPlatform.linux,
    }.contains(defaultTargetPlatform);

/// "Join with a link or code": paste, type or scan; opens the preview.
class JoinSpaceSheet extends ConsumerStatefulWidget {
  const JoinSpaceSheet({super.key});

  @override
  ConsumerState<JoinSpaceSheet> createState() => _JoinSpaceSheetState();
}

class _JoinSpaceSheetState extends ConsumerState<JoinSpaceSheet> {
  final _field = TextEditingController();
  var _valid = false;

  @override
  void initState() {
    super.initState();
    _field.addListener(() {
      final v = inviteFrom(_field.text) != null;
      if (v != _valid) setState(() => _valid = v);
    });
    if (_quietClipboard) _paste(onlyInvites: true);
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _paste({bool onlyInvites = false}) async {
    try {
      final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
      if (!mounted || text.isEmpty) return;
      if (onlyInvites && (inviteFrom(text) == null || _field.text.isNotEmpty)) {
        return;
      }
      _field.text = text.trim();
    } catch (_) {}
  }

  void _open(String text) {
    final invite = inviteFrom(text);
    if (invite == null) return;
    final server = inviteServerFrom(text);
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.push(joinPath(invite, server: server));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.link,
      title: l10n.joinWithLinkOrCode,
      subtitle: l10n.joinWorkspaceHelp,
      submitLabel: l10n.continueLabel,
      submitKey: const Key('joinWorkspaceSubmit'),
      onSubmit: _valid ? () => _open(_field.text) : null,
      children: [
        TextField(
          key: const Key('inviteLinkField'),
          controller: _field,
          autofocus: !_quietClipboard,
          autocorrect: false,
          textInputAction: TextInputAction.go,
          onSubmitted: (v) => _open(v),
          decoration: InputDecoration(
            labelText: l10n.inviteLinkOrCode,
            hintText: 'https://…/join/…  ·  7F3Q-9XWD',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('pasteInvite'),
                  tooltip: l10n.pasteLabel,
                  icon: const Icon(LucideIcons.clipboardPaste, size: 20),
                  onPressed: _paste,
                ),
                if (canScanInvite)
                  IconButton(
                    key: const Key('scanInvite'),
                    tooltip: l10n.scanQrCode,
                    icon: const Icon(LucideIcons.scanQrCode, size: 20),
                    onPressed: () async {
                      unfocusBeforeModal();
                      final v = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          settings: const RouteSettings(name: '/scan/invite'),
                          builder: (_) => const _ScanInvitePage(),
                        ),
                      );
                      if (v != null && mounted) _open(v);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanInvitePage extends StatefulWidget {
  const _ScanInvitePage();

  @override
  State<_ScanInvitePage> createState() => _ScanInvitePageState();
}

class _ScanInvitePageState extends State<_ScanInvitePage> {
  var _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scanQrCode)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          for (final b in capture.barcodes) {
            final v = b.rawValue ?? '';
            if (inviteFrom(v) != null) {
              _done = true;
              Navigator.of(context).pop(v);
              return;
            }
          }
        },
      ),
    );
  }
}

// --- showing an invite ------------------------------------------------------------------------------

/// The invite link as a QR code, for someone in the room or moving from a computer to a phone.
Future<void> showInviteQr(
  BuildContext context, {
  required String url,
  required String workspace,
}) => showAdaptiveSheet<void>(
  context: context,
  contentPadsBottom: true,
  builder: (c) {
    final l10n = c.l10n;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.lg,
        BottomPadding.of(c, minimum: AppSpace.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.scanToJoin(workspace),
            textAlign: TextAlign.center,
            style: c.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            key: const Key('inviteQr'),
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: QrImageView(
              data: url,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          SelectableText(
            url,
            textAlign: TextAlign.center,
            style: c.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.md),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(c),
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.doneLabel),
          ),
        ],
      ),
    );
  },
);

/// Copies [text] and says so.
Future<void> copyInvite(BuildContext context, String text) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
  } catch (_) {
    return;
  }
  HapticFeedback.selectionClick();
  Analytics.log('invite_shared', {'method': 'copy'});
  if (context.mounted) showMessage(context, context.l10n.inviteLinkCopied);
}

/// The platform share sheet with a short invitation and the link.
Future<void> shareInvite(
  BuildContext context, {
  required String url,
  required String workspace,
}) {
  Analytics.log('invite_shared', {'method': 'share'});
  return shareText(
    context.l10n.inviteShareText(workspace, url),
    origin: shareOrigin(context),
  );
}
