import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../integrations/app_logo.dart';

/// What a bot's MessageDraft component (D-335) shows: an email, a chat message or a post it wrote
/// for the person to check, change and send.
class DraftSpec {
  const DraftSpec({
    required this.kind,
    required this.body,
    this.app,
    this.title,
    this.status,
    this.sendLabel,
    this.from,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.subject,
  });

  /// "email", "message" or "post".
  final String kind;
  final String body;
  final String? app;
  final String? title;
  final String? status;
  final String? sendLabel;
  final String? from;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String? subject;

  bool get isEmail => kind == 'email';
  bool get isPost => kind == 'post';

  static List<String> _people(Object? v) => switch (v) {
    final String s => splitPeople(s),
    final List<Object?> l => [for (final x in l) ...splitPeople('${x ?? ''}')],
    _ => const [],
  };

  /// "a@x.com, b@y.com; c@z.com" as its addresses.
  static List<String> splitPeople(String s) => [
    for (final p in s.split(RegExp(r'[,;\n]')))
      if (p.trim().isNotEmpty) p.trim(),
  ];

  static String? _text(ComponentProps props, String key) {
    final v = props.string(key)?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  /// This draft as it was sent from its card ("draft.send" [values]): what the answered card shows.
  DraftSpec sentAs(Map<String, Object?> values) => DraftSpec(
    kind: kind,
    body: '${values['body'] ?? body}',
    app: app,
    title: title,
    status: status,
    sendLabel: sendLabel,
    from: from,
    to: _people(values['to']),
    cc: _people(values['cc']),
    bcc: _people(values['bcc']),
    subject: switch (values['subject']) {
      final String s when s.trim().isNotEmpty => s.trim(),
      _ => null,
    },
  );

  static DraftSpec of(ComponentProps props) {
    final kind = switch (props.string('kind')) {
      'message' => 'message',
      'post' => 'post',
      _ => 'email',
    };
    return DraftSpec(
      kind: kind,
      body: props.string('body') ?? '',
      app: _text(props, 'app'),
      title: _text(props, 'title'),
      status: _text(props, 'status'),
      sendLabel: _text(props, 'sendLabel'),
      from: _text(props, 'from'),
      to: _people(props.value('to')),
      cc: _people(props.value('cc')),
      bcc: _people(props.value('bcc')),
      subject: _text(props, 'subject'),
    );
  }
}

/// The A2UI `MessageDraft` component, Casama's own addition to the basic catalog (D-335). Its
/// Send and Discard buttons are its own, so the "draft.send" event only ever comes from a draft
/// the person saw: the server lets the matching send through without asking again.
final draftComponent = ComponentImplementation(
  name: 'MessageDraft',
  schema: Schema.fromMap(const <String, Object?>{
    'type': 'object',
    'properties': <String, Object?>{
      'component': <String, Object?>{'const': 'MessageDraft'},
      'kind': <String, Object?>{'type': 'string'},
      'app': <String, Object?>{'type': 'string'},
      'title': <String, Object?>{'type': 'string'},
      'status': <String, Object?>{'type': 'string'},
      'sendLabel': <String, Object?>{'type': 'string'},
      'from': <String, Object?>{'type': 'string'},
      'to': <String, Object?>{},
      'cc': <String, Object?>{},
      'bcc': <String, Object?>{},
      'subject': <String, Object?>{'type': 'string'},
      'body': <String, Object?>{'type': 'string'},
    },
    'required': <Object?>['component'],
  }),
  builder: (context, node, props, buildChild) {
    final spec = DraftSpec.of(props);
    if (spec.body.trim().isEmpty) return const SizedBox.shrink();
    final surface = node.context?.surface;
    final sent = surface == null
        ? null
        : _sentDrafts[surface]?[node.instanceId];
    return BotDraftCard(
      // The card rebuilds once answered: it then shows what was sent, edits included.
      key: ValueKey(sent),
      spec: sent == null ? spec : spec.sentAs(sent),
      onAction: (name, values, label) {
        if (name == 'draft.send' && surface != null) {
          (_sentDrafts[surface] ??= {})[node.instanceId] = values;
        }
        node.context?.dispatchAction({
          'event': {'name': name, 'context': values, 'userMessage': label},
        });
      },
    );
  },
);

/// What each draft card on a surface sent, by component id, for as long as the surface lives.
final _sentDrafts = Expando<Map<String, Map<String, Object?>>>('sentDrafts');

/// A draft in a bot's card: a header with its status, the message on a plain panel, and Send,
/// Discard and Edit under it. Edit turns the fields into text boxes; Send sends what is shown.
class BotDraftCard extends StatefulWidget {
  const BotDraftCard({
    super.key,
    required this.spec,
    required this.onAction,
    this.readOnly = false,
  });
  final DraftSpec spec;

  /// Just the message, without header or buttons: an approval card's preview (D-337).
  final bool readOnly;
  final void Function(String name, Map<String, Object?> values, String label)
  onAction;

  @override
  State<BotDraftCard> createState() => _BotDraftCardState();
}

class _BotDraftCardState extends State<BotDraftCard> {
  bool _editing = false;
  late final _to = TextEditingController(text: widget.spec.to.join(', '));
  late final _cc = TextEditingController(text: widget.spec.cc.join(', '));
  late final _bcc = TextEditingController(text: widget.spec.bcc.join(', '));
  late final _subject = TextEditingController(text: widget.spec.subject ?? '');
  late final _body = TextEditingController(text: widget.spec.body);

  @override
  void dispose() {
    for (final c in [_to, _cc, _bcc, _subject, _body]) {
      c.dispose();
    }
    super.dispose();
  }

  DraftSpec get spec => widget.spec;

  bool get _edited =>
      _to.text != spec.to.join(', ') ||
      _cc.text != spec.cc.join(', ') ||
      _bcc.text != spec.bcc.join(', ') ||
      _subject.text != (spec.subject ?? '') ||
      _body.text != spec.body;

  /// Exactly what the card shows, for the bot to send.
  Map<String, Object?> _values() {
    final to = DraftSpec.splitPeople(_to.text),
        cc = DraftSpec.splitPeople(_cc.text),
        bcc = DraftSpec.splitPeople(_bcc.text);
    final subject = _subject.text.trim();
    return {
      'kind': spec.kind,
      'app': ?spec.app,
      'from': ?spec.from,
      if (to.isNotEmpty) 'to': to,
      if (cc.isNotEmpty) 'cc': cc,
      if (bcc.isNotEmpty) 'bcc': bcc,
      if (subject.isNotEmpty) 'subject': subject,
      'body': _body.text.trim(),
      'edited': _edited,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    final hairline = context.appColors.hairline;
    final title =
        spec.title ??
        (spec.isEmail
            ? l10n.draftNewEmail
            : spec.isPost
            ? l10n.draftNewPost
            : l10n.draftNewMessage);
    final status =
        spec.status ??
        (spec.isPost ? l10n.draftReadyToPost : l10n.draftReadyToSend);
    final sendLabel =
        spec.sendLabel ??
        (spec.isEmail
            ? l10n.draftSendEmail
            : spec.isPost
            ? l10n.draftPost
            : l10n.draftSend);
    final labelStyle = tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final valueStyle = tt.bodyMedium?.copyWith(color: scheme.onSurface);
    final canSend =
        _body.text.trim().isNotEmpty &&
        (spec.isPost ||
            DraftSpec.splitPeople(_to.text).isNotEmpty ||
            spec.to.isEmpty);

    Widget field(String label, TextEditingController c, {bool show = true}) {
      if (!show) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: _editing
                  ? TextField(
                      controller: c,
                      style: valueStyle,
                      decoration: _bare,
                      onChanged: (_) => setState(() {}),
                    )
                  : Text(
                      c.text,
                      style: valueStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[
      if (spec.from != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Text(l10n.draftFrom, style: labelStyle),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  spec.from!,
                  style: valueStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      if (!spec.isPost)
        field(l10n.draftTo, _to, show: spec.to.isNotEmpty || _editing),
      field(
        l10n.draftCc,
        _cc,
        show: spec.cc.isNotEmpty || (_editing && spec.isEmail),
      ),
      field(l10n.draftBcc, _bcc, show: spec.bcc.isNotEmpty),
      field(
        l10n.draftSubject,
        _subject,
        show: spec.subject != null || (_editing && spec.isEmail),
      ),
    ].where((w) => w is! SizedBox).toList();

    final body = Padding(
      padding: EdgeInsets.only(top: rows.isEmpty ? 14 : 12, bottom: 14),
      child: _editing
          ? TextField(
              controller: _body,
              style: valueStyle?.copyWith(height: 1.5),
              decoration: _bare,
              minLines: 3,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            )
          : SelectableText(
              _body.text,
              style: valueStyle?.copyWith(height: 1.5),
            ),
    );

    final pill = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: WidgetStatePropertyAll(
        tt.labelLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.readOnly) ...[
          Row(
            children: [
              if (hasBundledAppLogo(spec.app)) ...[
                AppLogo(appId: spec.app, name: spec.app!, size: 20),
                const SizedBox(width: AppSpace.xs),
              ],
              Expanded(
                child: Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    fontFamily: AppFonts.sans,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _edited
                            ? context.appColors.warning
                            : scheme.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _edited ? l10n.draftEdited : status,
                      style: tt.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            border: Border.all(color: hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in rows) ...[
                r,
                Divider(height: 1, thickness: 1, color: hairline),
              ],
              body,
            ],
          ),
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                key: const Key('draftSend'),
                style: pill,
                onPressed: canSend
                    ? () => widget.onAction('draft.send', _values(), sendLabel)
                    : null,
                child: Text(sendLabel),
              ),
              OutlinedButton(
                key: const Key('draftDiscard'),
                style: pill.copyWith(
                  foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
                  side: WidgetStatePropertyAll(
                    BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                onPressed: () => widget.onAction('draft.discard', {
                  'kind': spec.kind,
                }, l10n.draftDiscard),
                child: Text(l10n.draftDiscard),
              ),
              TextButton(
                key: const Key('draftEdit'),
                style: pill.copyWith(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xs,
                    ),
                  ),
                ),
                onPressed: () => setState(() => _editing = !_editing),
                child: Text(_editing ? l10n.draftDoneEditing : l10n.draftEdit),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

const _bare = InputDecoration(
  isDense: true,
  contentPadding: EdgeInsets.zero,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  filled: false,
);
