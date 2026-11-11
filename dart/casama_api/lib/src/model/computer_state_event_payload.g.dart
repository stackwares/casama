// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_state_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerStateEventPayloadCWProxy {
  ComputerStateEventPayload computerId(String computerId);

  ComputerStateEventPayload state(ComputerStateEventPayloadStateEnum state);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerStateEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerStateEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerStateEventPayload call({
    String computerId,
    ComputerStateEventPayloadStateEnum state,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerStateEventPayload.copyWith(...)` or call `instanceOfComputerStateEventPayload.copyWith.fieldName(value)` for a single field.
class _$ComputerStateEventPayloadCWProxyImpl
    implements _$ComputerStateEventPayloadCWProxy {
  const _$ComputerStateEventPayloadCWProxyImpl(this._value);

  final ComputerStateEventPayload _value;

  @override
  ComputerStateEventPayload computerId(String computerId) =>
      call(computerId: computerId);

  @override
  ComputerStateEventPayload state(ComputerStateEventPayloadStateEnum state) =>
      call(state: state);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerStateEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerStateEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerStateEventPayload call({
    Object? computerId = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
  }) {
    return ComputerStateEventPayload(
      computerId:
          computerId == const $CopyWithPlaceholder() || computerId == null
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      state: state == const $CopyWithPlaceholder() || state == null
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as ComputerStateEventPayloadStateEnum,
    );
  }
}

extension $ComputerStateEventPayloadCopyWith on ComputerStateEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerStateEventPayload.copyWith(...)` or `instanceOfComputerStateEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerStateEventPayloadCWProxy get copyWith =>
      _$ComputerStateEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerStateEventPayload _$ComputerStateEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ComputerStateEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['computer_id', 'state']);
  final val = ComputerStateEventPayload(
    computerId: $checkedConvert('computer_id', (v) => v as String),
    state: $checkedConvert(
      'state',
      (v) => $enumDecode(_$ComputerStateEventPayloadStateEnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'computerId': 'computer_id'});

Map<String, dynamic> _$ComputerStateEventPayloadToJson(
  ComputerStateEventPayload instance,
) => <String, dynamic>{
  'computer_id': instance.computerId,
  'state': _$ComputerStateEventPayloadStateEnumEnumMap[instance.state]!,
};

const _$ComputerStateEventPayloadStateEnumEnumMap = {
  ComputerStateEventPayloadStateEnum.provisioning: 'provisioning',
  ComputerStateEventPayloadStateEnum.starting: 'starting',
  ComputerStateEventPayloadStateEnum.running: 'running',
  ComputerStateEventPayloadStateEnum.idle: 'idle',
  ComputerStateEventPayloadStateEnum.sleeping: 'sleeping',
  ComputerStateEventPayloadStateEnum.stopped: 'stopped',
  ComputerStateEventPayloadStateEnum.error: 'error',
};
