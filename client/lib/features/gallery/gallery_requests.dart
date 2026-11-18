import 'package:casama_sdk/casama_sdk.dart' show ReportTarget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/segmented.dart';
import '../../ui/shell_header.dart';
import '../moderation/report_sheet.dart';
import 'gallery_cards.dart';

/// Kinds a request can ask for.
const galleryRequestKinds = [
  'skill',
  'routine',
  'bot',
  'app',
  'theme',
  'wallpaper',
  'plugin',
];

/// Opens the new request form, [title] filled in. Returns the request (or the existing one with
/// a similar title, which the server answers with).
Future<GalleryRequest?> showGalleryNewRequest(
  BuildContext context, {
  String? title,
  String? kind,
}) => showAdaptiveSheet<GalleryRequest>(
  context: context,
  dialogMaxWidth: 520,
  builder: (_) => _NewRequestSheet(title: title, kind: kind),
);

/// The requests board (D-315): ideas people want in the gallery, top or newest first, with votes.
class GalleryRequestsScreen extends ConsumerStatefulWidget {
  const GalleryRequestsScreen({super.key, this.newTitle, this.openNew = false});

  /// Opens the new request form at once with this title (a deep link or an empty search).
  final String? newTitle;
  final bool openNew;

  @override
  ConsumerState<GalleryRequestsScreen> createState() =>
      _GalleryRequestsScreenState();
}

class _GalleryRequestsScreenState extends ConsumerState<GalleryRequestsScreen> {
  var _sort = 'top';
  late Future<List<GalleryRequest>> _list = _load();

  /// Votes changed here, shown at once while the list stays as loaded.
  final _voted = <String, GalleryRequest>{};

  Future<List<GalleryRequest>> _load() =>
      ref.read(backendProvider).galleryRequests(sort: _sort);

  @override
  void initState() {
    super.initState();
    if (widget.openNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _new(title: widget.newTitle);
      });
    }
  }

  void _reload() {
    setState(() {
      _voted.clear();
      _list = _load();
    });
  }

  Future<void> _new({String? title}) async {
    final created = await showGalleryNewRequest(context, title: title);
    if (created != null && mounted) {
      // The server answers a title like an existing one with that request, now with this vote.
      showSuccess(
        context,
        created.similar
            ? context.l10n.galleryRequestSimilar(created.title)
            : context.l10n.galleryRequestSent,
      );
      _reload();
    }
  }

  Future<void> _vote(GalleryRequest r) async {
    final shown = _voted[r.id] ?? r;
    final vote = !shown.voted;
    setState(() {
      _voted[r.id] = shown.copyWith(
        voted: vote,
        votes: shown.votes + (vote ? 1 : -1),
      );
    });
    try {
      await ref.read(backendProvider).voteGalleryRequest(r.id, vote: vote);
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _voted[r.id] = shown;
      });
      showError(context, e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SubPage(
      title: l10n.galleryRequestsTitle,
      actions: [
        HeaderIconButton(
          key: const Key('galleryRequestNew'),
          icon: LucideIcons.plus,
          tooltip: l10n.galleryRequestNew,
          onPressed: () => _new(),
        ),
      ],
      body: FutureBuilder<List<GalleryRequest>>(
        future: _list,
        builder: (context, snap) {
          final loading = snap.connectionState != ConnectionState.done;
          final list = snap.data ?? const <GalleryRequest>[];
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xs,
              AppSpace.md,
              AppSpace.xxl + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(
                l10n.galleryRequestsHelp,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Center(
                child: SizedBox(
                  width: 260,
                  child: AppSegmentedControl<String>(
                    key: const Key('galleryRequestsSort'),
                    values: const ['top', 'new'],
                    labels: {
                      'top': l10n.galleryRequestsTop,
                      'new': l10n.galleryRequestsNew,
                    },
                    groupValue: _sort,
                    onValueChanged: (v) {
                      _sort = v;
                      _reload();
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(AppSpace.xl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snap.hasError)
                EmptyState(
                  icon: LucideIcons.cloudOff,
                  message: l10n.galleryRequestsError,
                  action: OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    label: Text(l10n.retry),
                  ),
                )
              else if (list.isEmpty)
                EmptyState(
                  icon: LucideIcons.lightbulb,
                  message: l10n.galleryRequestsEmpty,
                  action: FilledButton.tonal(
                    onPressed: () => _new(),
                    child: Text(l10n.galleryRequestNew),
                  ),
                )
              else
                for (final r in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.xs),
                    child: _RequestTile(
                      request: _voted[r.id] ?? r,
                      onVote: () => _vote(r),
                      onReport: r.mine
                          ? null
                          : () => showReportSheet(
                              context,
                              kind: ReportTarget.galleryRequest,
                              targetId: r.id,
                            ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

String galleryRequestStatus(AppLocalizations l10n, String status) =>
    switch (status) {
      'planned' => l10n.galleryRequestPlanned,
      'done' => l10n.galleryRequestDone,
      'declined' => l10n.galleryRequestDeclined,
      _ => l10n.galleryRequestOpen,
    };

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.onVote,
    this.onReport,
  });
  final GalleryRequest request;
  final VoidCallback onVote;

  /// Reports the request (others' only).
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final r = request;
    final closed = r.status == 'done' || r.status == 'declined';
    return DecoratedBox(
      key: Key('galleryRequest-${r.id}'),
      decoration: BoxDecoration(
        color: context.isDark
            ? scheme.surfaceContainer
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.appColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              selected: r.voted,
              label: l10n.galleryRequestVote,
              child: InkWell(
                key: Key('galleryVote-${r.id}'),
                borderRadius: BorderRadius.circular(AppRadius.tile),
                onTap: closed ? null : onVote,
                child: Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                  decoration: BoxDecoration(
                    color: r.voted
                        ? scheme.primary.withValues(alpha: 0.12)
                        : null,
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                    border: Border.all(
                      color: r.voted
                          ? scheme.primary
                          : context.appColors.hairline,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.chevronUp,
                        size: 18,
                        color: r.voted ? scheme.primary : muted,
                      ),
                      Text(
                        r.votes.humanizedCount(l10n.localeName),
                        style: context.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: r.voted ? scheme.primary : null,
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (r.details != null && r.details!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      r.details!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    [
                      if (r.kind.isNotEmpty) galleryKindName(l10n, r.kind),
                      galleryRequestStatus(l10n, r.status),
                      if (r.mine) l10n.galleryRequestMine,
                    ].join(' · '),
                    style: context.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            if (onReport != null)
              IconButton(
                key: Key('galleryRequestReport-${r.id}'),
                tooltip: l10n.reportGalleryRequest,
                visualDensity: VisualDensity.compact,
                icon: Icon(LucideIcons.flag, size: 16, color: muted),
                onPressed: onReport,
              ),
          ],
        ),
      ),
    );
  }
}

class _NewRequestSheet extends ConsumerStatefulWidget {
  const _NewRequestSheet({this.title, this.kind});
  final String? title;
  final String? kind;

  @override
  ConsumerState<_NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends ConsumerState<_NewRequestSheet> {
  late final _title = TextEditingController(text: widget.title ?? '');
  final _details = TextEditingController();
  late var _kind = galleryRequestKinds.contains(widget.kind)
      ? widget.kind!
      : 'skill';
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final title = _title.text.trim();
    if (title.length < 4 || title.length > 80) {
      setState(() {
        _error = l10n.galleryRequestTitleLength;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final details = _details.text.trim();
      final created = await ref
          .read(backendProvider)
          .createGalleryRequest(
            kind: _kind,
            title: title,
            details: details.isEmpty ? null : details,
          );
      if (mounted) Navigator.of(context).pop(created);
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
      showError(context, e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.lightbulb,
      title: l10n.galleryRequestNew,
      subtitle: l10n.galleryRequestNewHelp,
      submitLabel: l10n.galleryRequestSend,
      submitKey: const Key('galleryRequestSend'),
      busy: _busy,
      onSubmit: _send,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('galleryRequestKind'),
          initialValue: _kind,
          decoration: InputDecoration(labelText: l10n.galleryRequestKind),
          items: [
            for (final k in galleryRequestKinds)
              DropdownMenuItem(value: k, child: Text(galleryKindName(l10n, k))),
          ],
          onChanged: (v) => setState(() {
            _kind = v ?? _kind;
          }),
        ),
        TextField(
          key: const Key('galleryRequestTitle'),
          controller: _title,
          maxLength: 80,
          autofocus: widget.title == null,
          decoration: InputDecoration(
            labelText: l10n.galleryRequestTitleLabel,
            errorText: _error,
          ),
        ),
        TextField(
          key: const Key('galleryRequestDetails'),
          controller: _details,
          maxLength: 500,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(labelText: l10n.galleryRequestDetails),
        ),
      ],
    );
  }
}
