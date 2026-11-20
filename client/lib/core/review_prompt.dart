import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics.dart';
import 'distribution.dart';
import 'remote_config.dart';

/// The store's rating prompt (D-305, loosened by D-460), asked only after something went well.
///
/// Every ask needs: no error message shown this session, nothing asked on this device within the
/// rules' gap, the remote flag `review_prompt` not off, and a supported platform. Only the phone apps
/// and the Mac App Store build ask; the web and direct downloads never do. The numbers (days of use,
/// first-open age, gap, reply milestones) come from [ReviewRules], which differ per platform.
/// - [ReviewMoment.replyFinished]: a milestone reply, and the rules' days of use and first-open age.
/// - [ReviewMoment.purchase]: right away; the store shows it over the celebration.
/// - [ReviewMoment.firstReply]: the first finished reply of the first-run session (the welcome chat or
///   the manual wizard's first bot), a few seconds after it lands. Needs [ReviewRules.onboarding].
enum ReviewMoment { replyFinished, purchase, firstReply }

/// What decides when a platform asks (D-460).
class ReviewRules {
  const ReviewRules({
    required this.name,
    required this.minDays,
    required this.minAgeDays,
    required this.gapDays,
    required this.milestones,
    required this.onboarding,
  });

  /// `eager_android`, `apple` or `default`; sent with `review_prompt_shown`.
  final String name;
  final int minDays;
  final int minAgeDays;
  final int gapDays;

  /// Whether reply number n is a good moment.
  final bool Function(int n) milestones;

  /// Whether the first reply of the first-run session asks.
  final bool onboarding;

  /// D-305's numbers: the 10th reply, then every 40th.
  static bool _defaultMilestone(int n) =>
      n == 10 || (n > 10 && (n - 10) % 40 == 0);

  /// Android: Google Play rations the sheet itself, so ours can be loose.
  static bool _androidMilestone(int n) =>
      n == 3 || n == 10 || (n > 10 && (n - 10) % 20 == 0);

  static const defaults = ReviewRules(
    name: 'default',
    minDays: 5,
    minAgeDays: 7,
    gapDays: 120,
    milestones: _defaultMilestone,
    onboarding: false,
  );

  /// The rules for this platform. [flags] are the server owner's remote switches:
  /// `review_prompt_eager_android` (default on) picks Android's looser numbers,
  /// `review_prompt_onboarding_android` (default on) and `review_prompt_onboarding_ios` (default off,
  /// Apple allows three a year) turn the first-run ask on.
  static ReviewRules forPlatform({
    required bool android,
    required bool apple,
    Map<String, dynamic> flags = const {},
  }) {
    if (android) {
      final onboarding = flags['review_prompt_onboarding_android'] != false;
      if (flags['review_prompt_eager_android'] == false) {
        return ReviewRules(
          name: defaults.name,
          minDays: defaults.minDays,
          minAgeDays: defaults.minAgeDays,
          gapDays: defaults.gapDays,
          milestones: defaults.milestones,
          onboarding: onboarding,
        );
      }
      return ReviewRules(
        name: 'eager_android',
        minDays: 2,
        minAgeDays: 1,
        gapDays: 30,
        milestones: _androidMilestone,
        onboarding: onboarding,
      );
    }
    if (apple) {
      return ReviewRules(
        name: 'apple',
        minDays: 3,
        minAgeDays: 3,
        gapDays: 90,
        milestones: _defaultMilestone,
        onboarding: flags['review_prompt_onboarding_ios'] == true,
      );
    }
    return defaults;
  }
}

class ReviewPrompt {
  ReviewPrompt(
    this._ref, {
    Future<bool> Function()? request,
    DateTime Function()? now,
    bool? supported,
    TargetPlatform Function()? platform,
    Duration firstReplyDelay = const Duration(seconds: 3),
  }) : _request = request ?? _storeRequest,
       _now = now ?? DateTime.now,
       _supported = supported ?? _platformSupported,
       _platform = platform ?? (() => defaultTargetPlatform),
       // ignore: prefer_initializing_formals
       _firstReplyDelay = firstReplyDelay;

  final Ref _ref;
  final Future<bool> Function() _request;
  final DateTime Function() _now;
  final bool _supported;
  final TargetPlatform Function() _platform;
  final Duration _firstReplyDelay;

  /// The default rules' milestones: the 10th reply, then every 40th (D-305).
  static bool replyMilestone(int n) => ReviewRules.defaults.milestones(n);

  static const _daysKey = 'casama.review.days';
  static const _firstKey = 'casama.review.first';
  static const _askedKey = 'casama.review.asked';
  static const _repliesKey = 'casama.review.replies';
  static const _firstRunKey = 'casama.review.firstRun';

  /// How long after the first-run mark its first reply still counts as part of onboarding.
  static const firstRunWindow = Duration(hours: 24);

  /// Set when an error message shows; this session doesn't ask after that.
  static bool errorThisSession = false;

  static bool get _platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android ||
          isMacAppStoreBuild);

  /// Casama AI's App Store id (iPhone, iPad and Mac); the Play listing needs none.
  static const appStoreId = '6833509960';

  /// Whether this build has a store page to rate on (the same builds that ask).
  static bool get canRate => _platformSupported;

  /// Settings → Help → Rate Casama: opens the store page. Not an ask, so no limits apply.
  static void openStore() {
    unawaited(Analytics.capture('review_store_opened'));
    unawaited(InAppReview.instance.openStoreListing(appStoreId: appStoreId));
  }

  static Future<bool> _storeRequest() async {
    final review = InAppReview.instance;
    if (!await review.isAvailable()) return false;
    await review.requestReview();
    return true;
  }

  ReviewRules _rules(Map<String, dynamic> flags) => ReviewRules.forPlatform(
    android: _platform() == TargetPlatform.android,
    apple:
        _platform() == TargetPlatform.iOS || _platform() == TargetPlatform.macOS,
    flags: flags,
  );

  /// The person just started using Casama (the welcome page made their first chat, or the manual
  /// wizard made their first bot): the first reply that finishes counts as the onboarding moment.
  Future<void> markFirstRun() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_firstRunKey, _now().toIso8601String());
    } catch (_) {}
  }

  String _day(DateTime d) => d.toIso8601String().substring(0, 10);

  static bool _recorded = false;

  /// [recordUse] once per app session (the home screen calls it as it builds).
  void recordUseOnce() {
    if (_recorded) return;
    _recorded = true;
    unawaited(recordUse());
  }

  /// Counts today as a day the app was used (once per day).
  Future<void> recordUse() async {
    try {
      final p = await SharedPreferences.getInstance();
      final today = _day(_now());
      final days = p.getStringList(_daysKey) ?? const [];
      if (!days.contains(today)) {
        await p.setStringList(
          _daysKey,
          [...days, today].skip((days.length + 1 - 30).clamp(0, 30)).toList(),
        );
      }
      if (p.getString(_firstKey) == null) await p.setString(_firstKey, today);
    } catch (_) {}
  }

  /// A good moment happened; asks when every rule above holds. Returns whether it asked.
  /// [stillIdle] is checked again after the first-reply delay: false (a new run started) skips the ask.
  Future<bool> moment(ReviewMoment m, {bool Function()? stillIdle}) async {
    if (!_supported || errorThisSession) return false;
    try {
      final p = await SharedPreferences.getInstance();
      final flags = _ref.read(remoteConfigProvider).value?.flags ?? const {};
      if (flags['review_prompt'] == false) return false;
      final rules = _rules(flags);
      var kind = m;
      var skipUseGates = m == ReviewMoment.purchase;
      if (m == ReviewMoment.replyFinished) {
        final n = (p.getInt(_repliesKey) ?? 0) + 1;
        await p.setInt(_repliesKey, n);
        // The first reply of the first-run session is the onboarding moment; it's used up either way.
        final marked = DateTime.tryParse(p.getString(_firstRunKey) ?? '');
        if (marked != null) {
          await p.remove(_firstRunKey);
          if (rules.onboarding &&
              _now().difference(marked) < firstRunWindow) {
            kind = ReviewMoment.firstReply;
            skipUseGates = true;
          }
        }
        if (kind == ReviewMoment.replyFinished && !rules.milestones(n)) {
          return false;
        }
      }
      final now = _now();
      final asked = DateTime.tryParse(p.getString(_askedKey) ?? '');
      if (asked != null && now.difference(asked).inDays < rules.gapDays) {
        return false;
      }
      if (!skipUseGates) {
        final days = p.getStringList(_daysKey) ?? const [];
        final first = DateTime.tryParse(p.getString(_firstKey) ?? '');
        if (days.length < rules.minDays) return false;
        if (first == null || now.difference(first).inDays < rules.minAgeDays) {
          return false;
        }
      }
      if (kind == ReviewMoment.firstReply) {
        // Let the reply finish drawing; a person who already sent another message is busy.
        await Future<void>.delayed(_firstReplyDelay);
        if (errorThisSession || (stillIdle != null && !stillIdle())) {
          return false;
        }
      }
      await p.setString(_askedKey, _now().toIso8601String());
      final shown = await _request();
      if (shown) {
        unawaited(
          Analytics.capture(
            'review_prompt_shown',
            properties: {'moment': kind.name, 'rules': rules.name},
          ),
        );
      }
      return shown;
    } catch (_) {
      return false;
    }
  }
}

final reviewPromptProvider = Provider<ReviewPrompt>((ref) => ReviewPrompt(ref));
