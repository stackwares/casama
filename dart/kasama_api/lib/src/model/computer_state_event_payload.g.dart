// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_state_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerStateEventPayloadCWProxy {
  ComputerStateEventPayload computerId(String computerId);

  ComputerStateEventPayload state(ComputerStateEventPayloadStateEnum state);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComputerStateEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComputerStateEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ComputerStateEventPayload call({
    String computerId,
    ComputerStateEventPayloadStateEnum state,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComputerStateEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComputerStateEventPayload.copyWith.fieldName(...)`
class _$ComputerStateEventPayloadCWProxyImpl
    implements _$ComputerStateEventPayloadCWProxy {
  const _$ComputerStateEventPayloadCWProxyImpl(this._value);

  final ComputerStateEventPayload _value;

  @override
  ComputerStateEventPayload computerId(String computerId) =>
      this(computerId: computerId);

  @override
  ComputerStateEventPayload state(ComputerStateEventPayloadStateEnum state) =>
      this(state: state);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComputerStateEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComputerStateEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ComputerStateEventPayload call({
    Object? computerId = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
  }) {
    return ComputerStateEventPayload(
      computerId: computerId == const $CopyWithPlaceholder()
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      state: state == const $CopyWithPlaceholder()
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as ComputerStateEventPayloadStateEnum,
    );
  }
}

extension $ComputerStateEventPayloadCopyWith on ComputerStateEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfComputerStateEventPayload.copyWith(...)` or like so:`instanceOfComputerStateEventPayload.copyWith.fieldName(...)`.
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
