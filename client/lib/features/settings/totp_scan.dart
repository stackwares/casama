import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';

/// Phones scan a two-step QR code (D-102); other platforms paste the link.
bool get canScanTotp => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

/// A scan button for a sign-in code field; puts the scanned otpauth:// link into [onScanned].
class TotpScanButton extends StatelessWidget {
  const TotpScanButton({super.key, required this.onScanned});
  final ValueChanged<String> onScanned;

  @override
  Widget build(BuildContext context) {
    if (!canScanTotp) return const SizedBox.shrink();
    return IconButton(
      key: const Key('scanTotp'),
      tooltip: context.l10n.scanQrCode,
      icon: const Icon(LucideIcons.scanQrCode, size: 20),
      onPressed: () async {
        unfocusBeforeModal();
        final link = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, settings: const RouteSettings(name: '/scan/sign-in-code'), builder: (_) => const _ScanPage()));
        if (link != null) onScanned(link);
      },
    );
  }
}

class _ScanPage extends StatefulWidget {
  const _ScanPage();

  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  var _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scanQrCode)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          for (final b in capture.barcodes) {
            final v = b.rawValue ?? '';
            if (v.toLowerCase().startsWith('otpauth://totp/')) {
              _done = true;
              Navigator.of(context).pop(v);
              return;
            }
          }
        },
      ),
    );
  }
}
