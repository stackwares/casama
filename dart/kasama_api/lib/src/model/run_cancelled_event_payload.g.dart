// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_cancelled_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunCancelledEventPayloadCWProxy {
  RunCancelledEventPayload cancelledBy(String? cancelledBy);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunCancelledEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunCancelledEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  RunCancelledEventPayload call({String? cancelledBy});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRunCancelledEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRunCancelledEventPayload.copyWith.fieldName(...)`
class _$RunCancelledEventPayloadCWProxyImpl
    implements _$RunCancelledEventPayloadCWProxy {
  const _$RunCancelledEventPayloadCWProxyImpl(this._value);

  final RunCancelledEventPayload _value;

  @override
  RunCancelledEventPayload cancelledBy(String? cancelledBy) =>
      this(cancelledBy: cancelledBy);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunCancelledEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunCancelledEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  RunCancelledEventPayload call({
    Object? cancelledBy = const $CopyWithPlaceholder(),
  }) {
    return RunCancelledEventPayload(
      cancelledBy: cancelledBy == const $CopyWithPlaceholder()
          ? _value.cancelledBy
          // ignore: cast_nullable_to_non_nullable
          : cancelledBy as String?,
    );
  }
}

extension $RunCancelledEventPayloadCopyWith on RunCancelledEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfRunCancelledEventPayload.copyWith(...)` or like so:`instanceOfRunCancelledEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunCancelledEventPayloadCWProxy get copyWith =>
      _$RunCancelledEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunCancelledEventPayload _$RunCancelledEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RunCancelledEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['cancelled_by']);
    final val = RunCancelledEventPayload(
      cancelledBy: $checkedConvert('cancelled_by', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {'cancelledBy': 'cancelled_by'},
);

Map<String, dynamic> _$RunCancelledEventPayloadToJson(
  RunCancelledEventPayload instance,
) => <String, dynamic>{'cancelled_by': instance.cancelledBy};
