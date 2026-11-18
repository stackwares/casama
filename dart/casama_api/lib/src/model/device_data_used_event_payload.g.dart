// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_data_used_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceDataUsedEventPayloadCWProxy {
  DeviceDataUsedEventPayload kind(String kind);

  DeviceDataUsedEventPayload count(int count);

  DeviceDataUsedEventPayload from(String from);

  DeviceDataUsedEventPayload to(String to);

  DeviceDataUsedEventPayload devices(List<String> devices);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceDataUsedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceDataUsedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceDataUsedEventPayload call({
    String kind,
    int count,
    String from,
    String to,
    List<String> devices,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceDataUsedEventPayload.copyWith(...)` or call `instanceOfDeviceDataUsedEventPayload.copyWith.fieldName(value)` for a single field.
class _$DeviceDataUsedEventPayloadCWProxyImpl
    implements _$DeviceDataUsedEventPayloadCWProxy {
  const _$DeviceDataUsedEventPayloadCWProxyImpl(this._value);

  final DeviceDataUsedEventPayload _value;

  @override
  DeviceDataUsedEventPayload kind(String kind) => call(kind: kind);

  @override
  DeviceDataUsedEventPayload count(int count) => call(count: count);

  @override
  DeviceDataUsedEventPayload from(String from) => call(from: from);

  @override
  DeviceDataUsedEventPayload to(String to) => call(to: to);

  @override
  DeviceDataUsedEventPayload devices(List<String> devices) =>
      call(devices: devices);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceDataUsedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceDataUsedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceDataUsedEventPayload call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? from = const $CopyWithPlaceholder(),
    Object? to = const $CopyWithPlaceholder(),
    Object? devices = const $CopyWithPlaceholder(),
  }) {
    return DeviceDataUsedEventPayload(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      from: from == const $CopyWithPlaceholder() || from == null
          ? _value.from
          // ignore: cast_nullable_to_non_nullable
          : from as String,
      to: to == const $CopyWithPlaceholder() || to == null
          ? _value.to
          // ignore: cast_nullable_to_non_nullable
          : to as String,
      devices: devices == const $CopyWithPlaceholder() || devices == null
          ? _value.devices
          // ignore: cast_nullable_to_non_nullable
          : devices as List<String>,
    );
  }
}

extension $DeviceDataUsedEventPayloadCopyWith on DeviceDataUsedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceDataUsedEventPayload.copyWith(...)` or `instanceOfDeviceDataUsedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceDataUsedEventPayloadCWProxy get copyWith =>
      _$DeviceDataUsedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceDataUsedEventPayload _$DeviceDataUsedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeviceDataUsedEventPayload', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['kind', 'count', 'from', 'to', 'devices'],
  );
  final val = DeviceDataUsedEventPayload(
    kind: $checkedConvert('kind', (v) => v as String),
    count: $checkedConvert('count', (v) => (v as num).toInt()),
    from: $checkedConvert('from', (v) => v as String),
    to: $checkedConvert('to', (v) => v as String),
    devices: $checkedConvert(
      'devices',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$DeviceDataUsedEventPayloadToJson(
  DeviceDataUsedEventPayload instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'count': instance.count,
  'from': instance.from,
  'to': instance.to,
  'devices': instance.devices,
};
