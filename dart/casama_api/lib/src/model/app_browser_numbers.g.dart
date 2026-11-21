// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_browser_numbers.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppBrowserNumbersCWProxy {
  AppBrowserNumbers days(int days);

  AppBrowserNumbers blockedRuns(int blockedRuns);

  AppBrowserNumbers blockedPeople(int blockedPeople);

  AppBrowserNumbers watchedBrowserRuns(int watchedBrowserRuns);

  AppBrowserNumbers phoneRuns(int phoneRuns);

  AppBrowserNumbers phonePeople(int phonePeople);

  AppBrowserNumbers phonesPaired(int phonesPaired);

  AppBrowserNumbers phonesWithSites(int phonesWithSites);

  AppBrowserNumbers refusedSteps(int refusedSteps);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppBrowserNumbers(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppBrowserNumbers(...).copyWith(id: 12, name: "My name")
  /// ```
  AppBrowserNumbers call({
    int days,
    int blockedRuns,
    int blockedPeople,
    int watchedBrowserRuns,
    int phoneRuns,
    int phonePeople,
    int phonesPaired,
    int phonesWithSites,
    int refusedSteps,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAppBrowserNumbers.copyWith(...)` or call `instanceOfAppBrowserNumbers.copyWith.fieldName(value)` for a single field.
class _$AppBrowserNumbersCWProxyImpl implements _$AppBrowserNumbersCWProxy {
  const _$AppBrowserNumbersCWProxyImpl(this._value);

  final AppBrowserNumbers _value;

  @override
  AppBrowserNumbers days(int days) => call(days: days);

  @override
  AppBrowserNumbers blockedRuns(int blockedRuns) =>
      call(blockedRuns: blockedRuns);

  @override
  AppBrowserNumbers blockedPeople(int blockedPeople) =>
      call(blockedPeople: blockedPeople);

  @override
  AppBrowserNumbers watchedBrowserRuns(int watchedBrowserRuns) =>
      call(watchedBrowserRuns: watchedBrowserRuns);

  @override
  AppBrowserNumbers phoneRuns(int phoneRuns) => call(phoneRuns: phoneRuns);

  @override
  AppBrowserNumbers phonePeople(int phonePeople) =>
      call(phonePeople: phonePeople);

  @override
  AppBrowserNumbers phonesPaired(int phonesPaired) =>
      call(phonesPaired: phonesPaired);

  @override
  AppBrowserNumbers phonesWithSites(int phonesWithSites) =>
      call(phonesWithSites: phonesWithSites);

  @override
  AppBrowserNumbers refusedSteps(int refusedSteps) =>
      call(refusedSteps: refusedSteps);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppBrowserNumbers(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppBrowserNumbers(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AppBrowserNumbers call({
    Object? days = const $CopyWithPlaceholder(),
    Object? blockedRuns = const $CopyWithPlaceholder(),
    Object? blockedPeople = const $CopyWithPlaceholder(),
    Object? watchedBrowserRuns = const $CopyWithPlaceholder(),
    Object? phoneRuns = const $CopyWithPlaceholder(),
    Object? phonePeople = const $CopyWithPlaceholder(),
    Object? phonesPaired = const $CopyWithPlaceholder(),
    Object? phonesWithSites = const $CopyWithPlaceholder(),
    Object? refusedSteps = const $CopyWithPlaceholder(),
  }) {
    return AppBrowserNumbers(
      days: days == const $CopyWithPlaceholder() || days == null
          ? _value.days
          // ignore: cast_nullable_to_non_nullable
          : days as int,
      blockedRuns:
          blockedRuns == const $CopyWithPlaceholder() || blockedRuns == null
          ? _value.blockedRuns
          // ignore: cast_nullable_to_non_nullable
          : blockedRuns as int,
      blockedPeople:
          blockedPeople == const $CopyWithPlaceholder() || blockedPeople == null
          ? _value.blockedPeople
          // ignore: cast_nullable_to_non_nullable
          : blockedPeople as int,
      watchedBrowserRuns:
          watchedBrowserRuns == const $CopyWithPlaceholder() ||
              watchedBrowserRuns == null
          ? _value.watchedBrowserRuns
          // ignore: cast_nullable_to_non_nullable
          : watchedBrowserRuns as int,
      phoneRuns: phoneRuns == const $CopyWithPlaceholder() || phoneRuns == null
          ? _value.phoneRuns
          // ignore: cast_nullable_to_non_nullable
          : phoneRuns as int,
      phonePeople:
          phonePeople == const $CopyWithPlaceholder() || phonePeople == null
          ? _value.phonePeople
          // ignore: cast_nullable_to_non_nullable
          : phonePeople as int,
      phonesPaired:
          phonesPaired == const $CopyWithPlaceholder() || phonesPaired == null
          ? _value.phonesPaired
          // ignore: cast_nullable_to_non_nullable
          : phonesPaired as int,
      phonesWithSites:
          phonesWithSites == const $CopyWithPlaceholder() ||
              phonesWithSites == null
          ? _value.phonesWithSites
          // ignore: cast_nullable_to_non_nullable
          : phonesWithSites as int,
      refusedSteps:
          refusedSteps == const $CopyWithPlaceholder() || refusedSteps == null
          ? _value.refusedSteps
          // ignore: cast_nullable_to_non_nullable
          : refusedSteps as int,
    );
  }
}

extension $AppBrowserNumbersCopyWith on AppBrowserNumbers {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAppBrowserNumbers.copyWith(...)` or `instanceOfAppBrowserNumbers.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppBrowserNumbersCWProxy get copyWith =>
      _$AppBrowserNumbersCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppBrowserNumbers _$AppBrowserNumbersFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AppBrowserNumbers',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'days',
        'blocked_runs',
        'blocked_people',
        'watched_browser_runs',
        'phone_runs',
        'phone_people',
        'phones_paired',
        'phones_with_sites',
        'refused_steps',
      ],
    );
    final val = AppBrowserNumbers(
      days: $checkedConvert('days', (v) => (v as num).toInt()),
      blockedRuns: $checkedConvert('blocked_runs', (v) => (v as num).toInt()),
      blockedPeople: $checkedConvert(
        'blocked_people',
        (v) => (v as num).toInt(),
      ),
      watchedBrowserRuns: $checkedConvert(
        'watched_browser_runs',
        (v) => (v as num).toInt(),
      ),
      phoneRuns: $checkedConvert('phone_runs', (v) => (v as num).toInt()),
      phonePeople: $checkedConvert('phone_people', (v) => (v as num).toInt()),
      phonesPaired: $checkedConvert('phones_paired', (v) => (v as num).toInt()),
      phonesWithSites: $checkedConvert(
        'phones_with_sites',
        (v) => (v as num).toInt(),
      ),
      refusedSteps: $checkedConvert('refused_steps', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'blockedRuns': 'blocked_runs',
    'blockedPeople': 'blocked_people',
    'watchedBrowserRuns': 'watched_browser_runs',
    'phoneRuns': 'phone_runs',
    'phonePeople': 'phone_people',
    'phonesPaired': 'phones_paired',
    'phonesWithSites': 'phones_with_sites',
    'refusedSteps': 'refused_steps',
  },
);

Map<String, dynamic> _$AppBrowserNumbersToJson(AppBrowserNumbers instance) =>
    <String, dynamic>{
      'days': instance.days,
      'blocked_runs': instance.blockedRuns,
      'blocked_people': instance.blockedPeople,
      'watched_browser_runs': instance.watchedBrowserRuns,
      'phone_runs': instance.phoneRuns,
      'phone_people': instance.phonePeople,
      'phones_paired': instance.phonesPaired,
      'phones_with_sites': instance.phonesWithSites,
      'refused_steps': instance.refusedSteps,
    };
