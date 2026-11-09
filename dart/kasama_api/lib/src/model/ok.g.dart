// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ok.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OkCWProxy {
  Ok ok(bool ok);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Ok(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Ok(...).copyWith(id: 12, name: "My name")
  /// ````
  Ok call({bool ok});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfOk.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfOk.copyWith.fieldName(...)`
class _$OkCWProxyImpl implements _$OkCWProxy {
  const _$OkCWProxyImpl(this._value);

  final Ok _value;

  @override
  Ok ok(bool ok) => this(ok: ok);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Ok(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Ok(...).copyWith(id: 12, name: "My name")
  /// ````
  Ok call({Object? ok = const $CopyWithPlaceholder()}) {
    return Ok(
      ok: ok == const $CopyWithPlaceholder()
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
    );
  }
}

extension $OkCopyWith on Ok {
  /// Returns a callable class that can be used as follows: `instanceOfOk.copyWith(...)` or like so:`instanceOfOk.copyWith.fieldName(...)`.
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
