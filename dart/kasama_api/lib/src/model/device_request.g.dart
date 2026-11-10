// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceRequestCWProxy {
  DeviceRequest id(String id);

  DeviceRequest sourceId(String sourceId);

  DeviceRequest kind(String kind);

  DeviceRequest action(DeviceRequestActionEnum action);

  DeviceRequest params(Map<String, Object?> params);

  DeviceRequest createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceRequest call({
    String id,
    String sourceId,
    String kind,
    DeviceRequestActionEnum action,
    Map<String, Object?> params,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceRequest.copyWith(...)` or call `instanceOfDeviceRequest.copyWith.fieldName(value)` for a single field.
class _$DeviceRequestCWProxyImpl implements _$DeviceRequestCWProxy {
  const _$DeviceRequestCWProxyImpl(this._value);

  final DeviceRequest _value;

  @override
  DeviceRequest id(String id) => call(id: id);

  @override
  DeviceRequest sourceId(String sourceId) => call(sourceId: sourceId);

  @override
  DeviceRequest kind(String kind) => call(kind: kind);

  @override
  DeviceRequest action(DeviceRequestActionEnum action) => call(action: action);

  @override
  DeviceRequest params(Map<String, Object?> params) => call(params: params);

  @override
  DeviceRequest createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceRequest call({
    Object? id = const $CopyWithPlaceholder(),
    Object? sourceId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? action = const $CopyWithPlaceholder(),
    Object? params = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return DeviceRequest(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      sourceId: sourceId == const $CopyWithPlaceholder() || sourceId == null
          ? _value.sourceId
          // ignore: cast_nullable_to_non_nullable
          : sourceId as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      action: action == const $CopyWithPlaceholder() || action == null
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as DeviceRequestActionEnum,
      params: params == const $CopyWithPlaceholder() || params == null
          ? _value.params
          // ignore: cast_nullable_to_non_nullable
          : params as Map<String, Object?>,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $DeviceRequestCopyWith on DeviceRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceRequest.copyWith(...)` or `instanceOfDeviceRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceRequestCWProxy get copyWith => _$DeviceRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRequest _$DeviceRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeviceRequest', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'source_id',
          'kind',
          'action',
          'params',
          'created_at',
        ],
      );
      final val = DeviceRequest(
        id: $checkedConvert('id', (v) => v as String),
        sourceId: $checkedConvert('source_id', (v) => v as String),
        kind: $checkedConvert('kind', (v) => v as String),
        action: $checkedConvert(
          'action',
          (v) => $enumDecode(_$DeviceRequestActionEnumEnumMap, v),
        ),
        params: $checkedConvert('params', (v) => v as Map<String, dynamic>),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'sourceId': 'source_id', 'createdAt': 'created_at'});

Map<String, dynamic> _$DeviceRequestToJson(DeviceRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source_id': instance.sourceId,
      'kind': instance.kind,
      'action': _$DeviceRequestActionEnumEnumMap[instance.action]!,
      'params': instance.params,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$DeviceRequestActionEnumEnumMap = {
  DeviceRequestActionEnum.read: 'read',
  DeviceRequestActionEnum.calendarPeriodCreate: 'calendar.create',
  DeviceRequestActionEnum.remindersPeriodCreate: 'reminders.create',
};
