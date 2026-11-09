// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeover_requested_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeoverRequestedEventPayloadCWProxy {
  TakeoverRequestedEventPayload computerId(String computerId);

  TakeoverRequestedEventPayload reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeoverRequestedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeoverRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  TakeoverRequestedEventPayload call({String computerId, String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTakeoverRequestedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTakeoverRequestedEventPayload.copyWith.fieldName(...)`
class _$TakeoverRequestedEventPayloadCWProxyImpl
    implements _$TakeoverRequestedEventPayloadCWProxy {
  const _$TakeoverRequestedEventPayloadCWProxyImpl(this._value);

  final TakeoverRequestedEventPayload _value;

  @override
  TakeoverRequestedEventPayload computerId(String computerId) =>
      this(computerId: computerId);

  @override
  TakeoverRequestedEventPayload reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeoverRequestedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeoverRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  TakeoverRequestedEventPayload call({
    Object? computerId = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return TakeoverRequestedEventPayload(
      computerId: computerId == const $CopyWithPlaceholder()
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $TakeoverRequestedEventPayloadCopyWith
    on TakeoverRequestedEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfTakeoverRequestedEventPayload.copyWith(...)` or like so:`instanceOfTakeoverRequestedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeoverRequestedEventPayloadCWProxy get copyWith =>
      _$TakeoverRequestedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeoverRequestedEventPayload _$TakeoverRequestedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'TakeoverRequestedEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['computer_id', 'reason']);
    final val = TakeoverRequestedEventPayload(
      computerId: $checkedConvert('computer_id', (v) => v as String),
      reason: $checkedConvert('reason', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'computerId': 'computer_id'},
);

Map<String, dynamic> _$TakeoverRequestedEventPayloadToJson(
  TakeoverRequestedEventPayload instance,
) => <String, dynamic>{
  'computer_id': instance.computerId,
  'reason': instance.reason,
};
