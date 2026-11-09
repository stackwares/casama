// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ok.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OkCWProxy {
  Ok ok(bool ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Ok(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Ok(...).copyWith(id: 12, name: "My name")
  /// ```
  Ok call({bool ok});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOk.copyWith(...)` or call `instanceOfOk.copyWith.fieldName(value)` for a single field.
class _$OkCWProxyImpl implements _$OkCWProxy {
  const _$OkCWProxyImpl(this._value);

  final Ok _value;

  @override
  Ok ok(bool ok) => call(ok: ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Ok(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Ok(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Ok call({Object? ok = const $CopyWithPlaceholder()}) {
    return Ok(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
    );
  }
}

extension $OkCopyWith on Ok {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOk.copyWith(...)` or `instanceOfOk.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OkCWProxy get copyWith => _$OkCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ok _$OkFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Ok', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ok']);
      final val = Ok(ok: $checkedConvert('ok', (v) => v as bool));
      return val;
    });

Map<String, dynamic> _$OkToJson(Ok instance) => <String, dynamic>{
  'ok': instance.ok,
};
