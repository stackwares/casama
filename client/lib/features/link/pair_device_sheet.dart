import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/chrome_extension.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';

/// Settings → Sign In on Another Device (D-296): a QR code a phone scans to sign in to this
/// account on this server. The code works once and for a few minutes; a new one replaces it when
/// it runs out. The same code as a link can be copied and pasted into Casama for Chrome or
/// another device, and in the web app Connect Chrome hands it to the extension (D-323).
///
/// [onTurnOnLink] is given on the computer that runs this server itself: when the server only
/// answers there, the sheet offers to give it an address a phone can reach.
Future<void> showPairDevice(
  BuildContext context, {
  VoidCallback? onTurnOnLink,
}) => showAdaptiveSheet<void>(
  context: context,
  dialogMaxWidth: 460,
  builder: (_) => PairDeviceSheet(onTurnOnLink: onTurnOnLink),
);

class PairDeviceSheet extends ConsumerStatefulWidget {
  const PairDeviceSheet({super.key, this.onTurnOnLink});
  final VoidCallback? onTurnOnLink;

  @override
  ConsumerState<PairDeviceSheet> createState() => _PairDeviceSheetState();
}

class _PairDeviceSheetState extends ConsumerState<PairDeviceSheet> {
  SignInCode? _code;
  Object? _error;
  var _expired = false;
  var _connecting = false;
  Timer? _expiry;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _expiry?.cancel();
    setState(() {
      _code = null;
      _error = null;
      _expired = false;
    });
    try {
      final code = await ref.read(backendProvider).createSignInCode();
      if (!mounted) return;
      setState(() => _code = code);
      final left = code.expiresAt.difference(DateTime.now());
      _expiry = Timer(left.isNegative ? Duration.zero : left, () {
        if (mounted) setState(() => _expired = true);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _copyLink(SignInCode code) async {
    await Clipboard.setData(ClipboardData(text: code.pairUrl));
    if (mounted) showToast(context, context.l10n.pairDeviceLinkCopied);
  }

  Future<void> _connectChrome(SignInCode code) async {
    final l10n = context.l10n;
    setState(() => _connecting = true);
    ChromeHandoverResult result;
    try {
      result = await connectChrome(code.pairUrl);
    } catch (e) {
      result = ChromeHandoverResult(ChromeHandover.failed, '$e');
    }
    if (!mounted) return;
    setState(() => _connecting = false);
    switch (result.outcome) {
      case ChromeHandover.signedIn:
        showSuccess(context, l10n.pairDeviceChromeDone);
        Navigator.pop(context);
      case ChromeHandover.finishInChrome:
        showToast(context, l10n.pairDeviceChromeFinish);
        Navigator.pop(context);
      case ChromeHandover.notInstalled:
        showToast(context, l10n.pairDeviceChromeMissing, kind: ToastKind.error);
      case ChromeHandover.failed:
        showToast(
          context,
          l10n.pairDeviceChromeFailed(result.error ?? ''),
          kind: ToastKind.error,
        );
        // The code may be used up: show a fresh one.
        unawaited(_load());
    }
  }

  /// Copy the code as a link; in the web app, also hand it to Casama for Chrome.
  Widget _linkActions(SignInCode code) {
    final l10n = context.l10n;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        TextButton.icon(
          key: const Key('pairCopyLink'),
          onPressed: _expired ? null : () => _copyLink(code),
          icon: const Icon(LucideIcons.copy, size: 18),
          label: Text(l10n.pairDeviceCopyLink),
        ),
        if (kIsWeb)
          FilledButton.tonalIcon(
            key: const Key('pairConnectChrome'),
            onPressed: _expired || _connecting
                ? null
                : () => _connectChrome(code),
            icon: const Icon(LucideIcons.globe, size: 18),
            label: Text(l10n.pairDeviceConnectChrome),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final code = _code;
    final host = code == null
        ? ''
        : (Uri.tryParse(code.serverUrl)?.host ?? code.serverUrl);
    final unreachable = code != null && !code.reachable;
    final canTurnOn = unreachable && widget.onTurnOnLink != null;
    return FormSheet(
      icon: LucideIcons.scanQrCode,
      title: l10n.pairDevice,
      subtitle: unreachable ? null : l10n.pairDeviceHelp,
      submitLabel: canTurnOn ? l10n.linkTurnOn : l10n.pairDeviceNewCode,
      submitKey: Key(canTurnOn ? 'pairTurnOnLink' : 'pairNewCode'),
      submitIcon: canTurnOn ? LucideIcons.smartphone : LucideIcons.refreshCw,
      cancelLabel: l10n.close,
      onSubmit: canTurnOn
          ? () {
              Navigator.pop(context);
              widget.onTurnOnLink!();
            }
          : (code == null && _error == null ? null : _load),
      children: [
        if (_error != null)
          Text(
            errorText(context, _error!),
            key: const Key('pairError'),
            style: TextStyle(color: scheme.error),
          )
        else if (code == null)
          const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (unreachable) ...[
          Text(
            widget.onTurnOnLink != null
                ? l10n.pairDeviceNotReachable
                : l10n.pairDeviceNotReachableOther,
            key: const Key('pairNotReachable'),
          ),
          // Casama for Chrome on this computer still reaches it.
          _linkActions(code),
        ] else ...[
          Center(
            child: AnimatedOpacity(
              duration: AppMotion.of(context, AppMotion.fast),
              opacity: _expired ? 0.12 : 1,
              // Always dark on white: a code drawn in the app's colours doesn't scan in dark mode.
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  key: const Key('pairQr'),
                  data: code.pairUrl,
                  size: 232,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                  semanticsLabel: l10n.pairDevice,
                ),
              ),
            ),
          ),
          Text(
            _expired ? l10n.pairDeviceExpired : l10n.pairDeviceServer(host),
            key: const Key('pairServer'),
            textAlign: TextAlign.center,
            style: context.textTheme.labelLarge?.copyWith(
              color: _expired ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
          _linkActions(code),
          FormNote(l10n.pairDeviceWarning, icon: LucideIcons.shieldAlert),
        ],
      ],
    );
  }
}
