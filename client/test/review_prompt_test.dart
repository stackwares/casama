import 'package:casama/core/remote_config.dart';
import 'package:casama/core/review_prompt.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedConfig extends RemoteConfigNotifier {
  _FixedConfig(this.flags);
  final Map<String, bool> flags;

  @override
  Future<RemoteAppConfig?> build() async => RemoteAppConfig(
    minVersions: RemoteAppConfigMinVersions(),
    updateUrls: RemoteAppConfigUpdateUrls(),
    maintenance: null,
    announcements: const [],
    flags: flags,
  );
}

/// The store's rating prompt (D-305, D-460): per-platform rules and the first-reply moment.
void main() {
  late ProviderContainer container;
  late int asked;
  late DateTime now;

  /// A prompt on [platform] with the server's [flags]; the first-reply delay is zero.
  Future<ReviewPrompt> prompt(
    TargetPlatform platform, {
    Map<String, bool> flags = const {},
    bool supported = true,
  }) async {
    container = ProviderContainer(
      overrides: [remoteConfigProvider.overrideWith(() => _FixedConfig(flags))],
    );
    addTearDown(container.dispose);
    await container.read(remoteConfigProvider.future);
    return ReviewPrompt(
      container.read(Provider((ref) => ref)),
      request: () async {
        asked++;
        return true;
      },
      now: () => now,
      supported: supported,
      platform: () => platform,
      firstReplyDelay: Duration.zero,
    );
  }

  Future<void> useOnDays(ReviewPrompt p, int days) async {
    for (var i = 0; i < days; i++) {
      await p.recordUse();
      now = now.add(const Duration(days: 1));
    }
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    asked = 0;
    now = DateTime(2026, 11, 1);
    ReviewPrompt.errorThisSession = false;
  });

  test('the default milestones are the 10th reply, then every 40th', () {
    expect([for (var n = 1; n <= 100; n++) if (ReviewPrompt.replyMilestone(n)) n], [10, 50, 90]);
  });

  group('Android', () {
    test('milestones are the 3rd, the 10th, then every 20th', () {
      final rules = ReviewRules.forPlatform(android: true, apple: false);
      expect(rules.name, 'eager_android');
      expect([for (var n = 1; n <= 70; n++) if (rules.milestones(n)) n], [3, 10, 30, 50, 70]);
    });

    test('asks on the 3rd reply after 2 days of use, a day after first open', () async {
      final p = await prompt(TargetPlatform.android);
      await useOnDays(p, 2);
      expect(await p.moment(ReviewMoment.replyFinished), isFalse);
      expect(await p.moment(ReviewMoment.replyFinished), isFalse);
      expect(await p.moment(ReviewMoment.replyFinished), isTrue);
      expect(asked, 1);
    });

    test('a purchase asks with no days of use, then waits 30 days', () async {
      final p = await prompt(TargetPlatform.android);
      expect(await p.moment(ReviewMoment.purchase), isTrue);
      now = now.add(const Duration(days: 29));
      expect(await p.moment(ReviewMoment.purchase), isFalse);
      now = now.add(const Duration(days: 2));
      expect(await p.moment(ReviewMoment.purchase), isTrue);
      expect(asked, 2);
    });

    test('the first reply of the first-run session asks, once', () async {
      final p = await prompt(TargetPlatform.android);
      await p.markFirstRun();
      expect(await p.moment(ReviewMoment.replyFinished), isTrue);
      expect(asked, 1);
      // The second reply is neither a milestone nor a first run.
      expect(await p.moment(ReviewMoment.replyFinished), isFalse);
      expect(asked, 1);
    });

    test('a check-in finishing first leaves the mark for the person\'s own first reply', () async {
      final p = await prompt(TargetPlatform.android);
      await p.markFirstRun();
      expect(await p.moment(ReviewMoment.replyFinished, personAsked: false), isFalse);
      expect(asked, 0);
      expect(await p.moment(ReviewMoment.replyFinished), isTrue);
      expect(asked, 1);
    });

    test('a first-run mark older than a day no longer counts', () async {
      final p = await prompt(TargetPlatform.android);
      await p.markFirstRun();
      now = now.add(const Duration(days: 2));
      expect(await p.moment(ReviewMoment.replyFinished), isFalse);
      expect(asked, 0);
    });

    test('a person who sent another message in the meantime isn\'t asked', () async {
      final p = await prompt(TargetPlatform.android);
      await p.markFirstRun();
      expect(await p.moment(ReviewMoment.replyFinished, stillIdle: () => false), isFalse);
      expect(asked, 0);
    });

    test('review_prompt_onboarding_android off: the first reply is just a reply', () async {
      final p = await prompt(TargetPlatform.android, flags: {'review_prompt_onboarding_android': false});
      await p.markFirstRun();
      expect(await p.moment(ReviewMoment.replyFinished), isFalse);
      expect(asked, 0);
    });

    test('review_prompt_eager_android off: back to D-305\'s numbers', () async {
      final rules = ReviewRules.forPlatform(
        android: true,
        apple: false,
        flags: {'review_prompt_eager_android': false},
      );
      expect((rules.minDays, rules.minAgeDays, rules.gapDays), (5, 7, 120));
      expect(rules.milestones(3), isFalse);
      expect(rules.onboarding, isTrue);
    });
  });

  group('iOS and the Mac App Store build', () {
    test('the first reply does not ask unless review_prompt_onboarding_ios is on', () async {
      var p = await prompt(TargetPlatform.iOS);
      await p.markFirstRun();
      expect(await p.moment(ReviewMoment.replyFinished), isFalse);
      expect(asked, 0);
      SharedPreferences.setMockInitialValues({});
      p = await prompt(TargetPlatform.iOS, flags: {'review_prompt_onboarding_ios': true});
      await p.markFirstRun();
      expect(await p.moment(ReviewMoment.replyFinished), isTrue);
      expect(asked, 1);
    });

    test('keeps the 10th and every 40th reply, 3 days of use over 3 days, a 90-day gap', () async {
      final p = await prompt(TargetPlatform.iOS);
      await useOnDays(p, 2);
      expect(await p.moment(ReviewMoment.purchase), isTrue);
      now = now.add(const Duration(days: 60));
      expect(await p.moment(ReviewMoment.purchase), isFalse);
      now = now.add(const Duration(days: 40));
      expect(await p.moment(ReviewMoment.purchase), isTrue);
      final rules = ReviewRules.forPlatform(android: false, apple: true);
      expect((rules.minDays, rules.minAgeDays, rules.gapDays), (3, 3, 90));
      expect([for (var n = 1; n <= 100; n++) if (rules.milestones(n)) n], [10, 50, 90]);
    });

    test('replies need 3 days of use, 3 days after first open', () async {
      final p = await prompt(TargetPlatform.iOS);
      await useOnDays(p, 2);
      for (var i = 0; i < 10; i++) {
        expect(await p.moment(ReviewMoment.replyFinished), isFalse);
      }
      await useOnDays(p, 2);
      for (var i = 0; i < 39; i++) {
        expect(await p.moment(ReviewMoment.replyFinished), isFalse);
      }
      expect(await p.moment(ReviewMoment.replyFinished), isTrue);
    });
  });

  group('every platform', () {
    test('never after an error this session, with the remote switch off, or where unsupported', () async {
      var p = await prompt(TargetPlatform.android);
      ReviewPrompt.errorThisSession = true;
      expect(await p.moment(ReviewMoment.purchase), isFalse);
      ReviewPrompt.errorThisSession = false;
      p = await prompt(TargetPlatform.android, supported: false);
      expect(await p.moment(ReviewMoment.purchase), isFalse);
      p = await prompt(TargetPlatform.android, flags: {'review_prompt': false});
      await p.markFirstRun();
      expect(await p.moment(ReviewMoment.purchase), isFalse);
      expect(await p.moment(ReviewMoment.replyFinished), isFalse);
      expect(asked, 0);
    });

    test('an onboarding ask starts the gap, so a purchase right after does not ask again', () async {
      final p = await prompt(TargetPlatform.android);
      await p.markFirstRun();
      expect(await p.moment(ReviewMoment.replyFinished), isTrue);
      expect(await p.moment(ReviewMoment.purchase), isFalse);
      expect(asked, 1);
    });
  });
  group('which builds can ask for a store review', () {
    bool supported(TargetPlatform platform, String distribution, {bool isWeb = false}) =>
        ReviewPrompt.platformSupported(platform: platform, isWeb: isWeb, distribution: distribution);

    test('Google Play (and the default build) on Android, iOS and the Mac App Store ask', () {
      expect(supported(TargetPlatform.android, 'play'), isTrue);
      expect(supported(TargetPlatform.android, 'direct'), isTrue);
      expect(supported(TargetPlatform.iOS, 'direct'), isTrue);
      expect(supported(TargetPlatform.macOS, 'appstore'), isTrue);
    });

    test('APK, Galaxy Store, web and desktop downloads never ask', () {
      expect(supported(TargetPlatform.android, 'apk'), isFalse);
      expect(supported(TargetPlatform.android, 'galaxy'), isFalse);
      expect(supported(TargetPlatform.android, 'play', isWeb: true), isFalse);
      expect(supported(TargetPlatform.macOS, 'direct'), isFalse);
      expect(supported(TargetPlatform.windows, 'direct'), isFalse);
    });
  });
}
