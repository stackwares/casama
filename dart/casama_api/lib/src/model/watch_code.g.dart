// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_code.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchCodeCWProxy {
  WatchCode code(String code);

  WatchCode expiresAt(DateTime expiresAt);

  WatchCode pollEveryS(int pollEveryS);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchCode(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchCode call({String code, DateTime expiresAt, int pollEveryS});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchCode.copyWith(...)` or call `instanceOfWatchCode.copyWith.fieldName(value)` for a single field.
class _$WatchCodeCWProxyImpl implements _$WatchCodeCWProxy {
  const _$WatchCodeCWProxyImpl(this._value);

  final WatchCode _value;

  @override
  WatchCode code(String code) => call(code: code);

  @override
  WatchCode expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  WatchCode pollEveryS(int pollEveryS) => call(pollEveryS: pollEveryS);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchCode(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchCode call({
    Object? code = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? pollEveryS = const $CopyWithPlaceholder(),
  }) {
    return WatchCode(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      pollEveryS:
          pollEveryS == const $CopyWithPlaceholder() || pollEveryS == null
          ? _value.pollEveryS
          // ignore: cast_nullable_to_non_nullable
          : pollEveryS as int,
    );
  }
}

extension $WatchCodeCopyWith on WatchCode {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchCode.copyWith(...)` or `instanceOfWatchCode.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchCodeCWProxy get copyWith => _$WatchCodeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchCode _$WatchCodeFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WatchCode',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['code', 'expires_at', 'poll_every_s'],
    );
    final val = WatchCode(
      code: $checkedConvert('code', (v) => v as String),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      pollEveryS: $checkedConvert('poll_every_s', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {'expiresAt': 'expires_at', 'pollEveryS': 'poll_every_s'},
);

Map<String, dynamic> _$WatchCodeToJson(WatchCode instance) => <String, dynamic>{
  'code': instance.code,
  'expires_at': instance.expiresAt.toIso8601String(),
  'poll_every_s': instance.pollEveryS,
};
