import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/billing.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/page.dart';
import 'billing_screen.dart' show platformProvider;

/// Where the redeem screen lives, with a code to fill in.
String redeemCodePath([String? code]) => Uri(
  path: '/settings/billing/redeem',
  queryParameters: code == null || code.isEmpty ? null : {'code': code},
).toString();

/// Redeem a gift code for a free plan (docs/COMP-PLANS-PLAN.md). Only where [giftCodesAllowed]
/// says so: the web app and the direct-download desktop builds, never the store apps.
class RedeemCodeScreen extends ConsumerStatefulWidget {
  const RedeemCodeScreen({super.key, this.code});

  final String? code;

  @override
  ConsumerState<RedeemCodeScreen> createState() => _RedeemCodeScreenState();
}

class _RedeemCodeScreenState extends ConsumerState<RedeemCodeScreen> {
  late final _code = TextEditingController(text: widget.code ?? '');
  Timer? _debounce;
  CompCodePreview? _preview;
  var _checking = false;
  var _invalid = false;
  var _busy = false;
  String? _orgId;
  RedeemedComp? _done;

  @override
  void initState() {
    super.initState();
    if (_code.text.trim().isNotEmpty) Future.microtask(_check);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _changed(String _) {
    _debounce?.cancel();
    setState(() {
      _preview = null;
      _invalid = false;
    });
    _debounce = Timer(const Duration(milliseconds: 450), _check);
  }

  /// Codes are 10 characters after G-; anything shorter isn't worth asking about yet.
  static bool _complete(String text) =>
      text.toUpperCase().replaceAll(RegExp('[^0-9A-Z]'), '').length >= 10;

  Future<void> _check() async {
    final text = _code.text.trim();
    if (!_complete(text)) return;
    setState(() => _checking = true);
    CompCodePreview? found;
    try {
      found = await ref.read(backendProvider).previewCompCode(text);
    } catch (_) {
      found = null;
    }
    if (!mounted || _code.text.trim() != text) return;
    setState(() {
      _checking = false;
      _preview = found;
      _invalid = found == null;
    });
  }

  Future<void> _redeem(String orgId) async {
    final text = _code.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    final r = await runGuarded(
      context,
      () => ref.read(backendProvider).redeemCompCode(text, orgId),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = r;
    });
    if (r != null) ref.invalidate(billingProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final allowed = giftCodesAllowed(
      platform: ref.watch(platformProvider),
      isWeb: kIsWeb,
    );
    final orgs =
        (ref.watch(organizationsProvider).value ??
                const <OrganizationWithRole>[])
            .where((o) => o.role == OrgRole.owner)
            .toList();
    final current = ref.watch(currentOrgProvider);
    final chosen =
        orgs.where((o) => o.id == _orgId).firstOrNull ??
        orgs.where((o) => o.id == current?.id).firstOrNull ??
        orgs.firstOrNull;
    final muted = context.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );

    Widget body;
    if (!allowed) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpace.gutter),
        child: Text(l10n.redeemCodeUnavailable, textAlign: TextAlign.center),
      );
    } else if (_done case final done?) {
      body = PageColumn(
        children: [
          AppCard(
            key: const Key('redeemCodeDone'),
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.gift,
                  size: 32,
                  color: context.appColors.positive,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  l10n.redeemCodeDoneTitle(done.planName),
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  l10n.redeemCodeDoneBody(
                    done.planName,
                    done.endsAt.toLocal().formattedWeekdayDate(context),
                  ),
                  style: muted,
                ),
                const SizedBox(height: AppSpace.md),
                FilledButton(
                  key: const Key('redeemCodeOpenBilling'),
                  onPressed: () => context.go('/settings/billing'),
                  child: Text(l10n.redeemCodeOpenBilling),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (orgs.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpace.gutter),
        child: Text(l10n.redeemCodeNoWorkspace, textAlign: TextAlign.center),
      );
    } else {
      final preview = _preview;
      body = PageColumn(
        children: [
          Text(l10n.redeemCodeIntro, style: muted),
          const SizedBox(height: AppSpace.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('redeemCodeField'),
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    hintText: 'G-XXXXX-XXXXX',
                    labelText: l10n.redeemCodeLabel,
                  ),
                  onChanged: _changed,
                  onSubmitted: (_) => _check(),
                ),
                const SizedBox(height: AppSpace.sm),
                if (_checking)
                  Text(l10n.redeemCodeChecking, style: muted)
                else if (preview != null)
                  Row(
                    key: const Key('redeemCodePreview'),
                    children: [
                      Icon(
                        LucideIcons.gift,
                        size: 18,
                        color: context.appColors.positive,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          l10n.redeemCodeGives(
                            preview.planName,
                            preview.months,
                          ),
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (_invalid)
                  Text(
                    l10n.redeemCodeInvalid,
                    key: const Key('redeemCodeInvalid'),
                    style: muted?.copyWith(color: scheme.error),
                  ),
              ],
            ),
          ),
          if (orgs.length > 1 && chosen != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(l10n.redeemCodeWorkspace, style: context.textTheme.labelLarge),
            const SizedBox(height: AppSpace.xs),
            DropdownButton<String>(
              key: const Key('redeemCodeWorkspace'),
              value: chosen.id,
              isExpanded: true,
              items: [
                for (final o in orgs)
                  DropdownMenuItem(value: o.id, child: Text(o.name)),
              ],
              onChanged: (v) => setState(() => _orgId = v),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          FilledButton(
            key: const Key('redeemCodeSubmit'),
            onPressed: _busy || preview == null || chosen == null
                ? null
                : () => _redeem(chosen.id),
            child: Text(l10n.redeemCodeSubmit),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            l10n.redeemCodeFinePrint,
            style: muted,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return SubPage(title: l10n.redeemCodeTitle, body: body);
  }
}
