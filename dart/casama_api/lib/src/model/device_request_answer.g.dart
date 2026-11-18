// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_request_answer.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceRequestAnswerCWProxy {
  DeviceRequestAnswer device(String device);

  DeviceRequestAnswer result(BrowserTabSummary result);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceRequestAnswer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceRequestAnswer(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceRequestAnswer call({String device, BrowserTabSummary result});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceRequestAnswer.copyWith(...)` or call `instanceOfDeviceRequestAnswer.copyWith.fieldName(value)` for a single field.
class _$DeviceRequestAnswerCWProxyImpl implements _$DeviceRequestAnswerCWProxy {
  const _$DeviceRequestAnswerCWProxyImpl(this._value);

  final DeviceRequestAnswer _value;

  @override
  DeviceRequestAnswer device(String device) => call(device: device);

  @override
  DeviceRequestAnswer result(BrowserTabSummary result) => call(result: result);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceRequestAnswer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceRequestAnswer(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceRequestAnswer call({
    Object? device = const $CopyWithPlaceholder(),
    Object? result = const $CopyWithPlaceholder(),
  }) {
    return DeviceRequestAnswer(
      device: device == const $CopyWithPlaceholder() || device == null
          ? _value.device
          // ignore: cast_nullable_to_non_nullable
          : device as String,
      result: result == const $CopyWithPlaceholder() || result == null
          ? _value.result
          // ignore: cast_nullable_to_non_nullable
          : result as BrowserTabSummary,
    );
  }
}

extension $DeviceRequestAnswerCopyWith on DeviceRequestAnswer {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceRequestAnswer.copyWith(...)` or `instanceOfDeviceRequestAnswer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceRequestAnswerCWProxy get copyWith =>
      _$DeviceRequestAnswerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRequestAnswer _$DeviceRequestAnswerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeviceRequestAnswer', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['device', 'result']);
      final val = DeviceRequestAnswer(
        device: $checkedConvert('device', (v) => v as String),
        result: $checkedConvert(
          'result',
          (v) => BrowserTabSummary.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DeviceRequestAnswerToJson(
  DeviceRequestAnswer instance,
) => <String, dynamic>{
  'device': instance.device,
  'result': instance.result.toJson(),
};
