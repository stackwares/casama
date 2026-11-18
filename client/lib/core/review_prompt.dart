import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics.dart';
import 'distribution.dart';
import 'remote_config.dart';

/// The store's rating prompt (D-305), asked only after something went well and only when:
/// - the app was used on [minDays] different days and first opened [minAgeDays] or more days ago;
/// - nothing went wrong in this session (no error message shown);
/// - it hasn't asked on this device in [gapDays] days (Apple adds its own cap of three a year,
///   and the call may show nothing);
/// - the server owner hasn't turned it off (remote flag `review_prompt`).
/// Only the phone apps and the Mac App Store build ask; the web and direct downloads never do.
enum ReviewMoment { replyFinished, purchase }

class ReviewPrompt {
  ReviewPrompt(
    this._ref, {
    Future<bool> Function()? request,
    DateTime Function()? now,
    bool? supported,
  }) : _request = request ?? _storeRequest,
       _now = now ?? DateTime.now,
       _supported = supported ?? _platformSupported;

  final Ref _ref;
  final Future<bool> Function() _request;
  final DateTime Function() _now;
  final bool _supported;

  static const minDays = 5;
  static const minAgeDays = 7;
  static const gapDays = 120;

  /// Replies that count as a good moment: the 10th, then every 40th.
  static bool replyMilestone(int n) =>
      n == 10 || (n > 10 && (n - 10) % 40 == 0);

  static const _daysKey = 'casama.review.days';
  static const _firstKey = 'casama.review.first';
  static const _askedKey = 'casama.review.asked';
  static const _repliesKey = 'casama.review.replies';

  /// Set when an error message shows; this session doesn't ask after that.
  static bool errorThisSession = false;

  static bool get _platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android ||
          isMacAppStoreBuild);

  static Future<bool> _storeRequest() async {
    final review = InAppReview.instance;
    if (!await review.isAvailable()) return false;
    await review.requestReview();
    return true;
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
  Future<bool> moment(ReviewMoment m) async {
    if (!_supported || errorThisSession) return false;
    try {
      final p = await SharedPreferences.getInstance();
      if (m == ReviewMoment.replyFinished) {
        final n = (p.getInt(_repliesKey) ?? 0) + 1;
        await p.setInt(_repliesKey, n);
        if (!replyMilestone(n)) return false;
      }
      final flags = _ref.read(remoteConfigProvider).value?.flags ?? const {};
      if (flags['review_prompt'] == false) return false;
      final now = _now();
      final days = p.getStringList(_daysKey) ?? const [];
      final first = DateTime.tryParse(p.getString(_firstKey) ?? '');
      final asked = DateTime.tryParse(p.getString(_askedKey) ?? '');
      if (days.length < minDays) return false;
      if (first == null || now.difference(first).inDays < minAgeDays) {
        return false;
      }
      if (asked != null && now.difference(asked).inDays < gapDays) return false;
      await p.setString(_askedKey, now.toIso8601String());
      final shown = await _request();
      if (shown) {
        unawaited(
          Analytics.capture(
            'review_prompt_shown',
            properties: {'moment': m.name},
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
