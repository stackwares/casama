import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import 'sites_providers.dart';

/// Opens Publish to the Web for [pageId]; returns the published site, or null when closed.
Future<Site?> showPublishSiteSheet(
  BuildContext context, {
  required String orgId,
  required String pageId,
  required String title,
  required String zone,
}) => showAdaptiveSheet<Site>(
  context: context,
  builder: (_) =>
      PublishSiteSheet(orgId: orgId, pageId: pageId, title: title, zone: zone),
);

/// Picks the address name (checked as typed), says anyone will be able to open it, and
/// publishes (`PUT /v1/pages/{id}/site`).
class PublishSiteSheet extends ConsumerStatefulWidget {
  const PublishSiteSheet({
    super.key,
    required this.orgId,
    required this.pageId,
    required this.title,
    required this.zone,
  });
  final String orgId;
  final String pageId;
  final String title;
  final String zone;

  @override
  ConsumerState<PublishSiteSheet> createState() => _PublishSiteSheetState();
}

class _PublishSiteSheetState extends ConsumerState<PublishSiteSheet> {
  static const debounce = Duration(milliseconds: 400);

  late final _text = TextEditingController(text: siteLabelFrom(widget.title));
  Timer? _timer;
  int _seq = 0;
  bool _checking = false;
  SiteAddressCheck? _check;

  /// The check itself failed (offline): publishing is still allowed and the server decides.
  String? _checkError;
  bool _busy = false;
  String? _publishError;

  String get _label => _text.text.trim();
  bool get _valid => siteLabelPattern.hasMatch(_label);

  @override
  void initState() {
    super.initState();
    if (_valid) _schedule(immediately: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _changed(String _) {
    setState(() {
      _check = null;
      _checkError = null;
      _publishError = null;
    });
    _schedule();
  }

  void _schedule({bool immediately = false}) {
    _timer?.cancel();
    final seq = ++_seq;
    if (!_valid) {
      setState(() => _checking = false);
      return;
    }
    _checking = true;
    _timer = Timer(immediately ? Duration.zero : debounce, () => _run(seq));
  }

  Future<void> _run(int seq) async {
    final label = _label;
    try {
      final check = await ref
          .read(backendProvider)
          .checkSiteAddress(widget.orgId, label);
      if (!mounted || seq != _seq) return;
      setState(() {
        _check = check;
        _checking = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _checkError = errorText(context, e);
        _checking = false;
      });
    }
  }

  bool get _canPublish =>
      !_busy &&
      _valid &&
      !_checking &&
      ((_check?.available == true && _check?.label == _label) ||
          _checkError != null);

  Future<void> _publish() async {
    setState(() {
      _busy = true;
      _publishError = null;
    });
    try {
      final site = await ref
          .read(backendProvider)
          .publishSite(widget.pageId, label: _label);
      if (!mounted) return;
      unawaited(HapticFeedback.mediumImpact());
      Navigator.pop(context, site);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _publishError = errorText(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final muted = context.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final label = _label;
    final check = _check;
    final Widget status;
    if (label.isNotEmpty && !_valid) {
      status = Text(
        l10n.siteAddressRules,
        key: const Key('siteAddressRules'),
        style: muted?.copyWith(color: scheme.error),
      );
    } else if (_checking) {
      status = Text(
        l10n.siteAddressChecking,
        key: const Key('siteAddressChecking'),
        style: muted,
      );
    } else if (check != null && check.label == label) {
      status = check.available
          ? Row(
              key: const Key('siteAddressAvailable'),
              children: [
                Icon(LucideIcons.circleCheck, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  l10n.siteAddressAvailable,
                  style: muted?.copyWith(color: scheme.primary),
                ),
              ],
            )
          : Text(
              check.message ?? l10n.siteAddressTaken,
              key: const Key('siteAddressTaken'),
              style: muted?.copyWith(color: scheme.error),
            );
    } else if (_checkError != null) {
      status = Text(
        _checkError!,
        key: const Key('siteAddressCheckError'),
        style: muted,
      );
    } else {
      status = Text(l10n.siteAddressRules, style: muted);
    }
    return FormSheet(
      icon: LucideIcons.globe,
      title: l10n.sitePublishToWeb,
      submitLabel: l10n.sitePublish,
      submitKey: const Key('sitePublish'),
      busy: _busy,
      onSubmit: _canPublish ? _publish : null,
      children: [
        TextField(
          key: const Key('siteAddressField'),
          controller: _text,
          autofocus: true,
          maxLength: 40,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.url,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
            TextInputFormatter.withFunction(
              (_, v) => v.copyWith(text: v.text.toLowerCase()),
            ),
          ],
          decoration: InputDecoration(
            labelText: l10n.siteAddressName,
            suffixText: '.${widget.zone}',
          ),
          onChanged: _changed,
          onSubmitted: (_) => _canPublish ? _publish() : null,
        ),
        const SizedBox(height: 4),
        SelectableText(
          'https://${label.isEmpty ? '…' : label}.${widget.zone}',
          key: const Key('siteAddressPreview'),
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        status,
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.globe, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.siteAnyoneCanOpen,
                key: const Key('siteAnyoneCanOpen'),
                style: muted,
              ),
            ),
          ],
        ),
        if (_publishError != null) ...[
          const SizedBox(height: 12),
          Text(
            _publishError!,
            key: const Key('sitePublishError'),
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}
