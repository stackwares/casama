import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/app_card.dart';
import '../../ui/casama_mark.dart';
import '../bots/bots_screen.dart';
import '../settings/model_keys_screen.dart';
import '../../ui/glow_button.dart';
import '../../ui/mascot.dart';

/// First run: create or join a workspace, add a model key, create a bot. One step at a time, with
/// progress across the top.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _workspace = TextEditingController();
  final _invite = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _workspace.dispose();
    _invite.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    await runGuarded(context, action);
    if (mounted) setState(() => _busy = false);
  }

  int _step(List<OrganizationWithRole> orgs, List<Credential> keys) {
    if (orgs.isEmpty) return 0;
    if (keys.isEmpty) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final orgs = ref.watch(organizationsProvider).value ?? const [];
    final keys = ref.watch(credentialsProvider).value ?? const [];
    final step = _step(orgs, keys);
    final titles = [l10n.createWorkspace, l10n.addModelKeyTitle, l10n.createFirstBot];
    final scheme = context.colorScheme;

    final Widget content = switch (step) {
      0 => _StepCard(
        key: const ValueKey(0),
        icon: LucideIcons.boxes,
        title: l10n.createWorkspace,
        body: l10n.createWorkspaceBody,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('workspaceName'),
              controller: _workspace,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.workspaceName, hintText: l10n.workspaceNameHint),
            ),
            const SizedBox(height: AppSpace.sm),
            GlowButton(
              key: const Key('createWorkspace'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _busy
                  ? null
                  : () => _guard(() async {
                      if (_workspace.text.trim().isEmpty) return;
                      final org = await ref.read(backendProvider).createOrganization(_workspace.text.trim());
                      ref.read(selectedOrgIdProvider.notifier).select(org.id);
                      ref.invalidate(organizationsProvider);
                    }),
              child: Text(l10n.create),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                    child: Text(l10n.orJoinWithCode, style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _invite,
                    decoration: InputDecoration(labelText: l10n.inviteCode),
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _guard(() async {
                            await ref.read(backendProvider).acceptInvite(_invite.text.trim());
                            ref.invalidate(organizationsProvider);
                          }),
                    child: Text(l10n.join),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      1 => _StepCard(
        key: const ValueKey(1),
        icon: LucideIcons.keyRound,
        title: l10n.addModelKeyTitle,
        body: l10n.addModelKeyBody,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AddKeyForm(onAdded: () => ref.invalidate(credentialsProvider)),
            const SizedBox(height: AppSpace.xs),
            Center(
              child: TextButton.icon(
                onPressed: () => launchUrl(Uri.parse('https://openrouter.ai/keys'), mode: LaunchMode.externalApplication),
                icon: const Icon(LucideIcons.squareArrowOutUpRight, size: 16),
                label: Text(l10n.getOpenRouterKey),
              ),
            ),
          ],
        ),
      ),
      _ => _StepCard(
        key: const ValueKey(2),
        icon: LucideIcons.bot,
        art: const BlankBotImage(size: 84),
        title: l10n.createFirstBot,
        body: l10n.createFirstBotBody,
        child: const CreateBotSheet(embedded: true),
      ),
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.xs, 0),
              child: Row(
                children: [
                  const CasamaMark(size: 30),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(l10n.onboardingTitle, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  TextButton(onPressed: () => ref.read(backendProvider).signOut(), child: Text(l10n.signOut)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _Progress(step: step, titles: titles),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, BottomPadding.of(context, minimum: AppSpace.xl)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: AnimatedSwitcher(
                      duration: AppMotion.of(context, const Duration(milliseconds: 320)),
                      switchInCurve: AppMotion.curve,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
                          child: child,
                        ),
                      ),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three segments that fill as steps complete, with the current step's name.
class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.titles});
  final int step;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < titles.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: AppMotion.of(context, const Duration(milliseconds: 400)),
                  curve: AppMotion.curve,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= step ? scheme.primary : scheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            Widget marker(int i) => AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.fast),
              child: i < step
                  ? Icon(LucideIcons.check, key: const ValueKey('done'), size: 16, color: context.appColors.positive)
                  : Text(
                      '${i + 1}',
                      key: const ValueKey('n'),
                      style: context.textTheme.labelMedium?.copyWith(color: i == step ? scheme.primary : scheme.onSurfaceVariant, fontWeight: FontWeight.w800),
                    ),
            );
            // Phones: the current step only; wider windows name all three.
            if (constraints.maxWidth < 480) {
              return Row(
                children: [
                  for (var i = 0; i < step; i++) Padding(padding: const EdgeInsets.only(right: 4), child: marker(i)),
                  if (step > 0) const SizedBox(width: 4),
                  Text(
                    context.l10n.stepOf(step + 1, titles.length),
                    style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < titles.length; i++)
                  Expanded(
                    child: Row(
                      children: [
                        marker(i),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            titles[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: i == step ? scheme.onSurface : scheme.onSurfaceVariant,
                              fontWeight: i == step ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({super.key, required this.icon, this.art, required this.title, required this.body, required this.child});
  final IconData icon;

  /// Shown instead of the icon tile (the blank bot on "Create your first bot").
  final Widget? art;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child:
                art ??
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Icon(icon, color: scheme.primary, size: 24),
                ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(title, style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4, fontSize: 24)),
          const SizedBox(height: AppSpace.xs),
          Text(body, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.45)),
          const SizedBox(height: AppSpace.lg),
          child,
        ],
      ),
    );
  }
}
