import 'package:casama_sdk/casama_sdk.dart'
    show
        InviteCodePreview,
        InviteCodePreviewKindEnum,
        InviteRedeemedOutcomeEnum,
        problemOf;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/display_text.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/brand_sign_in_buttons.dart';
import '../../ui/form_sheet.dart';
import '../../ui/otp_code_field.dart';
import 'invite_gate.dart';

enum _Step { code, choose, email, inbox, waitlisted }

/// I Have an Invite (D-427, WAITLIST-PLAN §7.3): the code first (a pasted invite link works too),
/// who it's from, then the ways to sign in. Email claims the code for the address and sends a
/// sign-in email that carries the code; Apple and Google get the ID token from the system sheet
/// first and sign in with it only once the server has let that address in.
class HaveInviteSheet extends ConsumerStatefulWidget {
  const HaveInviteSheet({super.key, this.initialCode, this.initialEmail});

  /// From an invite link the app opened; checked straight away.
  final String? initialCode;

  /// The address a refused sign-in used, filled in for the email step.
  final String? initialEmail;

  @override
  ConsumerState<HaveInviteSheet> createState() => _HaveInviteSheetState();
}

class _HaveInviteSheetState extends ConsumerState<HaveInviteSheet> {
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _otp = TextEditingController();
  var _step = _Step.code;
  var _busy = false;
  String? _codeError;
  var _emailInvalid = false;
  var _otpInvalid = false;
  InviteCodePreview? _preview;
  String? _sentTo;

  /// The code as checked (stripped of any link around it).
  String get _theCode => inviteCodeFrom(_code.text);

  @override
  void initState() {
    super.initState();
    if ((widget.initialCode ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _check();
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  static bool _validEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  Future<void> _check() async {
    final code = _theCode;
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _codeError = null;
    });
    try {
      final preview = await ref.read(backendProvider).previewInviteCode(code);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _step = preview.available ? _Step.choose : _Step.email;
      });
    } catch (e) {
      if (!mounted) return;
      final notFound = problemOf(e)?.code == 'invite_not_found';
      setState(
        () => _codeError = notFound
            ? context.l10n.inviteNotFound
            : errorText(context, e),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claimWithEmail() async {
    final email = _email.text.trim();
    if (!_validEmail(email)) {
      setState(() => _emailInvalid = true);
      return;
    }
    setState(() => _busy = true);
    final backend = ref.read(backendProvider);
    final outcome = await runSignInGuarded(context, () async {
      final r = await backend.redeemInviteForEmail(_theCode, email);
      if (r.outcome != InviteRedeemedOutcomeEnum.admitted) {
        return InviteRedeemedOutcomeEnum.waitlisted;
      }
      // Let in: the usual sign-in email, carrying the code so the server admits it on the spot too.
      await backend.sendMagicLinkWithInvite(email, _theCode);
      return InviteRedeemedOutcomeEnum.admitted;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (outcome == InviteRedeemedOutcomeEnum.admitted) {
        HapticsHelper.success();
        _sentTo = email;
        _otp.clear();
        _otpInvalid = false;
        _step = _Step.inbox;
      } else if (outcome == InviteRedeemedOutcomeEnum.waitlisted) {
        _step = _Step.waitlisted;
      }
    });
  }

  Future<void> _verify() async {
    final email = _sentTo;
    final code = _otp.text;
    if (email == null || code.length != OtpCodeField.length || _busy) return;
    setState(() => _busy = true);
    final ok = await runSignInGuarded(context, () async {
      await ref.read(backendProvider).verifyEmailCode(email, code);
      return true;
    });
    if (!mounted) return;
    if (ok == true) HapticsHelper.success();
    setState(() {
      _busy = false;
      _otpInvalid = ok != true;
    });
  }

  Future<void> _provider(String provider) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await runSignInGuarded(
      context,
      () => ref.read(backendProvider).signInWithInvite(provider, _theCode),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result == InviteSignInResult.waitlisted) _step = _Step.waitlisted;
    });
    if (result == InviteSignInResult.unavailable) {
      showMessage(context, context.l10n.inviteUseEmailHere);
    }
  }

  void _differentCode() => setState(() {
    _step = _Step.code;
    _preview = null;
    _codeError = null;
  });

  /// "Ana invited you to Casama", the campaign's label, or a plain line.
  String _from(InviteCodePreview p) {
    final l10n = context.l10n;
    if (p.kind == InviteCodePreviewKindEnum.campaign && p.label.isUsable) {
      return l10n.inviteFromCampaign(p.label!);
    }
    if (p.kind == InviteCodePreviewKindEnum.personal) {
      return p.inviterName.isUsable
          ? l10n.inviteFromName(p.inviterName!)
          : l10n.inviteFromFriend;
    }
    return l10n.inviteFromCasama;
  }

  Widget _busyBox(Widget child) => _busy
      ? const Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        )
      : child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Signed in (the code from the email, or Apple or Google): this sheet goes too.
    ref.listen(signedInProvider, (_, next) {
      if (next.value == true && mounted) Navigator.of(context).maybePop();
    });
    final preview = _preview;
    return switch (_step) {
      _Step.code => FormSheet(
        key: const Key('haveInviteCode'),
        art: 'wait-ticket',
        icon: LucideIcons.ticket,
        title: l10n.iHaveAnInvite,
        subtitle: l10n.inviteSubtitle,
        submitLabel: l10n.continueLabel,
        submitKey: const Key('inviteCheck'),
        busy: _busy,
        onSubmit: _check,
        cancelLabel: l10n.cancel,
        children: [
          TextField(
            key: const Key('inviteCode'),
            controller: _code,
            autofocus: (widget.initialCode ?? '').isEmpty,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.go,
            decoration: InputDecoration(
              labelText: l10n.inviteCodeLabel,
              prefixIcon: const Icon(LucideIcons.ticket, size: 20),
              errorText: _codeError,
              errorMaxLines: 3,
            ),
            onChanged: (_) {
              if (_codeError != null) setState(() => _codeError = null);
            },
            onSubmitted: (_) => _check(),
          ),
        ],
      ),
      _Step.choose => FormSheet(
        key: const Key('haveInviteChoose'),
        art: 'wait-gift',
        icon: LucideIcons.gift,
        title: _from(preview!),
        subtitle: l10n.inviteChooseSignIn,
        submitLabel: l10n.continueWithEmail,
        submitIcon: LucideIcons.mail,
        submitKey: const Key('inviteWithEmail'),
        onSubmit: _busy ? null : () => setState(() => _step = _Step.email),
        cancelLabel: l10n.inviteDifferentCode,
        onCancel: _busy ? null : _differentCode,
        children: [_providerButtons(context)],
      ),
      _Step.email => FormSheet(
        key: const Key('haveInviteEmail'),
        art: 'wait-envelope',
        icon: preview?.available == false
            ? LucideIcons.hourglass
            : LucideIcons.mail,
        title: preview == null ? l10n.iHaveAnInvite : _from(preview),
        subtitle: preview?.available == false
            ? l10n.inviteGoneHelp
            : l10n.inviteEmailHelp,
        submitLabel: l10n.continueLabel,
        submitKey: const Key('inviteEmailSubmit'),
        busy: _busy,
        onSubmit: _claimWithEmail,
        cancelLabel: preview?.available == false
            ? l10n.inviteDifferentCode
            : l10n.cancel,
        onCancel: _busy
            ? null
            : preview?.available == false
            ? _differentCode
            : () => setState(() => _step = _Step.choose),
        children: [
          TextField(
            key: const Key('inviteEmail'),
            controller: _email,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.send,
            decoration: InputDecoration(
              labelText: l10n.email,
              hintText: 'you@example.com',
              prefixIcon: const Icon(LucideIcons.atSign, size: 20),
              errorText: _emailInvalid ? l10n.invalidEmail : null,
            ),
            onChanged: (_) {
              if (_emailInvalid) setState(() => _emailInvalid = false);
            },
            onSubmitted: (_) => _claimWithEmail(),
          ),
        ],
      ),
      _Step.inbox => FormSheet(
        key: const Key('haveInviteInbox'),
        art: 'wait-envelope',
        icon: LucideIcons.mailCheck,
        iconColor: context.appColors.positive,
        title: l10n.checkInboxTitle,
        subtitle: l10n.inviteCheckInbox(_sentTo ?? ''),
        submitLabel: l10n.signIn,
        submitKey: const Key('inviteVerify'),
        busy: _busy,
        onSubmit: _verify,
        cancelLabel: l10n.useDifferentEmail,
        onCancel: _busy ? null : () => setState(() => _step = _Step.email),
        children: [
          OtpCodeField(
            key: const Key('inviteOtp'),
            controller: _otp,
            label: l10n.emailCodeLabel,
            invalid: _otpInvalid,
            onChanged: (_) {
              if (_otpInvalid) setState(() => _otpInvalid = false);
            },
            onCompleted: (_) => _verify(),
            onSubmitted: _verify,
          ),
        ],
      ),
      _Step.waitlisted => FormSheet(
        key: const Key('haveInviteWaitlisted'),
        art: 'wait-hourglass',
        icon: LucideIcons.hourglass,
        title: l10n.inviteWaitlistedTitle,
        subtitle: l10n.inviteWaitlisted,
        submitLabel: l10n.doneLabel,
        submitKey: const Key('inviteDone'),
        onSubmit: () => Navigator.of(context).maybePop(),
        showCancel: false,
        children: const [],
      ),
    };
  }

  /// Apple and Google, where this device has their system sheet; the order follows the sign-in
  /// screen (Apple first where Apple people are).
  Widget _providerButtons(BuildContext context) {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    final appleFirst =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final buttons = <Widget>[
      if (backend.inviteSignInAvailable('apple'))
        SizedBox(
          height: 50,
          child: AppleSignInButton(
            key: const Key('inviteApple'),
            label: l10n.continueWithApple,
            onPressed: _busy ? null : () => _provider('apple'),
          ),
        ),
      if (backend.inviteSignInAvailable('google'))
        SizedBox(
          height: 50,
          child: GoogleSignInButton(
            key: const Key('inviteGoogle'),
            label: l10n.continueWithGoogle,
            onPressed: _busy ? null : () => _provider('google'),
          ),
        ),
    ];
    final ordered = appleFirst ? buttons : buttons.reversed.toList();
    if (ordered.isEmpty) return const SizedBox.shrink();
    return _busyBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.sm,
        children: ordered,
      ),
    );
  }
}
