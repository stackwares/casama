import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import 'billing_screen.dart' show openUrlProvider, platformProvider;
import '../../core/remote_content.dart';

/// Casama's Terms of Use. It carries Apple's minimum EULA terms ("Apps from the Apple App Store"),
/// and the App Store description links the same page, so both Terms links match (3.1.2).
const casamaTermsUrl = 'https://casama.ai/terms';
const casamaPrivacyUrl = 'https://casama.ai/privacy';

/// The fine print every subscription offer needs (App Store 3.1.2, Google Play): price and period,
/// that it renews until cancelled, who charges it and how to cancel; then Terms and Privacy links.
/// [store] is the store source ('app_store', 'google_play') or null for web checkout.
class PurchaseTerms extends ConsumerWidget {
  const PurchaseTerms({super.key, required this.price, required this.yearly, this.weekly = false, required this.store, this.priceHasPeriod = false, this.trialDays});

  /// The price as shown to the person; null hides the disclosure line (no plan picked yet).
  final String? price;
  final bool yearly;

  /// A weekly plan (D-432); [yearly] is false then.
  final bool weekly;
  final String? store;

  /// Web price labels already read "$39 / month".
  final bool priceHasPeriod;

  /// Free-trial days the purchase starts with (web checkout, or a store offer the store confirmed), or null. The line then says when charging begins.
  final int? trialDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final small = context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35);
    final period = yearly ? l10n.pricePerYear : weekly ? l10n.pricePerWeek : l10n.pricePerMonth;
    final price = this.price;
    final trial = trialDays ?? 0;
    final String? disclosure = price == null
        ? null
        : store != null
        ? trial > 0
              ? l10n.paywallDisclosureStoreTrial(trial, price, period, store == 'app_store' ? l10n.storeAccountApple : l10n.storeAccountGoogle)
              : l10n.paywallDisclosureStore(price, period, store == 'app_store' ? l10n.storeAccountApple : l10n.storeAccountGoogle)
        : trial > 0
        ? l10n.paywallDisclosureWebTrial(trial, priceHasPeriod ? price : '$price $period')
        : l10n.paywallDisclosureWeb(priceHasPeriod ? price : '$price $period');
    final platform = ref.watch(platformProvider);
    final apple = !kIsWeb && (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS);
    final open = ref.read(openUrlProvider);
    Widget link(String label, String url, Key key) => TextButton(
      key: key,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(44, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: context.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      onPressed: () => open(url),
      child: Text(label),
    );
    return Column(
      key: const Key('purchaseTerms'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (disclosure != null) Text(disclosure, key: const Key('purchaseDisclosure'), textAlign: TextAlign.center, style: small),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (apple) ...[
              link(l10n.termsOfUse, remoteLink('terms', casamaTermsUrl), const Key('termsOfUse')),
              Text('·', style: small),
            ],
            link(l10n.privacyPolicy, remoteLink('privacy', casamaPrivacyUrl), const Key('privacyPolicy')),
          ],
        ),
      ],
    );
  }
}
