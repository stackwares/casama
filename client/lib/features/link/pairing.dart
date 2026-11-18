import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/providers.dart';
import '../../core/server_address.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../ui/adaptive_modal.dart';

/// What a sign-in QR code carries (D-296): the server to sign in to and a one-time code for it.
///
/// The QR holds a link, `https://casama.ai/pair#v=1&s=<server>&c=<code>`, so a phone's camera opens
/// the app with it. Everything rides after the `#`, which browsers never send to a web server.
class PairLink {
  const PairLink(this.server, this.code);
  final String server;
  final String code;

  String get host {
    final uri = Uri.tryParse(server);
    return (uri != null && uri.host.isNotEmpty) ? uri.host : server;
  }

  /// Reads a scanned or opened link; null when it isn't a sign-in code. Accepts the values after
  /// `#` (the QR) or after `?` (how a link arrives once the router has taken the fragment off).
  static PairLink? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    // The app's own links are casama://app/<route>.
    final isPair = uri.scheme == 'casama'
        ? uri.host == 'pair' || uri.path == '/pair'
        : uri.path == '/pair' || uri.path == 'pair';
    if (!isPair) return null;
    return fromValues({
      ...uri.queryParameters,
      if (uri.fragment.isNotEmpty) ...Uri.splitQueryString(uri.fragment),
    });
  }

  static PairLink? fromValues(Map<String, String> values) {
    final server = values['s'] ?? '';
    final code = values['c'] ?? '';
    final at = Uri.tryParse(server);
    if (code.length < 20 || at == null || !at.hasScheme || at.host.isEmpty) {
      return null;
    }
    if (at.scheme != 'https' && at.scheme != 'http') return null;
    return PairLink(ServerAddress.normalize(server), code);
  }
}

/// A scanned code for another server, kept while the app reconnects to it; the sign-in screen
/// that appears afterwards finishes the sign-in.
abstract final class PendingPairing {
  static PairLink? link;

  static PairLink? take() {
    final l = link;
    link = null;
    return l;
  }
}

bool _sameServer(String a, String b) =>
    ServerAddress.normalize(a).toLowerCase() ==
    ServerAddress.normalize(b).toLowerCase();

/// What this device is called in the "new sign-in" notice on the account.
String pairingDeviceName() {
  if (kIsWeb) return 'a web browser';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'an iPhone or iPad',
    TargetPlatform.android => 'an Android device',
    TargetPlatform.macOS => 'a Mac',
    TargetPlatform.windows => 'a Windows computer',
    TargetPlatform.linux => 'a Linux computer',
    _ => 'another device',
  };
}

/// Trades [link]'s code for a session on this device. Returns whether it signed in.
Future<bool> redeemPairLink(
  BuildContext context,
  WidgetRef ref,
  PairLink link,
) async {
  final backend = ref.read(backendProvider);
  try {
    await backend.signInWithCode(link.code, deviceName: pairingDeviceName());
    return true;
  } on DioException catch (e) {
    if (!context.mounted) return false;
    final status = e.response?.statusCode;
    if (status == 404 || status == 400) {
      showToast(context, context.l10n.pairCodeInvalid, kind: ToastKind.error);
    } else {
      showError(context, e);
    }
    return false;
  } catch (e) {
    if (context.mounted) showError(context, e);
    return false;
  }
}

/// Signs this device in from a scanned or opened [link]: asks first when that replaces a session
/// or moves the app to another server, switches server when needed, then trades the code.
Future<void> signInFromPairLink(
  BuildContext context,
  WidgetRef ref,
  PairLink link,
) async {
  final backend = ref.read(backendProvider);
  final l10n = context.l10n;
  final same = _sameServer(backend.apiUrl, link.server);
  if (backend.isSignedIn || !same) {
    final currentHost = Uri.tryParse(backend.apiUrl)?.host ?? backend.apiUrl;
    final ok = await showConfirm(
      context: context,
      title: l10n.pairSignInTo(link.host),
      message: same
          ? l10n.pairSignInBody
          : l10n.pairSwitchServerBody(currentHost, link.host),
      confirmLabel: l10n.signIn,
      icon: LucideIcons.scanQrCode,
      confirmKey: const Key('pairConfirm'),
    );
    if (!ok || !context.mounted) return;
  }
  if (!same) {
    // The app starts over on the other server; its sign-in screen picks the code up from here.
    PendingPairing.link = link;
    await onChangeServer?.call(link.server);
    return;
  }
  if (backend.isSignedIn) await backend.signOut();
  if (!context.mounted) return;
  await redeemPairLink(context, ref, link);
}

/// Finishes a sign-in whose code was scanned before the app switched servers. Sits on the sign-in
/// screen and shows "Signing in" while it works.
class PendingPairingRunner extends ConsumerStatefulWidget {
  const PendingPairingRunner({super.key});
  @override
  ConsumerState<PendingPairingRunner> createState() =>
      _PendingPairingRunnerState();
}

class _PendingPairingRunnerState extends ConsumerState<PendingPairingRunner> {
  var _busy = false;

  @override
  void initState() {
    super.initState();
    final link = PendingPairing.take();
    if (link == null) return;
    _busy = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Only for the server the code belongs to (the switch may have failed and left the old one).
      if (_sameServer(ref.read(backendProvider).apiUrl, link.server)) {
        await redeemPairLink(context, ref, link);
      }
      if (mounted) setState(() => _busy = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_busy) return const SizedBox.shrink();
    return Row(
      key: const Key('pairSigningIn'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Text(context.l10n.pairSigningIn),
      ],
    );
  }
}

/// `/pair`: where a sign-in QR code lands when the phone's camera (not the app's own scanner) read
/// it. Asks, then signs in; a link that isn't a sign-in code says so.
class PairLandingScreen extends ConsumerStatefulWidget {
  const PairLandingScreen({
    super.key,
    required this.link,
    required this.onDone,
  });

  /// The opened link's values, or null when it carried none.
  final PairLink? link;

  /// Leaves the page (the router sends a signed-in person on by itself).
  final VoidCallback onDone;

  @override
  ConsumerState<PairLandingScreen> createState() => _PairLandingScreenState();
}

class _PairLandingScreenState extends ConsumerState<PairLandingScreen> {
  @override
  void initState() {
    super.initState();
    final link = widget.link;
    if (link == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await signInFromPairLink(context, ref, link);
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: widget.link == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.pairLinkInvalid, key: const Key('pairLinkInvalid')),
                  const SizedBox(height: 12),
                  TextButton(onPressed: widget.onDone, child: Text(l10n.close)),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

/// A link code from `/link?code=…` opened while signed out, kept until the person has signed in.
class PendingLinkCode extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? code) => state = code;
}

final pendingLinkCodeProvider = NotifierProvider<PendingLinkCode, String?>(
  PendingLinkCode.new,
);

/// Phones and tablets have a camera to scan with; everything else shows the code instead.
bool get canScanSignInCode =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Opens the camera and returns the sign-in code it reads, or null when closed.
Future<PairLink?> scanSignInCode(BuildContext context) {
  unfocusBeforeModal();
  return Navigator.of(context, rootNavigator: true).push<PairLink>(
    MaterialPageRoute(
      fullscreenDialog: true,
      settings: const RouteSettings(name: '/scan/pair'),
      builder: (_) => const ScanSignInCodePage(),
    ),
  );
}

class ScanSignInCodePage extends StatefulWidget {
  const ScanSignInCodePage({super.key});
  @override
  State<ScanSignInCodePage> createState() => _ScanSignInCodePageState();
}

class _ScanSignInCodePageState extends State<ScanSignInCodePage> {
  var _done = false;
  var _wrongCode = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanToSignInTitle)),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                if (_done) return;
                for (final b in capture.barcodes) {
                  final link = PairLink.parse(b.rawValue ?? '');
                  if (link != null) {
                    _done = true;
                    Navigator.of(context).pop(link);
                    return;
                  }
                }
                // A QR code, but not one of ours: say so instead of doing nothing.
                if (capture.barcodes.isNotEmpty && !_wrongCode) {
                  setState(() => _wrongCode = true);
                }
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _wrongCode ? l10n.pairLinkInvalid : l10n.scanToSignInHelp,
                key: const Key('scanSignInHelp'),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
