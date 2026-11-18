// Every screen lays out in every window an iPhone Duo gives the app (D-411): the outer screen
// with its side strip, the inner screen flat and partly folded, wide and tall, and half of it
// beside another app. No overflow, no layout errors, no duplicate keys, in any of them.
import 'package:casama/core/fold/fold.dart';
import 'package:casama/core/local_cache.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/router.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/theme/app_theme.dart';
import 'package:casama/ui/text_scale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';
import 'phone_layout_test.dart' show routes;
import 'support/poses.dart';

/// Pages the shared list doesn't have: the Folding screen page, and the two settings pages main
/// gained while this was being built (widgets, D-405; the watch, D-410).
const _more = ['/settings/fold', '/settings/widgets', '/settings/watch'];

void main() {
  for (final pose in DuoPose.all) {
    testWidgets('every screen fits an iPhone Duo: ${pose.name}', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      setPose(tester, pose);
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          backendProvider.overrideWithValue(FakeBackend()),
          localCacheProvider.overrideWithValue(const NoCache()),
        ],
      );
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) =>
                FoldScope(child: limitTextScale(context, child)),
          ),
        ),
      );
      final problems = <String>{};
      final old = FlutterError.onError;
      FlutterError.onError = (d) {
        final t = d.toString();
        if (t.contains('Duplicate GlobalKey')) {
          problems.add(
            '   dup: ${t.substring(0, t.length.clamp(0, 900)).replaceAll('\n', ' ')}',
          );
        }
        final i = t.indexOf('relevant error-causing widget was');
        if (i >= 0) {
          problems.add(
            '   where: ${t.substring(i, (i + 260).clamp(0, t.length)).replaceAll('\n', ' ')}',
          );
        }
        old?.call(d);
      };
      Future<void> settle(String tag) async {
        for (var i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          final e = tester.takeException();
          if (e != null) {
            problems.add('$tag: ${e.toString().split('\n').first}');
          }
        }
      }

      await settle('start');
      for (final r in [...routes, ..._more]) {
        router.go(r);
        await settle(r);
      }
      FlutterError.onError = old;
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
      tester.takeException();
      expect(problems, isEmpty, reason: problems.join('\n'));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }
}
