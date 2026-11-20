import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/id_token_email.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import 'have_invite_sheet.dart';
import 'join_waitlist_sheet.dart';

/// Casama Cloud's invite gate in the app (D-427, WAITLIST-PLAN §2.3, §7.3): the line on the sign-in
/// screen, the sheet a refused sign-up gets, and the way to the waitlist and invite screens.

/// The sentence Auth passes on when the gate refuses a new account, or null for any other error.
/// Matches the hook's two sentences: "Casama Cloud is invite-only for now…" and, for an Apple
/// address that isn't the one invited, "Your invite is for another email address…".
String? inviteRefusalMessage(Object error) {
  if (error is! sb.AuthException) return null;
  final message = error.message;
  if (message.contains('invite-only') ||
      message.contains('Your invite is for another email address')) {
    return message;
  }
  return null;
}

/// [runGuarded] for sign-in and sign-up: the gate's refusal opens [showInviteRefusal] instead of a
/// toast; every other error is shown as usual. [email] is the address the person typed, if any;
/// an Apple or Google refusal brings its own.
Future<T?> runSignInGuarded<T>(
  BuildContext context,
  Future<T> Function() action, {
  String? email,
}) async {
  try {
    return await action();
  } catch (e, st) {
    if (!context.mounted) return null;
    final refusal = inviteRefusalMessage(e);
    if (refusal != null) {
      // Not awaited: the button behind it stops spinning while the sheet is up.
      final known = e is IdTokenAuthException ? e.email : email;
      unawaited(showInviteRefusal(context, refusal, email: known));
      return null;
    }
    return runGuarded<T>(context, () => Future<T>.error(e, st));
  }
}

/// The code inside what a person typed or pasted: a bare code, or an invite link
/// (`casama.ai/invite/<code>`, `casama.ai/i/<code>`, with or without https and a query).
String inviteCodeFrom(String input) {
  final text = input.trim();
  final link = RegExp(
    r'(?:^|/)(?:invite|i)/([^/?#\s]+)',
    caseSensitive: false,
  ).firstMatch(text);
  final code = link != null ? Uri.decodeComponent(link.group(1)!) : text;
  return code.trim();
}

/// Opens Join the Waitlist, with [email] already filled in (the address a refused sign-in used).
Future<void> openJoinWaitlist(BuildContext context, {String? email}) =>
    showAdaptiveSheet<void>(
      context: context,
      dialogMaxWidth: 480,
      builder: (_) => JoinWaitlistSheet(initialEmail: email),
    );

/// Opens I Have an Invite, with [code] already filled in (an invite link the app opened) and
/// [email] (the address a refused sign-in used).
Future<void> openHaveInvite(
  BuildContext context, {
  String? code,
  String? email,
}) => showAdaptiveSheet<void>(
  context: context,
  dialogMaxWidth: 480,
  builder: (_) => HaveInviteSheet(initialCode: code, initialEmail: email),
);

/// Closes the sheet [context] is in, then opens [next] from the navigator under it.
void replaceSheet(
  BuildContext context,
  Future<void> Function(BuildContext context) next,
) {
  final navigator = Navigator.of(context);
  navigator.pop();
  next(navigator.context);
}

/// Instead of a toast: the gate's sentence, with the two ways forward. [email] fills in the next
/// sheet, so nobody types again the address they just used.
Future<void> showInviteRefusal(
  BuildContext context,
  String message, {
  String? email,
}) {
  final l10n = context.l10n;
  // The usual sentence ends with "at casama.ai/waitlist"; in the app the buttons are right here.
  final otherEmail = message.contains(
    'Your invite is for another email address',
  );
  return showAdaptiveSheet<void>(
    context: context,
    dialogMaxWidth: 460,
    builder: (sheet) => FormSheet(
      key: const Key('inviteRefusal'),
      art: 'wait-ticket',
      icon: LucideIcons.ticket,
      title: otherEmail ? message : l10n.inviteGateLine,
      subtitle: otherEmail ? null : l10n.inviteRefusedHelp,
      submitLabel: l10n.joinTheWaitlist,
      submitKey: const Key('refusalJoinWaitlist'),
      onSubmit: () =>
          replaceSheet(sheet, (c) => openJoinWaitlist(c, email: email)),
      cancelLabel: l10n.notNow,
      children: [
        OutlinedButton.icon(
          key: const Key('refusalHaveInvite'),
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(48),
          ),
          // A relay address stays out of the email step: Continue with Apple there brings it.
          onPressed: () => replaceSheet(
            sheet,
            (c) => openHaveInvite(
              c,
              email: email != null && !isAppleRelayEmail(email) ? email : null,
            ),
          ),
          icon: const Icon(LucideIcons.ticket, size: 18),
          label: Text(l10n.iHaveAnInvite),
        ),
      ],
    ),
  );
}

/// "Casama Cloud is invite-only for now." with Join the Waitlist and I Have an Invite, while the
/// server says its gate is on. Nothing on servers without one (every self-hosted server).
class InviteGateBlock extends ConsumerWidget {
  const InviteGateBlock({super.key, this.closeFirst = false});

  /// In the sign-in sheet: close it before opening the next one.
  final bool closeFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(backendProvider).signupGate == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    void open(Future<void> Function(BuildContext) next) =>
        closeFirst ? replaceSheet(context, next) : next(context);
    return Column(
      key: const Key('inviteGate'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.inviteGateLine,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.xs,
          children: [
            TextButton(
              key: const Key('joinWaitlist'),
              onPressed: () => open(openJoinWaitlist),
              child: Text(l10n.joinTheWaitlist),
            ),
            TextButton(
              key: const Key('haveInvite'),
              onPressed: () => open(openHaveInvite),
              child: Text(l10n.iHaveAnInvite),
            ),
          ],
        ),
      ],
    );
  }
}
