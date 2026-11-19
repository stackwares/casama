// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_prefs.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchPrefsCWProxy {
  WatchPrefs allow(WatchAllowLevel allow);

  WatchPrefs showDetails(bool showDetails);

  WatchPrefs quickReplies(List<String> quickReplies);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchPrefs(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchPrefs(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchPrefs call({
    WatchAllowLevel allow,
    bool showDetails,
    List<String> quickReplies,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchPrefs.copyWith(...)` or call `instanceOfWatchPrefs.copyWith.fieldName(value)` for a single field.
class _$WatchPrefsCWProxyImpl implements _$WatchPrefsCWProxy {
  const _$WatchPrefsCWProxyImpl(this._value);

  final WatchPrefs _value;

  @override
  WatchPrefs allow(WatchAllowLevel allow) => call(allow: allow);

  @override
  WatchPrefs showDetails(bool showDetails) => call(showDetails: showDetails);

  @override
  WatchPrefs quickReplies(List<String> quickReplies) =>
      call(quickReplies: quickReplies);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchPrefs(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchPrefs(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchPrefs call({
    Object? allow = const $CopyWithPlaceholder(),
    Object? showDetails = const $CopyWithPlaceholder(),
    Object? quickReplies = const $CopyWithPlaceholder(),
  }) {
    return WatchPrefs(
      allow: allow == const $CopyWithPlaceholder() || allow == null
          ? _value.allow
          // ignore: cast_nullable_to_non_nullable
          : allow as WatchAllowLevel,
      showDetails:
          showDetails == const $CopyWithPlaceholder() || showDetails == null
          ? _value.showDetails
          // ignore: cast_nullable_to_non_nullable
          : showDetails as bool,
      quickReplies:
          quickReplies == const $CopyWithPlaceholder() || quickReplies == null
          ? _value.quickReplies
          // ignore: cast_nullable_to_non_nullable
          : quickReplies as List<String>,
    );
  }
}

extension $WatchPrefsCopyWith on WatchPrefs {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchPrefs.copyWith(...)` or `instanceOfWatchPrefs.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchPrefsCWProxy get copyWith => _$WatchPrefsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchPrefs _$WatchPrefsFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WatchPrefs',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['allow', 'show_details', 'quick_replies'],
    );
    final val = WatchPrefs(
      allow: $checkedConvert(
        'allow',
        (v) => $enumDecode(_$WatchAllowLevelEnumMap, v),
      ),
      showDetails: $checkedConvert('show_details', (v) => v as bool),
      quickReplies: $checkedConvert(
        'quick_replies',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'showDetails': 'show_details',
    'quickReplies': 'quick_replies',
  },
);

Map<String, dynamic> _$WatchPrefsToJson(WatchPrefs instance) =>
    <String, dynamic>{
      'allow': _$WatchAllowLevelEnumMap[instance.allow]!,
      'show_details': instance.showDetails,
      'quick_replies': instance.quickReplies,
    };

const _$WatchAllowLevelEnumMap = {
  WatchAllowLevel.medium: 'medium',
  WatchAllowLevel.low: 'low',
  WatchAllowLevel.none: 'none',
};
