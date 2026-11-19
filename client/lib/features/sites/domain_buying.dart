import 'package:casama_sdk/casama_sdk.dart';
import 'package:dio/dio.dart' show DioException;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/billing.dart';
import '../../core/distribution.dart';
import '../../core/providers.dart';
import '../../core/remote_config.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import '../billing/billing_screen.dart'
    show platformProvider, storefrontProvider;

/// The domain terms a buyer accepts (SITES-AND-DOMAINS-PLAN §7.7).
const domainTermsUrl = 'https://docs.casama.ai/guide/domain-terms';

/// Whether this workspace admin can buy a domain here: the server sells them
/// (`sites.buy_domains`) and this platform allows a web payment (D-070). Never in the Android app,
/// nor in an App Store build outside the US storefront.
final canBuyDomainsProvider = Provider<bool>((ref) {
  if (ref.watch(backendProvider).sitesConfig?.buyDomains != true) return false;
  final org = ref.watch(currentOrgProvider);
  if (org == null || org.role == OrgRole.member) return false;
  final platform = ref.watch(platformProvider);
  // `buy_domains_app_store: false` (Admin → remote settings) turns domain buying off in the App
  // Store builds only; web, desktop and Android are unaffected. It can only remove the feature,
  // never add one, and the App Review notes describe it.
  final appStoreBuild =
      !kIsWeb &&
      (platform == TargetPlatform.iOS ||
          (platform == TargetPlatform.macOS && isMacAppStoreBuild));
  if (appStoreBuild &&
      ref.watch(remoteConfigProvider).value?.flags['buy_domains_app_store'] ==
          false) {
    return false;
  }
  var channels = purchaseChannels(platform: platform, isWeb: kIsWeb);
  // Only the App Store builds depend on the storefront; ask the store only there.
  if (!channels.contains(PurchaseChannel.web) &&
      !kIsWeb &&
      platform != TargetPlatform.android) {
    channels = purchaseChannels(
      platform: platform,
      isWeb: kIsWeb,
      storefront: ref.watch(storefrontProvider).value,
    );
  }
  return channels.contains(PurchaseChannel.web);
});

/// Whether the server sells domains at all, even where this app can't take the payment.
final sellsDomainsProvider = Provider<bool>(
  (ref) => ref.watch(backendProvider).sitesConfig?.buyDomains ?? false,
);

/// A price in dollars, like $14.50.
String domainUsd(BuildContext context, num value) =>
    formatUsd(value, context.l10n.localeName);

/// The server's error code (`plan_limit`, `contact_required`…), if it sent one.
String? problemCode(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['code'] is String) return data['code'] as String;
  }
  return problemOf(error)?.code;
}

/// The HTTP status of a failed call, if it reached the server.
int? problemStatus(Object error) =>
    error is DioException ? error.response?.statusCode : null;

// --- Contact details -----------------------------------------------------------------------------

/// The checks of `checkDomainContact` (packages/domain), field by field, so the form says what to
/// fix before it's sent.
abstract final class DomainContactRules {
  static bool country(String v) => RegExp(r'^[A-Z]{2}$').hasMatch(v);
  static bool phone(String v) =>
      RegExp(r'^\+\d{1,3}\.?\d{4,14}$')
          .hasMatch(v.replaceAll(RegExp(r'[\s()-]'), ''));
  static bool email(String v) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
}

/// The text fields of a registrant, filled from what's saved or the account's email.
class _ContactFields {
  _ContactFields(DomainContact? c, String? defaultEmail)
    : first = TextEditingController(text: c?.firstName ?? ''),
      last = TextEditingController(text: c?.lastName ?? ''),
      org = TextEditingController(text: c?.organization ?? ''),
      address1 = TextEditingController(text: c?.address1 ?? ''),
      address2 = TextEditingController(text: c?.address2 ?? ''),
      city = TextEditingController(text: c?.city ?? ''),
      state = TextEditingController(text: c?.state ?? ''),
      zip = TextEditingController(text: c?.zip ?? ''),
      country = TextEditingController(text: c?.country ?? ''),
      phone = TextEditingController(text: c?.phone ?? ''),
      email = TextEditingController(text: c?.email ?? defaultEmail ?? '');

  final TextEditingController first, last, org, address1, address2, city;
  final TextEditingController state, zip, country, phone, email;

  List<TextEditingController> get _all => [
    first,
    last,
    org,
    address1,
    address2,
    city,
    state,
    zip,
    country,
    phone,
    email,
  ];

  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
  }

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  DomainContact get value => DomainContact(
    firstName: first.text.trim(),
    lastName: last.text.trim(),
    organization: _opt(org),
    address1: address1.text.trim(),
    address2: _opt(address2),
    city: city.text.trim(),
    state: state.text.trim(),
    zip: zip.text.trim(),
    country: country.text.trim().toUpperCase(),
    phone: phone.text.trim(),
    email: email.text.trim(),
  );

  List<Widget> build(BuildContext context, {required bool showErrors}) {
    final l10n = context.l10n;
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l10n.domainContactRequired : null;
    Widget field(
      String key,
      TextEditingController c,
      String label, {
      String? hint,
      String? Function(String?)? validator,
      TextInputType? keyboard,
      TextCapitalization caps = TextCapitalization.words,
      List<String>? autofill,
    }) => TextFormField(
      key: Key('domainContact-$key'),
      controller: c,
      keyboardType: keyboard,
      textCapitalization: caps,
      autofillHints: autofill,
      autovalidateMode: showErrors
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      validator: validator,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
    return [
      field(
        'first',
        first,
        l10n.domainContactFirstName,
        validator: required,
        autofill: const [AutofillHints.givenName],
      ),
      field(
        'last',
        last,
        l10n.domainContactLastName,
        validator: required,
        autofill: const [AutofillHints.familyName],
      ),
      field(
        'org',
        org,
        l10n.domainContactOrganization,
        autofill: const [AutofillHints.organizationName],
      ),
      field(
        'address1',
        address1,
        l10n.domainContactAddress1,
        validator: required,
        autofill: const [AutofillHints.streetAddressLine1],
      ),
      field(
        'address2',
        address2,
        l10n.domainContactAddress2,
        autofill: const [AutofillHints.streetAddressLine2],
      ),
      field(
        'city',
        city,
        l10n.domainContactCity,
        validator: required,
        autofill: const [AutofillHints.addressCity],
      ),
      field(
        'state',
        state,
        l10n.domainContactState,
        validator: required,
        autofill: const [AutofillHints.addressState],
      ),
      field(
        'zip',
        zip,
        l10n.domainContactZip,
        validator: required,
        caps: TextCapitalization.characters,
        autofill: const [AutofillHints.postalCode],
      ),
      field(
        'country',
        country,
        l10n.domainContactCountry,
        hint: l10n.domainContactCountryHint,
        caps: TextCapitalization.characters,
        autofill: const [AutofillHints.countryCode],
        validator: (v) =>
            DomainContactRules.country((v ?? '').trim().toUpperCase())
            ? null
            : l10n.domainContactCountryInvalid,
      ),
      field(
        'phone',
        phone,
        l10n.domainContactPhone,
        hint: l10n.domainContactPhoneHint,
        keyboard: TextInputType.phone,
        caps: TextCapitalization.none,
        autofill: const [AutofillHints.telephoneNumber],
        validator: (v) => DomainContactRules.phone((v ?? '').trim())
            ? null
            : l10n.domainContactPhoneInvalid,
      ),
      field(
        'email',
        email,
        l10n.domainContactEmail,
        keyboard: TextInputType.emailAddress,
        caps: TextCapitalization.none,
        autofill: const [AutofillHints.email],
        validator: (v) => DomainContactRules.email((v ?? '').trim())
            ? null
            : l10n.domainContactEmailInvalid,
      ),
    ];
  }
}

/// The registrant form in a sheet; saves the workspace's contact and answers it, or null when
/// closed. The server's words show under the fields when it refuses them.
Future<DomainContact?> showDomainContactSheet(
  BuildContext context, {
  required String orgId,
  required DomainContactState state,
}) => showAdaptiveSheet<DomainContact>(
  context: context,
  builder: (_) => _ContactSheet(orgId: orgId, state: state),
);

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet({required this.orgId, required this.state});
  final String orgId;
  final DomainContactState state;

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  final _form = GlobalKey<FormState>();
  late final _fields = _ContactFields(
    widget.state.contact,
    widget.state.defaultEmail,
  );
  bool _showErrors = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(backendProvider)
          .saveDomainContact(widget.orgId, _fields.value);
      if (mounted) Navigator.of(context).pop(saved.contact ?? _fields.value);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorText(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _form,
      child: FormSheet(
        icon: LucideIcons.idCard,
        title: l10n.domainContactTitle,
        subtitle: l10n.domainContactHelp,
        submitLabel: l10n.domainContactSave,
        submitKey: const Key('domainContactSave'),
        busy: _busy,
        onSubmit: _save,
        children: [
          ..._fields.build(context, showErrors: _showErrors),
          if (_error != null)
            Text(
              _error!,
              key: const Key('domainContactError'),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

/// Contact Details (`/settings/domains/contact`): the workspace's registrant, for every domain
/// it bought.
class DomainContactScreen extends ConsumerStatefulWidget {
  const DomainContactScreen({super.key});

  @override
  ConsumerState<DomainContactScreen> createState() =>
      _DomainContactScreenState();
}

class _DomainContactScreenState extends ConsumerState<DomainContactScreen> {
  final _form = GlobalKey<FormState>();
  AsyncValue<DomainContactState> _state = const AsyncLoading();
  _ContactFields? _fields;
  bool _showErrors = false;
  bool _busy = false;
  String? _error;
  bool _started = false;

  @override
  void dispose() {
    _fields?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null) return;
    setState(() => _state = const AsyncLoading());
    try {
      final s = await ref.read(backendProvider).domainContact(orgId);
      if (!mounted) return;
      _fields?.dispose();
      _fields = _ContactFields(s.contact, s.defaultEmail);
      setState(() => _state = AsyncData(s));
    } catch (e, st) {
      if (mounted) setState(() => _state = AsyncError(e, st));
    }
  }

  Future<void> _save() async {
    final orgId = ref.read(currentOrgIdProvider);
    final fields = _fields;
    if (orgId == null || fields == null) return;
    if (!(_form.currentState?.validate() ?? false)) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(backendProvider).saveDomainContact(orgId, fields.value);
      if (mounted) showSuccess(context, context.l10n.domainContactSaved);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Loads once the workspace is known.
    if (ref.watch(currentOrgIdProvider) != null && !_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    return SubPage(
      title: l10n.domainContactTitle,
      body: AsyncView(
        value: _state,
        onRetry: _load,
        data: (_) => Form(
          key: _form,
          child: PageColumn(
            children: [
              FormNote(l10n.domainContactChangeNote),
              const SizedBox(height: AppSpace.md),
              for (final f in _fields!.build(context, showErrors: _showErrors))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.md),
                  child: f,
                ),
              if (_error != null) ...[
                Text(
                  _error!,
                  key: const Key('domainContactError'),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: GlowButton(
                  key: const Key('domainContactSave'),
                  onPressed: _busy ? null : _save,
                  child: Text(l10n.domainContactSave),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Signing in again ----------------------------------------------------------------------------

/// The server wants a sign-in from the last few minutes ([message] says so). Offers a fresh
/// sign-in with a code emailed to the account; true once signed in again. Without an email on the
/// account it shows [message] with a line to sign out and in again.
Future<bool> showFreshSignIn(BuildContext context, String message) async {
  final ok = await showAdaptiveSheet<bool>(
    context: context,
    builder: (_) => _FreshSignInSheet(message: message),
  );
  return ok ?? false;
}

class _FreshSignInSheet extends ConsumerStatefulWidget {
  const _FreshSignInSheet({required this.message});
  final String message;

  @override
  ConsumerState<_FreshSignInSheet> createState() => _FreshSignInSheetState();
}

class _FreshSignInSheetState extends ConsumerState<_FreshSignInSheet> {
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(String email) step) async {
    final email = ref.read(backendProvider).userEmail;
    if (email == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await step(email);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run((email) async {
    await ref.read(backendProvider).sendMagicLink(email);
    if (mounted) setState(() => _sent = true);
  });

  Future<void> _verify() => _run((email) async {
    await ref.read(backendProvider).verifyEmailCode(email, _code.text.trim());
    if (mounted) Navigator.of(context).pop(true);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = ref.watch(backendProvider).userEmail;
    if (email == null) {
      return FormSheet(
        icon: LucideIcons.logIn,
        title: l10n.domainReauthTitle,
        subtitle: '${widget.message} ${l10n.domainReauthSignOut}',
        submitLabel: l10n.close,
        showCancel: false,
        onSubmit: () => Navigator.of(context).pop(false),
        children: const [],
      );
    }
    return FormSheet(
      icon: LucideIcons.logIn,
      title: l10n.domainReauthTitle,
      subtitle: widget.message,
      submitLabel: _sent ? l10n.domainReauthSignIn : l10n.domainReauthSendCode,
      submitKey: const Key('domainReauthSubmit'),
      busy: _busy,
      onSubmit: _sent ? _verify : _send,
      children: [
        if (_sent) ...[
          Text(l10n.domainReauthCodeSent(email)),
          TextField(
            key: const Key('domainReauthCode'),
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: InputDecoration(labelText: l10n.domainReauthCode),
            onSubmitted: (_) => _verify(),
          ),
        ],
        if (_error != null)
          Text(
            _error!,
            key: const Key('domainReauthError'),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.error,
            ),
          ),
      ],
    );
  }
}

/// The words for a search result that can't be bought.
String domainReasonLabel(AppLocalizations l10n, String? reason) =>
    switch (reason) {
      'premium' => l10n.domainReasonPremium,
      'not_sold' => l10n.domainReasonNotSold,
      _ => l10n.domainReasonTaken,
    };
