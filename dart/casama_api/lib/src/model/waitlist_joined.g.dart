// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_joined.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WaitlistJoinedCWProxy {
  WaitlistJoined ok(bool ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistJoined(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistJoined(...).copyWith(id: 12, name: "My name")
  /// ```
  WaitlistJoined call({bool ok});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWaitlistJoined.copyWith(...)` or call `instanceOfWaitlistJoined.copyWith.fieldName(value)` for a single field.
class _$WaitlistJoinedCWProxyImpl implements _$WaitlistJoinedCWProxy {
  const _$WaitlistJoinedCWProxyImpl(this._value);

  final WaitlistJoined _value;

  @override
  WaitlistJoined ok(bool ok) => call(ok: ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistJoined(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistJoined(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WaitlistJoined call({Object? ok = const $CopyWithPlaceholder()}) {
    return WaitlistJoined(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
    );
  }
}

extension $WaitlistJoinedCopyWith on WaitlistJoined {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWaitlistJoined.copyWith(...)` or `instanceOfWaitlistJoined.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WaitlistJoinedCWProxy get copyWith => _$WaitlistJoinedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaitlistJoined _$WaitlistJoinedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WaitlistJoined', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ok']);
      final val = WaitlistJoined(ok: $checkedConvert('ok', (v) => v as bool));
      return val;
    });

Map<String, dynamic> _$WaitlistJoinedToJson(WaitlistJoined instance) =>
    <String, dynamic>{'ok': instance.ok};
