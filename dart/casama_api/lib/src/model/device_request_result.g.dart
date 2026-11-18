// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_request_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceRequestResultCWProxy {
  DeviceRequestResult ok(bool ok);

  DeviceRequestResult result(Map<String, Object?>? result);

  DeviceRequestResult error(String? error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceRequestResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceRequestResult(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceRequestResult call({
    bool ok,
    Map<String, Object?>? result,
    String? error,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceRequestResult.copyWith(...)` or call `instanceOfDeviceRequestResult.copyWith.fieldName(value)` for a single field.
class _$DeviceRequestResultCWProxyImpl implements _$DeviceRequestResultCWProxy {
  const _$DeviceRequestResultCWProxyImpl(this._value);

  final DeviceRequestResult _value;

  @override
  DeviceRequestResult ok(bool ok) => call(ok: ok);

  @override
  DeviceRequestResult result(Map<String, Object?>? result) =>
      call(result: result);

  @override
  DeviceRequestResult error(String? error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceRequestResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceRequestResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceRequestResult call({
    Object? ok = const $CopyWithPlaceholder(),
    Object? result = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return DeviceRequestResult(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
      result: result == const $CopyWithPlaceholder()
          ? _value.result
          // ignore: cast_nullable_to_non_nullable
          : result as Map<String, Object?>?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
    );
  }
}

extension $DeviceRequestResultCopyWith on DeviceRequestResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceRequestResult.copyWith(...)` or `instanceOfDeviceRequestResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceRequestResultCWProxy get copyWith =>
      _$DeviceRequestResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRequestResult _$DeviceRequestResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeviceRequestResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ok']);
      final val = DeviceRequestResult(
        ok: $checkedConvert('ok', (v) => v as bool),
        result: $checkedConvert('result', (v) => v as Map<String, dynamic>?),
        error: $checkedConvert('error', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$DeviceRequestResultToJson(
  DeviceRequestResult instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'result': ?instance.result,
  'error': ?instance.error,
};
