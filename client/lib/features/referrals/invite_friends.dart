import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics.dart';
import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/page.dart';
import '../workspaces/join_flow.dart' show JoinCard;

/// Invite friends (D-211): your invite code and link, what it has earned you, and who invited you.
/// Null when it couldn't load; `enabled` is false on servers without it (self-hosted).
final referralProvider = FutureProvider<Referral?>((ref) async {
  if (ref.watch(signedInProvider).value != true) return null;
  try {
    return await ref.watch(backendProvider).referral();
  } catch (_) {
    return null;
  }
});

/// A friend's code from an invite link (casama.ai/i/<code>), kept on disk until the person is
/// signed in and has said yes or no to it, so it survives installing the app and signing up.
class PendingReferral extends Notifier<String?> {
  static const _key = 'casama.pending_referral';

  @override
  String? build() {
    SharedPreferences.getInstance()
        .then((p) {
          final saved = p.getString(_key);
          if (saved != null && state == null) state = saved;
        })
        .catchError((_) {});
    return null;
  }

  void set(String? code) {
    state = code;
    SharedPreferences.getInstance()
        .then((p) => code == null ? p.remove(_key) : p.setString(_key, code))
        .catchError((_) => false);
  }
}

final pendingReferralProvider = NotifierProvider<PendingReferral, String?>(
  PendingReferral.new,
);

/// The app path for a friend's invite code.
String referralPath(String code) => '/i/${Uri.encodeComponent(code)}';

/// A credit amount the way invites show it: "$2" for whole dollars, "$2.50" otherwise.
String creditLabel(BuildContext context, num value) {
  final whole = value == value.roundToDouble();
  return whole
      ? '\$${value.toInt()}'
      : formatUsd(value, context.l10n.localeName);
}

/// What to say once a friend's code is accepted.
String redeemedMessage(BuildContext context, Referral r) {
  final l10n = context.l10n;
  if (r.welcomeUsd > 0) {
    return l10n.referralRedeemedBonus(creditLabel(context, r.welcomeUsd));
  }
  final name = r.invitedBy?.name;
  return name.isUsable
      ? l10n.referralRedeemedFrom(name!)
      : l10n.referralRedeemed;
}

// --- Settings → Invite friends -------------------------------------------------------------------

class InviteFriendsScreen extends ConsumerStatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  ConsumerState<InviteFriendsScreen> createState() =>
      _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends ConsumerState<InviteFriendsScreen> {
  final _code = TextEditingController();
  var _busy = false;

  @override
  void initState() {
    super.initState();
    // Settings keeps the summary alive; refresh it so counts and credits are current on open.
    Future.microtask(() {
      if (mounted) ref.invalidate(referralProvider);
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _copy(String text, String method) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      return;
    }
    HapticFeedback.selectionClick();
    Analytics.log('referral_shared', {'method': method});
    if (mounted) showMessage(context, context.l10n.inviteFriendsCopied);
  }

  Future<void> _share(Referral r) {
    Analytics.log('referral_shared', {'method': 'share'});
    final l10n = context.l10n;
    return shareText(
      r.welcomeUsd > 0
          ? l10n.inviteFriendsShareTextBonus(
              r.link!,
              r.code!,
              creditLabel(context, r.welcomeUsd),
            )
          : l10n.inviteFriendsShareText(r.link!, r.code!),
      origin: shareOrigin(context),
    );
  }

  Future<void> _redeem() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    final r = await runGuarded(
      context,
      () => ref.read(backendProvider).redeemReferral(code),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r == null) return;
    _code.clear();
    ref.invalidate(referralProvider);
    showMessage(context, redeemedMessage(context, r));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final referral = ref.watch(referralProvider);
    return SubPage(
      title: l10n.inviteFriends,
      body: referral.when(
        loading: () => const SkeletonDetail(),
        error: (_, _) => Center(child: Text(l10n.inviteFriendsUnavailable)),
        data: (r) {
          if (r == null || !r.enabled || r.code == null || r.link == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.gutter),
                child: Text(
                  l10n.inviteFriendsUnavailable,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(referralProvider.future),
            child: PageColumn(children: _sections(context, r)),
          );
        },
      ),
    );
  }

  List<Widget> _sections(BuildContext context, Referral r) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final hasReward = r.rewardUsd > 0;
    final reward = creditLabel(context, r.rewardUsd);
    final welcome = creditLabel(context, r.welcomeUsd);
    // Both sides get something: "you each get $2" when the amounts match.
    final both = hasReward && r.welcomeUsd > 0;
    final same = both && r.rewardUsd == r.welcomeUsd;
    final left = (r.rewardCap - r.rewarded).clamp(0, r.rewardCap);
    return [
      AppCard(
        key: const Key('inviteFriendsHero'),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          children: [
            Icon(LucideIcons.gift, size: 44, color: scheme.primary),
            const SizedBox(height: AppSpace.sm),
            Text(
              same
                  ? l10n.inviteFriendsHeadlineBoth(reward)
                  : hasReward
                  ? l10n.inviteFriendsHeadline(reward)
                  : l10n.inviteFriendsHeadlinePlain,
              textAlign: TextAlign.center,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              same
                  ? l10n.inviteFriendsHelpBoth(reward)
                  : both
                  ? l10n.inviteFriendsHelpTwo(reward, welcome)
                  : hasReward
                  ? l10n.inviteFriendsHelp(reward)
                  : l10n.inviteFriendsHelpPlain,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Semantics(
              label: l10n.inviteFriendsYourCode,
              child: InkWell(
                key: const Key('inviteFriendsCode'),
                borderRadius: AppRadius.tileAll,
                onTap: () => _copy(r.code!, 'copy_code'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.sm,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadius.tileAll,
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        r.code!,
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Icon(
                        LucideIcons.copy,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('inviteFriendsShare'),
                    onPressed: () => _share(r),
                    icon: const Icon(LucideIcons.share2, size: 18),
                    label: Text(l10n.inviteFriendsShare),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('inviteFriendsCopyLink'),
                    onPressed: () => _copy(r.link!, 'copy'),
                    icon: const Icon(LucideIcons.link, size: 18),
                    label: Text(l10n.inviteFriendsCopyLink),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      SectionHeader(title: l10n.inviteFriendsProgress),
      GroupedCard(
        children: [
          GroupedTile(
            key: const Key('inviteFriendsJoined'),
            icon: LucideIcons.users,
            title: l10n.inviteFriendsJoined,
            trailing: Text(
              '${r.invited}',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: AppText.tabular,
              ),
            ),
            subtitle: r.pending > 0
                ? l10n.inviteFriendsPending(r.pending)
                : null,
          ),
          if (hasReward || r.earnedUsd > 0)
            GroupedTile(
              key: const Key('inviteFriendsEarned'),
              icon: LucideIcons.banknote,
              iconColor: colors.positive,
              title: l10n.inviteFriendsEarned,
              trailing: Text(
                creditLabel(context, r.earnedUsd),
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppText.tabular,
                ),
              ),
              subtitle: hasReward
                  ? (left > 0
                        ? l10n.inviteFriendsLeft(left)
                        : l10n.inviteFriendsCapReached)
                  : null,
            ),
        ],
      ),
      SectionHeader(title: l10n.inviteFriendsHow),
      GroupedCard(
        children: [
          GroupedTile(icon: LucideIcons.send, title: l10n.inviteFriendsStep1),
          GroupedTile(
            icon: LucideIcons.userPlus,
            title: l10n.inviteFriendsStep2,
          ),
          GroupedTile(
            icon: LucideIcons.sparkles,
            title: same
                ? l10n.inviteFriendsStep3Both(reward)
                : both
                ? l10n.inviteFriendsStep3Two(reward, welcome)
                : hasReward
                ? l10n.inviteFriendsStep3(reward)
                : l10n.inviteFriendsStep3Plain,
          ),
        ],
      ),
      if (r.invitedBy != null) ...[
        const SizedBox(height: AppSpace.lg),
        Center(
          child: Text(
            [
              r.invitedBy!.name.isUsable
                  ? l10n.referralJoinedThrough(r.invitedBy!.name!)
                  : l10n.referralJoinedThroughFriend,
              if ((r.invitedBy!.welcomeEarnedUsd ?? 0) > 0)
                l10n.referralWelcomeEarned(
                  creditLabel(context, r.invitedBy!.welcomeEarnedUsd!),
                )
              else if (r.invitedBy!.welcomeEarnedUsd == null &&
                  r.welcomeUsd > 0)
                l10n.referralWelcomePending(welcome),
            ].join(' '),
            textAlign: TextAlign.center,
            key: const Key('inviteFriendsInvitedBy'),
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ] else if (r.redeemUntil != null) ...[
        SectionHeader(title: l10n.referralHaveCode),
        if (r.welcomeUsd > 0)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpace.xxs,
              right: AppSpace.xxs,
              bottom: AppSpace.xs,
            ),
            child: Text(
              l10n.referralHaveCodeHelp(welcome),
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('referralCodeField'),
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: l10n.referralCodeHint,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _redeem(),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              FilledButton.tonal(
                key: const Key('referralRedeem'),
                onPressed: _busy ? null : _redeem,
                child: Text(l10n.referralUse),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpace.xl),
    ];
  }
}

// --- casama.ai/i/<code> -------------------------------------------------------------------------

final _referralPreviewProvider = FutureProvider.autoDispose
    .family<ReferralPreview, String>(
      (ref, code) => ref.watch(backendProvider).previewReferral(code),
      retry: (_, _) => null,
    );

/// A friend's invite link, opened in the app: who invited you, and one tap to accept. Works signed
/// out ("Get started" keeps the code through sign-up). Nothing is redeemed without a tap.
class InviteLinkScreen extends ConsumerStatefulWidget {
  const InviteLinkScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<InviteLinkScreen> createState() => _InviteLinkScreenState();
}

class _InviteLinkScreenState extends ConsumerState<InviteLinkScreen> {
  var _busy = false;

  void _done() {
    ref.read(pendingReferralProvider.notifier).set(null);
    context.go('/bots');
  }

  Future<void> _accept() async {
    final signedIn = ref.read(signedInProvider).value == true;
    if (!signedIn) {
      ref.read(pendingReferralProvider.notifier).set(widget.code);
      context.go('/sign-in');
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await ref.read(backendProvider).redeemReferral(widget.code);
      if (!mounted) return;
      ref.invalidate(referralProvider);
      showMessage(context, redeemedMessage(context, r));
    } catch (e) {
      // Already used a code, too late, or one's own: nothing to do but say so and move on.
      if (mounted) showMessage(context, errorText(context, e));
    }
    if (mounted) _done();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final signedIn = ref.watch(signedInProvider).value == true;
    final preview = ref.watch(_referralPreviewProvider(widget.code));
    final body = preview.when(
      loading: () => const SkeletonDetail(),
      error: (_, _) => JoinCard(
        key: const Key('referralInvalid'),
        leading: Icon(
          LucideIcons.unlink,
          size: 48,
          color: context.colorScheme.onSurfaceVariant,
        ),
        title: l10n.referralInvalid,
        message: l10n.referralInvalidHelp,
        actions: [
          FilledButton(
            onPressed: _done,
            child: Text(signedIn ? l10n.doneLabel : l10n.referralGetStarted),
          ),
        ],
      ),
      data: (p) => JoinCard(
        key: const Key('referralPreview'),
        leading: Icon(
          LucideIcons.gift,
          size: 56,
          color: context.colorScheme.primary,
        ),
        eyebrow: p.inviterName.isUsable
            ? l10n.referralInvitedBy(p.inviterName!)
            : l10n.referralInvitedByFriend,
        title: l10n.referralWelcomeTitle,
        message: p.welcomeUsd > 0
            ? l10n.referralWelcomeHelpBonus(creditLabel(context, p.welcomeUsd))
            : l10n.referralWelcomeHelp,
        actions: [
          FilledButton(
            key: const Key('referralAccept'),
            onPressed: _busy ? null : _accept,
            child: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    signedIn ? l10n.referralAccept : l10n.referralGetStarted,
                  ),
          ),
          TextButton(
            key: const Key('referralNotNow'),
            onPressed: _done,
            child: Text(l10n.notNow),
          ),
        ],
      ),
    );
    return Scaffold(body: SafeArea(top: false, bottom: false, child: body));
  }
}
