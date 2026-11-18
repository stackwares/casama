// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_signed_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchSignedOutCWProxy {
  WatchSignedOut ok(bool ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSignedOut(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSignedOut(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchSignedOut call({bool ok});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchSignedOut.copyWith(...)` or call `instanceOfWatchSignedOut.copyWith.fieldName(value)` for a single field.
class _$WatchSignedOutCWProxyImpl implements _$WatchSignedOutCWProxy {
  const _$WatchSignedOutCWProxyImpl(this._value);

  final WatchSignedOut _value;

  @override
  WatchSignedOut ok(bool ok) => call(ok: ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSignedOut(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSignedOut(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchSignedOut call({Object? ok = const $CopyWithPlaceholder()}) {
    return WatchSignedOut(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
    );
  }
}

extension $WatchSignedOutCopyWith on WatchSignedOut {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchSignedOut.copyWith(...)` or `instanceOfWatchSignedOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchSignedOutCWProxy get copyWith => _$WatchSignedOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchSignedOut _$WatchSignedOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchSignedOut', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ok']);
      final val = WatchSignedOut(ok: $checkedConvert('ok', (v) => v as bool));
      return val;
    });

Map<String, dynamic> _$WatchSignedOutToJson(WatchSignedOut instance) =>
    <String, dynamic>{'ok': instance.ok};
