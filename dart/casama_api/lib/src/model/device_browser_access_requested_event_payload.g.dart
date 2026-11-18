// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_browser_access_requested_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceBrowserAccessRequestedEventPayloadCWProxy {
  DeviceBrowserAccessRequestedEventPayload kind(
    DeviceBrowserAccessRequestedEventPayloadKindEnum kind,
  );

  DeviceBrowserAccessRequestedEventPayload reason(String reason);

  DeviceBrowserAccessRequestedEventPayload botId(String botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceBrowserAccessRequestedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceBrowserAccessRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceBrowserAccessRequestedEventPayload call({
    DeviceBrowserAccessRequestedEventPayloadKindEnum kind,
    String reason,
    String botId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceBrowserAccessRequestedEventPayload.copyWith(...)` or call `instanceOfDeviceBrowserAccessRequestedEventPayload.copyWith.fieldName(value)` for a single field.
class _$DeviceBrowserAccessRequestedEventPayloadCWProxyImpl
    implements _$DeviceBrowserAccessRequestedEventPayloadCWProxy {
  const _$DeviceBrowserAccessRequestedEventPayloadCWProxyImpl(this._value);

  final DeviceBrowserAccessRequestedEventPayload _value;

  @override
  DeviceBrowserAccessRequestedEventPayload kind(
    DeviceBrowserAccessRequestedEventPayloadKindEnum kind,
  ) => call(kind: kind);

  @override
  DeviceBrowserAccessRequestedEventPayload reason(String reason) =>
      call(reason: reason);

  @override
  DeviceBrowserAccessRequestedEventPayload botId(String botId) =>
      call(botId: botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceBrowserAccessRequestedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceBrowserAccessRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceBrowserAccessRequestedEventPayload call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
  }) {
    return DeviceBrowserAccessRequestedEventPayload(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as DeviceBrowserAccessRequestedEventPayloadKindEnum,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
    );
  }
}

extension $DeviceBrowserAccessRequestedEventPayloadCopyWith
    on DeviceBrowserAccessRequestedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceBrowserAccessRequestedEventPayload.copyWith(...)` or `instanceOfDeviceBrowserAccessRequestedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceBrowserAccessRequestedEventPayloadCWProxy get copyWith =>
      _$DeviceBrowserAccessRequestedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceBrowserAccessRequestedEventPayload
_$DeviceBrowserAccessRequestedEventPayloadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeviceBrowserAccessRequestedEventPayload', json, (
      $checkedConvert,
    ) {
      $checkKeys(json, requiredKeys: const ['kind', 'reason', 'bot_id']);
      final val = DeviceBrowserAccessRequestedEventPayload(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(
            _$DeviceBrowserAccessRequestedEventPayloadKindEnumEnumMap,
            v,
          ),
        ),
        reason: $checkedConvert('reason', (v) => v as String),
        botId: $checkedConvert('bot_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'botId': 'bot_id'});

Map<String, dynamic> _$DeviceBrowserAccessRequestedEventPayloadToJson(
  DeviceBrowserAccessRequestedEventPayload instance,
) => <String, dynamic>{
  'kind':
      _$DeviceBrowserAccessRequestedEventPayloadKindEnumEnumMap[instance.kind]!,
  'reason': instance.reason,
  'bot_id': instance.botId,
};

const _$DeviceBrowserAccessRequestedEventPayloadKindEnumEnumMap = {
  DeviceBrowserAccessRequestedEventPayloadKindEnum.browserTab: 'browser_tab',
  DeviceBrowserAccessRequestedEventPayloadKindEnum.browserHistory:
      'browser_history',
};
