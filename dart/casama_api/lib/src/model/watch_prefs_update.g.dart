// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_prefs_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchPrefsUpdateCWProxy {
  WatchPrefsUpdate allow(WatchAllowLevel? allow);

  WatchPrefsUpdate showDetails(bool? showDetails);

  WatchPrefsUpdate quickReplies(List<String>? quickReplies);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchPrefsUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchPrefsUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchPrefsUpdate call({
    WatchAllowLevel? allow,
    bool? showDetails,
    List<String>? quickReplies,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchPrefsUpdate.copyWith(...)` or call `instanceOfWatchPrefsUpdate.copyWith.fieldName(value)` for a single field.
class _$WatchPrefsUpdateCWProxyImpl implements _$WatchPrefsUpdateCWProxy {
  const _$WatchPrefsUpdateCWProxyImpl(this._value);

  final WatchPrefsUpdate _value;

  @override
  WatchPrefsUpdate allow(WatchAllowLevel? allow) => call(allow: allow);

  @override
  WatchPrefsUpdate showDetails(bool? showDetails) =>
      call(showDetails: showDetails);

  @override
  WatchPrefsUpdate quickReplies(List<String>? quickReplies) =>
      call(quickReplies: quickReplies);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchPrefsUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchPrefsUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchPrefsUpdate call({
    Object? allow = const $CopyWithPlaceholder(),
    Object? showDetails = const $CopyWithPlaceholder(),
    Object? quickReplies = const $CopyWithPlaceholder(),
  }) {
    return WatchPrefsUpdate(
      allow: allow == const $CopyWithPlaceholder()
          ? _value.allow
          // ignore: cast_nullable_to_non_nullable
          : allow as WatchAllowLevel?,
      showDetails: showDetails == const $CopyWithPlaceholder()
          ? _value.showDetails
          // ignore: cast_nullable_to_non_nullable
          : showDetails as bool?,
      quickReplies: quickReplies == const $CopyWithPlaceholder()
          ? _value.quickReplies
          // ignore: cast_nullable_to_non_nullable
          : quickReplies as List<String>?,
    );
  }
}

extension $WatchPrefsUpdateCopyWith on WatchPrefsUpdate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchPrefsUpdate.copyWith(...)` or `instanceOfWatchPrefsUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchPrefsUpdateCWProxy get copyWith => _$WatchPrefsUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchPrefsUpdate _$WatchPrefsUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'WatchPrefsUpdate',
      json,
      ($checkedConvert) {
        final val = WatchPrefsUpdate(
          allow: $checkedConvert(
            'allow',
            (v) => $enumDecodeNullable(_$WatchAllowLevelEnumMap, v),
          ),
          showDetails: $checkedConvert('show_details', (v) => v as bool?),
          quickReplies: $checkedConvert(
            'quick_replies',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'showDetails': 'show_details',
        'quickReplies': 'quick_replies',
      },
    );

Map<String, dynamic> _$WatchPrefsUpdateToJson(WatchPrefsUpdate instance) =>
    <String, dynamic>{
      'allow': ?_$WatchAllowLevelEnumMap[instance.allow],
      'show_details': ?instance.showDetails,
      'quick_replies': ?instance.quickReplies,
    };

const _$WatchAllowLevelEnumMap = {
  WatchAllowLevel.medium: 'medium',
  WatchAllowLevel.low: 'low',
  WatchAllowLevel.none: 'none',
};
