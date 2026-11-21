import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'pairing.dart';

/// `/link?code=K7QM-2XFD` on Casama Cloud (D-296): the page a self-hosted server sends its owner
/// to. It shows which server asked and the code that server displays, and links the server to a
/// workspace the person administers. The server then collects its key by itself.
///
/// A code is a few characters someone could be talked into approving, so the page says what
/// linking gives the server (an address and notifications, never the workspace's credits) and
/// asks the person to check the code against their own server's screen.
class LinkServerScreen extends ConsumerStatefulWidget {
  const LinkServerScreen({super.key, this.code});
  final String? code;

  @override
  ConsumerState<LinkServerScreen> createState() => _LinkServerScreenState();
}

class _LinkServerScreenState extends ConsumerState<LinkServerScreen> {
  late final _typed = TextEditingController(text: widget.code ?? '');
  LinkSignInRequest? _request;
  var _loading = false;
  var _invalid = false;
  var _linking = false;
  String? _orgId;
  String? _linked;

  @override
  void initState() {
    super.initState();
    // Here now, so the code no longer has to be carried through a sign-in.
    Future.microtask(() {
      if (mounted) ref.read(pendingLinkCodeProvider.notifier).set(null);
    });
    if ((widget.code ?? '').trim().isNotEmpty) unawaited(_find());
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final code = _typed.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _invalid = false;
      _request = null;
    });
    try {
      final found = await ref.read(backendProvider).linkSignIn(code);
      if (!mounted) return;
      setState(() {
        _request = found;
        _invalid = found == null;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _link(String orgId) async {
    final request = _request;
    if (request == null) return;
    setState(() => _linking = true);
    final name = await runGuarded(
      context,
      () =>
          ref.read(backendProvider).approveLinkSignIn(orgId, request.userCode),
    );
    if (!mounted) return;
    setState(() {
      _linking = false;
      _linked = name;
      // A refused code can't be approved later either.
      if (name == null) {
        _request = null;
        _invalid = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final orgs =
        ref.watch(organizationsProvider).value ??
        const <OrganizationWithRole>[];
    final mine = [
      for (final o in orgs)
        if (o.role != OrgRole.member) o,
    ];
    final current = ref.watch(currentOrgProvider);
    final orgId =
        _orgId ??
        (mine.any((o) => o.id == current?.id)
            ? current!.id
            : (mine.isEmpty ? null : mine.first.id));
    final request = _request;
    final linked = _linked;

    if (linked != null) {
      return SubPage(
        title: l10n.linkServerTitle,
        children: [
          Icon(
            LucideIcons.circleCheck,
            size: 56,
            color: context.appColors.positive,
          ),
          Text(
            l10n.linkServerDone,
            key: const Key('linkServerDone'),
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall,
          ),
          Text(
            l10n.linkServerDoneBody(linked),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Center(
            child: TextButton(
              key: const Key('linkServerClose'),
              onPressed: () => context.go('/bots'),
              child: Text(l10n.close),
            ),
          ),
        ],
      );
    }

    return SubPage(
      title: l10n.linkServerTitle,
      // Opened from a server's link, so often with nothing behind it to go back to.
      backFallback: '/bots',
      children: [
        if (request == null) ...[
          TextField(
            key: const Key('linkServerCode'),
            controller: _typed,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.linkServerEnterCode,
              hintText: 'K7QM-2XFD',
              errorText: _invalid ? l10n.linkServerInvalid : null,
            ),
            onSubmitted: (_) => _find(),
          ),
          FilledButton(
            key: const Key('linkServerFind'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _loading ? null : _find,
            child: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.linkServerFind),
          ),
        ] else ...[
          Text(
            l10n.linkServerBody(request.instanceName),
            key: const Key('linkServerBody'),
            style: context.textTheme.titleMedium,
          ),
          GroupedCard(
            children: [
              GroupedTile(
                icon: LucideIcons.keyRound,
                title: request.userCode,
                subtitle: l10n.linkServerCode,
              ),
            ],
          ),
          FormNote(l10n.linkServerCheck, icon: LucideIcons.shieldAlert),
          FormNote(l10n.linkServerWhat, icon: LucideIcons.info),
          if (mine.isEmpty)
            FormNote(
              l10n.linkServerNeedAdmin,
              key: const Key('linkServerNeedAdmin'),
              icon: LucideIcons.lock,
              color: scheme.error,
            )
          else ...[
            if (mine.length > 1)
              GroupedCard(
                children: [
                  for (final o in mine)
                    GroupedTile(
                      key: Key('linkServerOrg-${o.id}'),
                      icon: o.id == orgId
                          ? LucideIcons.circleCheck
                          : LucideIcons.circle,
                      iconColor: o.id == orgId
                          ? scheme.primary
                          : scheme.outline,
                      title: o.name,
                      onTap: () => setState(() => _orgId = o.id),
                    ),
                ],
              ),
            FilledButton.icon(
              key: const Key('linkServerApprove'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _linking || orgId == null ? null : () => _link(orgId),
              icon: const Icon(LucideIcons.link, size: 20),
              label: Text(l10n.linkServerApprove),
            ),
          ],
          const SizedBox(height: AppSpace.xs),
        ],
      ],
    );
  }
}
