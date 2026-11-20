import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/haptics.dart';
import '../../core/id_token_email.dart';
import '../../core/link_browser.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/form_sheet.dart';
import 'invite_gate.dart';

/// Where "Run It Yourself" goes: the self-hosting guide.
final selfHostingDocs = Uri.parse('https://docs.casama.ai/self-hosting/');

/// Join the Waitlist (D-427, WAITLIST-PLAN §5.2, §5.4): email, one optional line, two boxes, then a
/// calm "You're on the list". The server answers the same for every address, so this does too.
class JoinWaitlistSheet extends ConsumerStatefulWidget {
  const JoinWaitlistSheet({super.key, this.initialEmail});

  /// The address a refused sign-in used (D-427): typed, or from the Apple or Google sheet.
  final String? initialEmail;

  @override
  ConsumerState<JoinWaitlistSheet> createState() => _JoinWaitlistSheetState();
}

class _JoinWaitlistSheetState extends ConsumerState<JoinWaitlistSheet> {
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  late final _prefilled = (widget.initialEmail ?? '').isNotEmpty;
  final _note = TextEditingController();
  var _selfHosting = false;
  var _newsletter = false;
  var _invalid = false;
  var _busy = false;
  var _joined = false;

  @override
  void dispose() {
    _email.dispose();
    _note.dispose();
    super.dispose();
  }

  static bool _validEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  Future<void> _join() async {
    final email = _email.text.trim();
    if (!_validEmail(email)) {
      setState(() => _invalid = true);
      return;
    }
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref
          .read(backendProvider)
          .joinWaitlist(
            WaitlistJoin(
              email: email,
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              selfHosting: _selfHosting,
              newsletter: _newsletter,
            ),
          );
      return true;
    });
    if (!mounted) return;
    if (ok == true) HapticsHelper.success();
    setState(() {
      _busy = false;
      _joined = ok == true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final muted = context.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );
    if (_joined) {
      return FormSheet(
        key: const Key('waitlistJoined'),
        art: 'wait-envelope',
        icon: LucideIcons.circleCheck,
        iconColor: context.appColors.positive,
        title: l10n.waitlistJoinedTitle,
        subtitle: l10n.waitlistJoinedBody,
        submitLabel: l10n.doneLabel,
        submitKey: const Key('waitlistDone'),
        onSubmit: () => Navigator.of(context).maybePop(),
        showCancel: false,
        children: [
          Text(l10n.waitlistJoinedCode, style: muted),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: const Key('waitlistHaveInvite'),
              style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
              onPressed: () => replaceSheet(context, openHaveInvite),
              icon: const Icon(LucideIcons.ticket, size: 18),
              label: Text(l10n.iHaveAnInvite),
            ),
          ),
          Text(l10n.waitlistJoinedSelfHost, style: muted),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('waitlistSelfHost'),
              onPressed: () => openWebLink(selfHostingDocs),
              icon: const Icon(LucideIcons.serverCog, size: 18),
              label: Text(l10n.waitlistRunItYourself),
            ),
          ),
        ],
      );
    }
    return FormSheet(
      key: const Key('joinWaitlistForm'),
      art: 'wait-hourglass',
      icon: LucideIcons.listPlus,
      title: l10n.joinTheWaitlist,
      subtitle: l10n.waitlistSubtitle,
      submitLabel: l10n.joinTheWaitlist,
      submitKey: const Key('waitlistSubmit'),
      busy: _busy,
      onSubmit: _join,
      cancelLabel: l10n.cancel,
      children: [
        TextField(
          key: const Key('waitlistEmail'),
          controller: _email,
          // Filled in already: the keyboard waits for the one optional line instead.
          autofocus: !_prefilled,
          autocorrect: false,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          maxLength: 254,
          buildCounter: _noCounter,
          decoration: InputDecoration(
            labelText: l10n.email,
            hintText: 'you@example.com',
            prefixIcon: const Icon(LucideIcons.atSign, size: 20),
            errorText: _invalid ? l10n.invalidEmail : null,
          ),
          onChanged: (_) => setState(() => _invalid = false),
        ),
        // Apple's "Hide My Email": this private address is the one a later Continue with Apple
        // signs in with, so it is the one to keep on the list.
        if (isAppleRelayEmail(_email.text))
          Text(
            l10n.waitlistAppleRelay,
            key: const Key('waitlistAppleRelay'),
            style: muted,
          ),
        TextField(
          key: const Key('waitlistNote'),
          controller: _note,
          maxLength: 280,
          buildCounter: _noCounter,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.waitlistNote,
            hintText: l10n.waitlistNoteHint,
            prefixIcon: const Icon(LucideIcons.sparkles, size: 20),
          ),
          onSubmitted: (_) => _join(),
        ),
        FormSwitch(
          key: const Key('waitlistSelfHosting'),
          icon: LucideIcons.server,
          title: l10n.waitlistSelfHosting,
          value: _selfHosting,
          onChanged: _busy ? null : (v) => setState(() => _selfHosting = v),
        ),
        CheckboxListTile(
          key: const Key('waitlistNewsletter'),
          value: _newsletter,
          onChanged: _busy
              ? null
              : (v) => setState(() => _newsletter = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text(
            l10n.waitlistNewsletter,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xxs),
      ],
    );
  }
}

Widget? _noCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) => null;
